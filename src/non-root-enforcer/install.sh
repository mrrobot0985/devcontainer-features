#!/bin/bash
set -e

# non-root-enforcer install script
# Installs a validation script that audits remoteUser in devcontainer.json

cat > /usr/local/bin/non-root-enforcer <<'EOF'
#!/bin/bash
set -e

# non-root-enforcer — audit devcontainer.json for root remoteUser
# Claude Code and other AI agents reject --dangerously-skip-permissions when run as root.

DEVCONTAINER_JSON="${DEVCONTAINER_CONFIG:-/workspace/.devcontainer/devcontainer.json}"
WARNINGS=0

warn() {
    echo "WARNING [non-root-enforcer]: $1"
    WARNINGS=$((WARNINGS + 1))
}

if [ ! -f "$DEVCONTAINER_JSON" ]; then
    echo "INFO [non-root-enforcer]: No devcontainer.json found; skipping audit."
    exit 0
fi

# Parse with jq if available
if command -v jq >/dev/null 2>&1; then
    remote_user=$(jq -r '.remoteUser // empty' "$DEVCONTAINER_JSON" 2>/dev/null || true)
    if [ -z "$remote_user" ]; then
        warn "remoteUser is not set. Claude Code requires a non-root user."
    elif [ "$remote_user" = "root" ]; then
        warn "remoteUser is set to 'root'. Claude Code and many AI agents require a non-root user."
    fi
else
    # Fallback grep
    if grep -q '"remoteUser"' "$DEVCONTAINER_JSON"; then
        if grep -A 1 '"remoteUser"' "$DEVCONTAINER_JSON" | grep -q 'root'; then
            warn "remoteUser appears to be 'root'. Claude Code requires a non-root user."
        fi
    else
        warn "remoteUser is not set. Claude Code requires a non-root user."
    fi
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo "WARNING [non-root-enforcer]: $WARNINGS non-root configuration issue(s) detected."
    if [ "${FAIL_ON_WARNING:-false}" = "true" ]; then
        echo "ERROR [non-root-enforcer]: failOnWarning is enabled; aborting container creation."
        exit 1
    fi
else
    echo "INFO [non-root-enforcer]: remoteUser is correctly set to a non-root user."
fi

exit 0
EOF

chmod +x /usr/local/bin/non-root-enforcer

echo "non-root-enforcer installed. Run 'non-root-enforcer' to audit remoteUser."
