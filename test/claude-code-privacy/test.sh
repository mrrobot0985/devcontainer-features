#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"

check "settings.json exists" test -f "$SETTINGS_FILE"
check "telemetry disabled" sh -c "jq -e '.env.DISABLE_TELEMETRY == \"1\"' '$SETTINGS_FILE' >/dev/null 2>&1"
check "error reporting disabled" sh -c "jq -e '.env.DISABLE_ERROR_REPORTING == \"1\"' '$SETTINGS_FILE' >/dev/null 2>&1"
check "feedback command disabled" sh -c "jq -e '.env.DISABLE_FEEDBACK_COMMAND == \"1\"' '$SETTINGS_FILE' >/dev/null 2>&1"
check "updates disabled" sh -c "jq -e '.env.DISABLE_UPDATES == \"1\"' '$SETTINGS_FILE' >/dev/null 2>&1"

reportResults
