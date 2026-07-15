# Claude Code Skills (claude-code-skills)

Installs skills into `~/.claude/skills/` with configurable sources.

## What it installs

By default, Matt Pocock's skills are cloned from [github.com/mattpocock/skills](https://github.com/mattpocock/skills) and copied into `~/.claude/skills/` for Claude Code discovery.

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

### Sandcastle Headless (`installSandcastleHeadless`)

Custom skills designed for AFK (away-from-keyboard) sandcastle automation. These mirror Matt Pocock's engineering skills but skip interactive confirmation loops, producing `.scratch/` output deterministically for headless CI/devcontainer use.

| Skill | Mirrors | Purpose |
|-------|---------|---------|
| `local-markdown-tracker` | `setup-matt-pocock-skills` | Scaffold `.scratch/` issue tracker conventions |
| `to-spec-headless` | `to-spec` | Synthesize spec from repo context, write to `.scratch/` |
| `wayfinder-headless` | `wayfinder` | Create decision map + tickets in `.scratch/` |
| `to-tickets-headless` | `to-tickets` | Break spec into tracer-bullet tickets with blocking edges |
| `implement-headless` | `implement` | Implement AFK-capable tickets, TDD, commit |
| `code-review-headless` | `code-review` | Parallel Standards + Spec review, write report |
| `prototype-headless` | `prototype` | Throwaway prototype (degraded HITL mode) |

These skills are **not** a fork of Matt's skills — they consume the same `.scratch/` conventions and are meant to be installed alongside them.

## Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| `enableMattPocockSkills` | boolean | `true` | Clone and install Matt Pocock's skills from github.com/mattpocock/skills |
| `mattPocockSkillsVersion` | string | `v1.1.0` | Version/tag of mattpocock/skills to clone |
| `installEngineering` | boolean | `true` | Install engineering skills (requires enableMattPocockSkills) |
| `installProductivity` | boolean | `true` | Install productivity skills (requires enableMattPocockSkills) |
| `installMisc` | boolean | `false` | Install miscellaneous skills (requires enableMattPocockSkills) |
| `installPersonal` | boolean | `false` | Install personal skills (requires enableMattPocockSkills) |
| `skipOnFailure` | boolean | `false` | Skip skill installation if clone fails instead of failing the build |
| `installSandcastleHeadless` | boolean | `true` | Install sandcastle headless skill wrappers for AFK automation |

## Requirements

- `ghcr.io/anthropics/devcontainer-features/claude-code` must be installed first (for the `~/.claude` directory to exist).
- `git` is required for cloning; the feature will install it if missing.
