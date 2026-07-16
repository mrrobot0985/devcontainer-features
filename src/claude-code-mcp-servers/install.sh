#!/bin/sh
set -e

echo "Activating feature 'claude-code-mcp-servers'"

ENABLE_GITHUB="${ENABLEGITHUB:-true}"
ENABLE_FILESYSTEM="${ENABLEFILESYSTEM:-false}"
GITHUB_TOKEN_VAR="${GITHUBTOKENENVVAR:-GITHUB_TOKEN}"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

mkdir -p "$CLAUDE_DIR"

# Ensure Node.js is available for npx-based MCP servers
if ! command -v npx >/dev/null 2>&1; then
    echo "WARNING: npx is not available. MCP servers that require Node.js will not be configured."
    echo "         Ensure the Node.js devcontainer feature is installed before this feature."
fi

# Build mcpServers configuration
MCP_JSON='{}'

if [ "$ENABLE_GITHUB" = "true" ] && command -v npx >/dev/null 2>&1; then
    echo "Configuring GitHub MCP server..."
    MCP_JSON=$(printf '%s' "$MCP_JSON" | jq \
        --arg token_var "$GITHUB_TOKEN_VAR" \
        '.mcpServers.github = {
            "command": "npx",
            "args": ["-y", "@anthropic-ai/mcp-server-github"],
            "env": {
                ($token_var): ""
            }
        }')
fi

if [ "$ENABLE_FILESYSTEM" = "true" ] && command -v npx >/dev/null 2>&1; then
    echo "Configuring filesystem MCP server..."
    MCP_JSON=$(printf '%s' "$MCP_JSON" | jq \
        '.mcpServers.filesystem = {
            "command": "npx",
            "args": ["-y", "@anthropic-ai/mcp-server-filesystem", "/workspaces"]
        }')
fi

# Merge into settings.json
HELPER_FILE="$(dirname "$0")/merge-settings.sh"
# shellcheck source=merge-settings.sh
# shellcheck disable=SC1091
. "$HELPER_FILE"

merge_settings_json "$SETTINGS_FILE" "$MCP_JSON"

chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

echo "Claude Code MCP servers configured in $SETTINGS_FILE"
if [ "$ENABLE_GITHUB" = "true" ]; then
    echo "  - GitHub MCP server: set $GITHUB_TOKEN_VAR in your environment or devcontainer.json secrets"
fi
if [ "$ENABLE_FILESYSTEM" = "true" ]; then
    echo "  - Filesystem MCP server: scoped to /workspaces"
fi
