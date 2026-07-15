#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"

check "settings.json exists" test -f "$SETTINGS_FILE"

check "github mcp server configured" bash -c "jq -e '.mcpServers.github' '$SETTINGS_FILE' >/dev/null"
check "filesystem mcp server configured" bash -c "jq -e '.mcpServers.filesystem' '$SETTINGS_FILE' >/dev/null"
check "filesystem mcp server scopes to workspaces" bash -c "jq -e '.mcpServers.filesystem.args | contains([\"/workspaces\"])' '$SETTINGS_FILE' >/dev/null"

reportResults
