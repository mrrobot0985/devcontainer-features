# MCP Server Manager

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Installs and configures Model Context Protocol (MCP) servers for AI-assisted development inside devcontainers.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/mcp-server-manager:0": {
        "servers": "github,playwright,fetch"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `servers` | string | `github` | Comma-separated list of MCP servers to configure |
| `configPath` | string | `auto` | Path to write MCP config JSON, or `auto` for `~/.mcp/mcp-servers.json` |
| `startServers` | boolean | `true` | Generate a startup script for configured servers |

## Supported Servers

| Server | Package | Description |
|--------|---------|-------------|
| `github` | `@github/github-mcp-server` | GitHub API operations |
| `playwright` | `@anthropics/playwright-mcp` | Browser automation |
| `fetch` | `@modelcontextprotocol/server-fetch` | Web fetching |
| `sequentialthinking` | `@modelcontextprotocol/server-sequential-thinking` | Step-by-step reasoning |
| `memory` | `@modelcontextprotocol/server-memory` | Persistent memory |
| `sqlite` | `@modelcontextprotocol/server-sqlite` | SQLite database queries |
| `context7` | `@upstash/context7-mcp` | Documentation context |

## CLI

```bash
# View configured MCP servers
devcontainer-mcp-status

# Start MCP servers (generated script)
devcontainer-mcp-start
```

## Requirements

- Node.js and npm must be available (install via `ghcr.io/devcontainers/features/node`)
- MCP servers are launched via `npx` at runtime, not installed globally at build time

## Notes

- The generated config follows the Claude Desktop / Claude Code MCP config format
- Configure your AI client to point to the generated config file
- Some servers require environment variables (e.g., `GITHUB_TOKEN` for GitHub MCP)
