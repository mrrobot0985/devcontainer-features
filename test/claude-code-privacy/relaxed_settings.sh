#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-/home/$(whoami)}/.claude/settings.json"

check "settings.json exists" test -f "$SETTINGS_FILE"
check "telemetry enabled" sh -c "jq -e '.env.DISABLE_TELEMETRY == \"0\"' '$SETTINGS_FILE' >/dev/null 2>&1"
check "error reporting enabled" sh -c "jq -e '.env.DISABLE_ERROR_REPORTING == \"0\"' '$SETTINGS_FILE' >/dev/null 2>&1"
check "feedback command still disabled" sh -c "jq -e '.env.DISABLE_FEEDBACK_COMMAND == \"1\"' '$SETTINGS_FILE' >/dev/null 2>&1"
check "updates still disabled" sh -c "jq -e '.env.DISABLE_UPDATES == \"1\"' '$SETTINGS_FILE' >/dev/null 2>&1"

reportResults
