# Devcontainer CI Tools

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Installs the devcontainer CLI, docker-buildx, and `act` (local GitHub Actions
runner) so template and feature authors can self-test their work inside the
devcontainer itself.

## Features

- **devcontainer CLI**: Build, up, and exec commands for testing configurations.
- **docker-buildx**: Advanced build capabilities for multi-platform images.
- **act**: Run GitHub Actions workflows locally.

## Usage

Add to `devcontainer.json`:

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/devcontainer-ci-tools:0": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `devcontainerCliVersion` | string | `latest` | Version of devcontainer CLI to install |
| `installAct` | boolean | `true` | Install act (local GitHub Actions runner) |
| `installBuildx` | boolean | `true` | Install docker-buildx |

## Example: Pin CLI version

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/devcontainer-ci-tools:0": {
    "devcontainerCliVersion": "v0.73.0",
    "installAct": false
  }
}
```
