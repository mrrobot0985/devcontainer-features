---
name: to-tickets-headless
description: Break a spec into tracer-bullet tickets with blocking edges, writing to .scratch/<feature-slug>/issues/. No user quiz — auto-breakdown for AFK sandcastle mode.
disable-model-invocation: true
---

# To Tickets (Headless)

Break a spec into tracer-bullet tickets and write them to `.scratch/<feature-slug>/issues/`.

## When to use

AFK sandcastle mode when a spec exists but has not yet been ticketed.

## Process

1. **Read spec** — Read `.scratch/<feature-slug>/spec.md`.

2. **Explore codebase** — Understand current state. Look for prefactoring opportunities.

3. **Draft vertical slices** — Break into tracer-bullet tickets:
   - Each slice is a complete vertical path (schema → API → UI → tests)
   - Sized to fit one context window
   - Wide refactors use expand–contract sequencing

4. **Write tickets** — Create files at `.scratch/<feature-slug>/issues/NN-<slug>.md`, numbered from `01`:

```markdown
Status: open
Type: task
Blocked by: <NN, NN or empty>

## Title

<Short descriptive name>

## What it delivers

<End-to-end behavior this ticket makes work>

## Spec references

- <Section names or line ranges from spec.md>

## Acceptance criteria

- <Verifiable condition 1>
- <Verifiable condition 2>
```

1. **Update spec** — Add a `## Tickets` section to `spec.md` listing the ticket files with one-line summaries.

## Rules

- No user quiz — write tickets directly.
- Prefer vertical slices over horizontal layers.
- If tickets already exist for this spec, error and do not overwrite.
- Blocking edges are advisory; sandcastle runner validates them at runtime.
