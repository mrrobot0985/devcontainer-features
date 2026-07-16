# direnv Integration

![Version](https://img.shields.io/badge/version-1.0.0-blue)

Installs [direnv](https://direnv.net) and hooks it into shell startup for automatic `.envrc` loading when changing directories inside the devcontainer.

## Problem

Developers frequently need environment variables specific to a project (API keys, database URLs, feature flags). Without direnv, these must be manually exported or sourced every session. direnv automatically loads `.envrc` when you `cd` into a directory.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/direnv-integration:0": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"latest"` | direnv version to install, or `"latest"` for auto-resolution from GitHub releases |
| `shell` | string | `"auto"` | Shells to hook: `auto`, `bash`, `zsh`, `fish`. Use comma-separated for multiple. |
| `autoAllow` | boolean | `true` | Automatically run `direnv allow` in workspace directories where `.envrc` exists |

## Quick Start

After the feature installs, create an `.envrc` in your workspace:

```bash
echo 'export DATABASE_URL=postgres://localhost:5432/mydb' > .envrc
direnv allow
```

Now every time you open the devcontainer or `cd` into the workspace, `DATABASE_URL` is automatically set.

## Shell Support

The feature detects available shells and hooks direnv into each:

- **bash** — appends `eval "$(direnv hook bash)"` to `~/.bashrc`
- **zsh** — appends `eval "$(direnv hook zsh)"` to `~/.zshrc`
- **fish** — appends `direnv hook fish | source` to `~/.config/fish/config.fish`

Specify shells explicitly:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/direnv-integration:0": {
        "shell": "bash,zsh"
    }
}
```

## Pinning a Version

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/direnv-integration:0": {
        "version": "2.35.0"
    }
}
```

## Auto-Allow

With `autoAllow: true` (default), the feature automatically runs `direnv allow` in any `/workspaces/*` directory that contains an `.envrc` file. This is convenient for pre-configured repositories but requires trusting the `.envrc` content.

Disable auto-allow for stricter security:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/direnv-integration:0": {
        "autoAllow": false
    }
}
```

## direnv Configuration

The feature creates a sensible `~/.direnvrc`:

```bash
export DIRENV_WARN_TIMEOUT=10s
export DIRENV_LOG_FORMAT=""
strict_env
```

- `DIRENV_WARN_TIMEOUT=10s` — Warn if `.envrc` evaluation takes longer than 10 seconds
- `DIRENV_LOG_FORMAT=""` — Suppress verbose output in devcontainers
- `strict_env` — Fail on unset variables in `.envrc`

## Notes

- The direnv binary is downloaded from GitHub releases; no package manager dependency
- Supports `x86_64`/`amd64` and `aarch64`/`arm64` architectures
- All shell configuration files are owned by the container user (`_REMOTE_USER`)
