Status: open
Type: research
Blocked by: 01

## Question

How do we invoke Matt's skills headlessly when they are designed for interactive use?

## Context

Matt's skills are invoked via `/skill-name` in Claude Code interactive sessions. They expect conversation context, user confirmation loops, and the ability to ask follow-up questions. Sandcastle runs AFK — no human is present. We need a deterministic way to produce the same `.scratch/` output without the interactive parts.

## Options

1. **Prompt-based headless** — Create custom skills (markdown+JSON) that embed the same logic but skip confirmation loops. Run via `claude --no-interactive --skill /path/to/skill.md`.
2. **Script-based headless** — Shell scripts that read `CONTEXT.md` + existing `.scratch/` files and write new ones deterministically. No LLM invocation for ticket creation.
3. **Hybrid** — Use LLM for spec synthesis (`to-spec`) and ticket breakdown (`to-tickets`), but use scripts for state transitions (claim, resolve, frontier scan).

## Answer

**Hybrid** — custom headless skills for synthesis, scripts for state transitions.

Strategy:

1. **Custom skills** (`to-spec-headless`, `wayfinder-headless`, `to-tickets-headless`, `implement-headless`, `code-review-headless`) are markdown-based Claude Code skills that embed the same logic as Matt's but skip confirmation loops. They write directly to `.scratch/`.
2. **Shell scripts** (`bootstrap.sh`, `runner.mjs`) handle deterministic transitions: find frontier, claim ticket, invoke skill, resolve ticket, update map.
3. **Prototype** gets a degraded AFK variant (`prototype-headless`) that produces code but doesn't wait for human validation.

Proof-of-concept: the custom skills are already implemented in `src/claude-code-skills/skills/sandcastle/`.

## What would resolve this

A decision on the invocation strategy and a proof-of-concept wrapper that creates a `.scratch/` spec file without human input.

---

Status: resolved
