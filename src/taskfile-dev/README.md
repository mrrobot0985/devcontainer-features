# Taskfile Development

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs the [Task](https://taskfile.dev) command runner (go-task) with shell completions and optional alias. Task is a modern Make alternative that uses YAML instead of Makefiles.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/taskfile-dev:0": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `"latest"` | Task version to install, or `latest` for auto-resolution |
| `alias` | boolean | `true` | Create a `t` alias for `task` in shell rc files |
| `completions` | boolean | `true` | Install bash and zsh completions |
| `detectTaskfile` | boolean | `true` | Print a hint if Taskfile.yml is found in the workspace |

## Quick Start

After the feature installs, create a Taskfile:

```bash
task --init
```

Or manually create a `Taskfile.yml`:

```yaml
version: '3'

tasks:
  hello:
    cmds:
      - echo "Hello from Task!"
```

Run it:

```bash
task hello
# or
 t hello
```

## Includes

- Task binary at `/usr/local/bin/task`
- Bash completions at `/usr/local/share/bash-completion/completions/task`
- Zsh completions at `/usr/local/share/zsh/site-functions/_task`
- Shell alias `t='task'` (when `alias: true`)

## Notes

- Task is downloaded from official GitHub releases
- Supports `x86_64`/`amd64` and `aarch64`/`arm64` architectures
- The `t` alias is added to `~/.bashrc` and `~/.zshrc` for the container user
