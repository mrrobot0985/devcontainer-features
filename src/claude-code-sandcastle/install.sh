#!/bin/sh
set -e

echo "Activating feature 'claude-code-sandcastle'"

USER_HOME="${_REMOTE_USER_HOME:-$HOME}"
DEVCONTAINER_DIR="${USER_HOME}/.devcontainer"
SANDCASTLE_DIR="${DEVCONTAINER_DIR}/sandcastle"

ENABLE_AUTO_MODE="${ENABLEAUTOMODE:-false}"
MAX_ITERATIONS="${MAXITERATIONS:-10}"
DEGRADED_PROTOTYPE="${DEGRADEDPROTOTYPE:-false}"

# Create sandcastle directory
mkdir -p "$SANDCASTLE_DIR"
mkdir -p "${SANDCASTLE_DIR}/.ralph/logs"

# Copy scripts from feature source to sandcastle directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for script in bootstrap.sh ralph-loop.sh validate-branch.sh runner.mjs; do
    src="${SCRIPT_DIR}/${script}"
    if [ -f "$src" ]; then
        cp "$src" "${SANDCASTLE_DIR}/${script}"
        chmod +x "${SANDCASTLE_DIR}/${script}"
        echo "Installed ${script}"
    else
        echo "WARN: ${script} not found at ${src}"
    fi
done

# Write default state.json if it doesn't exist
if [ ! -f "${SANDCASTLE_DIR}/.ralph/state.json" ]; then
    cat > "${SANDCASTLE_DIR}/.ralph/state.json" << EOF
{
  "phase": "discover",
  "iteration": 0,
  "maxIterations": ${MAX_ITERATIONS},
  "lastRun": null,
  "currentEffort": null,
  "resolvedTickets": [],
  "failedTickets": [],
  "degradedPrototype": ${DEGRADED_PROTOTYPE}
}
EOF
fi

# Fix ownership
chown -R "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$SANDCASTLE_DIR"

echo "Claude Code Sandcastle installed to ${SANDCASTLE_DIR}"
echo "  autoMode: ${ENABLE_AUTO_MODE}"
echo "  maxIterations: ${MAX_ITERATIONS}"
echo "  degradedPrototype: ${DEGRADED_PROTOTYPE}"
