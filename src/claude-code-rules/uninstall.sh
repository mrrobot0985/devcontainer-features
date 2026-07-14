#!/bin/sh
set -e

echo "Uninstalling feature 'claude-code-rules'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
RULES_DIR="${CLAUDE_DIR}/rules"

if [ -d "$RULES_DIR" ]; then
    rm -rf "$RULES_DIR"
    echo "Deleted ${RULES_DIR}"
else
    echo "No rules directory found at ${RULES_DIR}"
fi

if [ -d "$CLAUDE_DIR" ]; then
    chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"
fi

echo "Claude Code rules uninstalled"
