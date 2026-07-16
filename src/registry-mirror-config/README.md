# Registry Mirror Config

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Configures Docker daemon registry mirrors to accelerate image pulls in corporate, air-gapped, or network-constrained environments.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/registry-mirror-config:0": {
        "mirrors": "[\"https://mirror.example.com\"]",
        "insecureRegistries": "registry.local:5000"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `mirrors` | string | `""` | JSON array of registry mirror URLs, or full `registry-mirrors` config object |
| `insecureRegistries` | string | `""` | Comma-separated list of insecure registries (no TLS) |
| `restartDocker` | boolean | `true` | Attempt to restart Docker after updating config |

## Examples

### Docker Hub Mirror

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/registry-mirror-config:0": {
        "mirrors": "[\"https://dockerhub-proxy.example.com\"]"
    }
}
```

### Harbor Pull-Through Cache

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/registry-mirror-config:0": {
        "mirrors": "[{\"https://registry-1.docker.io\": [{\"https://harbor.example.com\": true}]}]"
    }
}
```

### Insecure Internal Registry

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/registry-mirror-config:0": {
        "insecureRegistries": "registry.local:5000,registry.internal"
    }
}
```

## Notes

- Modifies `/etc/docker/daemon.json` and merges with existing configuration
- Docker restart requires privileged mode or docker-in-docker feature
- For air-gapped environments, combine with `corporate-cert-injector` for TLS trust
- See [Docker registry mirror documentation](https://docs.docker.com/docker-hub/mirror/)
