# Claude Code Backend

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Configures Claude Code to use a custom API backend

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `baseUrl` | Custom API base URL (auto-defaults to http://host.docker.internal:11434 when authToken is ollama) | string | "" |
| `authToken` | Auth token for the custom backend | string | ollama |
| `models` | Comma-separated model overrides in key:value format | string | "" |
| `logLevel` | Anthropic client log level | string | error |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:1": {}
}
```
