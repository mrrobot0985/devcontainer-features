#!/bin/sh
set -e

echo "Activating feature 'claude-code-privacy'"

# Ensure jq is available; fail loudly if it cannot be installed.
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
HELPER_FILE="$(dirname "$0")/merge-settings.sh"
# shellcheck source=merge-settings.sh
# shellcheck disable=SC1091
. "$HELPER_FILE"

# Convert a boolean option string to a Claude Code flag value.
bool_to_flag() {
    if [ "$1" = "true" ]; then
        echo "1"
    else
        echo "0"
    fi
}

DISABLE_TELEMETRY="$(bool_to_flag "${DISABLETELEMETRY:-true}")"
DISABLE_ERROR_REPORTING="$(bool_to_flag "${DISABLEERRORREPORTING:-true}")"
DISABLE_FEEDBACK_COMMAND="$(bool_to_flag "${DISABLEFEEDBACK:-true}")"
DISABLE_UPDATES="$(bool_to_flag "${DISABLEUPDATES:-true}")"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

mkdir -p "$CLAUDE_DIR"

ENV_JSON=$(jq -n \
    --arg dt "$DISABLE_TELEMETRY" \
    --arg der "$DISABLE_ERROR_REPORTING" \
    --arg dfc "$DISABLE_FEEDBACK_COMMAND" \
    --arg du "$DISABLE_UPDATES" \
    '{
        "DISABLE_TELEMETRY": $dt,
        "DISABLE_ERROR_REPORTING": $der,
        "DISABLE_FEEDBACK_COMMAND": $dfc,
        "DISABLE_UPDATES": $du
    }')

# Merge privacy flags into settings.json (new values take precedence).
merge_settings_json "$SETTINGS_FILE" "$ENV_JSON" "env"

chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

echo "Claude Code privacy settings configured in $SETTINGS_FILE"
