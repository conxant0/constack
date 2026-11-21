# constack

Spec-driven, test-first feature building with Claude Code: grill the idea, write a spec with numbered acceptance criteria, slice it into vertical tickets, build them in parallel worktrees with per-ticket review, then a final review against the spec.

## Install

```bash
git clone <this repo> && cd constack && ./install.sh
```

It links each skill, the hooks and the status line into `~/.claude`, so `git pull` here updates them. Your `~/.claude/CLAUDE.md` gets one import line (`@<this repo>/CLAUDE.md`), so your own rules stay. `settings.json` is copied only when you have none; otherwise merge `settings.example.json` by hand. Anything already there is left alone and listed; `./install.sh --replace` moves those to `~/.claude/backups/` first. Tests: `test/install-test.sh` and `skills/build/scripts/test/*.sh`.

Needs: Claude Code, `git`, `gh` (for `/pr` and `/resolve`), `node` (status line), `python3` (`afk-loop`). Optional: [rtk](https://github.com/rtk-ai/rtk) (the hook and `RTK.md` do nothing without it).

## The flow

| Step | Command | Writes |
|---|---|---|
| 0 | `git worktree add ../<feature> -b feature/<feature> <base>`, then `cd ../<feature> && claude` | |
| 1 | `/grill-me` | conversation only |
| 2 | `/spec` (same session) | `docs/work/<feature>/spec.md` |
| 3 | `/clear`, `/slice <spec>` (or `/direct <spec>` for at most 6 ACs: one session, no tickets) | `index.md` + `tickets/T01-*.md` |
| 4 | `/clear`, `/build <index>` | merged, reviewed tickets |
| 5 | `/clear`, `/encode-comments <Base>`, then `/clear`, `/final-review <spec>` | comment rules as tests; `review.md`; fix tickets on FAIL, then back to 4 |
| 6 | `/pr` | draft PR |

Every stage after `/spec` starts fresh and reads only the files. Each acceptance criterion needs a `test(US-n.ACm): red` commit that fails before the code exists; `scripts/check-red-green.sh` and `/final-review` enforce it.

Extras: `/resolve` turns PR review comments into fixes and replies. `/retro` reviews a finished feature's workflow. `/handoff` writes a resume note before `/clear`. `/bro` restates the last answer in plain words. `skills/build/scripts/afk-loop <index>` runs build and final-review headless until PASS or a blocker; on a blocker it prints a command that opens `/unblock <index>`, which re-checks each AFK pick against the code, asks you one ticket at a time and writes the ruling into the ticket file. For phone pushes, put an unguessable topic name in `~/.claude/afk-ntfy-topic` and subscribe to it in the ntfy app.

## Things to adjust

- **Base branch.** Features merge into what `skills/build/scripts/wf base` prints: `git config constack.base <branch>` in that repo, else `origin/HEAD` (usually `main`). Set it once per repo if you merge into something else, e.g. `git config constack.base staging`.
- **Private rules (optional).** Skills read extra checks from `~/.claude/checks/` when present, so a team can keep its own rules out of this repo: `spec-*` (executables `/spec` runs on each spec; exit 1 flags, 2 cannot run), `pr.md` (extra `/pr` rules), `afk-disallowed-tools` (tools `afk-loop` sessions may not use, one per line), `clean-suite-env` (env var names `/final-review` unsets for its clean-checkout run).
- **macOS.** The tests in `skills/build/scripts/test/` use BSD `sed -i ''`. On Linux, change it to `sed -i`.
- **Models.** Implementers and per-ticket reviewers run on Sonnet. `/final-review` and its security pass run on Opus.
- **Plugins.** `/encode-comments` needs [pstack](https://github.com/cursor/plugins) (`pstack@cursor-plugins`). The settings also enable [humanizer](https://github.com/blader/humanizer) and two built-in plugins; the other skills work without them.

`DECISIONS.md` explains why each stage works the way it does.

## Credits

`grill-me` and the PR shape are adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT). The security pass is adapted from [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review) (MIT, see `skills/final-review/references/security-LICENSE`).
