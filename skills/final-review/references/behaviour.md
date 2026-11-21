# Behaviour pass (step 6c)

Why: the blocking findings on heads that had passed this review were states no AC listed. The owner fixes an edge case only when it costs the customer **money** or is **common**; every other one is a **note**, so no fix round is spent on it.

## Find

Spawn one subagent on the security finder's model. Give it the spec path, `<BASE>` and the branch diff (delta: `PREV..HEAD`, plus every caller of a changed function). Do not give it `review.md` or the tickets. Its prompt:

1. List each state the changed code branches on. Always consider: a step ran and found nothing, finished but not marked done, still running, failed, replaced by a newer run, empty input, the same call retried or a chat reopened, a paid step that charged and then errored.
2. For each state, write what the user or client receives and what they can do next.
3. A bug is one of: a state with no way forward; two parts of one reply that disagree; a reply that is false in that state; a charge with no result returned; an ask repeated after it was answered.
4. Reproduce each bug with a script in the scratchpad that calls the real code. Drop any you cannot reproduce. No style, speed or naming bugs.
5. Answer two questions for each bug, yes or no:
   - **Money:** following the reply charges the customer again, loses what they paid for, or asks them to pay for something they already have.
   - **Common:** a user on the normal path meets it, with no unusual action and no database error, crash or size limit.
6. Return at most 5 bugs, money first, then common, then the rest: `file:line`, the state, what the user gets, the probe command and its output, money and common, and whether the index's `Base:` gives the same reply.

## Sort

Re-run each probe yourself and answer money and common again from its output; where your answer differs from the finder's, yours stands. Drop a bug the spec's Decisions or Out of Scope chose on purpose. Then each bug is one of:

- **Finding:** money or common is yes, and the index's `Base:` (also on a delta run, where `<BASE>` is `PREV`) gives a different reply. It fails the verdict and goes to the user in step 8.
- **Note:** everything else. One line under `### Notes` in `## Behaviour`: `file:line`, the state, and `older` (same reply at `Base:`) or `neither`. No ticket, no AC.

Done when every bug is a finding or a note.
