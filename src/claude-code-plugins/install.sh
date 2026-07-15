#!/bin/sh
set -e

echo "Activating feature 'claude-code-plugins'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
CLAUDE_DIR="${USER_HOME}/.claude"

# Read options (uppercase env vars, matching JSON camelCase names)
ENABLE_RALPH_LOOP="${ENABLERALPHLOOP:-false}"
ENABLE_OBRA_SUPERPOWERS="${ENABLEOBRASUPERPOWERS:-false}"
ENABLE_WORKFLOWS="${ENABLEWORKFLOWS:-false}"
ENABLE_EVERYTHING_CLAUDE_CODE="${ENABLEEVERYTHINGCLAUDECODE:-false}"
CUSTOM_PLUGINS="${CUSTOMPLUGINS:-}"
CUSTOM_MARKETPLACES="${CUSTOMMARKETPLACES:-}"
SKIP_ON_FAILURE="${SKIPONFAILURE:-false}"

mkdir -p "$CLAUDE_DIR"

# Ensure git is available so the CLI can clone marketplace repositories.
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

# Ensure jq is available for JSON manipulation (tests and CLI operations).
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

# The claude-code feature must run before this one.
if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: claude CLI not found. Ensure ghcr.io/anthropics/devcontainer-features/claude-code is installed before this feature."
    exit 1
fi

# Point the CLI at the remote user's config directory during this build.
export HOME="$USER_HOME"
export CLAUDE_CONFIG_DIR="$CLAUDE_DIR"

# Some Claude Code commands expect an API key to be present even when not
# strictly required (e.g. for public marketplace operations). Set a dummy
# key if none is configured to avoid interactive prompts.
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    export ANTHROPIC_API_KEY="sk-dummy-placeholder"
fi

_add_marketplace() {
    _mp="$1"
    echo "Adding marketplace ${_mp}..."
    if ! claude plugin marketplace add "$_mp"; then
        if [ "$SKIP_ON_FAILURE" = "true" ]; then
            echo "WARNING: Failed to add marketplace ${_mp}; continuing because skipOnFailure=true"
            return 0
        fi
        echo "ERROR: Failed to add marketplace ${_mp}"
        return 1
    fi
}

_install_plugin() {
    _spec="$1"
    echo "Installing plugin ${_spec}..."
    if ! claude plugin install "$_spec" --scope user; then
        if [ "$SKIP_ON_FAILURE" = "true" ]; then
            echo "WARNING: Failed to install plugin ${_spec}; continuing because skipOnFailure=true"
            return 0
        fi
        echo "ERROR: Failed to install plugin ${_spec}"
        return 1
    fi
}

# Register marketplaces required by curated plugins.
if [ "$ENABLE_WORKFLOWS" = "true" ]; then
    _add_marketplace "shinpr/claude-code-workflows"
fi

if [ "$ENABLE_EVERYTHING_CLAUDE_CODE" = "true" ]; then
    _add_marketplace "affaan-m/everything-claude-code"
fi

# Register custom marketplaces.
OLD_IFS="$IFS"
IFS=','
set -f
for mp in $CUSTOM_MARKETPLACES; do
    [ -z "$mp" ] && continue
    _add_marketplace "$mp"
done
set +f
IFS="$OLD_IFS"

# Install curated plugins.
if [ "$ENABLE_RALPH_LOOP" = "true" ]; then
    _install_plugin "ralph-loop@claude-plugins-official"
fi

if [ "$ENABLE_OBRA_SUPERPOWERS" = "true" ]; then
    _install_plugin "superpowers@claude-plugins-official"
fi

if [ "$ENABLE_WORKFLOWS" = "true" ]; then
    _install_plugin "dev-workflows@claude-code-workflows"
fi

if [ "$ENABLE_EVERYTHING_CLAUDE_CODE" = "true" ]; then
    _install_plugin "everything-claude-code@everything-claude-code"
fi

# Install custom plugins.
IFS=','
set -f
for spec in $CUSTOM_PLUGINS; do
    [ -z "$spec" ] && continue
    _install_plugin "$spec"
done
set +f
IFS="$OLD_IFS"

# Fix ownership so the remote user can read/write the config.
chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$CLAUDE_DIR"

echo "Claude Code plugins feature activated"
