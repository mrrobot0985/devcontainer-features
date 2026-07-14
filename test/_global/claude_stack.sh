#!/bin/bash
set -e

# shellcheck source=/dev/null
source dev-container-features-test-lib

SETTINGS_JSON="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"

check "settings.json exists" test -f "$SETTINGS_JSON"
check "settings.json contains ANTHROPIC_BASE_URL" grep -q '"ANTHROPIC_BASE_URL"' "$SETTINGS_JSON"
check "settings.json contains DISABLE_TELEMETRY" grep -q '"DISABLE_TELEMETRY"' "$SETTINGS_JSON"
check "settings.json contains hooks" grep -q '"hooks"' "$SETTINGS_JSON"
check "container-firewall init script exists" test -x /usr/local/bin/container-firewall-init

reportResults
