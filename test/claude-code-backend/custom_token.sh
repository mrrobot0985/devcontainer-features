#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"
BASHRC_FILE="${_REMOTE_USER_HOME:-$HOME}/.bashrc"

check "settings.json exists" test -f "$SETTINGS_FILE"
check "authToken set" bash -c "jq -e '.env.ANTHROPIC_AUTH_TOKEN == \"my-litellm-key\"' \"$SETTINGS_FILE\" >/dev/null"
check "logLevel set" bash -c "jq -e '.env.ANTHROPIC_LOG == \"error\"' \"$SETTINGS_FILE\" >/dev/null"
check "api key cleared" bash -c "jq -e '.env.ANTHROPIC_API_KEY == \"\"' \"$SETTINGS_FILE\" >/dev/null"
check "baseUrl absent when empty and non-ollama" bash -c "! jq -e '.env.ANTHROPIC_BASE_URL' \"$SETTINGS_FILE\" >/dev/null"
check "no ollama healthcheck in .bashrc" bash -c "! grep -q 'claude-code-backend: ollama healthcheck' \"$BASHRC_FILE\""

reportResults
