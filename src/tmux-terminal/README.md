# tmux Terminal Multiplexer

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs tmux terminal multiplexer with sensible default configuration.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | tmux version to install (via package manager) |
| `installConfig` | boolean | `false` | Install default .tmux.conf with sensible bindings |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/tmux-terminal:1": {
        "installConfig": true
    }
}
```

## CLI

```bash
# Check feature status
devcontainer-tmux status

# Start new session
devcontainer-tmux new

# Attach to session
devcontainer-tmux attach

# List sessions
devcontainer-tmux list
```

## Key Bindings

When `installConfig: true`:

| Key | Action |
|-----|--------|
| `Ctrl+b c` | New window |
| `Ctrl+b n` | Next window |
| `Ctrl+b p` | Previous window |
| `Ctrl+b %` | Split vertically |
| `Ctrl+b "` | Split horizontally |
| `Ctrl+b h/j/k/l` | Navigate panes |

## Notes

- tmux preserves terminal sessions across disconnections
- Essential for long-running processes in devcontainers
- Mouse support and 256-color terminal are enabled by default
