#!/usr/bin/env bash
# check-red-green.sh <worktree> <base-sha> "<verify command>" [<ticket.md> [<ticket-start-sha>]]
#   DELIVERS: every `- US-n.ACm:` line under the ticket's ## Delivers has a red or guard
#           commit in <ticket-start>..HEAD (start defaults to base; fix rounds pass the dispatch BASE)
#   RED:   every `test(US-n.ACm): red` commit in base..HEAD fails its own test files (see narrowed)
#   GUARD:  every `test(US-n.ACm): guard` commit passes them and names a `Mutation:` in its body
#   GREEN:  HEAD passes the verify command
#   FROZEN: no later non-red/guard commit touches a file a red or guard commit touched
#   TESTS:  a red or guard commit touches test files only (see test_re)
# One line per check. Exit 0 all OK, 1 any FAIL, 2 could not run.
set -u
wt=$1 base=$2 verify=$3 ticket=${4:-} start=${5:-$2}
here=$(cd "$(dirname "$0")" && pwd)
red_re='^test\(US-[0-9]+\.AC[0-9]+[a-z]?\): (red|guard)$'
. "$here/test-re.sh"
. "$here/ac-covered.sh"
if [ -n "$ticket" ]; then
  case $ticket in /*) ;; *) ticket=$PWD/$ticket ;; esac
  [ -r "$ticket" ] || { echo "ERROR cannot read ticket $ticket. Fix: pass the ticket path from the index (docs/work/<feature>/tickets/<id>-*.md)."; exit 2; }
fi

cd "$wt" || { echo "ERROR cannot cd to $wt. Fix: pass the worktree path from the implementer's report (git worktree list shows it)."; exit 2; }
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "ERROR worktree has uncommitted changes. Fix: the implementer commits or discards them (git -C <worktree> status), then re-run."; exit 2; }
head=$(git rev-parse HEAD)
branch=$(git symbolic-ref -q --short HEAD || echo "$head")
patch=$(mktemp)
trap 'git checkout -q -f "$branch" 2>/dev/null; rm -f "$patch"' EXIT
[ -z "$ticket" ] || git merge-base --is-ancestor "$start" "$head" 2>/dev/null || { echo "ERROR ticket start $start is not an ancestor of HEAD. Fix: pass the BASE the ticket was dispatched from."; exit 2; }

last_line() { # most telling line of a test run's output
  local l
  l=$(printf '%s\n' "$1" | grep -E 'Error|FAIL|assert|[Ee]xpected' | tail -n 1)
  [ -n "$l" ] || l=$(printf '%s\n' "$1" | tail -n 1)
  printf '%s' "$l" | cut -c1-200
}

pytest_cmd() { # <extra flags> <files>: the narrow pytest command for the test_*.py files under a
  # tests/ or tests_unit/ dir in <files>, run from their package root; nothing when none or two roots
  local tests roots py
  tests=$(printf '%s\n' "$2" | grep -E '(^|/)tests(_unit)?/(.*/)?test_[^/]*\.py$')
  roots=$(printf '%s\n' "$2" | sed -nE 's#^(.*/)?tests(_unit)?/.*#\1#p' | sort -u)
  [ -n "$tests" ] && [ "$(printf '%s\n' "$roots" | wc -l)" -eq 1 ] || return 0
  py=$(printf '%s' "$verify" | grep -oE '[^ ]*/python3?' | head -n 1)
  printf 'cd %q && %s -m pytest -q%s -p no:cacheprovider -p no:xdist' "${roots:-.}" "${py:-python3}" "$1"
  printf ' %q' $(printf '%s\n' "$tests" | sed "s#^${roots}##")
}

# The command a red/guard commit runs: only the test_*.py files it added or changed,
# serially from their package root. The full verify when it touched anything outside a
# tests/ or tests_unit/ dir (e.g. a frontend test) or spans two package roots.
narrowed() {
  local all cmd
  all=$(git diff-tree --no-commit-id --name-only -r --diff-filter=AMR "$1")
  [ "$(printf '%s\n' "$all" | grep -cvE '(^|/)tests(_unit)?/')" -eq 0 ] && cmd=$(pytest_cmd "" "$all")
  printf '%s' "${cmd:-$verify}"
}

