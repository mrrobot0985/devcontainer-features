# AI Agent Sandbox

Tiered security isolation presets for AI coding agent devcontainers. Audits the
container's runtime security posture and warns or fails when excessive
privileges are detected.

## Features

- **Three presets**: `strict` (maximum isolation), `moderate` (safe defaults),
  `permissive` (audit-only).
- **Automatic audit**: Runs via `postCreateCommand` to validate isolation at
  container creation time.
- **Checks**: Docker socket mounts, root user, dangerous capabilities, outbound
  network, read-only root filesystem recommendation.

## Usage

Add to `devcontainer.json`:

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/ai-agent-sandbox:0": {
    "preset": "moderate",
    "failOnWarning": false
  }
}
```

## Presets

| Preset | docker.sock | root user | dangerous caps | network |
|--------|-------------|-----------|----------------|---------|
| `strict` | Fail if mounted | Fail if root | Fail if present | Fail if reachable |
| `moderate` | Warn | Warn | Warn | Allowed (configurable domains) |
| `permissive` | Info | Info | Info | Info |

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `preset` | string | `moderate` | Security preset: strict, moderate, or permissive |
| `failOnWarning` | boolean | `false` | Fail container creation on audit violations |
| `allowedDomains` | string | `github.com,registry.npmjs.org,pypi.org,crates.io` | Allowed domains for moderate preset |

## Example: Strict isolation

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/ai-agent-sandbox:0": {
    "preset": "strict",
    "failOnWarning": true
  }
}
```

Recommended accompanying `devcontainer.json` settings for strict mode:

```json
{
  "remoteUser": "vscode",
  "runArgs": ["--cap-drop=ALL", "--security-opt=no-new-privileges:true"]
}
```
