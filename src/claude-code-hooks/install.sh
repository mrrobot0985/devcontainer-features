#!/bin/sh
set -e

echo "Activating feature 'claude-code-hooks'"

INSTALL_SESSION="${INSTALLSESSIONHOOKS:-true}"
INSTALL_AGENT="${INSTALLAGENTHOOKS:-true}"
INSTALL_TURN="${INSTALLTURNHOOKS:-true}"
INSTALL_STATUSLINE="${INSTALLSTATUSLINE:-true}"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

FEATURE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing hooks from ${FEATURE_DIR}/hooks to ${HOOKS_DIR}..."

mkdir -p "$HOOKS_DIR"

# Always install shared libraries and config
for dir in lib config; do
    if [ -d "${FEATURE_DIR}/hooks/${dir}" ]; then
        cp -r "${FEATURE_DIR}/hooks/${dir}" "${HOOKS_DIR}/"
    fi
done

# Conditionally install hook categories
if [ "$INSTALL_SESSION" = "true" ]; then
    echo "Installing session hooks..."
    cp -r "${FEATURE_DIR}/hooks/session" "${HOOKS_DIR}/"
fi

if [ "$INSTALL_AGENT" = "true" ]; then
    echo "Installing agent hooks..."
    cp -r "${FEATURE_DIR}/hooks/agent" "${HOOKS_DIR}/"
fi

if [ "$INSTALL_TURN" = "true" ]; then
    echo "Installing turn hooks..."
    cp -r "${FEATURE_DIR}/hooks/turn" "${HOOKS_DIR}/"
fi

# Ensure scripts are executable
find "$HOOKS_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Ensure jq is available for JSON manipulation.
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

# Source shared settings merge helper.
# shellcheck disable=SC1091
. "${FEATURE_DIR}/hooks/lib/merge-settings.sh"

# Conditionally merge session hooks configuration
if [ "$INSTALL_SESSION" = "true" ] && [ -f "${HOOKS_DIR}/config/settings.session.json" ]; then
    echo "Merging session hooks configuration into ${SETTINGS_FILE}..."
    merge_settings_json "${SETTINGS_FILE}" "${HOOKS_DIR}/config/settings.session.json"
fi

# Conditionally merge agent hooks configuration
if [ "$INSTALL_AGENT" = "true" ] && [ -f "${HOOKS_DIR}/config/settings.agent.json" ]; then
    echo "Merging agent hooks configuration into ${SETTINGS_FILE}..."
    merge_settings_json "${SETTINGS_FILE}" "${HOOKS_DIR}/config/settings.agent.json"
fi

# Conditionally merge turn hooks configuration
if [ "$INSTALL_TURN" = "true" ] && [ -f "${HOOKS_DIR}/config/settings.turn.json" ]; then
    echo "Merging turn hooks configuration into ${SETTINGS_FILE}..."
    merge_settings_json "${SETTINGS_FILE}" "${HOOKS_DIR}/config/settings.turn.json"
fi

# Optionally merge status line config
if [ "$INSTALL_STATUSLINE" = "true" ] && [ -f "${HOOKS_DIR}/config/settings.statusline.json" ]; then
    echo "Merging status line configuration into ${SETTINGS_FILE}..."
    merge_settings_json "${SETTINGS_FILE}" "${HOOKS_DIR}/config/settings.statusline.json"
fi

# Fix ownership
chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

echo "Claude Code hooks installed to ${HOOKS_DIR}"
echo "Configuration written to ${SETTINGS_FILE}"
