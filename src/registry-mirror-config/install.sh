#!/usr/bin/env bash
set -euo pipefail

MIRRORS="${REGISTRYMIRRORCONFIGMIRRORS:-}"
INSECURE_REGISTRIES="${REGISTRYMIRRORCONFIGINSECUREREGISTRIES:-}"
RESTART_DOCKER="${REGISTRYMIRRORCONFIGRESTARTDOCKER:-true}"

DAEMON_JSON="/etc/docker/daemon.json"

# Build the new config JSON
CONFIG_PARTS=""

# Handle mirrors
if [ -n "$MIRRORS" ]; then
    if [ "$MIRRORS" = "auto" ] || [ "$MIRRORS" = "automatic" ]; then
        echo "INFO: 'auto' mirror detection not implemented; provide explicit mirrors."
    else
        CONFIG_PARTS="\"registry-mirrors\": $MIRRORS"
    fi
fi

# Handle insecure registries
if [ -n "$INSECURE_REGISTRIES" ]; then
    IFS=',' read -ra REG_LIST <<< "$INSECURE_REGISTRIES"
    REG_ARRAY=""
    FIRST=true
    for REG in "${REG_LIST[@]}"; do
        REG="$(echo "$REG" | tr -d '[:space:]')"
        if [ -z "$REG" ]; then
            continue
        fi
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            REG_ARRAY="${REG_ARRAY}, "
        fi
        REG_ARRAY="${REG_ARRAY}\"$REG\""
    done

    if [ -n "$REG_ARRAY" ]; then
        if [ -n "$CONFIG_PARTS" ]; then
            CONFIG_PARTS="${CONFIG_PARTS}, "
        fi
        CONFIG_PARTS="${CONFIG_PARTS}\"insecure-registries\": [$REG_ARRAY]"
    fi
fi

if [ -z "$CONFIG_PARTS" ]; then
    echo "WARNING: No registry mirrors or insecure registries configured. Nothing to do."
    exit 0
fi

# Ensure /etc/docker exists
mkdir -p "$(dirname "$DAEMON_JSON")"

# Write daemon.json — overwrite if exists for simplicity
NEW_CONFIG="{ $CONFIG_PARTS }"
echo "$NEW_CONFIG" > "$DAEMON_JSON"
chmod 644 "$DAEMON_JSON"

echo "Config written to $DAEMON_JSON"

# Restart Docker if requested and possible
if [ "$RESTART_DOCKER" = "true" ]; then
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet docker 2>/dev/null; then
            echo "Restarting Docker daemon..."
            systemctl restart docker || echo "WARNING: Failed to restart Docker via systemctl."
        else
            echo "INFO: Docker service not active; skipping restart."
        fi
    elif [ -S /var/run/docker.sock ] || [ -S /run/docker.sock ]; then
        echo "INFO: Docker socket detected but systemctl unavailable; manual restart required."
    else
        echo "INFO: Docker not detected; skipping restart."
    fi
fi

echo "Registry Mirror Config installed."
echo "  Config: $DAEMON_JSON"
