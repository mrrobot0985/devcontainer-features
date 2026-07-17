# Locust Load Testing

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Locust for Python-based load and performance testing in devcontainers

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `version` | Version of locust to install, or 'latest' | string | latest |
| `installPlugins` | Install common Locust plugins for additional metrics and reporting | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/locust-testing:1": {}
}
```
