#!/bin/sh
set -e

echo "Uninstalling feature 'claude-code-hooks'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is not available, skipping hooks settings cleanup"
else
    if [ -f "$SETTINGS_FILE" ]; then
        if ! jq -e . "$SETTINGS_FILE" >/dev/null 2>&1; then
            echo "WARN: $SETTINGS_FILE is not valid JSON, skipping"
        else
            jq 'del(.hooks)' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
            echo "Removed hooks configuration from $SETTINGS_FILE"
        fi
    else
        echo "No settings file found at $SETTINGS_FILE"
    fi
fi

if [ -d "$HOOKS_DIR" ]; then
    rm -rf "$HOOKS_DIR"
    echo "Deleted ${HOOKS_DIR}"
else
    echo "No hooks directory found at ${HOOKS_DIR}"
fi

if [ -d "$CLAUDE_DIR" ]; then
    chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"
fi

echo "Claude Code hooks uninstalled"
