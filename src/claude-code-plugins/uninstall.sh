#!/bin/sh
set -e

echo "Uninstalling feature 'claude-code-plugins'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"

# Attempt to uninstall curated plugins if the claude CLI is still available.
if command -v claude >/dev/null 2>&1; then
    export HOME="$USER_HOME"
    export CLAUDE_CONFIG_DIR="$CLAUDE_DIR"

    for plugin in "ralph-loop" "superpowers" "dev-workflows" "everything-claude-code"; do
        if claude plugin list 2>/dev/null | grep -q "$plugin"; then
            echo "Uninstalling plugin ${plugin}..."
            claude plugin uninstall "$plugin" --scope user >/dev/null 2>&1 || true
        fi
    done
else
    echo "claude CLI not available; plugin uninstallation skipped"
fi

if [ -d "$CLAUDE_DIR" ]; then
    chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"
fi

echo "Claude Code plugins feature uninstalled"
