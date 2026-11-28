# Retro reads the logs first

Status: approved
Branch: feature/self-improve
Base: origin/main
Date: 2026-11-28

## Problem

A retrospective on a feature starts by hunting through raw session logs by hand, so the same refused command repeated by five helpers, or a request the owner had to type twice, is easy to miss. The merge-quick retro found both only after a manual search; a script that prints them up front makes every retro start from the evidence.

## User stories

### US-1 A retro starts from the feature's repeated errors and typed messages

As the owner, I want one command that prints a feature's repeated tool errors and every message I typed, and `/retro` to run it first, so that each retro starts from what went wrong and what I had to ask for.

- US-1.AC1: Given a feature's log folder where a main session holds the tool error `worktree agent-a1c refused, exit 1`, a helper subagent log holds `worktree agent-b2d refused, exit 2`, a scratch run started from that session's scratchpad holds `worktree agent-e5f refused, exit 3`, a different feature's log folder holds the same error, and another error appears once, when the script runs for that feature's worktree path, then the repeated-errors section shows exactly one line, that error with its id and numbers stripped and the count 3, and not the single error; given six different repeated errors it shows only the five most frequent; given a worktree path with no log folder it prints exactly `no logs on this machine` and exits 0.
- US-1.AC2: Given a feature's main session where the owner typed `go`, then `go` again, then `do the manual check via a subagent`, then `do the manual check via a subagent!`, plus a task notification and a helper subagent log holding its own prompt, when the script runs, then the typed-messages section lists exactly `go` and `do the manual check via a subagent`, in that order.
- US-1.AC3: Given the retro skill, when its steps are read, then its first step runs the script for the feature's worktree path before any other step.
- US-1.AC4: Given a feature's main session holding the typed message `go` and a compaction summary row (a user row marked `isCompactSummary`), when the script runs, then the typed-messages section lists exactly `go`.
- US-1.AC5: Given a feature's main session where the owner typed `start`, then, while the agent was working, `do the manual check via a subagent` (a queued command from a human), then `ship it`, and where a helper's hand-back (a queued command from a peer) and a task notification (a queued command from a task notification) were queued the same way, when the script runs, then the typed-messages section lists exactly `start`, `do the manual check via a subagent` and `ship it`, in that order.
- US-1.AC6: Given a feature's main session where the owner typed `start`, then sent a message made of a pasted block holding `Sam: can you send me the setup page?` followed by the typed text `do the manual check via a subagent`, then sent a message made only of a pasted block holding `set up the mount`, then typed `ship it`, when the script runs, then the typed-messages section lists exactly four messages in that order: `start`, the first paste message as stored (its `<pasted_content …>` block, then `do the manual check via a subagent`), the second paste message as stored, and `ship it`.
- US-1.AC7: Given a feature's main session where the owner typed `go` and then `/clear`, and a session started by `claude -p` (every row has `entrypoint` `sdk-cli`) holding the slash command `/final-review docs/work/x/spec.md AFK` and the plain prompt `yes, approve as written`, when the script runs, then the typed-messages section lists exactly `go` and `/clear`, in that order.

## Decisions

- Data: a feature's logs are the Claude Code project log folder named after its worktree path (every character that is not a letter or digit becomes `-`), under the Claude config folder (`CLAUDE_CONFIG_DIR`, else `~/.claude`) in `projects`. Main sessions are the folder's top-level logs; helper subagent logs sit under each session's `subagents` folder. Scratch runs count too: any log folder whose name holds the feature's log folder name followed by `-<session id>-scratchpad`, where the session id is one of the feature's main sessions; their top-level logs and subagent logs are read like the feature's own. The script takes the worktree path as its one argument, defaulting to the current directory.
- Repeated errors: an error is a tool result marked as an error, from main and helper logs. Its text is stripped of ids (any word holding both letters and digits) and numbers (any run of digits) and whitespace is collapsed; texts equal after stripping are one group. A group seen 2 or more times is repeated. The top 5 by count print, most first, each as `<count>x <stripped text>`.
- Typed messages: main sessions only, in time order. A message typed while the agent is working is stored as a queued command; one whose origin is a human is a typed message, and one from a peer or a task notification is a harness row. A slash command prints as `/<name> <args>`; a `!` shell input prints as `! <command>`. Harness rows (meta rows, compaction summaries, tool results, task notifications, local command output, shell output) are not typed messages. A message is dropped when it matches an earlier one after lowercasing, keeping only letters, digits and single spaces. Slash commands with no arguments, such as `/clear`, still print. A message that starts with a pasted block (`<pasted_content …>`) is a typed message and prints as stored, pasted text included. Prompts of a session started by a script (`claude -p`, rows with `entrypoint` `sdk-cli`) are harness rows.
- Testing seams: the script's output and exit code for a fixture log folder; the retro skill's text for its first step.

## Out of Scope

- The two merge-quick fixes (helpers retrying a refused compound git command, the manual check run by a subagent): a separate `/direct` task after this lands.
- Classifying, ranking or explaining the findings: `/retro` still does that from the printed evidence.
- Reading logs from another machine (the Mac).

## Manual check

1. Run the script for the merge-quick worktree path: the repeated-errors section shows the helpers' "command is too complex" refusal as one line with a count of 2 or more.
   Its count includes errors from the scratchpad manual-check runs, if any errored.
2. In the same output, the typed-messages section shows both requests for the manual check to be done by a subagent ("cant do the manual check yourself?" and "do the manual checks yourself via a subagent").
3. Run the script for a path with no logs: it prints `no logs on this machine`.
