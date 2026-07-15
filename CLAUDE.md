# Claude Code Context

## Agent skills

### Issue tracker

Issues and specs live as markdown files in `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout — one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Project overview

This repository contains devcontainer features and templates for the BrainXio ecosystem. Features are installable units (skills, plugins, rules, backends) that compose into devcontainer templates. Templates provide complete development environments (e.g., ollama-claude-sandcastle-studio).

## Key directories

- `src/` — individual devcontainer features
- `schemas/` — JSON schemas for feature validation
- `.plans/` — architecture and planning documents
- `.github/` — workflows, templates, community docs
