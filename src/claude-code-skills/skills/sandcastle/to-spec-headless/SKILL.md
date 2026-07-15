---
name: to-spec-headless
description: Turn repo context into a spec and write it to .scratch/<feature-slug>/spec.md. No interview, no user confirmation — deterministic synthesis for AFK sandcastle mode.
disable-model-invocation: true
---

# To Spec (Headless)

Synthesize a spec from the current repo context and write it to `.scratch/<feature-slug>/spec.md`.

## When to use

AFK sandcastle mode when no spec exists yet for the current effort.

## Process

1. **Explore** — Read `CONTEXT.md`, `CLAUDE.md`, and any existing `docs/adr/` to understand current state. Use the repo's domain glossary.

2. **Identify seams** — Find the highest testable seam for the feature. Prefer existing seams. If new seams are needed, note them at the highest point.

3. **Write spec** — Produce a markdown file at `.scratch/<feature-slug>/spec.md` using this template:

```markdown
# Spec: <Feature Name>

## Problem Statement

<What problem this solves, from the user's perspective.>

## Solution

<What the solution looks like, from the user's perspective.>

## User Stories

1. As an <actor>, I want <feature>, so that <benefit>
2. ...

## Implementation Decisions

- <Module boundaries, interfaces, schema changes, API contracts>
- <No file paths or code snippets — those rot quickly>

## Testing Decisions

- <Seams at which to test>
- <What a completed slice should verify>

## Status

Status: ready-for-agent
```

1. **Create .scratch directory** if it doesn't exist.

## Rules

- Do NOT interview the user. Synthesize from existing context only.
- Do NOT include specific file paths or code snippets.
- Apply the `ready-for-agent` status automatically.
- If a spec already exists at the target path, error and do not overwrite.
