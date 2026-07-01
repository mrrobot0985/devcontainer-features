#!/bin/sh
set -e

echo "Activating feature 'claude-code-skills'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills"

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

echo "Cloning ${REPO_URL}..."
git clone --depth 1 "$REPO_URL" "$TEMP_DIR/skills"

# Ensure the destination directory exists
mkdir -p "$SKILLS_DIR"

# Copy skill directories from stable categories
for category in engineering productivity misc personal; do
    src_dir="$TEMP_DIR/skills/skills/$category"
    if [ -d "$src_dir" ]; then
        for skill in "$src_dir"/*; do
            if [ -d "$skill" ]; then
                skill_name="$(basename "$skill")"
                # Skip README files and other non-directory entries
                if [ "$skill_name" = "README.md" ]; then
                    continue
                fi
                dest="$SKILLS_DIR/$skill_name"

                # Remove existing directory to avoid conflicts
                if [ -d "$dest" ]; then
                    echo "Replacing existing $dest..."
                    rm -rf "$dest"
                fi

                cp -r "$skill" "$dest"
                echo "Skill copied: $skill_name"
            fi
        done
    else
        echo "WARN: category directory $src_dir not found"
    fi
done

# Clean up the temporary clone
rm -rf "$TEMP_DIR"

# Fix ownership
chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

echo "Claude Code skills installed to ${SKILLS_DIR}"
