# T<nn> <title>

Spec: docs/work/<feature>/spec.md
Blocked by: <T01, T02 | none>

## Delivers

<Each AC line copied verbatim from the spec. For a prefactor: "none (prefactor: no behaviour change, existing tests stay green)".>
- US-n.ACm: Given ..., when ..., then ...

## Files

- create: <path>
- modify: <path>
- test: <path>

## Interfaces

- Consumes: `<exact signature or data shape>` from <T0n | existing path>
- Produces: `<exact name(params: types) -> return type>` in <path>

## Tests

### US-n.ACm
File: <test path>
```<lang>
<test name and assertions with the spec's exact values. Setup only where it is not obvious. No implementation code. Heading `### US-n.ACm (guard)` if the AC is already true before this ticket's code.>
```

## Approach

<One line per real choice the signatures and tests leave open (which existing helper, which library call, which data structure). A code block only for an algorithm the tests do not pin. Write "none" if nothing is open.>

## Constraints

- <project rule that applies to these files, with its source>

## Verify

`<one command that runs this ticket's tests>`

## Out of scope

- <what this slice must not touch or build, including ACs that belong to other tickets>
