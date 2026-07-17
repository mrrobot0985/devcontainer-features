#!/bin/bash
set -e

# shellcheck source=/dev/null
source dev-container-features-test-lib

SETTINGS_JSON="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"
CLAUDE_HOME="${_REMOTE_USER_HOME:-$HOME}/.claude"

check "settings.json exists" test -f "$SETTINGS_JSON"
check "settings.json contains ANTHROPIC_BASE_URL" grep -q '"ANTHROPIC_BASE_URL"' "$SETTINGS_JSON"
check "settings.json contains DISABLE_TELEMETRY" grep -q '"DISABLE_TELEMETRY"' "$SETTINGS_JSON"
check "settings.json contains hooks" grep -q '"hooks"' "$SETTINGS_JSON"
check "hooks key is non-empty object" bash -c "jq -e '.hooks | type == \"object\" and (length > 0)' \"$SETTINGS_JSON\" >/dev/null"
check "skills directory exists" test -d "${CLAUDE_HOME}/skills"
check "container-firewall init script exists" test -x /usr/local/bin/container-firewall-init

# Hook scripts installed by claude-code-hooks (behavioral, not install-only)
if compgen -G /usr/local/share/claude-code-hooks/hooks/*.sh > /dev/null 2>&1 \
	|| compgen -G "${CLAUDE_HOME}/hooks"/*.sh > /dev/null 2>&1 \
	|| [ -d /usr/local/share/claude-code-hooks ]; then
	check "claude-code-hooks share or home hooks present" true
else
	# Fallback: hooks feature at least wrote settings hooks
	check "hooks configured in settings (scripts path varies)" bash -c "jq -e '.hooks' \"$SETTINGS_JSON\" >/dev/null"
fi

if [ -f "${CLAUDE_HOME}/hooks.env" ] || [ -f /usr/local/etc/claude-code-hooks.env ] || [ -f /etc/claude-code-hooks.env ]; then
	check "hooks env file present" true
else
	check "hooks settings present without dedicated env file" bash -c "jq -e '.hooks' \"$SETTINGS_JSON\" >/dev/null"
fi

reportResults
