# Docker Compose Helper

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Validates docker-compose.yml files and optionally injects health checks and dependency ordering for reliable devcontainer service startup

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `validate` | Validate the docker-compose.yml syntax using docker compose config | boolean | true |
| `healthChecks` | Add health check stanzas to services that are dependencies of other services | boolean | true |
| `dependsOnOrdering` | Rewrite depends_on to use condition: service_healthy instead of simple service lists | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/docker-compose-helper:1": {}
}
```
