# Registry Mirror Config

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Configures Docker daemon registry mirrors to accelerate image pulls in corporate, air-gapped, or network-constrained environments.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/registry-mirror-config:0": {
        "mirrors": "https://mirror.example.com",
        "insecureRegistries": "registry.local:5000"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `mirrors` | string | `""` | Comma-separated list of registry mirror URLs |
| `insecureRegistries` | string | `""` | Comma-separated list of insecure registries (no TLS) |
| `restartDocker` | boolean | `true` | Attempt to restart Docker after updating config |

## Examples

### Docker Hub Mirror

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/registry-mirror-config:0": {
        "mirrors": "https://dockerhub-proxy.example.com"
    }
}
```

### Multiple Mirrors

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/registry-mirror-config:0": {
        "mirrors": "https://mirror1.example.com,https://mirror2.example.com"
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

- Modifies `/etc/docker/daemon.json`
- Docker restart requires privileged mode or docker-in-docker feature
- For air-gapped environments, combine with `corporate-cert-injector` for TLS trust
- See [Docker registry mirror documentation](https://docs.docker.com/docker-hub/mirror/)
