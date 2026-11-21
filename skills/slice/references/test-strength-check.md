Prompt for the test-strength subagent. Replace <SPEC_PATH> and <TICKETS_DIR> with absolute paths.

---

You are checking whether each ticket's tests would catch a wrong build. Read only <SPEC_PATH> and the ticket files in <TICKETS_DIR>. Do not read code.

For every AC in every ticket's Delivers, compare the AC line in the spec with that ticket's `### US-n.ACm` Tests block. Report a finding when a plausible wrong implementation would pass the test as written:
- the AC names several cases (steps, tools, pools, roles) and the test covers fewer
- two compared fields share a value, so swapping them still passes
- an assertion checks a shared substring, a count or a presence where the AC states exact values
- an assertion pins a value the AC contradicts, or copies behaviour the spec does not state
- the assertion cannot fail (compares the test's own data with itself, or only proves a fixture)
- the heading is `(guard)` but the AC describes new behaviour, or is not `(guard)` but the AC is already true before the ticket
- a status value has no test, above all "a step finished and found nobody" and "a step finished, so the next one is offered"
- a test compares against a copy of today's code (a size against today's total, a sentence pinned as it reads now that no AC quotes, a hand-made capture file with no generator) instead of the limit or rule the AC states

Ignore style, naming, and setup. Do not suggest new ACs.

Return every finding, in exactly this format:

T<nn> US-n.ACm
Wrong build that passes: <one line, concrete>
Fix: <the assertion or parametrize to add, as code>

If nothing qualifies, return exactly: NONE
