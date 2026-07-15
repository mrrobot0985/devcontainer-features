# Plan: Automated Sandcastle Lifecycle for Ollama-Claude-Sandcastle-Studio

## Problem Statement

The existing `ollama-claude-sandcastle-studio` template has the scaffolding (bootstrap.sh phases, runner.mjs, ralph-loop.sh, validate-branch.sh) but lacks the **automation layer** that evolves a project from inception to maintenance without manual phase transitions. The user wants a self-driving system that:

1. Creates a spec from initial context (`/to-spec`)
2. Charts a wayfinder map (`/wayfinder`)
3. Converts spec into actionable tickets (`/to-tickets`)
4. Implements tickets via ralph loops + sandcastle (`/implement`)
5. Code-reviews each cycle (`/code-review`)
6. Repeats until the project "dies of" (reaches stable maintenance)

## Current State Analysis

### What Exists

- `bootstrap.sh` — phase machine: init → HITL → AFK → verify
- `runner.mjs` — deterministic task router (research/spec/implement/quality/generic), but `runImplementTask` is a **placeholder**
- `ralph-loop.sh` — runs runner.mjs in Docker, commits, updates state
- `validate-branch.sh` — branch-type bound validation (conventional commits, per-type gates)
- `create-devcontainer` package — instantiates templates into workspaces
- `devcontainer-features` — claude-code-plugins, skills, hooks, backend, privacy, rules

### What Is Missing

1. **Skill implementations** for `/to-spec`, `/wayfinder`, `/to-tickets`, `/implement`, `/code-review`
2. **Auto-bootstrap** — when no spec exists, the system creates one without human intervention
3. **Real implementation in runner.mjs** — currently blocked for all implement tasks
4. **Ticket dependency graph** — tickets have "Blocked by" but no automated scheduling
5. **Multi-perspective code review** — not just lint/tests, but architecture, security, correctness
6. **Self-evolution loop** — sandcastle improves its own scripts based on failure logs
7. **GitHub integration** — tickets should sync with issues, branches with PRs

## Design Decisions

### Decision 1: Skills as Claude Code Plugins (Not Hooks)

Slash commands like `/to-spec` are **user-facing commands**, not session lifecycle events. They belong as Claude Code plugins (installed via `claude-code-plugins` feature) or as custom skills in `~/.claude/skills/`. We will implement them as **skills** (simple markdown + JSON configs in `~/.claude/skills/`) because:

- They don't need hook interception points
- They are invoked explicitly by the user or bootstrap script
- Skills are easier to version and distribute than plugins

### Decision 2: Runner.mjs Becomes the Orchestrator, Not the Implementer

The runner should **spawn sub-processes** (Claude Code CLI in headless mode, Docker containers, or local shell commands) rather than trying to implement logic itself. It becomes a **workflow engine**:

- Reads ticket state
- Decides which tool to invoke (claude headless, npm test, git commit)
- Captures output
- Updates state

### Decision 3: Bootstrap.sh Gets an `auto` Mode

A new `bash .devcontainer/bootstrap.sh auto` command that:

1. Checks if SPEC.md exists → if not, runs `/to-spec` equivalent
2. Checks if wayfinder map exists → if not, runs `/wayfinder`
3. Checks for unticketed spec sections → runs `/to-tickets`
4. Checks for open AFK tickets → runs `/implement` (ralph loops)
5. Checks for pending-review tickets → runs `/code-review`
6. Commits approved work, merges to main, loops

### Decision 4: Multi-Perspective Review via Parallel Subagents

Each implementation cycle triggers **3 parallel review perspectives**:

- **Correctness** — tests pass, types check, logic is sound
- **Architecture** — fits existing patterns, no circular deps, reasonable abstractions
- **Safety** — no secrets, no attribution, conventional commits, human-sovereignty compliant

These are run as separate Docker containers (sandcastle isolation) and results are aggregated.

## Implementation Phases

### Phase 1: Skill Definitions (Foundation)

