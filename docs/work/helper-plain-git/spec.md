# Helpers run git in forms an isolated worktree accepts

Status: approved
Branch: feature/self-improve
Base: origin/main
Date: 2026-11-28

## Problem

Helpers and implementers run in isolated worktrees, where the harness refuses a command it cannot prove stays in that worktree. In the merge-quick run helpers lost 11 calls this way, mostly to a brace group built for the guard commit message and a test loop, and nothing stops the prompts from teaching such a form again.

## User stories

### US-1 Helper prompts give only forms that run

As the lead, I want every command a helper prompt gives to be a form the isolated worktree accepts, and a check that fails when one is not, so that helpers stop losing turns to refused commands.

- US-1.AC1: Given the helper prompt and the implementer prompt, when they are read, then each tells the agent to run git in its own worktree with no `cd`, no `git -C`, no `$( )` and no `{ }` group, and to split a refused command into separate plain calls instead of sending it again.
- US-1.AC2: Given the guard step in the /direct steps a helper follows and in the implementer prompt, when it is read, then it saves the mutation diff with `git diff --output=<file>` and assembles the commit message by writing its head and tail with the Write tool and joining them with `cat <head> <diff> <tail> > <message file>`, and no brace group appears in it.
- US-1.AC3: Given a helper-read text holding the command `` `{ printf 'x\n'; cat d.diff; } > msg` ``, or `` `cd "$(git rev-parse --show-toplevel)" && git log -1` ``, or `` `git -C wt log -1` ``, when the check runs on it, then it exits 1 and prints, for each, the file and line, the offending form and a `Fix:` line; given `` `git log -1 && git status --short` `` it prints nothing; run on this repo's helper prompts it prints nothing and exits 0.

## Decisions

- Refused forms (measured with an isolated probe agent on 2026-11-28): a `{ }` group, `$( )` in a command naming git, `git -C <dir>`. Ran: `&&` and `;` chains, pipes, redirects, a leading `VAR=` assignment, a loop with no git, `git diff --output=<file>`, `cat a b > c`, writing a file with the Write tool, and the suite run as one script.
- Helper-read text: the whole helper prompt, the whole implementer prompt, and the /direct Hard rules and Step 4 the helper prompt points at. Lead-only lines are not scanned.
- The check scans backticked commands in those texts; it flags a `{ }` group, `$(` in a command naming git, `git -C`, and `cd` in a command naming git.
- Testing seams: the check's output and exit code on fixture texts and on the repo; the prompt and step texts for AC1 and AC2.

## Out of Scope

- Checking the Test command line a /direct or /build index holds (the suite now runs as one script, which ran in the probe).
- Changing how the lead (not isolated) runs git.
- The retry-on-refusal behaviour of the harness itself.

## Manual check

1. Run the check on this repo: it prints nothing and exits 0.
2. Add `` `git -C x log` `` to the helper prompt, run the check: it names that line with a `Fix:`; revert.
