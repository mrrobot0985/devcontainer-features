# Claude Code Audit Log

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs a simple audit-log script that appends structured JSON events to a workspace file for compliance and post-incident review

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `logDir` | Directory where audit log files are written | string | /workspace/.audit-logs |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-audit-log:1": {}
}
```
