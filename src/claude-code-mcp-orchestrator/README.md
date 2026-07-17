# Claude Code MCP Orchestrator

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs and manages MCP server lifecycle from .mcp.json configuration. Starts servers on container launch and provides health-check utilities.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `configPath` | Path to .mcp.json configuration file | string | /workspace/.mcp.json |
| `autoStart` | Automatically start MCP servers on postCreateCommand | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-mcp-orchestrator:1": {}
}
```
