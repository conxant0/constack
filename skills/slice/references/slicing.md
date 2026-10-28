# Slicing

## Rules, in order

1. **Prefactor first.** If slices need existing code reshaped (extract a function, widen a type, move a module), that is ticket T01. It changes no behaviour: no ACs, existing tests stay green. Skip it if nothing needs reshaping.
2. **Vertical.** Each other ticket is a thin path through every layer it needs (data, logic, API, UI) and delivers at least one AC. Done means a test proves that AC through its testing seam.
3. **Infrastructure inside the slice.** A table, migration, route, config or client appears in the first ticket that needs it, sized for that ticket only. Auth or permissions is its own later slice that changes behaviour already built.
4. **Size.** One implementer context: roughly 100-300 changed lines, 1-4 ACs. Bigger: split again. One trivial AC: merge it into a neighbour that touches the same files.
5. **Edges.** A ticket is blocked by the tickets whose Produces it Consumes, and by any earlier ticket that shares a resource with it: a file, a table, a route, a config key. Different files writing the same table still conflict. Everything else can run in parallel.

## Ways to split a ticket that is too big

- **By AC:** one AC per ticket, happy path first.
- **Happy path, then edges:** the simple success case first; empty, error and limit cases next.
- **By data variation:** one input kind first (one file type, one entity), others later.
- **By operation:** create and read first; update and delete later.
- **Simple rule first:** a hardcoded or simple version first, then the complex rule as a ticket that changes it.
- **Defer performance:** make it work, then a separate ticket for a measured speed AC.

## Worked example

Spec: users save a search filter, see their saved searches, delete one; only the owner sees theirs.
US-1 save + list (AC1 save appears in list, AC2 empty list message), US-2 delete (AC1), US-3 owner only (AC1).

Horizontal (wrong):
| T01 | DB table and migration for saved searches |
| T02 | All saved-search API endpoints |
| T03 | Saved searches UI |
| T04 | Auth on saved searches |
No ticket proves an AC until T03, and T04 changes everything built before it.

Vertical (right):
| Ticket | Delivers | Blocked by |
|---|---|---|
| T01 prefactor: extract filter serializer used by search | none | none |
| T02 save a search and see it in the list (table, POST, GET, list UI) | US-1.AC1 | T01 |
| T03 empty saved-search list message | US-1.AC2 | T02 |
| T04 delete a saved search | US-2.AC1 | T02 |
| T05 list and delete only the caller's own searches | US-3.AC1 | T02, T04 |

T03 and T04 both build on T02. Give them a blocked-by edge only if they share a resource: T04 deletes rows from the table T03 reads, so here T04 is blocked by T03.
