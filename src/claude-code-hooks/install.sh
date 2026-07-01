#!/bin/sh
set -e

echo "Activating feature 'claude-code-hooks'"

INSTALL_STATUSLINE="${INSTALLSTATUSLINE:-true}"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

FEATURE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing hooks from ${FEATURE_DIR}/hooks to ${HOOKS_DIR}..."

mkdir -p "$HOOKS_DIR"

# Copy all hook scripts preserving directory structure
for dir in agent session turn lib config; do
    if [ -d "${FEATURE_DIR}/hooks/${dir}" ]; then
        cp -r "${FEATURE_DIR}/hooks/${dir}" "${HOOKS_DIR}/"
    fi
done

# Ensure scripts are executable
find "$HOOKS_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Ensure jq is available for JSON manipulation
if ! command -v jq >/dev/null 2>&1; then
    echo "Installing jq..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y --no-install-recommends jq
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache jq
    elif command -v yum >/dev/null 2>&1; then
        yum install -y jq
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y jq
    else
        echo "ERROR: jq is required but could not be installed"
        exit 1
    fi
fi

# Merge JSON config into settings.json
merge_config() {
    _config_file="$1"
    _settings_file="$2"

    _tmp="$(mktemp)"
    jq 'del(.["$schema"])' "$_config_file" > "$_tmp"

    if [ -f "$_settings_file" ]; then
        if ! jq -e . "$_settings_file" >/dev/null 2>&1; then
            echo "ERROR: existing $_settings_file is not valid JSON"
            rm -f "$_tmp"
            exit 1
        fi
        jq -s '.[0] * .[1]' "$_settings_file" "$_tmp" > "${_settings_file}.tmp" && mv "${_settings_file}.tmp" "$_settings_file"
    else
        jq '.' "$_tmp" > "$_settings_file"
    fi

    rm -f "$_tmp"
}

# Merge settings.hooks.json into settings.json
if [ -f "${HOOKS_DIR}/config/settings.hooks.json" ]; then
    echo "Merging hooks configuration into ${SETTINGS_FILE}..."
    merge_config "${HOOKS_DIR}/config/settings.hooks.json" "${SETTINGS_FILE}"
fi

# Optionally merge status line config
if [ "$INSTALL_STATUSLINE" = "true" ] && [ -f "${HOOKS_DIR}/config/settings.statusline.json" ]; then
    echo "Merging status line configuration into ${SETTINGS_FILE}..."
    merge_config "${HOOKS_DIR}/config/settings.statusline.json" "${SETTINGS_FILE}"
fi

# Fix ownership
chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

echo "Claude Code hooks installed to ${HOOKS_DIR}"
echo "Configuration written to ${SETTINGS_FILE}"
