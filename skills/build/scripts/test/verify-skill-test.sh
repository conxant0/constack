#!/usr/bin/env bash
# verify-skill-test.sh: wf verify-skill finds the verify skill or says why it is missing, and
# wf check-review fails a PASS whose Verify section says the skill is missing. Prints FAIL lines, exit 1 on any.
set -u
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
export HOME=$d GIT_CONFIG_NOSYSTEM=1
unset XDG_CONFIG_HOME
expect() { # expect <name> <dir> <exit> <output> <wf args...>
  local name=$1 dir=$2 want_rc=$3 want=$4 out rc; shift 4
  out=$(cd "$dir" && "$wf" "$@" 2>&1); rc=$?
  if [ "$rc" != "$want_rc" ] || [ "$out" != "$want" ]; then
    printf 'FAIL %s: exit %s, got:\n%s\nwant (exit %s):\n%s\n' "$name" "$rc" "$out" "$want_rc" "$want"; fail=1
  fi
}
repo() {
  mkdir -p "$1/src"; git -C "$1" init -q -b main
  git -C "$1" config user.email t@t; git -C "$1" config user.name t
  echo a > "$1/src/a.py"; git -C "$1" add -A; git -C "$1" commit -qm base
}

R=$d/plain; repo "$R"
expect "no skill anywhere" "$R" 0 "none" verify-skill
mkdir -p "$R/.claude/skills/verify"; echo x > "$R/.claude/skills/verify/tools.txt"
expect "untracked verify files do not count" "$R" 0 "none" verify-skill

R=$d/own; repo "$R"; mkdir -p "$R/.claude/skills/verify"; echo s > "$R/.claude/skills/verify/SKILL.md"
own=$(cd "$R" && pwd -P)/.claude/skills/verify/SKILL.md
expect "repo's own skill" "$R" 0 "$own" verify-skill
expect "repo's own skill from a subfolder" "$R/src" 0 "$own" verify-skill
git -C "$R" config constack.verify "$d/nowhere/SKILL.md"
expect "repo's own skill wins over the config" "$R" 0 "$own" verify-skill

R=$d/cfg; repo "$R"; mkdir -p "$R/.claude/skills/verify" "$d/overlay/verify"
echo x > "$R/.claude/skills/verify/tools.txt"; git -C "$R" add -A; git -C "$R" commit -qm tools
echo s > "$d/overlay/verify/SKILL.md"
git -C "$R" config constack.verify "$d/overlay/verify/SKILL.md"
expect "config names an existing skill" "$R" 0 "$d/overlay/verify/SKILL.md" verify-skill
git -C "$R" config constack.verify "$d/gone/SKILL.md"
missing_cfg="not run: verify skill missing: git config constack.verify names $d/gone/SKILL.md, which does not exist. Fix: install or sync the overlay that provides the verify skill, or correct git config constack.verify."
expect "config names a missing file" "$R" 1 "$missing_cfg" verify-skill
git -C "$R" config constack.verify ""
missing_unset="not run: verify skill missing: the repo keeps files under .claude/skills/verify/ but has no .claude/skills/verify/SKILL.md, and git config constack.verify is unset. Fix: set git config constack.verify <path to the skill's SKILL.md>, which the overlay's installer does."
expect "empty config counts as unset" "$R" 1 "$missing_unset" verify-skill
git -C "$R" config --unset constack.verify
expect "tracked verify files, config unset" "$R" 1 "$missing_unset" verify-skill
expect "tracked verify files, config unset, from a subfolder" "$R/src" 1 "$missing_unset" verify-skill

expect "outside a git repo" "$d" 2 "wf verify-skill: not in a git repo. Fix: run it from inside the repo under review." verify-skill
expect "extra argument" "$R" 2 "usage: wf verify-skill" verify-skill x

# check-review: only "not run: no verify skill" leaves a PASS standing
v=$d/rev; repo "$v"; mkdir -p "$v/docs/work/x"
echo '- US-1.AC1: Given a, when b, then c' > "$v/docs/work/x/spec.md"
git -C "$v" add -A; git -C "$v" commit -qm spec; end=$(git -C "$v" rev-parse HEAD)
R=$v/docs/work/x/review.md
review() { # review <verdict> <OPEN body> <Verify lines...>
  local verdict=$1 open=$2; shift 2
  { printf '# X: final review\n\nVerdict: %s\nSpec: docs/work/x/spec.md\nRange: main...%s\nMode: full\nDate: 2026-11-28\n\n' "$verdict" "$end"
    printf '## Acceptance criteria\n\n| AC | Red commit | Test checks the AC | Note |\n|---|---|---|---|\n| US-1.AC1 | abc | yes | |\n\n'
    printf '## Full suite\n\n`true`: pass\n\n## Verify\n\n'; printf '%s\n' "$@"
    printf '\n## Fix tickets\n\nnone\n\n## OPEN\n\n%s\n' "$open"; } > "$R"
}
review PASS none "not run: no verify skill"
expect "check-review: no verify skill passes" "$v" 0 "" check-review "$R"
review PASS none "not run: no verify skill (no .claude/skills/verify/SKILL.md). 0 minutes."
expect "check-review: no verify skill with a note passes" "$v" 0 "" check-review "$R"
review PASS none "$missing_cfg"
expect "check-review: PASS with the skill missing (config)" "$v" 1 "$R:21: Verify says the verify skill did not run (\"$missing_cfg\"), but Verdict is PASS. Fix: put that line under OPEN and set Verdict: FAIL; the user decides (step 6b). Only \"not run: no verify skill\" leaves a PASS standing." check-review "$R"
review PASS none ".claude/skills/verify/tools.txt" "$missing_unset"
expect "check-review: PASS with the skill missing after the own-check line" "$v" 1 "$R:22: Verify says the verify skill did not run (\"$missing_unset\"), but Verdict is PASS. Fix: put that line under OPEN and set Verdict: FAIL; the user decides (step 6b). Only \"not run: no verify skill\" leaves a PASS standing." check-review "$R"
review PASS none "not run: no verify skillset"
expect "check-review: a longer word after the harmless text counts" "$v" 1 "$R:21: Verify says the verify skill did not run (\"not run: no verify skillset\"), but Verdict is PASS. Fix: put that line under OPEN and set Verdict: FAIL; the user decides (step 6b). Only \"not run: no verify skill\" leaves a PASS standing." check-review "$R"
review FAIL "$missing_cfg" "$missing_cfg"
expect "check-review: FAIL with the skill missing under OPEN" "$v" 0 "" check-review "$R"
review PASS none "US-1.AC1: not run, refused"
expect "check-review: per-AC not run row still fails PASS" "$v" 1 "$R:21: Verify row says not run, but Verdict is PASS. Fix: put it under OPEN and set Verdict: FAIL; the user decides (step 6b)." check-review "$R"

exit $fail
