#!/bin/sh
set -e

echo "Activating feature 'claude-code-rules'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
RULES_DIR="${CLAUDE_DIR}/rules"
FEATURE_DIR="$(dirname "$0")"

ENFORCE_SAFETY="${ENFORCESAFETY:-true}"
STANDARDIZE_WORKFLOW="${STANDARDIZEWORKFLOW:-true}"
PROTECT_GIT="${PROTECTGIT:-true}"
PREFER_PYTHON_TOOLING="${PREFERPYTHONTOOLING:-false}"

# Ensure the destination directory exists
mkdir -p "$RULES_DIR"

# Helper to copy all rules from a group directory if enabled
copy_group() {
    local group_dir="$1"
    local group_name="$2"
    local enabled="$3"

    if [ "$enabled" != "true" ]; then
        return 0
    fi

    if [ ! -d "$group_dir" ]; then
        echo "WARN: group directory not found: $group_dir"
        return 0
    fi

    for file in "$group_dir"/*.md; do
        if [ -f "$file" ]; then
            cp "$file" "$RULES_DIR/"
            echo "Installed ($group_name): $(basename "$file")"
        fi
    done
}

# Copy rules by group
copy_group "$FEATURE_DIR/rules/safety" "safety" "$ENFORCE_SAFETY"
copy_group "$FEATURE_DIR/rules/workflow" "workflow" "$STANDARDIZE_WORKFLOW"
copy_group "$FEATURE_DIR/rules/git" "git" "$PROTECT_GIT"
copy_group "$FEATURE_DIR/rules/python" "python" "$PREFER_PYTHON_TOOLING"

# Fix ownership
chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

echo "Claude Code rules installed to ${RULES_DIR}"
