# MCP Server Manager

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs and configures Model Context Protocol (MCP) servers for AI-assisted development inside devcontainers

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `servers` | Comma-separated list of MCP servers to install (github, playwright, context7, vercel, supabase, fetch, sequentialthinking, memory, sqlite) | string | github |
| `configPath` | Path to write the MCP server configuration JSON, or 'auto' for ~/.mcp/mcp-servers.json | string | auto |
| `startServers` | Generate a startup script that launches configured MCP servers in the background | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/mcp-server-manager:1": {}
}
```
