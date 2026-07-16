# Podman Checkpoint Helper

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Podman with checkpoint/restore support (CRIU) for ephemeral AI agent container workflows and cross-node container migration.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/podman-checkpoint-helper:0": {
        "installCriu": true,
        "addAliases": true
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `installCriu` | boolean | `true` | Install CRIU for checkpoint/restore support |
| `configureStorage` | boolean | `true` | Configure Podman overlay storage for checkpoint compatibility |
| `addAliases` | boolean | `true` | Add `docker` and `docker-compose` aliases wrapping Podman |

## Why Podman?

- **Checkpoint/Restore:** Podman's `container checkpoint --export` and `restore --import` work end-to-end for single containers and multi-service Compose projects
- **Rootless:** Podman runs containers without root privileges
- **Docker-compatible:** Podman supports most Docker CLI commands and Compose files

## CLI

```bash
# Check Podman and CRIU status
devcontainer-podman-checkpoint status

# Checkpoint a running container
devcontainer-podman-checkpoint checkpoint my-container /tmp/my-checkpoint.tar.gz

# Restore a container from checkpoint
devcontainer-podman-checkpoint restore my-container /tmp/my-checkpoint.tar.gz
```

## Requirements

- Requires a Linux container runtime (Podman is Linux-only)
- CRIU requires kernel support for checkpoint/restore (most modern kernels support this)
- For Docker Desktop users, Podman runs inside the VM but checkpoint/restore may be limited

## Notes

- Checkpoint archives can be large (include container filesystem + memory)
- Multi-service Compose checkpoint/restore was empirically proven in June 2026
- Combine with `docker-compose-helper` for Compose-based checkpoint workflows
