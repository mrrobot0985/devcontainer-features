# Devcontainer Shared Library

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs a shared shell utility library for use in devcontainer lifecycle scripts and custom automation. Provides common functions like retry, wait-for, logging, and architecture detection.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `installPath` | Path where the shared library is installed | string | /usr/local/share/devcontainer-lib |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/devcontainer-lib:1": {}
}
```
