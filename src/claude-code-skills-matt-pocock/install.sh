#!/bin/sh
set -e

echo "Activating feature 'claude-code-skills-matt-pocock'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills"

INSTALL_ENGINEERING="${INSTALLENGINEERING:-true}"
INSTALL_PRODUCTIVITY="${INSTALLPRODUCTIVITY:-true}"
INSTALL_MISC="${INSTALLMISC:-false}"
INSTALL_PERSONAL="${INSTALLPERSONAL:-false}"

# Ensure git is available
if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y --no-install-recommends git
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache git
    elif command -v yum >/dev/null 2>&1; then
        yum install -y git
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y git
    else
        echo "ERROR: git is required but could not be installed"
        exit 1
    fi
fi

# Temporary clone location
TEMP_DIR="$(mktemp -d)"
REPO_URL="https://github.com/mattpocock/skills.git"

echo "Cloning ${REPO_URL} at v1.1.0..."
git clone --branch v1.1.0 --depth 1 "$REPO_URL" "$TEMP_DIR/skills"

# Ensure the destination directory exists
mkdir -p "$SKILLS_DIR"

# Helper to copy a category if enabled
copy_category() {
    local category="$1"
    local enabled="$2"
    local src_dir="$TEMP_DIR/skills/skills/$category"

    if [ "$enabled" != "true" ]; then
        echo "Skipping ${category} (disabled)"
        return 0
    fi

    if [ ! -d "$src_dir" ]; then
        echo "WARN: category directory ${src_dir} not found"
        return 0
    fi

    for skill in "$src_dir"/*; do
        if [ -d "$skill" ]; then
            skill_name="$(basename "$skill")"
            if [ "$skill_name" = "README.md" ]; then
                continue
            fi
            dest="$SKILLS_DIR/$skill_name"

            if [ -d "$dest" ]; then
                echo "Replacing existing ${skill_name}..."
                rm -rf "$dest"
            fi

            cp -r "$skill" "$dest"
            echo "Skill copied: ${skill_name}"
        fi
    done
}

# Copy enabled categories
copy_category "engineering" "$INSTALL_ENGINEERING"
copy_category "productivity" "$INSTALL_PRODUCTIVITY"
copy_category "misc" "$INSTALL_MISC"
copy_category "personal" "$INSTALL_PERSONAL"

# Clean up the temporary clone
rm -rf "$TEMP_DIR"

# Fix ownership
chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

echo "Claude Code skills installed to ${SKILLS_DIR}"
