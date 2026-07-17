# Podman Checkpoint Helper

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Podman with checkpoint/restore support (CRIU) for ephemeral AI agent container workflows and cross-node container migration

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `installCriu` | Install CRIU (Checkpoint/Restore In Userspace) required for Podman checkpoint/restore | boolean | true |
| `configureStorage` | Configure Podman storage to use overlay filesystem for checkpoint compatibility | boolean | true |
| `addAliases` | Add docker-compatible aliases (docker, docker-compose) that wrap Podman commands | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/podman-checkpoint-helper:1": {}
}
```
