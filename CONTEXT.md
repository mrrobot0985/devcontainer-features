# Context: devcontainer-features

## What this repo is

A collection of devcontainer features and templates for the BrainXio ecosystem. Features are composable installable units that configure development environments. Templates bundle features into complete ready-to-use workspaces.

## Key domains

- **Devcontainer features** — installable units conforming to the Dev Container Specification. Each feature has `devcontainer-feature.json`, `install.sh`, `README.md`.
- **Devcontainer templates** — complete `.devcontainer/` configurations referencing features. Defined in a separate `devcontainer-templates` repo.
- **Sandcastle automation** — headless AFK automation layer for evolving projects via Matt Pocock's skills (wayfinder, to-spec, to-tickets, implement, code-review, prototype).

## Architecture decisions

- Features are self-contained; templates reference them from `ghcr.io` or local paths.
- The `claude-code-skills` feature clones Matt Pocock's skills to `~/.claude/skills/`.
- Sandcastle wrappers must produce output compatible with Matt's local-markdown tracker (`.scratch/`).

## Current focus

Aligning sandcastle headless wrappers with Matt Pocock's skill outputs so AFK automation can drive `.scratch/` issue creation and resolution.
