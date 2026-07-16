#!/bin/bash
set -e

# devcontainer-lock-audit install script
# Installs a validation script for .devcontainer-lock.json

# Template variables replaced during feature build
# FAIL_ON_MISSING="__FAILONMISSING__"
# FAIL_ON_STALE="__FAILONSTALE__"

cat > /usr/local/bin/devcontainer-lock-audit <<'EOF'
#!/bin/bash
set -e

# devcontainer-lock-audit — validate .devcontainer-lock.json
# Run in CI or postCreateCommand to enforce reproducible builds.

LOCKFILE="${DEVCONTAINER_LOCKFILE:-/workspace/.devcontainer/devcontainer-lock.json}"
CONFIG="${DEVCONTAINER_CONFIG:-/workspace/.devcontainer/devcontainer.json}"
FAIL_ON_MISSING="${FAIL_ON_MISSING:-true}"
FAIL_ON_STALE="${FAIL_ON_STALE:-true}"
ERRORS=0

error() {
    echo "ERROR [devcontainer-lock-audit]: $1"
    ERRORS=$((ERRORS + 1))
}

warn() {
    echo "WARNING [devcontainer-lock-audit]: $1"
}

if [ ! -f "$LOCKFILE" ]; then
    if [ "$FAIL_ON_MISSING" = "true" ]; then
        error "Lockfile not found: $LOCKFILE"
    else
        warn "Lockfile not found: $LOCKFILE"
    fi
else
    # Validate JSON structure
    if ! jq -e 'has("features")' "$LOCKFILE" >/dev/null 2>&1; then
        error "Lockfile missing 'features' key: $LOCKFILE"
    fi

    # Check staleness if config exists
    if [ -f "$CONFIG" ] && [ "$FAIL_ON_STALE" = "true" ]; then
        lock_mtime=$(stat -c %Y "$LOCKFILE" 2>/dev/null || stat -f %m "$LOCKFILE")
        config_mtime=$(stat -c %Y "$CONFIG" 2>/dev/null || stat -f %m "$CONFIG")
        if [ "$lock_mtime" -lt "$config_mtime" ]; then
            error "Lockfile is older than devcontainer.json. Run 'devcontainer build' to regenerate."
        fi
    fi

    # Verify every feature in config has a lock entry
    if [ -f "$CONFIG" ] && command -v jq >/dev/null 2>&1; then
        config_features=$(jq -r '.features // {} | keys[]' "$CONFIG" 2>/dev/null || true)
        for feat in $config_features; do
            if ! jq -e ".features | has(\"$feat\")" "$LOCKFILE" >/dev/null 2>&1; then
                error "Feature '$feat' in devcontainer.json but not in lockfile"
            fi
        done
    fi
fi

if [ "$ERRORS" -gt 0 ]; then
    echo "ERROR [devcontainer-lock-audit]: $ERRORS validation failure(s)."
    exit 1
fi

echo "INFO [devcontainer-lock-audit]: Lockfile validation passed."
exit 0
EOF

chmod +x /usr/local/bin/devcontainer-lock-audit

echo "devcontainer-lock-audit installed."
echo "  Run 'devcontainer-lock-audit' to validate lockfile."
