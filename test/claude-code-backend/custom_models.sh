#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"

check "custom baseUrl set" bash -c "jq -e '.env.ANTHROPIC_BASE_URL == \"http://ollama:11434\"' \"$SETTINGS_FILE\" >/dev/null"
check "custom sonnet model set" bash -c "jq -e '.env.ANTHROPIC_DEFAULT_SONNET_MODEL == \"custom-sonnet:latest\"' \"$SETTINGS_FILE\" >/dev/null"
check "custom subagent model set" bash -c "jq -e '.env.CLAUDE_CODE_SUBAGENT_MODEL == \"custom-subagent:cloud\"' \"$SETTINGS_FILE\" >/dev/null"

reportResults
