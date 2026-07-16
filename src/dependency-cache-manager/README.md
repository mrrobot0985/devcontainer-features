# Dependency Cache Manager

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Configures package manager cache directories to use a named volume mount point,
reducing container rebuild times by persisting downloaded dependencies across
rebuilds.

## Features

- **Auto-detection**: Identifies project types by scanning for `package.json`,
  `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `go.mod`, `pom.xml`, and
  Gradle build files.
- **Tool coverage**: npm, yarn, pnpm, pip, uv, cargo, gradle, maven, go.
- **Prints mount config**: Outputs the exact `mounts` entry needed in
  `devcontainer.json`.

## Usage

Add to `devcontainer.json`:

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/dependency-cache-manager:0": {}
}
```

Then add the named volume mount:

```json
"mounts": [
  "source=devcontainer-cache,target=/mnt/devcontainer-cache,type=volume"
]
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `autoDetect` | boolean | `true` | Auto-detect project types |
| `tools` | string | `""` | Comma-separated list of tools to configure |
| `cachePath` | string | `/mnt/devcontainer-cache` | Base cache directory |
| `printMountConfig` | boolean | `true` | Print required mount config |

## Example: Explicit tools

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/dependency-cache-manager:0": {
    "autoDetect": false,
    "tools": "npm,cargo,uv"
  }
}
```
