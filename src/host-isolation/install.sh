#!/bin/bash
set -e

# host-isolation install script
# Installs a validation script that audits devcontainer.json

FAIL_ON_WARNING="__FAILONWARNING__"

cat > /usr/local/bin/host-isolation-check <<'EOF'
#!/bin/bash
set -e

# host-isolation-check — audit devcontainer.json for unsafe configurations
# Run during postCreateCommand to validate the active configuration.

DEVCONTAINER_JSON="${DEVCONTAINER_JSON:-/workspaces/.devcontainer/devcontainer.json}"
WARNINGS=0

warn() {
    echo "WARNING [host-isolation]: $1"
    WARNINGS=$((WARNINGS + 1))
}

if [ ! -f "$DEVCONTAINER_JSON" ]; then
    echo "INFO [host-isolation]: No devcontainer.json found at $DEVCONTAINER_JSON; skipping audit."
    exit 0
fi

# Parse with jq if available; otherwise use grep heuristics
if command -v jq >/dev/null 2>&1; then
    # Check for privileged mode
    if jq -e '.runArgs | contains(["--privileged"])' "$DEVCONTAINER_JSON" >/dev/null 2>&1; then
        warn "Container runs with --privileged. Host isolation is bypassed."
    fi

    # Check for Docker socket mount
    if jq -e '.mounts // [] | .[] | select(.source | contains("docker.sock"))' "$DEVCONTAINER_JSON" >/dev/null 2>&1; then
        warn "Docker socket is mounted into the container. This allows container escape."
    fi

    # Check for excessive capabilities
    CAPS=$(jq -r '(.capAdd // []) | join(",")' "$DEVCONTAINER_JSON" 2>/dev/null || true)
    if echo "$CAPS" | grep -qE "SYS_ADMIN|NET_ADMIN|ALL"; then
        warn "Dangerous capabilities detected: $CAPS"
    fi
else
    # Fallback grep checks
    if grep -q '"--privileged"' "$DEVCONTAINER_JSON"; then
        warn "Container runs with --privileged. Host isolation is bypassed."
    fi
    if grep -q 'docker.sock' "$DEVCONTAINER_JSON"; then
        warn "Docker socket is mounted into the container. This allows container escape."
    fi
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo "WARNING [host-isolation]: $WARNINGS unsafe configuration(s) detected."
    if [ "${FAIL_ON_WARNING:-false}" = "true" ]; then
        echo "ERROR [host-isolation]: failOnWarning is enabled; aborting container creation."
        exit 1
    fi
else
    echo "INFO [host-isolation]: No unsafe configurations detected."
fi

exit 0
EOF

chmod +x /usr/local/bin/host-isolation-check

echo "host-isolation installed. Run 'host-isolation-check' to audit devcontainer.json."
