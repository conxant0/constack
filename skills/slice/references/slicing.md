# Slicing

## Rules, in order

1. **Prefactor first.** Ticket T00 holds every reshape the slices need: extract a function, widen a type, move a module, and pull out each constant or type that two or more tickets consume, at today's value. It changes no behaviour: no ACs, existing tests stay green, and the new wording or value stays in the AC ticket that changes it. Tickets that consume it are then blocked by T00, and by each other only where rule 5 still finds a shared resource. Skip T00 if nothing needs reshaping.
2. **Vertical.** Each other ticket is a thin path through every layer it needs (data, logic, API, UI) and delivers at least one AC. Done means a test proves that AC through its testing seam.
   - **New tests go in a new test file** that imports the existing fixtures. An existing test file is listed only when a pin in it must change, so two tickets rarely share one.
   - **Out of scope keeps the story true.** If an Out of scope line would leave the user story's "so that" false (the AC fixes emails but the same charge happens on LinkedIn), that is a spec gap: step 3, never a ticket line.
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
| T00 prefactor: extract filter serializer used by search | none | none |
| T01 save a search and see it in the list (table, POST, GET, list UI) | US-1.AC1 | T00 (interface) |
| T02 empty saved-search list message | US-1.AC2 | T01 (interface) |
| T03 delete a saved search | US-2.AC1 | T01 (interface), T02 (file only) |
| T04 list and delete only the caller's own searches | US-3.AC1 | T01 (interface), T03 (interface) |

Waves: 5. T02 and T03 both build on T01. Give them a blocked-by edge only if they share a resource: T03 deletes rows from the table T02 reads, so here T03 is blocked by T02, a `file only` edge.
