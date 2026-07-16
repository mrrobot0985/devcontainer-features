#!/bin/bash
set -e

# cloud-cli-persistence install script
# Configures cloud CLI credential persistence across container rebuilds

PROVIDERS="${PROVIDERS:-aws,azure,gcp,github}"
VALIDATE="${VALIDATEMOUNTS:-true}"
PRINT_CONFIG="${PRINTMOUNTCONFIG:-true}"

# Normalize providers to lowercase
PROVIDERS_LOWER=$(echo "$PROVIDERS" | tr '[:upper:]' '[:lower:]')

# Credential mount points (host path -> container path)
declare -A MOUNTS
MOUNTS[aws]="~/.aws:/home/${_REMOTE_USER:-vscode}/.aws"
MOUNTS[azure]="~/.azure:/home/${_REMOTE_USER:-vscode}/.azure"
MOUNTS[gcp]="~/.config/gcloud:/home/${_REMOTE_USER:-vscode}/.config/gcloud"
MOUNTS[github]="~/.config/gh:/home/${_REMOTE_USER:-vscode}/.config/gh"

# Container credential paths for validation
declare -A CRED_PATHS
CRED_PATHS[aws]="/home/${_REMOTE_USER:-vscode}/.aws"
CRED_PATHS[azure]="/home/${_REMOTE_USER:-vscode}/.azure"
CRED_PATHS[gcp]="/home/${_REMOTE_USER:-vscode}/.config/gcloud"
CRED_PATHS[github]="/home/${_REMOTE_USER:-vscode}/.config/gh"

# Helper script
cat > /usr/local/bin/cloud-persist <<'EOF'
#!/bin/bash
set -e

# cloud-persist — validate and manage cloud CLI credential persistence
# Usage: cloud-persist [status|validate|mount-config]

CRED_PATHS[aws]="/home/${_REMOTE_USER:-vscode}/.aws"
CRED_PATHS[azure]="/home/${_REMOTE_USER:-vscode}/.azure"
CRED_PATHS[gcp]="/home/${_REMOTE_USER:-vscode}/.config/gcloud"
CRED_PATHS[github]="/home/${_REMOTE_USER:-vscode}/.config/gh"

PROVIDERS="aws azure gcp github"

show_status() {
    echo "Cloud CLI persistence status:"
    for provider in $PROVIDERS; do
        path="${CRED_PATHS[$provider]}"
        if [ -d "$path" ]; then
            count=$(find "$path" -type f 2>/dev/null | wc -l)
            echo "  $provider: mounted ($count files)"
        else
            echo "  $provider: not mounted"
        fi
    done
}

validate_mounts() {
    echo "Validating cloud CLI credential mounts..."
    missing=0
    for provider in $PROVIDERS; do
        path="${CRED_PATHS[$provider]}"
        if [ -d "$path" ]; then
            echo "  $provider: OK ($path)"
        else
            echo "  $provider: MISSING ($path)"
            missing=$((missing + 1))
        fi
    done
    if [ "$missing" -gt 0 ]; then
        echo ""
        echo "WARNING: $missing provider(s) not mounted."
        echo "Add the following to devcontainer.json mounts:"
        echo ''
        echo '  "mounts": ['
        echo '    "source=${localEnv:HOME}/.aws,target=/home/vscode/.aws,type=bind,consistency=cached",'
        echo '    "source=${localEnv:HOME}/.azure,target=/home/vscode/.azure,type=bind,consistency=cached",'
        echo '    "source=${localEnv:HOME}/.config/gcloud,target=/home/vscode/.config/gcloud,type=bind,consistency=cached",'
        echo '    "source=${localEnv:HOME}/.config/gh,target=/home/vscode/.config/gh,type=bind,consistency=cached"'
        echo '  ]'
        echo ''
        return 1
    fi
    echo "All configured mounts present."
    return 0
}

show_mount_config() {
    echo "Add the following to devcontainer.json:"
    echo ''
    echo '  "mounts": ['
    echo '    "source=${localEnv:HOME}/.aws,target=/home/vscode/.aws,type=bind,consistency=cached",'
    echo '    "source=${localEnv:HOME}/.azure,target=/home/vscode/.azure,type=bind,consistency=cached",'
    echo '    "source=${localEnv:HOME}/.config/gcloud,target=/home/vscode/.config/gcloud,type=bind,consistency=cached",'
    echo '    "source=${localEnv:HOME}/.config/gh,target=/home/vscode/.config/gh,type=bind,consistency=cached"'
    echo '  ]'
}

case "${1:-}" in
    status) show_status ;;
    validate) validate_mounts ;;
    mount-config) show_mount_config ;;
    *) echo "Usage: cloud-persist {status|validate|mount-config}"; exit 1 ;;
esac
EOF

chmod +x /usr/local/bin/cloud-persist

# Validate mounts at install time if requested
if [ "$VALIDATE" = "true" ]; then
    echo "Validating cloud CLI credential mounts..."
    missing=0
    IFS=',' read -ra PROVIDER_LIST <<< "$PROVIDERS_LOWER"
    for provider in "${PROVIDER_LIST[@]}"; do
        provider=$(echo "$provider" | tr -d '[:space:]')
        path="${CRED_PATHS[$provider]}"
        if [ -d "$path" ]; then
            echo "  $provider: OK ($path)"
        else
            echo "  $provider: not mounted yet ($path)"
            missing=$((missing + 1))
        fi
    done
    if [ "$missing" -gt 0 ]; then
        echo ""
        echo "INFO: $missing provider(s) not yet mounted. This is expected during image build."
        echo "      Mounts are applied at container runtime, not build time."
        echo "      Run 'cloud-persist validate' after container start to verify."
    fi
fi

# Print mount configuration if requested
if [ "$PRINT_CONFIG" = "true" ]; then
    echo ""
    echo "=== cloud-cli-persistence mount configuration ==="
    echo "Add the following to devcontainer.json:"
    echo ''
    echo '  "mounts": ['
    IFS=',' read -ra PROVIDER_LIST <<< "$PROVIDERS_LOWER"
    first=true
    for provider in "${PROVIDER_LIST[@]}"; do
        provider=$(echo "$provider" | tr -d '[:space:]')
        case "$provider" in
            aws)
                mount='    "source=${localEnv:HOME}/.aws,target=/home/vscode/.aws,type=bind,consistency=cached"'
                ;;
            azure)
                mount='    "source=${localEnv:HOME}/.azure,target=/home/vscode/.azure,type=bind,consistency=cached"'
                ;;
            gcp)
                mount='    "source=${localEnv:HOME}/.config/gcloud,target=/home/vscode/.config/gcloud,type=bind,consistency=cached"'
                ;;
            github)
                mount='    "source=${localEnv:HOME}/.config/gh,target=/home/vscode/.config/gh,type=bind,consistency=cached"'
                ;;
            *) continue ;;
        esac
        if [ "$first" = "true" ]; then
            first=false
        else
            echo ','
        fi
        printf '%s' "$mount"
    done
    echo ''
    echo '  ]'
    echo ""
fi

echo "cloud-cli-persistence installed."
echo "  Providers: $PROVIDERS"
echo "  Run 'cloud-persist status' to check credential mount status."
echo "  Run 'cloud-persist mount-config' to show required devcontainer.json configuration."
