# constack

Spec-driven, test-first feature building with Claude Code: grill the idea, write a spec with numbered acceptance criteria, slice it into vertical tickets, build them in parallel worktrees with per-ticket review, then a final review against the spec.

## Install

```bash
git clone <this repo> && cd constack && ./install.sh
```

It copies into `~/.claude` and skips anything you already have. If it skipped `settings.json` or `CLAUDE.md`, merge `settings.example.json` and `CLAUDE.md` by hand.

Needs: Claude Code, `git`, `gh` (for `/pr`), `node` (status line), `python3` (`afk-loop`).

## The flow

| Step | Command | Writes |
|---|---|---|
| 0 | `git worktree add ../<feature> -b feature/<feature> origin/<base>`, then `cd ../<feature> && claude` | |
| 1 | `/grill-me` | conversation only |
| 2 | `/spec` (same session) | `docs/work/<feature>/spec.md` |
| 3 | `/clear`, `/slice <spec>` | `index.md` + `tickets/T01-*.md` |
| 4 | `/clear`, `/build <index>` | merged, reviewed tickets |
| 5 | `/clear`, `/final-review <spec>` | `review.md`; fix tickets on FAIL, then back to 4 |
| 6 | `/pr` | draft PR |

Every stage after `/spec` starts fresh and reads only the files. Each acceptance criterion needs a `test(US-n.ACm): red` commit that fails before the code exists; `scripts/check-red-green.sh` and `/final-review` enforce it.

Extras: `/handoff` writes a resume note before `/clear`. `/bro` restates the last answer in plain words. `skills/build/scripts/afk-loop <index>` runs build and final-review headless until PASS or a blocker; on a blocker it prints a command that opens `/unblock <index>`, which re-checks each AFK pick against the code, asks you one ticket at a time and writes the ruling into the ticket file. For phone pushes, put an unguessable topic name in `~/.claude/afk-ntfy-topic` and subscribe to it in the ntfy app.

## Things to adjust

- **Base branch.** The examples use `staging`. `/pr` falls back to `staging` when the spec has no `Base:`. Change it in `skills/pr/SKILL.md` if you merge straight to `main`.
- **macOS.** The tests in `skills/build/scripts/test/` use BSD `sed -i ''`. On Linux, change it to `sed -i`.
- **Models.** Implementers and per-ticket reviewers run on Sonnet. `/final-review` and its security pass run on Opus.
- **Plugins (optional).** The settings enable [ponytail](https://github.com/DietrichGebert/ponytail) and [humanizer](https://github.com/blader/humanizer). The skills work without them.

`DECISIONS.md` explains why each stage works the way it does.

## Credits

`grill-me` and the PR shape are adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT). The security pass is adapted from [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review) (MIT, see `skills/final-review/references/security-LICENSE`).
