Status: open
Type: task
Blocked by: 02, 04

## Question

How does `runner.mjs` read from and write to `.scratch/` files?

## Context

`runner.mjs` is the deterministic task router. Currently it has placeholder `runImplementTask`. It needs to:

- Read `.scratch/` map files to find the frontier
- Read ticket files to understand what to implement
- Write status updates (`Status: claimed`, `Status: resolved`) to ticket files
- Append answers and context pointers to map.md

## Proposed API

```javascript
// .scratch/ I/O helpers
function readMap(effortSlug) { ... }
function listTickets(effortSlug) { ... }
function findFrontier(effortSlug) { ... } // open + unblocked + unclaimed
function claimTicket(effortSlug, ticketNumber) { ... }
function resolveTicket(effortSlug, ticketNumber, answer, contextPointer) { ... }
function appendToMapDecisions(effortSlug, decisionLine) { ... }
```

## Answer

Implemented in `src/claude-code-sandcastle/runner.mjs`.

`.scratch/` I/O helpers:

| Function | Purpose |
|----------|---------|
| `readMap(effortSlug)` | Returns map.md content or null |
| `listTickets(effortSlug)` | Returns sorted array of ticket file paths |
| `parseTicket(filePath)` | Parses Status, Type, Blocked by from frontmatter |
| `findFrontier(effortSlug)` | Returns open + unblocked + unclaimed tickets |
| `claimTicket(effortSlug, ticketNumber)` | Sets `Status: claimed` in ticket file |
| `resolveTicket(effortSlug, ticketNumber, answer, contextPointer)` | Sets `Status: resolved`, appends answer, updates map decisions |
| `appendToMapDecisions(effortSlug, decisionLine)` | Injects `- decisionLine` into map.md Decisions-so-far section |
| `frontierCount(effortSlug)` | Returns count of frontier tickets |

Task routing:

| CLI command | Action |
|-------------|--------|
| `runner.mjs implement <effort>` | Finds frontier[0], claims it, invokes `implement-headless`, resolves it |
| `runner.mjs review <effort>` | Invokes `code-review-headless` |
| `runner.mjs frontier-count <effort>` | Prints count of open unblocked tickets |
| `runner.mjs list-frontier <effort>` | Lists frontier tickets with status and type |

HITL filtering:

- `Type: grilling` → always skipped
- `Type: prototype` → skipped unless `SANDCASTLE_DEGRADED_PROTOTYPE=true`
- `Type: task | research` → implemented via `implement-headless`

## What would resolve this

Implemented `.scratch/` I/O helpers in `runner.mjs` and test coverage for state transitions.

---

Status: resolved
