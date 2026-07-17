# Claude Code MCP Servers

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs and configures Model Context Protocol (MCP) servers for Claude Code so external tools are available out of the box

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `enableGithub` | Configure the GitHub MCP server for repository, issue, and PR access | boolean | true |
| `enableFilesystem` | Configure the filesystem MCP server for structured file access | boolean | false |
| `githubTokenEnvVar` | Environment variable name that holds the GitHub personal access token | string | GITHUB_TOKEN |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-mcp-servers:1": {}
}
```
