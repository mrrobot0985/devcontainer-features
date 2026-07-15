# Claude Code Sandcastle (claude-code-sandcastle)

AFK sandcastle automation layer for devcontainer templates. Self-drives a project from inception to maintenance using local markdown files (`.scratch/`) as the issue tracker.

## What it installs

Into `.devcontainer/sandcastle/`:

| File | Purpose |
|------|---------|
| `bootstrap.sh` | Phase machine: discover → spec → map → ticket → implement → review → verify |
| `runner.mjs` | Task router + `.scratch/` I/O helpers (frontier scan, claim, resolve) |
| `ralph-loop.sh` | Docker-based parallel review perspectives (architecture, correctness, safety) |
| `validate-branch.sh` | Conventional commits, branch naming, per-type gates |
| `.ralph/state.json` | Persistent state tracking current phase, effort, iteration count |

## Usage

### Manual

```bash
bash .devcontainer/sandcastle/bootstrap.sh auto
```

### Auto-mode (on devcontainer start)

Set `enableAutoMode: true` in the feature options. The bootstrap auto-mode runs via `postStartCommand`.

## Phases

| Phase | What happens |
|-------|-------------|
| **discover** | Scans for `.scratch/` maps. If none, scaffolds tracker. |
| **spec** | Runs `to-spec-headless` → `.scratch/<feature>/spec.md` |
| **map** | Runs `wayfinder-headless` → `.scratch/<effort>/map.md` + child tickets |
| **ticket** | Runs `to-tickets-headless` → `.scratch/<effort>/issues/NN-*.md` |
| **implement** | Finds frontier (open + unblocked + unclaimed), runs `implement-headless` |
| **review** | Runs `code-review-headless` → `.scratch/<effort>/reviews/` |
| **verify** | Runs `validate-branch.sh`, commits state |

## AFK vs HITL

| Skill | Auto-mode behavior |
|-------|-------------------|
| `/wayfinder` | AFK — creates map directly |
| `/to-spec` | AFK — synthesizes from context |
| `/to-tickets` | AFK — auto-breakdown, no quiz |
| `/implement` | AFK — TDD, commits, resolves |
| `/code-review` | AFK — parallel sub-agents, writes report |
| `/prototype` | Degraded AFK (opt-in via `degradedPrototype: true`) |
| `/grilling` | **HITL only** — skipped in auto-mode |

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enableAutoMode` | boolean | `false` | Run bootstrap auto on devcontainer start |
| `maxIterations` | string | `"10"` | Max iterations per auto-mode run |
| `degradedPrototype` | boolean | `false` | Allow degraded-AFK prototype mode |

## Requirements

- `claude-code-skills` feature (for headless skill definitions)
- `claude-code` feature (for `claude` CLI)
- `git` (for commits and branch validation)
- `jq` (for state JSON manipulation)
- `node` ≥ 18 (for `runner.mjs`)
