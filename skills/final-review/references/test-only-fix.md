Prompt for a test-only fix round. Replace <INDEX>, <SPEC>, <BASE> (the index's `Base:`) and <IDS> (the fix ticket ids, in index order). Print it for the user to paste after `/clear`.

---

Do fix tickets <IDS> from `<INDEX>` yourself, in order, in this session. No subagents. `WF` is `~/.claude/skills/build/scripts/wf`.

For each ticket:

1. `WF set <INDEX> <id> doing`, then `START=$(git rev-parse HEAD)`. Read the ticket. It is the whole brief.
2. Write each test exactly as its Tests block gives it. Touch only the ticket's Files. If a test needs a change outside them, or to production code, stop: `WF set <INDEX> <id> "blocked: needs product code"` and tell the user to run `/build <INDEX>`.
3. The code already does what the AC says, so each test is a guard. Break the production code the way the AC forbids, see the test fail, and with the break still in place save `git diff -- <production files>` to a file outside the worktree. Restore with `git checkout -- <file>`, then commit only the test file(s) with `git commit --cleanup=verbatim -F <message file>`: the subject `test(US-n.ACm): guard`, a blank line, the line `Mutation: <file>: <what you changed> -> <the failing line>`, then the saved diff between a line ```` ```diff ```` and a line ```` ``` ````. Never use `-m` for the patch: the default cleanup strips its blank lines and trailing spaces, so it no longer applies. A test that fails on arrival means the code is wrong: stop as in step 2.
4. Run `~/.claude/skills/build/scripts/check-red-green.sh . $START "<the ticket's Verify>"`. Any `FAIL`: fix the test and run it again, at most twice, then stop and tell the user.
5. `WF done <INDEX> <id> $(git rev-parse HEAD)`.

After the last ticket: run the index's `Test command` once (`2>&1 | tail -40`). Then tell the user: `/clear`, `/final-review <SPEC>`.
