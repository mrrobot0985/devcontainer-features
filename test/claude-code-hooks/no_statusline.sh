#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"

check "settings.json exists" test -f "$SETTINGS_FILE"
check "hooks key present" bash -c "jq -e '.hooks' '$SETTINGS_FILE' >/dev/null"
check "statusLine not present" bash -c "! jq -e '.statusLine' '$SETTINGS_FILE' >/dev/null 2>&1"

reportResults
