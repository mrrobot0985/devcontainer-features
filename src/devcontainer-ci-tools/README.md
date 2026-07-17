# Devcontainer CI Tools

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs the devcontainer CLI, docker-buildx, and act (local GitHub Actions runner) for self-testing devcontainers inside devcontainers

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `devcontainerCliVersion` | Version of the devcontainer CLI to install (e.g., 0.73.0 or latest) | string | latest |
| `installAct` | Install act (local GitHub Actions runner) | boolean | true |
| `installBuildx` | Install docker-buildx | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/devcontainer-ci-tools:1": {}
}
```
