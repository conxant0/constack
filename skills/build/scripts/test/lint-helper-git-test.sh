#!/usr/bin/env bash
set -u
root=$(cd "$(dirname "$0")/../../../.." && pwd)
fail=0
bad() { echo "FAIL $1"; echo "Fix: $2"; fail=1; }

for f in skills/direct/references/helper.md skills/build/references/implementer.md; do
  rule=$(grep -F -- 'no `cd`' "$root/$f" | grep -F -- 'no `git -C`' | grep -F -- 'no `$( )`' | grep -F -- 'no `{ }`' | grep -i 'split' | grep -i 'refused' | grep -i 'instead of sending it again')
  [ -n "$rule" ] || bad "AC1 $f: no line forbids \`cd\`, \`git -C\`, \`\$( )\` and \`{ }\` and says to split a refused command" \
    "add one rule line to $f that says no \`cd\`, no \`git -C\`, no \`\$( )\` and no \`{ }\`, and tells the agent to split a refused command into separate plain calls instead of sending it again."
done

for spec in 'skills/direct/SKILL.md:- **Guard**' 'skills/build/references/implementer.md:**Guard AC**'; do
  f=${spec%%:*}; start=${spec#*:}
  step=$(grep -F -- "$start" "$root/$f")
  [ -n "$step" ] || { bad "AC2 $f: no guard step starting $start" "keep the guard step's opening words $start in $f."; continue; }
  for want in 'git diff --output=<file>' 'Write tool' 'cat <head> <diff> <tail> > <message file>'; do
    case $step in *"$want"*) ;; *) bad "AC2 $f: guard step lacks $want" "make the guard step save the diff with \`git diff --output=<file>\`, write the message head and tail with the Write tool and join them with \`cat <head> <diff> <tail> > <message file>\`." ;; esac
  done
  case $step in *'{ '*) bad "AC2 $f: guard step holds a { } group" "drop the brace group; join the message parts with cat instead." ;; esac
done

lint="$root/skills/build/scripts/lint-helper-git"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cat >"$tmp/prompt.md" <<'EOF'
Build the message with `{ printf 'x\n'; cat d.diff; } > msg` first.
Go to the top with `cd "$(git rev-parse --show-toplevel)" && git log -1` then.
Or read it with `git -C wt log -1` instead.
Check with `git log -1 && git status --short` at the end.
A line ```` ```diff ```` then `git -C wt diff` after a fence.
Move with `cd wt && git log -1` there.
Never use `git -C`, `cd`, `$( )` or `{ }` in a helper.
EOF
out=$(bash "$lint" "$tmp/prompt.md" 2>&1); rc=$?
[ $rc = 1 ] || bad "AC3 fixture: exit $rc, want 1: $out" "make the check exit 1 when it flags a line."
for want in "$tmp/prompt.md:1: { } group" "$tmp/prompt.md:2: \$( ) in a git command" "$tmp/prompt.md:3: git -C" "$tmp/prompt.md:5: git -C" "$tmp/prompt.md:6: cd in a git command"; do
  line=$(grep -F -- "$want" <<<"$out")
  [ -n "$line" ] || { bad "AC3 fixture: no line starting $want in: $out" "print <file>:<line>: <form> for each refused form."; continue; }
  case $line in *'Fix: '*) ;; *) bad "AC3 fixture: no Fix: on $line" "end each flagged line with a Fix: saying how to split the command." ;; esac
done
fixtext='Fix: split it into separate plain calls run from the worktree (no cd, no git -C, no $( ), no { } group); write files with the Write tool.'
grep -qF -- "git -C in \`git -C wt log -1\`. $fixtext" <<<"$out" || bad "AC3 fixture: Fix text changed: $out" "end each flagged line with: $fixtext"
grep -qF -- "$tmp/prompt.md:7:" <<<"$out" && bad "form names: a span that only names a form was flagged: $out" "skip a backticked span that is exactly cd, git -C, \$( ) or { }: naming a form is not running it."
grep -qF -- "$tmp/prompt.md:4:" <<<"$out" && bad "AC3 fixture: plain && chain flagged: $out" "flag only { } groups, \$( ) or cd in a git command, and git -C."
grep -nF -- '\b' "$lint" && bad "portability: lint-helper-git uses \\b, which BSD grep lacks" "match git as a word with (^|[^[:alnum:]_-])git([^[:alnum:]_-]|\$) instead of \\b."
out=$(bash "$lint" 2>&1); rc=$?
[ $rc = 0 ] && [ -z "$out" ] || bad "AC3 repo: exit $rc: $out" "rewrite each flagged helper-prompt command as separate plain calls."

[ $fail = 0 ] && echo "OK lint-helper-git-test"
exit $fail
