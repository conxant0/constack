---
name: handoff
description: Write a personal handoff note to ~/.claude/handoffs/<branch>.md and print a resume prompt to paste after /clear. Never committed.
disable-model-invocation: true
argument-hint: "[goal for the next session]"
---

# /handoff

Write what the next session needs to continue, not a summary. If `$ARGUMENTS` is given, keep only what serves that goal.

1. One Bash call: `pwd; git branch --show-current; git status --short; git log --oneline -5; git log @{u}..HEAD --oneline 2>/dev/null`. Run nothing else.
2. Write `~/.claude/handoffs/<branch, / as ->.md`, under 40 lines, never `git add` it. If one exists, read it and keep dead ends that still apply. Tag claims `[V]` (checked in step 1) or `[?]` (recalled). Never copy what a spec, `index.md`, plan, commit or PR already holds: link it by absolute path or URL. Sections:
   - **Goal**: one line.
   - **Where we are**: committed, unpushed, uncommitted, last test result.
   - **Tried and failed**: what and why. Never skip.
   - **Decisions**: decision and reason, incl. user rulings.
   - **Open questions**: or "None".
   - **Next action**: one step, with the exact command or file.
3. Print this for the user to paste after `/clear`:
   `Read <abs path>. Re-check the [V] claims against git, say what changed, then do "Next action".`
