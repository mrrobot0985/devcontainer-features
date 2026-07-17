# Host Isolation Security Profile

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Audits devcontainer.json for unsafe runArgs, mounts, and capabilities. Warns when privileged mode, Docker socket binds, or excessive capabilities are detected.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `failOnWarning` | Fail container creation if unsafe configurations are detected | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/host-isolation:1": {}
}
```
