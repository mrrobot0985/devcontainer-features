#!/bin/sh
set -e

echo "Activating feature 'claude-code-backend'"

BASE_URL="${BASEURL:-}"
AUTH_TOKEN="${AUTHTOKEN:-ollama}"
MODELS="${MODELS:-}"
LOG_LEVEL="${LOGLEVEL:-error}"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

mkdir -p "$CLAUDE_DIR"

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
HELPER_FILE="$(dirname "$0")/merge-settings.sh"
# shellcheck source=merge-settings.sh
# shellcheck disable=SC1091
. "$HELPER_FILE"

# When baseUrl is empty and authToken is ollama, default to the Docker host gateway.
if [ -z "$BASE_URL" ] && [ "$AUTH_TOKEN" = "ollama" ]; then
    BASE_URL="http://host.docker.internal:11434"
fi

# Build the env object with base backend settings.
if [ -n "$BASE_URL" ]; then
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
else
    ENV_JSON=$(jq -n \
        --arg auth_token "$AUTH_TOKEN" \
        --arg log_level "$LOG_LEVEL" \
        '{
            "ANTHROPIC_API_KEY": "",
            "ANTHROPIC_AUTH_TOKEN": $auth_token,
            "ANTHROPIC_LOG": $log_level
        }')
fi

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

# Merge env vars into settings.json (new values take precedence).
merge_settings_json "$SETTINGS_FILE" "$ENV_JSON" "env"

chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

# If we auto-defaulted to the Docker host gateway, inject a runtime healthcheck
# into the user's shell rc files so they get a warning when the host is unreachable.
if [ "$BASE_URL" = "http://host.docker.internal:11434" ]; then
    HEALTHCHECK_MARK="# claude-code-backend: ollama healthcheck"
    for rc_file in "$USER_HOME/.bashrc" "$USER_HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q "$HEALTHCHECK_MARK" "$rc_file"; then
                {
                    echo ""
                    echo "$HEALTHCHECK_MARK"
                    echo "_ollama_healthcheck() {"
                    echo "    if ! curl -sf \"http://host.docker.internal:11434/api/tags\" >/dev/null 2>&1; then"
                    echo "        echo \"WARNING: Ollama does not appear to be reachable at http://host.docker.internal:11434\" >&2"
                    echo "        echo \"         Inside a dev container, localhost:11434 refers to the container, not the host.\" >&2"
                    echo "        echo \"         Ensure Ollama is running on the Docker host and accessible via host.docker.internal.\" >&2"
                    echo "    fi"
                    echo "}"
                    echo "_ollama_healthcheck"
                    echo "unset -f _ollama_healthcheck"
                } >> "$rc_file"
                chown "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$rc_file"
            fi
        fi
    done
fi

echo "Claude Code backend configured in $SETTINGS_FILE"
