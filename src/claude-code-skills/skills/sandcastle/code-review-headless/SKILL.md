---
name: code-review-headless
description: Review changes since a fixed point along Standards and Spec axes, running parallel sub-agents. Writes review report to .scratch/<feature-slug>/reviews/. AFK mode, no human interaction.
disable-model-invocation: true
---

# Code Review (Headless)

Review changes since a fixed point along two axes — Standards and Spec — and write the report to `.scratch/<feature-slug>/reviews/`.

## When to use

AFK sandcastle mode after implementation commits exist and before merging.

## Process

1. **Pin fixed point** — Use `git diff <base>...HEAD` (three-dot). Default base is `main` if not specified.

2. **Identify spec source** — Look for:
   - Issue references in commit messages
   - `spec.md` under `.scratch/<feature-slug>/`
   - PRD/spec files under `docs/`, `specs/`, `.scratch/`

3. **Identify standards** — Read repo standards docs (`CODING_STANDARDS.md`, `CONTRIBUTING.md`) plus the Fowler smell baseline:
   - Mysterious Name, Duplicated Code, Feature Envy, Data Clumps
   - Primitive Obsession, Repeated Switches, Shotgun Surgery
   - Divergent Change, Speculative Generality, Message Chains
   - Middle Man, Refused Bequest

4. **Run parallel reviews** — Spawn two sub-agents:
   - **Standards** — conformant? smells? overrides?
   - **Spec** — faithful to originating issue/spec?

5. **Write report** — Create `.scratch/<feature-slug>/reviews/<timestamp>-<base>.md`:

```markdown
# Code Review: <branch> since <base>

## Standards Review

<Findings, severity, line references>

## Spec Review

<Findings, severity, line references>

## Verdict

- [ ] Pass — merge allowed
- [ ] Fail — address findings before merge

## Actions

- <Specific changes required>
```

## Rules

- Report line references using file:line format.
- If no diff exists, error cleanly.
- If no spec is found, Spec axis reports "no spec available" but still runs.
