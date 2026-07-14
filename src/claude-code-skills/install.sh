#!/bin/sh
set -e

echo "Activating feature 'claude-code-skills'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
SKILLS_DIR="${CLAUDE_DIR}/skills"

ENABLE_MATT_POCOCK_SKILLS="${ENABLEMATTPOCOCKSKILLS:-true}"
MATT_POCOCK_SKILLS_VERSION="${MATTPOCOCKSKILLSVERSION:-v1.1}"
INSTALL_ENGINEERING="${INSTALLENGINEERING:-true}"
INSTALL_PRODUCTIVITY="${INSTALLPRODUCTIVITY:-true}"
INSTALL_MISC="${INSTALLMISC:-false}"
INSTALL_PERSONAL="${INSTALLPERSONAL:-false}"
SKIP_ON_FAILURE="${SKIPONFAILURE:-false}"

# Ensure the destination directory exists
mkdir -p "$SKILLS_DIR"

if [ "$ENABLE_MATT_POCOCK_SKILLS" != "true" ]; then
    echo "Matt Pocock skills disabled (enableMattPocockSkills=false), skipping clone"
    chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"
    echo "Claude Code skills directory ensured at ${SKILLS_DIR}"
    exit 0
fi

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

echo "Cloning ${REPO_URL} at ${MATT_POCOCK_SKILLS_VERSION}..."
if ! git clone --branch "$MATT_POCOCK_SKILLS_VERSION" --depth 1 "$REPO_URL" "$TEMP_DIR/skills"; then
    if [ "$SKIP_ON_FAILURE" = "true" ]; then
        echo "WARNING: Failed to clone skills repository. Skipping due to skipOnFailure=true."
        rm -rf "$TEMP_DIR"
        exit 0
    else
        echo "ERROR: Failed to clone skills repository"
        exit 1
    fi
fi

# Helper to copy a category if enabled
copy_category() {
    _category="$1"
    _enabled="$2"
    _src_dir="$TEMP_DIR/skills/skills/$_category"

    if [ "$_enabled" != "true" ]; then
        echo "Skipping ${_category} (disabled)"
        return 0
    fi

    if [ ! -d "$_src_dir" ]; then
        echo "WARN: category directory ${_src_dir} not found"
        return 0
    fi

    for _skill in "$_src_dir"/*; do
        if [ -d "$_skill" ]; then
            _skill_name="$(basename "$_skill")"
            if [ "$_skill_name" = "README.md" ]; then
                continue
            fi
            _dest="$SKILLS_DIR/$_skill_name"

            if [ -d "$_dest" ]; then
                echo "Replacing existing ${_skill_name}..."
                rm -rf "$_dest"
            fi

            cp -r "$_skill" "$_dest"
            echo "Skill copied: ${_skill_name}"
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
