# /code-review

Run multi-perspective review on pending-review tickets/branches.

## Usage

```bash
/code-review [ticket-id]
```

Without a ticket-id, reviews all pending-review tickets.

## Inputs

- pending-review tickets in `wayfinder/tickets/`
- corresponding git branches
- `validate-branch.sh` output
- `runner.mjs` quality output

## Outputs

- Review report in `.ralph/reviews/<ticket-id>.md`
- Updated ticket status (approved, changes-requested, or blocked)

## Perspectives

1. **Correctness** — tests pass, types check, logic is sound, no regressions
2. **Architecture** — fits existing patterns, no circular deps, reasonable abstractions, matches SPEC
3. **Safety** — no secrets, no attribution, conventional commits, human-sovereignty compliant

## Behavior

Spawns three parallel review subagents (or runs sequentially if Docker unavailable). Aggregates JSON results. Merges only when AUTO_MERGE=true and all gates pass.
