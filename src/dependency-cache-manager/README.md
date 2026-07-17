# Dependency Cache Manager

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Auto-detects project types and configures package manager cache directories to use a named volume mount point, reducing rebuild times from minutes to seconds

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `autoDetect` | Automatically detect project types and configure appropriate caches | boolean | true |
| `tools` | Comma-separated list of tools to configure (npm, yarn, pnpm, pip, cargo, gradle, maven, go, uv). Overrides auto-detect when set. | string | "" |
| `cachePath` | Base path for cache directories. Add a named volume mount targeting this path in devcontainer.json. | string | /mnt/devcontainer-cache |
| `printMountConfig` | Print the required devcontainer.json mounts configuration after setup | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/dependency-cache-manager:1": {}
}
```
