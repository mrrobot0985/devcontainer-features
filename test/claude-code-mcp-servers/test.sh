#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"

check "settings.json exists" test -f "$SETTINGS_FILE"
check "settings.json is valid JSON" bash -c "jq empty '$SETTINGS_FILE'"

# Default scenario should have github MCP server configured
check "github mcp server configured" bash -c "jq -e '.mcpServers.github' '$SETTINGS_FILE' >/dev/null"
check "github mcp server uses npx" bash -c "jq -e '.mcpServers.github.command == \"npx\"' '$SETTINGS_FILE' >/dev/null"
check "github mcp server has env placeholder" bash -c "jq -e '.mcpServers.github.env.GITHUB_TOKEN' '$SETTINGS_FILE' >/dev/null"

reportResults
