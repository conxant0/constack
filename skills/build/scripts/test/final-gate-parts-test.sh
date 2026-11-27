#!/usr/bin/env bash
set -u
wf=$(cd "$(dirname "$0")/.." && pwd)/wf
d=$(mktemp -d); trap 'rm -rf "$d"' EXIT
fail=0
r=$d/r; mkdir -p "$r"; git -C "$r" init -q -b main; git -C "$r" config user.email t@t; git -C "$r" config user.name t
echo a > "$r/app.txt"; git -C "$r" add -A; git -C "$r" commit -qm base
git -C "$r" checkout -qb feature/x; mkdir -p "$r/docs/work/x"; x=$r/docs/work/x
printf '# X\n\nStatus: approved\nBranch: feature/x\nBase: main\n' > "$x/spec.md"
printf '# X: build index\n\nSpec: docs/work/x/spec.md\nBranch: feature/x\nBase: main\nTest command: `true`\n\n| Part | Title | Blocked by | Status |\n|---|---|---|---|\n| P1 | a | none | done abc12345 |\n| P2 | b | P1 | doing |\n\n## Open questions\n\nnone\n\n## Parts\n\n- P1: US-1.AC1; files: a.sh\n- P2: US-1.AC2; files: b.sh\n' > "$x/index.md"
git -C "$r" add -A; git -C "$r" commit -qm 'docs(direct): x index'
git -C "$r" checkout -qb helper; echo b > "$r/b.sh"; git -C "$r" add -A; git -C "$r" commit -qm 'feat(US-1.AC2): green'
git -C "$r" checkout -q feature/x; git -C "$r" merge -q --no-ff helper -m 'merge P2: b'
sha=$(git -C "$r" rev-parse --short=8 HEAD)
[ ! -e "$x/tickets" ] || { echo "FAIL US-3.AC7 fixture has a tickets folder"; fail=1; }
out=$("$wf" gate "$x/spec.md" --final 2>&1); rc=$?
want="$x/index.md:11: P2 is merged ($sha) but still doing. Fix: finish the no-ticket build (lead check, quality review, full suite), then run wf done $x/index.md P2 $sha."
[ "$rc" = 1 ] && [ "$out" = "$want" ] || { printf 'FAIL US-3.AC7: exit %s, got:\n%s\nwant (exit 1):\n%s\n' "$rc" "$out" "$want"; fail=1; }
case $out in *"/build"*) echo "FAIL US-3.AC7 the reply names the ticket build: $out"; fail=1 ;; esac
[ $fail = 0 ] && echo "OK final-gate-parts-test"; exit $fail
