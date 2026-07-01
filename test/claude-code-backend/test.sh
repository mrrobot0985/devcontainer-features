#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"

check "settings.json exists" test -f "$SETTINGS_FILE"
check "baseUrl set" bash -c "jq -e '.env.ANTHROPIC_BASE_URL == \"http://host.docker.internal:11434\"' \"$SETTINGS_FILE\" >/dev/null"
check "authToken set" bash -c "jq -e '.env.ANTHROPIC_AUTH_TOKEN == \"ollama\"' \"$SETTINGS_FILE\" >/dev/null"
check "logLevel set" bash -c "jq -e '.env.ANTHROPIC_LOG == \"error\"' \"$SETTINGS_FILE\" >/dev/null"
check "api key cleared" bash -c "jq -e '.env.ANTHROPIC_API_KEY == \"\"' \"$SETTINGS_FILE\" >/dev/null"

reportResults
