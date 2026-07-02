# Claude Code Matt Pocock Skills (claude-code-skills-matt-pocock)

Clones [Matt Pocock's skills](https://github.com/mattpocock/skills) into `~/.claude/skills/` with selectable categories.

## What it installs

Individual skills from the `skills/` directory are copied into `~/.claude/skills/` for Claude Code discovery.

## Skill Categories

### Engineering (`installEngineering`)

Software engineering, architecture, and codebase skills.

- `ask-matt` — Ask Matt Pocock coding questions
- `code-review` — Review code for quality and correctness
- `codebase-design` — Design and structure codebases
- `diagnosing-bugs` — Systematic bug diagnosis
- `domain-modeling` — Model business domains in code
- `grill-with-docs` — Drill down on documentation gaps
- `implement` — Implement features from specifications
- `improve-codebase-architecture` — Refactor and improve architecture
- `prototype` — Rapid prototyping patterns
- `resolving-merge-conflicts` — Resolve git merge conflicts
- `setup-matt-pocock-skills` — Configure the skills system
- `tdd` — Test-driven development workflows
- `to-issues` — Convert discussions to issues
- `to-prd` — Convert ideas to product requirements
- `triage` — Prioritize and categorize incoming work

### Productivity (`installProductivity`)

Workflow optimization, teaching, and writing skills.

- `grill-me` — Be interviewed/grilled on a topic
- `grilling` — Grill someone else on a topic
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
