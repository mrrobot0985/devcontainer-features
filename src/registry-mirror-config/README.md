# Registry Mirror Config

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Configures Docker daemon registry mirrors to accelerate image pulls in corporate, air-gapped, or network-constrained environments

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `mirrors` | Comma-separated list of registry mirror URLs (e.g. 'https://mirror.example.com,https://mirror2.example.com') | string | "" |
| `insecureRegistries` | Comma-separated list of insecure registries (no TLS verification) | string | "" |
| `restartDocker` | Attempt to restart Docker daemon after updating daemon.json (requires privileged mode) | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/registry-mirror-config:1": {}
}
```
