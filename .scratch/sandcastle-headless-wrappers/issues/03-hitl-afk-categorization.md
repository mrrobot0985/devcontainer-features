Status: open
Type: research
Blocked by: 02

## Question

Which of Matt's skills can run AFK and which require human-in-the-loop?

## Context

Matt's skills have different interaction models:

- `/wayfinder` — planning, mostly decisions, could be AFK with auto-approval
- `/to-spec` — synthesis from conversation context; if context is complete, AFK possible
- `/to-tickets` — breakdown + user quiz; the quiz is the blocker
- `/implement` — uses `/tdd`, runs tests, commits; AFK possible if spec is clear
- `/code-review` — parallel sub-agents; AFK possible
- `/prototype` — explicitly throwaway, asks user "does this feel right?"; HITL by design
- `/grilling` — interviews the user; HITL by design

## Options

1. **Whitelist AFK** — Only allow `/wayfinder`, `/to-spec`, `/to-tickets`, `/implement`, `/code-review` in auto-mode. Block `/prototype` and `/grilling` with a message saying "human required."
2. **Auto-mode with HITL escape hatch** — Run AFK until a skill says it needs human input, then pause and notify.
3. **All-AFK with degraded UX** — Run everything headlessly; prototype produces code but doesn't wait for "feels right" confirmation.

## Answer

**Whitelist AFK with degraded prototype mode**.

Categorization:

| Skill | Mode in sandcastle auto | Rationale |
|-------|------------------------|-----------|
| `/wayfinder` | AFK | Planning decisions, no human needed |
| `/to-spec` | AFK | Synthesis from repo context |
| `/to-tickets` | AFK | Auto-breakdown, no quiz |
| `/implement` | AFK | TDD + tests + commits, deterministic |
| `/code-review` | AFK | Parallel sub-agents, no human input |
| `/prototype` | Degraded AFK | Produces throwaway code, skips "feels right" validation |
| `/grilling` | **HITL only** | Requires human interview; skipped in auto-mode |

Sandcastle `bootstrap.sh auto` skips `grilling` entirely. `prototype` runs in degraded mode only if explicitly enabled.

## What would resolve this

A categorization table in sandcastle docs and a conditional in `bootstrap.sh auto` that skips HITL-only skills.

---

Status: resolved
