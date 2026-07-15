# NVIDIA Container Toolkit for Docker-in-Docker

Installs and configures the NVIDIA Container Toolkit so GPU-accelerated containers can run from an inner Docker daemon (Docker-in-Docker).

## Problem Solved

When a devcontainer with `--gpus=all` runs an inner Docker daemon (via the `docker-in-docker` feature), containers launched inside that inner daemon cannot access the host GPU because the inner `dockerd` does not know about the NVIDIA runtime.

This feature:

1. Installs `nvidia-container-toolkit` inside the devcontainer.
2. Configures `/etc/docker/daemon.json` to register the `nvidia` runtime.
3. Reloads the inner `dockerd` (if running) so the runtime is available immediately.

## Options

| Options Id | Description | Type | Default Value |
| ---------- | ----------- | ---- | ------------- |
| `enable` | Enable the NVIDIA Container Toolkit feature. When `false`, the feature is a no-op. | boolean | `true` |
| `defaultRuntime` | Set `nvidia` as the default container runtime for the inner dockerd | boolean | `false` |
| `restartDockerd` | Automatically reload the inner dockerd after configuration if it is running | boolean | `true` |

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:1": {
        "defaultRuntime": false,
        "restartDockerd": true
    }
}
```

With `defaultRuntime: true`, you can omit `--runtime=nvidia` when running inner containers:

```json
"features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:1": {
        "defaultRuntime": true
    }
}
```

## Requirements

- The devcontainer must be launched with `--gpus=all` (or equivalent GPU access).
- NVIDIA drivers must be present on the host.
- This feature is designed to work alongside the `docker-in-docker` devcontainer feature.

## Notes

- This feature currently supports **apt-based** distributions (Debian, Ubuntu). Contributions for other package managers are welcome.
- If `dockerd` is not running at install time, the configuration is written to `/etc/docker/daemon.json` and will be picked up automatically when `dockerd` starts.
- **Auto-skip:** The feature automatically skips installation when no NVIDIA GPU is detected (`/dev/nvidia0` missing and `nvidia-smi` unavailable), even when `enable` is `true`. This makes it safe to include in templates that may run on both GPU and non-GPU hosts.
