# Container Resource Limits

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Enforces CPU and memory resource limits on the devcontainer via cgroup v2 configuration

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `cpuLimit` | CPU limit (e.g., 2 for 2 cores, 0.5 for half a core). Empty means no limit. | string | "" |
| `memoryLimit` | Memory limit (e.g., 4g, 512m). Empty means no limit. | string | "" |
| `swapLimit` | Swap limit (e.g., 4g, 512m). Empty means no limit. | string | "" |
| `pidsLimit` | Maximum number of PIDs allowed in the container. 0 means no limit. | string | 0 |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/container-resource-limits:1": {}
}
```
