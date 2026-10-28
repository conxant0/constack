# F<nn> <title>

Spec: docs/work/<feature>/spec.md
Blocked by: none
Fixes: <review.md section and line: an AC id, an Out of Scope hit, or a security finding>

## Delivers

<The AC line(s) this fix makes true, copied verbatim from the spec. For removing out-of-scope code: "none (removal: no behaviour in scope changes, existing tests stay green)".>
- US-n.ACm: Given ..., when ..., then ...

## Files

- modify: <path>
- test: <path>

## Interfaces

- Consumes: `<exact existing signature>` from <path>
- Produces: `<exact signature, only if this fix changes or adds one>`

## Tests

### US-n.ACm
File: <test path>
```<lang>
<test name and assertions that fail on the current code and pass once fixed>
```

## Approach

<One line per real choice. "none" if nothing is open.>

## Constraints

- <project rule that applies to these files, with its source>

## Verify

`<one command that runs this ticket's tests>`

## Out of scope

- <everything except this one fix>
