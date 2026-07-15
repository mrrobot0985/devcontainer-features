---
name: wayfinder-headless
description: Plan a large effort as a wayfinder map in .scratch/<effort>/map.md with child decision tickets. No interactive confirmation — runs AFK for sandcastle automation.
disable-model-invocation: true
---

# Wayfinder (Headless)

Chart a large effort as a wayfinder map with child decision tickets in `.scratch/<effort>/`.

## When to use

AFK sandcastle mode when a spec exists but no wayfinder map has been created.

## Process

1. **Read spec** — Read `.scratch/<effort>/spec.md` (or the spec path provided as argument).

2. **Draft decisions** — Break the effort into decision tickets (questions, not build slices). Each ticket resolves one decision needed before implementation can proceed.

3. **Write map** — Create `.scratch/<effort>/map.md`:

```markdown
# Wayfinder: <Effort Name>

## Destination

<What reaching the end looks like — the spec, decision, or change this effort finds its way to.>

## Notes

<Domain; skills to consult; standing preferences>

## Decisions so far

<!-- closed tickets index -->

## Not yet specified

<!-- fog of war -->

## Out of scope

<!-- ruled beyond the destination -->
```

1. **Write tickets** — Create child tickets in `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`:

```markdown
Status: open
Type: <research | prototype | grilling | task>
Blocked by: <NN, NN or empty>

## Question

<The decision question, sized to one session>

## Context

<Why this question matters, what spec section it relates to>
```

## Rules

- Produce decisions, not deliverables. The map is done when the way is clear.
- No user confirmation — write directly to `.scratch/`.
- If a map already exists, error and append to it rather than replace.
- Ticket titles must be descriptive; names are how humans read the map.
