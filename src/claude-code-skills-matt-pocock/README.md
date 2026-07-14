# Claude Code Matt Pocock Skills (claude-code-skills-matt-pocock)

Clones [Matt Pocock's skills](https://github.com/mattpocock/skills) (v1.1.0) into `~/.claude/skills/` with selectable categories.

## What it installs

Individual skills from the `skills/` directory are copied into `~/.claude/skills/` for Claude Code discovery.

## Skill Categories

### Engineering (`installEngineering`)

Software engineering, architecture, and codebase skills.

- `ask-matt` — Router to find the right skill
- `code-review` — Review code for quality and correctness (model-invoked)
- `codebase-design` — Design and structure codebases
- `diagnosing-bugs` — Systematic bug diagnosis (model-invoked)
- `domain-modeling` — Model business domains in code (model-invoked)
- `grill-with-docs` — Drill down on documentation gaps
- `implement` — Implement features from specifications
- `improve-codebase-architecture` — Refactor and improve architecture
- `prototype` — Rapid prototyping patterns (model-invoked)
- `research` — Investigate questions against primary sources and capture cited findings (model-invoked)
- `resolving-merge-conflicts` — Resolve git merge conflicts (model-invoked)
- `setup-matt-pocock-skills` — Configure the skills system
- `tdd` — Test-driven development workflows (model-invoked)
- `to-spec` — Turn conversation into a spec and publish it
- `to-tickets` — Break plans into tracer-bullet tickets with blocking edges
- `triage` — Prioritize and categorize incoming work and pull requests
- `wayfinder` — Plan large multi-session work as investigation tickets

### Productivity (`installProductivity`)

Workflow optimization, teaching, and writing skills.

- `grill-me` — Be interviewed/grilled on a topic
- `grilling` — Grill someone else on a topic (model-invoked)
- `handoff` — Prepare work for handoff
- `teach` — Create teaching materials
- `writing-great-skills` — Author effective Claude Code skills

### Misc (`installMisc`)

Utility and tooling-specific skills.

- `git-guardrails-claude-code` — Git guardrails for Claude Code
- `migrate-to-shoehorn` — Migrate projects to Shoehorn
- `scaffold-exercises` — Scaffold learning exercises
- `setup-pre-commit` — Configure pre-commit hooks

### Personal (`installPersonal`)

Personal development and writing skills.

- `edit-article` — Edit and improve articles
- `obsidian-vault` — Manage Obsidian vault workflows

## Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| `installEngineering` | boolean | `true` | Install engineering skills |
| `installProductivity` | boolean | `true` | Install productivity skills |
| `installMisc` | boolean | `false` | Install miscellaneous skills |
| `installPersonal` | boolean | `false` | Install personal skills |

## Requirements

- `ghcr.io/anthropics/devcontainer-features/claude-code` must be installed first (for the `~/.claude` directory to exist).
- `git` is required for cloning; the feature will install it if missing.
