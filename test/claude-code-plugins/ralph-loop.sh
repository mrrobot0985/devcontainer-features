#!/bin/bash
set -e

source dev-container-features-test-lib

CLAUDE_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

check "claude directory exists" test -d "$CLAUDE_DIR"
check "settings.json exists" test -f "$SETTINGS_FILE"

# When plugins are requested, verify they are recorded in settings.
# Actual installation requires network and may be skipped with skipOnFailure.
if [ -n "${ENABLERALPHLOOP:-}" ] && [ "$ENABLERALPHLOOP" = "true" ]; then
    check "ralph-loop enabled in settings" bash -c "jq -e '.enabledPlugins | has(\"ralph-loop@claude-plugins-official\")' '$SETTINGS_FILE' >/dev/null" || true
fi

if [ -n "${ENABLEOBRASUPERPOWERS:-}" ] && [ "$ENABLEOBRASUPERPOWERS" = "true" ]; then
    check "superpowers enabled in settings" bash -c "jq -e '.enabledPlugins | has(\"superpowers@claude-plugins-official\")' '$SETTINGS_FILE' >/dev/null" || true
fi

if [ -n "${ENABLEWORKFLOWS:-}" ] && [ "$ENABLEWORKFLOWS" = "true" ]; then
    check "workflows enabled in settings" bash -c "jq -e '.enabledPlugins | has(\"dev-workflows@claude-code-workflows\")' '$SETTINGS_FILE' >/dev/null" || true
fi

if [ -n "${ENABLEEVERYTHINGCLAUDECODE:-}" ] && [ "$ENABLEEVERYTHINGCLAUDECODE" = "true" ]; then
    check "everything-claude-code enabled in settings" bash -c "jq -e '.enabledPlugins | has(\"everything-claude-code@everything-claude-code\")' '$SETTINGS_FILE' >/dev/null" || true
fi

if [ -n "${CUSTOMPLUGINS:-}" ]; then
    for spec in $(echo "$CUSTOMPLUGINS" | tr ',' ' '); do
        [ -z "$spec" ] && continue
        check "custom plugin ${spec} enabled in settings" bash -c "jq -e '.enabledPlugins | has(\"$spec\")' '$SETTINGS_FILE' >/dev/null" || true
    done
fi

reportResults
