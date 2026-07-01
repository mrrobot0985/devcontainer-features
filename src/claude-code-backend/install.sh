#!/bin/sh
set -e

echo "Activating feature 'claude-code-backend'"

BASE_URL="${BASEURL:-http://host.docker.internal:11434}"
AUTH_TOKEN="${AUTHTOKEN:-ollama}"
MODELS="${MODELS:-}"
LOG_LEVEL="${LOGLEVEL:-error}"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

mkdir -p "$CLAUDE_DIR"

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

# Build the env object with base backend settings
ENV_JSON=$(jq -n \
    --arg base_url "$BASE_URL" \
    --arg auth_token "$AUTH_TOKEN" \
    --arg log_level "$LOG_LEVEL" \
    '{
        "ANTHROPIC_API_KEY": "",
        "ANTHROPIC_AUTH_TOKEN": $auth_token,
        "ANTHROPIC_BASE_URL": $base_url,
        "ANTHROPIC_LOG": $log_level
    }')

# Parse optional comma-separated model overrides.
# Expected format: key:value,key:value
# "subagent" maps to CLAUDE_CODE_SUBAGENT_MODEL; all other keys map to
# ANTHROPIC_DEFAULT_<KEY>_MODEL.
if [ -n "$MODELS" ]; then
    OLD_IFS="$IFS"
    IFS=','
    set -f
    for pair in $MODELS; do
        key="${pair%%:*}"
        value="${pair#*:}"
        if [ -z "$key" ] || [ "$key" = "$pair" ]; then
            echo "ERROR: invalid model entry '$pair'. Expected key:value"
            exit 1
        fi
        upper_key=$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')
        if [ "$upper_key" = "SUBAGENT" ]; then
            var_name="CLAUDE_CODE_SUBAGENT_MODEL"
        else
            var_name="ANTHROPIC_DEFAULT_${upper_key}_MODEL"
        fi
        ENV_JSON=$(printf '%s' "$ENV_JSON" | jq \
            --arg k "$var_name" \
            --arg v "$value" \
            '. + {($k): $v}')
    done
    set +f
    IFS="$OLD_IFS"
fi

# Load existing settings or start fresh
if [ -f "$SETTINGS_FILE" ]; then
    SETTINGS=$(jq '.' "$SETTINGS_FILE" || echo '{}')
else
    SETTINGS='{}'
fi

# Merge env vars (new values take precedence)
UPDATED=$(printf '%s' "$SETTINGS" | jq --argjson env "$ENV_JSON" '.env = ((.env // {}) + $env)')

# Write settings back atomically
printf '%s\n' "$UPDATED" | jq . > "$SETTINGS_FILE"

chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

echo "Claude Code backend configured in $SETTINGS_FILE"
