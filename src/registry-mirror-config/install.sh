#!/usr/bin/env bash
set -euo pipefail

MIRRORS="${REGISTRYMIRRORCONFIGMIRRORS:-}"
INSECURE_REGISTRIES="${REGISTRYMIRRORCONFIGINSECUREREGISTRIES:-}"
RESTART_DOCKER="${REGISTRYMIRRORCONFIGRESTARTDOCKER:-true}"

# Detect Docker daemon config path
DAEMON_JSON="/etc/docker/daemon.json"

# Helper to merge JSON objects using Python
merge_json() {
    local existing_file="$1"
    local new_config="$2"

    if [ -f "$existing_file" ]; then
        python3 -c "
import json
import sys

try:
    with open('$existing_file', 'r') as f:
        existing = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    existing = {}

try:
    new_cfg = json.loads('$new_config')
except json.JSONDecodeError as e:
    print(f'ERROR: Invalid JSON config: {e}', file=sys.stderr)
    sys.exit(1)

# Merge: new config takes precedence for same keys
for key, value in new_cfg.items():
    if key in existing and isinstance(existing[key], dict) and isinstance(value, dict):
        existing[key].update(value)
    elif key in existing and isinstance(existing[key], list) and isinstance(value, list):
        # Merge lists avoiding duplicates
        existing_set = set(json.dumps(x, sort_keys=True) for x in existing[key])
        for item in value:
            item_str = json.dumps(item, sort_keys=True)
            if item_str not in existing_set:
                existing[key].append(item)
                existing_set.add(item_str)
    else:
        existing[key] = value

with open('$existing_file', 'w') as f:
    json.dump(existing, f, indent=2)
    f.write('\n')

print(f'Merged config written to $existing_file')
"
    else
        mkdir -p "$(dirname "$DAEMON_JSON")"
        echo "$new_config" | python3 -c "import json,sys; json.dump(json.load(sys.stdin), open('$existing_file','w'), indent=2); open('$existing_file','a').write('\n')"
        echo "Config written to $existing_file"
    fi
}

# Build the new config JSON
CONFIG_PARTS=""

# Handle mirrors
if [ -n "$MIRRORS" ]; then
    if [ "$MIRRORS" = "auto" ] || [ "$MIRRORS" = "automatic" ]; then
        echo "INFO: 'auto' mirror detection not implemented; provide explicit mirrors."
    else
        # Validate and add registry-mirrors
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

NEW_CONFIG="{ $CONFIG_PARTS }"

# Merge with existing daemon.json
merge_json "$DAEMON_JSON" "$NEW_CONFIG"

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
