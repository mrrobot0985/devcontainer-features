# /implement

Trigger ralph-loop execution for open AFK tickets.

## Usage

```bash
/implement [ticket-id]
```

Without a ticket-id, selects the next unblocked open AFK ticket.

## Inputs

- `wayfinder/tickets/*.md` with YAML frontmatter
- `ralph-loop.sh` and `runner.mjs` in `.devcontainer/sandcastle/`

## Outputs

- Git branch `feat/<id>-<slug>`
- Updated ticket status (in-progress → pending-review or failed)
- `.ralph/logs/<id>.log`

## Behavior

Respects MAX_TICKETS_PER_CYCLE. Creates feature branch, invokes ralph-loop.sh, pushes on success. Does not merge to main — leaves for code-review.
