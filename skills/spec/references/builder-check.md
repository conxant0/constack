Prompt for the builder-check subagent. Replace <SPEC_PATH> with the spec's absolute path.

---

You are about to build the feature in this spec and are reading it cold. Read only <SPEC_PATH>. Do not read code, other files, or anything else.

Find the places where you would have to guess, and where a wrong guess would change what gets built or how it is tested. These count:
- an acceptance criterion you could not write a failing test for
- two parts of the spec that contradict each other
- a behaviour the stories imply but no AC states (an error case, an empty state, who is allowed to do it)
- an Out of Scope line that is ambiguous enough to argue about

Ignore wording, style, and anything a competent builder can decide alone.

Return at most 5 questions, most consequential first, in exactly this format:

Q<n>: <question>
Where: <section or AC id>
If guessed wrong: <what gets built or tested wrong, one line>

If nothing qualifies, return exactly: NONE
