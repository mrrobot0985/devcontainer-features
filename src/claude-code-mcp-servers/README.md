# Claude Code MCP Servers

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs and configures Model Context Protocol (MCP) servers for Claude Code so external tools are available out of the box.

## Problem Solved

The embedded behavior rules preach "MCP tools first," but the devcontainer does not ship any MCP servers. Claude Code cannot use the GitHub MCP, filesystem MCP, or any other tool server without manual setup. This feature closes that gap by pre-wiring stable MCP servers into `~/.claude/settings.json` at build time.

## Options

| Options Id | Description | Type | Default Value |
| ---------- | ----------- | ---- | ------------- |
| `enableGithub` | Configure the GitHub MCP server for repository, issue, and PR access | boolean | `true` |
| `enableFilesystem` | Configure the filesystem MCP server for structured file access | boolean | `false` |
| `githubTokenEnvVar` | Environment variable name that holds the GitHub personal access token | string | `GITHUB_TOKEN` |

## Example Usage

Default configuration (GitHub MCP server only):

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-mcp-servers:0": {}
}
```

With GitHub + filesystem MCP servers:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-mcp-servers:0": {
        "enableGithub": true,
        "enableFilesystem": true,
        "githubTokenEnvVar": "GITHUB_TOKEN"
    }
}
```

## Authentication

The GitHub MCP server requires a personal access token. The feature writes a placeholder into `settings.json` referencing the configured environment variable. You must provide the actual token via one of these methods:

1. **Devcontainer secrets** (recommended):

   ```json
   "containerEnv": {
       "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}"
   }
   ```

2. **GitHub Codespaces secrets**: Add `GITHUB_TOKEN` in your Codespaces user secrets.

3. **Manual export** in the container: `export GITHUB_TOKEN=ghp_...`

## Requirements

- Node.js must be installed (via the official `ghcr.io/devcontainers/features/node` feature) so that `npx` is available.
- This feature should be installed **after** the Node.js feature.
