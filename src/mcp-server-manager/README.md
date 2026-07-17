# MCP Server Manager

![Version](https://img.shields.io/badge/version-1.0.1-blue?style=flat-square)

Agent-agnostic Model Context Protocol (MCP) server config for multi-ai and non-Claude agent studios. Writes a shared mcpServers JSON clients can consume.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `servers` | Comma-separated list of MCP servers to configure (github, playwright, context7, supabase, fetch, sequentialthinking, memory, sqlite) | string | github |
| `configPath` | Path to write the MCP server configuration JSON, or 'auto' for ~/.mcp/mcp-servers.json. Use a workspace path (e.g. /workspaces/<name>/.mcp.json) for shared multi-agent config. | string | auto |
| `startServers` | Generate a startup script that lists configured MCP servers (clients typically spawn servers themselves) | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/mcp-server-manager:1": {}
}
```

## Multi-agent composition

Use this feature as the **default MCP layer** for multi-ai workspaces and non-Claude agent studios (Grok, Codex, Pi, Hermes, Gemini CLI, OpenCode, etc.). It is agent-agnostic: it only writes a shared `mcpServers` JSON and helper CLIs.

| Feature | Audience | Config target |
| ------- | -------- | ------------- |
| **`mcp-server-manager`** | Multi-ai / any agent | `~/.mcp/mcp-servers.json` (or `configPath`) |
| **`claude-code-mcp-servers`** | Claude Code only | `~/.claude/settings.json` |
| **`claude-code-mcp-orchestrator`** | Lifecycle helper (Claude-oriented) | workspace `.mcp.json` via `mcp-ctl` |

### When to use which

- **multi-ai / agent studios (recommended):** `mcp-server-manager` only. Point each client at the generated config (or copy `mcp.json.example` to workspace `.mcp.json`).
- **Claude-only templates:** `claude-code-mcp-servers` (and optionally `claude-code-mcp-orchestrator`) is fine; do **not** also stack `mcp-server-manager` unless you intentionally want a second shared config.
- **Never** apply `claude-code-mcp-*` to Grok/Codex/Pi/Hermes-only studios — those features assume Claude Code paths and settings.

### Multi-ai example

```json
"features": {
    "ghcr.io/devcontainers/features/node:1": { "version": "20" },
    "ghcr.io/mrrobot0985/devcontainer-features/mcp-server-manager:1": {
        "servers": "github,memory,sequentialthinking,context7",
        "configPath": "auto"
    }
},
"containerEnv": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${localEnv:GITHUB_PERSONAL_ACCESS_TOKEN}"
}
```

To share one workspace file across tools, set `configPath` to the project `.mcp.json`:

```json
"ghcr.io/mrrobot0985/devcontainer-features/mcp-server-manager:1": {
    "servers": "github,memory",
    "configPath": "${containerWorkspaceFolder}/.mcp.json"
}
```

(`configPath` is resolved at install time; prefer an absolute path such as `/workspaces/<name>/.mcp.json` if variable substitution is unavailable.)

### Claude-only example (do not use for multi-ai)

```json
"features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:1": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-mcp-servers:1": {
        "enableGithub": true
    }
}
```

## Supported servers

| Id | Package / launcher | Notes |
| -- | ----------------- | ----- |
| `github` | `npx -y @modelcontextprotocol/server-github` | Needs `GITHUB_PERSONAL_ACCESS_TOKEN` in the environment |
| `playwright` | `npx -y @playwright/mcp` | Browser automation |
| `context7` | `npx -y @upstash/context7-mcp` | Library docs lookup |
| `supabase` | `npx -y @supabase/mcp-server-supabase@latest` | Needs `SUPABASE_ACCESS_TOKEN` |
| `fetch` | `uvx mcp-server-fetch` | Requires `uv`/`uvx` at runtime |
| `sequentialthinking` | `npx -y @modelcontextprotocol/server-sequential-thinking` | |
| `memory` | `npx -y @modelcontextprotocol/server-memory` | Data under `~/.mcp/memory` |
| `sqlite` | `npx -y mcp-sqlite /tmp/mcp-sqlite.db` | |

Unknown names are skipped with a warning and **never** produce invalid JSON.

## Install ordering

`installsAfter` includes `common-utils` and `node` so `npx`-based servers resolve after Node is present when that feature is also installed. Include the official Node feature in multi-ai templates:

```json
"ghcr.io/devcontainers/features/node:1": { "version": "20" }
```

## Example `.mcp.json`

A copy is installed at `/usr/local/share/mcp-server-manager/mcp.json.example` and lives in the feature source as [`mcp.json.example`](./mcp.json.example). Shape:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

## Helpers

| Command | Purpose |
| ------- | ------- |
| `devcontainer-mcp-status` | Print configured servers from the config file |
| `devcontainer-mcp-start` | Informational launcher (most clients spawn servers themselves) |

## Secrets

Provide tokens via `containerEnv` / secrets — do not bake them into the JSON:

```json
"containerEnv": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "${localEnv:GITHUB_PERSONAL_ACCESS_TOKEN}",
    "SUPABASE_ACCESS_TOKEN": "${localEnv:SUPABASE_ACCESS_TOKEN}"
}
```
