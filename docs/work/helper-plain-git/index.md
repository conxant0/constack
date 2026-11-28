# Helpers run git in forms an isolated worktree accepts: build index

Spec: docs/work/helper-plain-git/spec.md
Branch: feature/self-improve
Base: origin/main
Test command: test/run-all.sh <python with pytest>

Status values: todo | doing | done <merge sha> | blocked: <reason>

| Part | Title | Blocked by | Status |
|---|---|---|---|
| P1 | helper-plain-git | none | done 9f419cc7 |
| F01 | AC1 test checks the forms are forbidden | none | done fa49f492 |

## Open questions

none

## Parts

- P1: US-1.AC1, US-1.AC2, US-1.AC3; files: skills/direct/references/helper.md, skills/build/references/implementer.md, skills/direct/SKILL.md, skills/build/scripts/lint-helper-git, skills/build/scripts/test/lint-helper-git-test.sh

## Rulings
- 2026-11-28, P1 (direct): isolated probe 2026-11-28 also saw `git apply --check f; echo exit=$?` refused (a $ expansion after git); left out, the spec lists only the forms measured before approval; candidate for a follow-up /direct
