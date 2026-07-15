Status: open
Type: task
Blocked by: 01, 02, 03

## Question

What is the state machine for `bootstrap.sh auto` using `.scratch/` as the tracker?

## Context

The current `bootstrap.sh` has phases: init → HITL → AFK → verify. We need an `auto` subcommand that self-drives through the lifecycle using `.scratch/` files as state.

## Proposed states

1. **Discover** — Check if `.scratch/` has any maps. If none, run `/to-spec` equivalent to create one.
2. **Map** — Check if the spec has a wayfinder map. If not, run `/wayfinder`.
3. **Ticket** — Check if the map has child tickets. If not, run `/to-tickets`.
4. **Implement** — Find the frontier (open, unblocked, unclaimed tickets). Run `/implement` on each AFK-capable ticket.
5. **Review** — When implementation commits exist, run `/code-review`.
6. **Merge** — If review passes, commit, merge to main, mark tickets resolved.
7. **Loop** — Repeat from state 4 until no frontier tickets remain.

## Answer

Implemented in `src/claude-code-sandcastle/bootstrap.sh` as the `auto` subcommand.

State machine phases (self-driving):

| Phase | Action | Next if success |
|-------|--------|-----------------|
| **discover** | Scan `.scratch/` for maps. Scaffold tracker if empty. | → spec |
| **spec** | Check if `.scratch/<effort>/spec.md` exists. Create via `to-spec-headless` if not. | → map |
| **map** | Check if `.scratch/<effort>/map.md` exists. Create via `wayfinder-headless` if not. | → ticket |
| **ticket** | Check if `.scratch/<effort>/issues/` has tickets. Create via `to-tickets-headless` if not. | → implement |
| **implement** | Find frontier (open + unblocked + unclaimed). Invoke `runner.mjs implement <effort>`. Loop with maxIterations guard. | → review |
| **review** | Run `code-review-headless`. Write report to `.scratch/<effort>/reviews/`. | → verify |
| **verify** | Run `validate-branch.sh`. Commit state changes. | → done |

State persistence: `.ralph/state.json` tracks `phase`, `iteration`, `currentEffort`, `lastRun`.

Fallbacks when `claude` CLI unavailable: creates placeholder spec/map/tickets so the structure is testable.

## What would resolve this

An implemented `auto` subcommand in `bootstrap.sh` and a state log (`.ralph/state.json`) tracking which phase the sandcastle is in.

---

Status: resolved
