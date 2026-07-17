# Claude Code Privacy

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Privacy-hardened defaults for Claude Code

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `disableTelemetry` | Disable telemetry collection | boolean | true |
| `disableErrorReporting` | Disable automatic error reporting | boolean | true |
| `disableFeedback` | Disable the /feedback command | boolean | true |
| `disableUpdates` | Disable automatic updates | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-privacy:1": {}
}
```
