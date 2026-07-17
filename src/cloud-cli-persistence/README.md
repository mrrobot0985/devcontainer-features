# Cloud CLI Persistence

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Persists cloud CLI authentication state across container rebuilds by validating host credential mounts and providing helper utilities for AWS, Azure, GCP, and GitHub CLI

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `providers` | Comma-separated list of cloud providers to configure (aws, azure, gcp, github) | string | aws,azure,gcp,github |
| `validateMounts` | Validate that host credential directories are mounted into the container at install time | boolean | true |
| `printMountConfig` | Print the required devcontainer.json mounts configuration after setup | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/cloud-cli-persistence:1": {}
}
```
