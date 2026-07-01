# Claude Code Skills (claude-code-skills)

Clones [Matt Pocock's skills](https://github.com/mattpocock/skills) into `~/.claude/skills/`.

## What it installs

Individual skills from the `skills/engineering/` and `skills/productivity/` directories are symlinked into `~/.claude/skills/` for Claude Code discovery.

## Options

None.

## Requirements

- `ghcr.io/anthropics/devcontainer-features/claude-code` must be installed first (for the `~/.claude` directory to exist).
- `git` is required for cloning; the feature will install it if missing.
