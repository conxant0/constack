# <Feature title>: final review

Verdict: PASS | FAIL
Spec: <spec path>
Range: <BASE>...<HEAD sha>
Mode: full | delta since <PREV sha>
Date: <YYYY-MM-DD>

## Acceptance criteria

| AC | Red commit | Test checks the AC | Note |
|---|---|---|---|
| US-1.AC1 | <sha> | yes | |
| US-1.AC2 | missing | | |

## Full suite

`<test command>`: pass | fail (<failing test names>)

## Out of Scope

<Each Out of Scope line built anyway, with the file. "none" if none.>

## Structure

`wf size`: <its lines, or "none">
<At most 5: file:line, the problem, the smaller structure that removes it, and the F<nn> ticket or `declined`. "none" if none.>

## Security

<Findings scored 8+, in the finder's format. "none" if none.>

Safe because: <the one fact>. Proof: `<command>` -> <output, or "unproven">.

## Behaviour

<Findings: file:line, the state, what the user gets, money or common, the probe command and its output. "none" if none.>

### Notes

<One line each: file:line, the state, and `older` or `neither`. "none" if none.>

## Verify

<"not run: no verify skill", or one row per AC: `<AC id>: pass | fail | unreachable | not run | not observable`, then the reason or the skill's evidence block. Last line: minutes the step took.>

## Fix tickets

<F01 <title>: fixes <AC id or finding>. "none" if PASS.>

## OPEN

<Findings that cannot become a testable ticket (design-level), for the user. "none" if none.>
