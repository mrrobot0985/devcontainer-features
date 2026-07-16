#!/bin/bash
set -e

# prebuild-lifecycle-helper install script
# Installs a validation script that audits lifecycle hook placement

cat > /usr/local/bin/prebuild-lifecycle-helper <<'EOF'
#!/bin/bash
set -e

# prebuild-lifecycle-helper — audit lifecycle commands for prebuild optimization
# Heavy operations should be in updateContentCommand (frozen in prebuild),
# not postCreateCommand or postStartCommand (run at connect time).

DEVCONTAINER_JSON="${DEVCONTAINER_CONFIG:-/workspace/.devcontainer/devcontainer.json}"
WARNINGS=0

warn() {
    echo "WARNING [prebuild-lifecycle-helper]: $1"
    WARNINGS=$((WARNINGS + 1))
}

if [ ! -f "$DEVCONTAINER_JSON" ]; then
    echo "INFO [prebuild-lifecycle-helper]: No devcontainer.json found; skipping audit."
    exit 0
fi

# Heavy operation patterns that should be in updateContentCommand
HEAVY_PATTERNS="npm install|pip install|apt-get|cargo build|mvn install|gradle build|git clone|curl.*install|yarn install|pnpm install|bundle install|go mod download|conda install|poetry install|uv sync"

# Parse with jq if available
if command -v jq >/dev/null 2>&1; then
    # Check postCreateCommand for heavy operations
    post_create=$(jq -r '.postCreateCommand // empty' "$DEVCONTAINER_JSON" 2>/dev/null || true)
    if [ -n "$post_create" ]; then
        if echo "$post_create" | grep -qE "$HEAVY_PATTERNS"; then
            warn "postCreateCommand contains heavy operations: '$post_create'. Move to updateContentCommand for prebuild optimization."
        fi
    fi

    # Check postStartCommand for heavy operations
    post_start=$(jq -r '.postStartCommand // empty' "$DEVCONTAINER_JSON" 2>/dev/null || true)
    if [ -n "$post_start" ]; then
        if echo "$post_start" | grep -qE "$HEAVY_PATTERNS"; then
            warn "postStartCommand contains heavy operations: '$post_start'. Move to updateContentCommand for prebuild optimization."
        fi
    fi

    # Check if updateContentCommand is missing when heavy ops exist elsewhere
    has_heavy=false
    for cmd in "$post_create" "$post_start"; do
        if [ -n "$cmd" ] && echo "$cmd" | grep -qE "$HEAVY_PATTERNS"; then
            has_heavy=true
            break
        fi
    done

    if [ "$has_heavy" = "true" ]; then
        update_content=$(jq -r '.updateContentCommand // empty' "$DEVCONTAINER_JSON" 2>/dev/null || true)
        if [ -z "$update_content" ]; then
            warn "Heavy operations found in non-prebuild hooks but updateContentCommand is missing. Add updateContentCommand for prebuild optimization."
        fi
    fi
else
    # Fallback: grep the raw JSON
    if grep -q '"postCreateCommand"' "$DEVCONTAINER_JSON"; then
        if grep -A 5 '"postCreateCommand"' "$DEVCONTAINER_JSON" | grep -qE "$HEAVY_PATTERNS"; then
            warn "postCreateCommand may contain heavy operations. Move to updateContentCommand for prebuild optimization."
        fi
    fi
fi

if [ "$WARNINGS" -gt 0 ]; then
    echo "WARNING [prebuild-lifecycle-helper]: $WARNINGS lifecycle misconfiguration(s) detected."
    if [ "${FAIL_ON_WARNING:-false}" = "true" ]; then
        echo "ERROR [prebuild-lifecycle-helper]: failOnWarning is enabled; aborting container creation."
        exit 1
    fi
else
    echo "INFO [prebuild-lifecycle-helper]: Lifecycle commands are prebuild-optimized."
fi

exit 0
EOF

chmod +x /usr/local/bin/prebuild-lifecycle-helper

echo "prebuild-lifecycle-helper installed."
echo "  Run 'prebuild-lifecycle-helper' to audit lifecycle commands."
