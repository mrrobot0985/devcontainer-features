---
name: local-markdown-tracker
description: Scaffold a local-markdown issue tracker for this repo. Creates docs/agents/ config and .scratch/ conventions so Matt's skills can write to flat files instead of GitHub/GitLab issues. Run once per repo.
disable-model-invocation: true
---

# Local Markdown Tracker Setup

Scaffolds the per-repo configuration for using `.scratch/` as the issue tracker.

## What it creates

1. `docs/agents/issue-tracker.md` — tracker conventions (local markdown)
2. `docs/agents/triage-labels.md` — five canonical label strings
3. `docs/agents/domain.md` — single-context layout rules
4. `CLAUDE.md` (or updates existing) — Agent skills block pointing at the above
5. `CONTEXT.md` (or updates existing) — High-level repo context

## Usage

Run this skill once when setting up a new repo for sandcastle automation:

```
/local-markdown-tracker
```

After running, Matt's skills (`/to-spec`, `/wayfinder`, `/to-tickets`, etc.) will default to writing issues under `.scratch/<feature-slug>/` instead of GitHub/GitLab.

## Conventions enforced

- One feature per directory: `.scratch/<feature-slug>/`
- Spec: `.scratch/<feature-slug>/spec.md`
- Issues: `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`
- Wayfinder map: `.scratch/<effort>/map.md`
- Wayfinder tickets: `.scratch/<effort>/issues/NN-<slug>.md`
- Status line near top of each issue: `Status: <state>`
- Blocking line near top: `Blocked by: NN, NN`
