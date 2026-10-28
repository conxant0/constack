# Ticket detail

The implementer is a cheaper model that sees only its ticket. Decide everything it would otherwise guess; leave it to write the bodies.

## The bar

Every line lets the implementer write exactly one reasonable thing. A line that decides nothing is a gap. A function body the signature and tests already determine is a transcript. Fix both.

## Per section

- **Interfaces.** Exact names, parameters with types, return types, endpoint method + path + request/response shape, table columns with types. Consumes names its source (a ticket id or an existing path from the code map).
- **Tests.** One block per AC. The test's name, its file, and its assertions as code, with the spec's exact values (strings, numbers, limits, status codes). Setup only where it is not obvious. The implementer writes this test first and must see it fail. Mark the heading `### US-n.ACm (guard)` when the AC will already be true when the test is written (a limit not yet crossed, existing behaviour that must not change, or code an earlier AC's green already covers): the implementer then proves the test with a mutation instead of a red commit.
- **Approach.** Only real choices: "reuse `normalize_name` from <path>", "use a single query with LEFT JOIN, not N+1". Never restate what the tests and signatures already say.
- **Bodies.** Never, except an algorithm the tests do not determine, or exact copy the spec fixes.
- **No line ranges.** Paths only; line numbers go stale when an earlier ticket merges.

## Cross-ticket checks (step 7)

- **Type consistency.** Every Consumes matches, character for character, a Produces in an earlier ticket or a signature in the code map. `clear_layers()` in T03 and `clear_all_layers()` in T05 is a bug.
- **Proportion.** If code blocks are most of the tickets, replace bodies with signatures and assertions. If a ticket is over ~120 lines, it is probably two tickets.

## Example Tests and Approach blocks

~~~markdown
## Tests

### US-1.AC1
File: tests/routes/test_saved_searches.py
```python
def test_saved_search_appears_in_list(client, user):
    client.post("/api/saved-searches", json={"name": "CA hospitals", "filter": {"state": "CA"}})
    resp = client.get("/api/saved-searches")
    assert resp.status_code == 200
    assert [s["name"] for s in resp.json()] == ["CA hospitals"]
```

## Approach

- Store `filter` as JSON via the existing `serialize_filter` from T01; do not add a new serializer.
~~~
