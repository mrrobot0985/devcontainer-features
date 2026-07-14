# Claude Code Rules (claude-code-rules)

Installs a curated, condensed set of Claude Code behavior rules into `~/.claude/rules/`.

## What it installs

Rules are organized into four declarative groups:

### Safety (`enforceSafety`)

| Rule | Priority | Description |
| ---- | -------- | ----------- |
| `00-human-sovereignty.md` | Highest | Human override is absolute; no lock-out, no self-escalation. |
| `00-no-attribution.md` | Highest | Never attribute output to AI, tools, or external sources. |
| `00-no-secrets.md` | Highest | Never expose secrets, credentials, or sensitive data. |

### Workflow (`standardizeWorkflow`)

| Rule | Priority | Description |
| ---- | -------- | ----------- |
| `00-mcp-tools-first.md` | Essential | Prefer MCP tool interfaces over raw file reads. |
| `00-skill-discovery.md` | High | Scan and invoke skills before every request. |
| `04-anti-overengineering.md` | Essential | Ground in physical reality; no speculative futures. |
| `01-conventional-commits.md` | Strict | All commit messages follow Conventional Commits. |
| `03-branch-strategy.md` | Strict | Branch naming, CI gate, and merge requirements. |

### Git Protection (`protectGit`)

| Rule | Priority | Description |
| ---- | -------- | ----------- |
| `00-no-git-config-override.md` | Highest | Never override git config inline; it is already correct. |

### Python Tooling (`preferPythonTooling`)

| Rule | Priority | Description |
| ---- | -------- | ----------- |
| `00-prefer-uv.md` | High | Prefer `uv`/`uvx` over raw `python`/`pip` commands. |
| `01-markdown-formatting.md` | Strict | Always use `mdformat` with frontmatter and GFM plugins. |

## Options

| Option | Type | Default | Description |
| ------ | ---- | ------- | ----------- |
| `enforceSafety` | boolean | `true` | Enforce safety invariants: human sovereignty, no-attribution, no-secrets |
| `standardizeWorkflow` | boolean | `true` | Standardize agent workflow: skill discovery, MCP tools first, anti-overengineering, conventional commits, branch strategy |
| `protectGit` | boolean | `true` | Protect git configuration: never override git config inline |
| `preferPythonTooling` | boolean | `false` | Prefer Python toolchain rules: uv/uvx for Python, mdformat with frontmatter/gfm plugins |

## Requirements

- `ghcr.io/anthropics/devcontainer-features/claude-code` must be installed first (for the `~/.claude` directory to exist).
- `ghcr.io/devcontainers/features/common-utils` is also required (declared via `installsAfter`).
