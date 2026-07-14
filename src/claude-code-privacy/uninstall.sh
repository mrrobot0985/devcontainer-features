#!/bin/sh
set -e

echo "Uninstalling feature 'claude-code-privacy'"

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is not available, skipping privacy settings cleanup"
    exit 0
fi

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

if [ -f "$SETTINGS_FILE" ]; then
    if ! jq -e . "$SETTINGS_FILE" >/dev/null 2>&1; then
        echo "WARN: $SETTINGS_FILE is not valid JSON, skipping"
    else
        jq '
            (.env // {}) as $env |
            ($env | keys | map(select(
                . == "DISABLE_TELEMETRY" or
                . == "DISABLE_ERROR_REPORTING" or
                . == "DISABLE_FEEDBACK_COMMAND" or
                . == "DISABLE_UPDATES"
            ))) as $to_delete |
            reduce $to_delete[] as $k (.; del(.env[$k])) |
            if .env == {} then del(.env) else . end
        ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
        echo "Removed privacy environment variables from $SETTINGS_FILE"
    fi
else
    echo "No settings file found at $SETTINGS_FILE"
fi

if [ -d "$CLAUDE_DIR" ]; then
    chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"
fi

echo "Claude Code privacy uninstalled"
