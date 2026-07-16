# Docker Compose Helper

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Validates `docker-compose.yml` files and optionally injects health checks and dependency ordering for reliable devcontainer service startup.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/docker-compose-helper:0": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `validate` | boolean | `true` | Validate the docker-compose.yml syntax using `docker compose config` |
| `healthChecks` | boolean | `true` | Add health check stanzas to services that are dependencies of other services |
| `dependsOnOrdering` | boolean | `true` | Rewrite `depends_on` to use `condition: service_healthy` instead of simple service lists |

## Why?

Docker Compose is the devcontainer spec's only supported orchestrator. Without health checks, a dependent service may start before its dependency is actually ready, causing connection errors during `postCreateCommand`.

This feature helps ensure services start in the correct order with proper readiness probes.

## CLI

```bash
devcontainer-compose-check [path/to/docker-compose.yml]
```

## Notes

- Requires Docker CLI to be available (install via `docker-in-docker` feature for validation)
- Health check injection requires the dependency service to expose a health endpoint or command
