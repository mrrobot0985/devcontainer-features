#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"

check "settings.json exists" test -f "$SETTINGS_FILE"
check "no mcpServers when disabled" bash -c "! jq -e '.mcpServers' '$SETTINGS_FILE' >/dev/null 2>&1 || test \"$(jq '.mcpServers | keys | length' '$SETTINGS_FILE')\" -eq 0"

reportResults
