# Devcontainer Lock Audit

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

CI gate that enforces .devcontainer-lock.json presence and validates that pinned feature versions match the current devcontainer.json configuration

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `failOnMissing` | Fail if .devcontainer-lock.json is missing | boolean | true |
| `failOnStale` | Fail if lockfile is older than devcontainer.json | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/devcontainer-lock-audit:1": {}
}
```