finding() { # <mode> <check> <subject> <text> <fix>: FAIL and fail=1 in block mode, WARN in warn mode
  if [ "$1" = block ]; then echo "FAIL $2 $3: $4. Fix: $5"; fail=1; else
    echo "WARN $2 $3: $4. Fix: $5"
    [ -z "$ticket" ] || "$here/wf" warn-log "$(dirname "$(dirname "$ticket")")" "$2" "$ticket_id" "$3: $4"
  fi
}
# WORDING: mutate-copy over the ticket's changed .py sources, with only its red and guard
# test files as the test command (`false` when they are not under one package's tests dir).
wording() {
  local srcs tests cmd out rc l
  srcs=$(git diff --name-only --diff-filter=AM "$start..$head" | grep -E '\.py$' | grep -vE "$test_re")
  [ -n "$srcs" ] || return 0
  tests=$(for c in $(git log --format='%H %s' "$start..$head" | grep -E "^[0-9a-f]+ ${red_re#^}" | cut -d' ' -f1); do
    git diff-tree --no-commit-id --name-only -r --diff-filter=AM "$c"
  done | grep -E '(^|/)tests(_unit)?/(.*/)?test_[^/]*\.py$' | sort -u)
  cmd=$(pytest_cmd " -x" "$tests")
  cmd=${cmd:-false}
  out=$("$here/mutate-copy" --base "$start" $srcs -- bash -c "$cmd" 2>&1); rc=$?
  [ $rc = 0 ] && return 0
  if [ $rc = 1 ] && printf '%s\n' "$out" | grep -q '^SURVIVED '; then
    while read -r l; do
      finding "$wording_mode" wording "${l%% *}" "SURVIVED ${l#* }" \
        "add an assertion on the rule this sentence states to this ticket's test; a sentence that only describes needs none (the ticket reviewer decides)."
    done <<<"$(printf '%s\n' "$out" | sed -n 's/^SURVIVED \([^ ]*\): /\1 /p')"
  else
    finding "$wording_mode" wording "$ticket_id" "could not run: $(printf '%s\n' "$out" | tail -n 1 | cut -c1-200)" \
      "keep snapshot and golden tests out of this ticket's red and guard test files, and put its tests under one package's tests dir."
  fi
}

guard_patch_mode=$("$here/wf" mode guard-patch) || { echo "$guard_patch_mode"; exit 2; }
if [ -n "$ticket" ]; then
  delivers_mode=$("$here/wf" mode delivers) || { echo "$delivers_mode"; exit 2; }
  wording_mode=$("$here/wf" mode wording) || { echo "$wording_mode"; exit 2; }
  ticket_id=$(basename "$ticket"); ticket_id=${ticket_id%%-*}
fi

fail=0
reds=$(git log --reverse --format='%H %s' "$base..$head" | grep -E "^[0-9a-f]+ ${red_re#^}" | cut -d' ' -f1)
[ -n "$reds" ] || echo "INFO no red commits in $base..$head"

