#!/bin/sh
set -e

echo "Uninstalling feature 'claude-code-skills'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills"

if [ -d "$SKILLS_DIR" ]; then
    rm -rf "$SKILLS_DIR"
    echo "Deleted ${SKILLS_DIR}"
else
    echo "No skills directory found at ${SKILLS_DIR}"
fi

if [ -d "$CLAUDE_DIR" ]; then
    chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"
fi

echo "Claude Code skills uninstalled"
