# Non-Root Enforcer

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Audits devcontainer.json for root remoteUser and warns or fails when the container is configured to run as root, which breaks Claude Code and other AI-agent permissions

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `failOnWarning` | Fail container creation if remoteUser is root or missing | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/non-root-enforcer:1": {}
}
```
