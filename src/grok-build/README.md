# Grok Build

![Version](https://img.shields.io/badge/version-1.0.2-blue?style=flat-square)

Installs xAI Grok Build CLI and persists `~/.grok` home directory across container rebuilds via bind mount.

## Usage

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/grok-build:1": {}
  }
}
```

## Options

| Option | Description | Type | Default |
| ------ | ----------- | ---- | ------- |
| `version` | Grok Build version to install (latest, or specific version tag) | string | latest |

## Home Directory Persistence

This feature configures home directory persistence to survive container rebuilds:

1. Bind-mount host `~/.grok` to `/var/lib/grok-build` in the container
2. Symlink `~/.grok` inside the container to the mounted location

Add to your `devcontainer.json`:

```json
"mounts": [
  "source=${localEnv:HOME}/.grok,target=/var/lib/grok-build,type=bind,consistency=cached"
]
```

And pre-create the directory on the host:

```json
"initializeCommand": "mkdir -p \"${localEnv:HOME}/.grok\""
```

## Authentication

After installation, authenticate with:

```bash
grok login
```

Or set the `GROK_DEPLOYMENT_KEY` environment variable for non-interactive use.

**Note:** Grok Build requires **SuperGrok** or **X Premium Plus** subscription.

## What it installs

- Grok Build CLI (`grok` / `agent` command)
- PATH configuration for CLI access
- Home directory persistence symlink

## Requirements

- Ubuntu-based devcontainer image
- `git` and `curl` (installed if missing)
- Non-root user (configured via `_REMOTE_USER`)

## Conflicts

This feature provides home persistence for the Grok Build agent. Do not use alongside other Grok Build installers that don't support bind mounts.

## See also

- [grok-build-cli template](../../templates/src/grok-build-cli/README.md)
- [grok-build-cli-studio template](../../templates/src/grok-build-cli-studio/README.md)
- [container-firewall](../container-firewall/README.md) — network whitelist with `grok-build` tag
