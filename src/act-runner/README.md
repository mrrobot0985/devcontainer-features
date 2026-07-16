# GitHub Actions Local Runner

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Installs `nektos/act` for running GitHub Actions workflows locally inside devcontainers.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/act-runner:0": {
        "version": "latest",
        "runnerImage": "medium"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of act to install |
| `runnerImage` | string | `medium` | Default runner image: micro, medium, or large |
| `configureDocker` | boolean | `true` | Configure Docker-outside-of-Docker access |

## Runner Images

| Size | Image | Description |
|------|-------|-------------|
| `micro` | `node:16-buster-slim` | ~200MB, minimal Node.js |
| `medium` | `catthehacker/ubuntu:act-latest` | ~500MB, closer to GitHub runners |
| `large` | `catthehacker/ubuntu:full-latest` | ~18GB, full GitHub runner parity |

## CLI

```bash
# List available workflows
act -l

# Run default push event
act

# Run specific job
act -j test

# Run with secrets file
act --secret-file .secrets

# Check status
devcontainer-act status
```

## Requirements

- Docker CLI must be available (install via `docker-in-docker` or `docker-outside-of-docker` feature)
- For `medium`/`large` runners, sufficient disk space (~500MB–18GB)

## Notes

- act uses Docker to spawn runner containers; ensure Docker socket access
- The `.actrc` file is generated with runner image mappings
- Combine with `docker-compose-helper` for service container workflows