for r in $reds; do
  ac=$(git log -1 --format=%s "$r" | sed -E 's/^test\((.*)\): (red|guard)$/\1/')
  kind=$(git log -1 --format=%s "$r" | sed -E 's/.*: //')
  nontest=$(git diff-tree --no-commit-id --name-only -r "$r" | grep -vE "$test_re" | head -n 5 | tr '\n' ' ')
  [ -z "$nontest" ] || { echo "FAIL $kind $ac ${r:0:8}: touches non-test files: ${nontest% }. Fix: move those changes out of the $kind commit into the next commit, so it holds test files only."; fail=1; }
  git checkout -q --detach "$r"
  run=$(narrowed "$r")
  if [ "$kind" = guard ]; then
    mut=$(git log -1 --format=%b "$r" | grep -m1 '^Mutation: ' | cut -c1-200)
    if ! out=$(bash -c "$run" 2>&1); then
      echo "FAIL guard $ac ${r:0:8}: verify failed at the guard commit: $(last_line "$out"). Fix: a guard must pass on arrival; if the code is missing, make it a red commit and add a green one."; fail=1
    elif [ -z "$mut" ]; then
      echo "FAIL guard $ac ${r:0:8}: no \"Mutation: \" line in the commit body. Fix: break the code the way the AC forbids, see the test fail, restore, and add \"Mutation: <change> -> <failure>\" to the guard commit body."; fail=1
    else
      echo "OK   guard $ac ${r:0:8}: $mut"
      git log -1 --format=%b "$r" | sed -n '/^Mutation: /,$p' | awk 'f && /^```$/ {exit} f {print} /^```diff$/ {f=1}' > "$patch"
      testpath=$(git apply --numstat "$patch" 2>/dev/null | cut -f3- | grep -E "$test_re" | head -n 1)
      if [ ! -s "$patch" ]; then
        finding "$guard_patch_mode" guard-patch "$ac ${r:0:8}" "Mutation has no patch" \
          "re-do the break, save git diff -- <file>, and put it in the guard commit body in a diff fence under the Mutation: line (git commit --amend --cleanup=verbatim -F <file>)."
      elif [ -n "$testpath" ]; then
        finding "$guard_patch_mode" guard-patch "$ac ${r:0:8}" "Mutation patch changes a test file ($testpath)" \
          "the patch must change production code only; break the code, not the test."
      elif ! git apply --check "$patch" 2>/dev/null; then
        finding "$guard_patch_mode" guard-patch "$ac ${r:0:8}" "Mutation patch does not apply at the guard commit" \
          "regenerate it with git diff at that commit and commit with --cleanup=verbatim (the default cleanup strips blank lines and trailing spaces)."
      else
        git apply "$patch"
        if bash -c "$run" >/dev/null 2>&1; then
          finding "$guard_patch_mode" guard-patch "$ac ${r:0:8}" "tests still pass with the Mutation patch applied" \
            "strengthen the test until this patch makes it fail, or pick the break the AC forbids."
        fi
        git apply -R "$patch"
      fi
    fi
  elif out=$(bash -c "$run" 2>&1); then
    echo "FAIL red $ac ${r:0:8}: verify passed at the red commit. Fix: strengthen the test until it fails without the code; if the code already did this, make it a guard commit with a Mutation: line."; fail=1
  else
    echo "OK   red $ac ${r:0:8}: $(last_line "$out")"
  fi
  files=$(git diff-tree --no-commit-id --name-only -r "$r")
  for c in $(git rev-list --reverse "$r..$head"); do
    subj=$(git log -1 --format=%s "$c")
    printf '%s\n' "$subj" | grep -qE "$red_re" && continue
    touched=$(git diff-tree --no-commit-id --name-only -r "$c")
    for f in $files; do
      if printf '%s\n' "$touched" | grep -qFx -- "$f"; then
        echo "FAIL frozen $ac: ${c:0:8} \"$subj\" changed $f after its red commit. Fix: revert that change to $f; a test only changes after red with a lead ruling (may change:)."; fail=1
      fi
    done
  done
done

if [ -n "$ticket" ]; then
  subjects=$(git log --format=%s "$start..$head")
  for ac in $(sed -n '/^## Delivers/,/^## /p' "$ticket" | ac_uncovered "$subjects" - | cut -d' ' -f2); do
    finding "$delivers_mode" delivers "$ac" "no \"test($ac): red\" or guard commit in ${start:0:8}..${head:0:8}" \
      "add the red commit for $ac (or a guard with a Mutation patch if the code already does it); a prefactor's Delivers says none."
  done
fi

git checkout -q "$branch"
if out=$(bash -c "$verify" 2>&1); then
  echo "OK   green HEAD ${head:0:8}"
  [ -z "$ticket" ] || wording
else
  echo "FAIL green HEAD ${head:0:8}: $(last_line "$out"). Fix: make HEAD pass the verify command without editing a frozen test."; fail=1
fi
exit $fail
