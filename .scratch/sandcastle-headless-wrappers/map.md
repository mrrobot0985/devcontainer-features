# Wayfinder: Align Sandcastle Wrappers with Matt's Skills

## Destination

Sandcastle headless wrappers produce Matt-compatible `.scratch/` output and can be used AFK in devcontainer templates. A developer can run `bash .devcontainer/bootstrap.sh auto` and the system self-drives from inception to maintenance using local markdown files as the issue tracker.

## Notes

- Domain: devcontainer automation, headless CLI invocation
- Skills to consult: `setup-matt-pocock-skills`, `wayfinder`, `to-spec`, `to-tickets`, `implement`, `code-review`, `prototype`
- Standing preference: deterministic scripts over LLM improvisation in sandcastle; Matt's skills drive content, sandcastle drives orchestration
- This effort is scoped to the `devcontainer-features` and `devcontainer-templates` repos

## Decisions so far

<!-- the index — one line per closed ticket: enough to judge relevance, then zoom the link for the detail the ticket holds -->

- [01-tracker-backend](issues/01-tracker-backend.md) — Default to local-markdown tracker (`.scratch/`) for AFK sandcastle mode. GitHub sync is Phase 4 opt-in.
- [02-headless-invocation](issues/02-headless-invocation.md) — Hybrid approach: custom headless skills for synthesis, scripts for state transitions. Proof-of-concept implemented.
- [03-hitl-afk-categorization](issues/03-hitl-afk-categorization.md) — Whitelist AFK with degraded prototype mode. `/grilling` is HITL-only and skipped in auto-mode.
- [04-bootstrap-auto-mode](issues/04-bootstrap-auto-mode.md) — Implemented auto-mode state machine in `bootstrap.sh` with `.ralph/state.json` persistence.
- [05-runner-mjs-integration](issues/05-runner-mjs-integration.md) — Implemented `.scratch/` I/O helpers in `runner.mjs` with frontier scanning, claim/resolve, and HITL filtering.

## Not yet specified

- Whether GitHub integration (sync `.scratch/` ↔ GitHub issues) is in-scope for this effort or a follow-up
- Whether `ralph-loop.sh` Docker parallelization is needed for single-container devcontainers

## Out of scope

- Rewriting Matt's actual skills — we consume them, we don't fork them
- Non-devcontainer use cases — sandcastle is specific to the template
