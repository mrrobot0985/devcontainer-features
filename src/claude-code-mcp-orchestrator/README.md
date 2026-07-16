# Claude Code MCP Orchestrator

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Installs and manages MCP server lifecycle from `.mcp.json` configuration.
Provides `mcp-ctl` utility to start, stop, and check status of configured
servers.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-mcp-orchestrator:0": {
        "configPath": "/workspace/.mcp.json",
        "autoStart": true
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `configPath` | string | `/workspace/.mcp.json` | Path to `.mcp.json` |
| `autoStart` | boolean | `true` | Start servers on `postCreateCommand` |

## .mcp.json Format

```json
{
  "github": {
    "command": "docker",
    "args": ["run", "-i", "--rm", "ghcr.io/github/github-mcp-server"]
  },
  "fetch": {
    "command": "uvx",
    "args": ["mcp-server-fetch"]
  }
}
```

## Commands

- `mcp-ctl start` — start all configured servers
- `mcp-ctl stop` — stop all running servers
- `mcp-ctl status` — show running server status
- `mcp-ctl list` — list configured server names

## Notes

- Requires `jq` for JSON parsing.
- PID files stored in `/tmp/mcp-pids/`.
- Servers run via `nohup`; logs go to `/dev/null`.