Create 5 Claude Code skills in `src/claude-code-skills/` or as standalone files:

| Skill | Purpose | Trigger |
|-------|---------|---------|
| `to-spec` | Read README + context → write SPEC.md | `/to-spec` or bootstrap auto |
| `wayfinder` | Read SPEC.md → write wayfinder map + tickets | `/wayfinder` or bootstrap auto |
| `to-tickets` | Parse SPEC.md sections → ticket markdown files | `/to-tickets` or bootstrap auto |
| `implement` | Trigger ralph-loop.sh for open AFK tickets | `/implement` or bootstrap auto |
| `code-review` | Run multi-perspective review on pending-review branches | `/code-review` or bootstrap auto |

### Phase 2: Enhanced runner.mjs (Engine)

- Replace placeholder `runImplementTask` with real implementation
- Add sub-process spawning for `claude` CLI in headless mode
- Add multi-perspective review orchestration
- Add self-evolution: read `.ralph/logs/` failures, suggest script improvements

### Phase 3: Bootstrap Auto-Mode (Glue)

- Add `auto` subcommand to bootstrap.sh
- Implement state machine transitions without human prompts
- Add cron-like scheduling via `devcontainer`'s `postStartCommand`

### Phase 4: GitHub Integration (Network)

- Sync wayfinder tickets ↔ GitHub issues
- Sync pending-review branches ↔ PRs
- Auto-merge PRs that pass all checks + review

### Phase 5: Template Updates (Distribution)

- Update `devcontainer.json` to include new skills
- Update `bootstrap.sh` in the template
- Update `create-devcontainer` package if needed
- Update README.md

## Files to Create/Modify

### New Files (Skills)

- `src/claude-code-skills/skills/to-spec/` (skill definition + implementation script)
- `src/claude-code-skills/skills/wayfinder/` (skill definition + implementation script)
- `src/claude-code-skills/skills/to-tickets/` (skill definition + implementation script)
- `src/claude-code-skills/skills/implement/` (skill definition + implementation script)
- `src/claude-code-skills/skills/code-review/` (skill definition + implementation script)

### Modified Files (Template)

- `devcontainer-templates/src/ollama-claude-sandcastle-studio/.devcontainer/bootstrap.sh` — add `auto` mode
- `devcontainer-templates/src/ollama-claude-sandcastle-studio/.devcontainer/sandcastle/runner.mjs` — implement real tasks
- `devcontainer-templates/src/ollama-claude-sandcastle-studio/.devcontainer/sandcastle/ralph-loop.sh` — add multi-perspective review
- `devcontainer-templates/src/ollama-claude-sandcastle-studio/.devcontainer/sandcastle/validate-branch.sh` — enhance checks
- `devcontainer-templates/src/ollama-claude-sandcastle-studio/devcontainer-template.json` — version bump
- `devcontainer-templates/src/ollama-claude-sandcastle-studio/README.md` — document auto mode

### Modified Files (Features)

- `src/claude-code-skills/install.sh` — install new skills
- `src/claude-code-skills/devcontainer-feature.json` — add options for new skills

## Testing Strategy

1. Unit tests for runner.mjs task routing
2. Integration tests for bootstrap.sh phase transitions
3. End-to-end test: create empty dir → apply template → run auto → verify SPEC.md exists
4. CI updates in `devcontainer-templates/.github/workflows/`

## Anti-Patterns to Avoid

- **No LLM improvisation in sandcastle scripts** — keep bootstrap.sh, runner.mjs, ralph-loop.sh deterministic
- **No infinite loops** — max iterations, max tickets per cycle, human approval for destructive ops
- **No silent failures** — all state changes logged, all failures surfaced
- **No attribution in generated commits** — per repo rules

## Rollback Plan

If auto-mode causes chaos:

1. Disable `postStartCommand` in devcontainer.json
2. Revert to manual `bash .devcontainer/bootstrap.sh init/afk/verify`
3. All changes are in git branches, so `git reset` or branch deletion recovers
