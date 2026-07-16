# Git Hooks Manager

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs and configures pre-commit hooks for linting, formatting, and conventional commits in devcontainer projects.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/git-hooks-manager:0": {
        "hooks": "pre-commit,commitlint,prettier",
        "autoInstall": true
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hooks` | string | `pre-commit` | Comma-separated list of hooks to install |
| `autoInstall` | boolean | `true` | Auto-install hooks into workspace git repo on startup |
| `configPath` | string | `.pre-commit-config.yaml` | Path to pre-commit config relative to workspace root |

## Supported Hooks

| Hook | Description | Requirement |
|------|-------------|-------------|
| `pre-commit` | Pre-commit framework (trailing whitespace, EOF fixer, YAML/JSON checks) | Python/pip |
| `commitlint` | Conventional commit message linting | Node.js/npm |
| `prettier` | Code formatting | Node.js/npm |
| `lint-staged` | Run linters on git staged files | Node.js/npm |

## CLI

```bash
# Install hooks into current workspace
devcontainer-git-hooks-install

# Install hooks into specific workspace with custom config
devcontainer-git-hooks-install /path/to/workspace .pre-commit-config.yaml
```

## Notes

- Requires Python/pip for the pre-commit framework
- Node.js-based hooks (commitlint, prettier, lint-staged) require npm
- A default `.pre-commit-config.yaml` is generated if none exists and `autoInstall` is true
- Combine with `direnv-integration` for per-project hook configurations
