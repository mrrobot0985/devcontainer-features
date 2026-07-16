#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
INSTALL_CRIU="${PODMANCHECKPOINTHELPERINSTALLCRIU:-true}"
CONFIGURE_STORAGE="${PODMANCHECKPOINTHELPERCONFIGURESTORAGE:-true}"
ADD_ALIASES="${PODMANCHECKPOINTHELPERADDALIASES:-true}"

# Detect username
if [ "$USERNAME" = "auto" ] || [ "$USERNAME" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 '{ if ($3 >= val) exit; print $1 }' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "$CURRENT_USER" > /dev/null 2>&1; then
            USERNAME="$CURRENT_USER"
            break
        fi
    done
    if [ -z "$USERNAME" ]; then
        USERNAME="root"
    fi
fi

USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

# Install Podman
if ! command -v podman >/dev/null 2>&1; then
    echo "Installing Podman..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y podman
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y podman
    elif command -v yum >/dev/null 2>&1; then
        yum install -y podman
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache podman
    else
        echo "WARNING: No supported package manager found for Podman installation."
    fi
else
    echo "Podman already installed."
fi

# Install CRIU if requested
if [ "$INSTALL_CRIU" = "true" ]; then
    if ! command -v criu >/dev/null 2>&1; then
        echo "Installing CRIU..."
        if command -v apt-get >/dev/null 2>&1; then
            apt-get install -y criu || echo "WARNING: CRIU not available in apt repositories."
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y criu || echo "WARNING: CRIU not available in dnf repositories."
        elif command -v yum >/dev/null 2>&1; then
            yum install -y criu || echo "WARNING: CRIU not available in yum repositories."
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache criu || echo "WARNING: CRIU not available in apk repositories."
        else
            echo "WARNING: No supported package manager found for CRIU installation."
        fi
    else
        echo "CRIU already installed."
    fi
fi

# Configure Podman storage for checkpoint compatibility
if [ "$CONFIGURE_STORAGE" = "true" ]; then
    mkdir -p /etc/containers
    STORAGE_CONF="/etc/containers/storage.conf"
    if [ ! -f "$STORAGE_CONF" ]; then
        cat > "$STORAGE_CONF" << 'EOF'
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

[storage.options.overlay]
mountopt = "nodev,metacopy=on"
EOF
        echo "Podman storage configured for checkpoint compatibility."
    else
        echo "Podman storage config already exists; skipping."
    fi
fi

# Add docker-compatible aliases if requested
if [ "$ADD_ALIASES" = "true" ]; then
    ALIAS_SCRIPT="/usr/local/bin/docker"
    cat > "$ALIAS_SCRIPT" << 'EOF'
#!/usr/bin/env bash
# docker alias for Podman
exec podman "$@"
EOF
    chmod +x "$ALIAS_SCRIPT"

    ALIAS_SCRIPT="/usr/local/bin/docker-compose"
    cat > "$ALIAS_SCRIPT" << 'EOF'
#!/usr/bin/env bash
# docker-compose alias for Podman Compose
exec podman compose "$@"
EOF
    chmod +x "$ALIAS_SCRIPT"

    echo "Docker-compatible aliases installed."
fi

# Install helper CLI
HELPER_SCRIPT="/usr/local/bin/devcontainer-podman-checkpoint"
cat > "$HELPER_SCRIPT" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
CONTAINER_NAME="${2:-}"
EXPORT_PATH="${3:-/tmp/checkpoint.tar.gz}"

case "$COMMAND" in
    status)
        echo "Podman Checkpoint Helper"
        echo "========================"
        echo "Podman version: $(podman --version 2>/dev/null || echo 'not found')"
        echo "CRIU version: $(criu --version 2>/dev/null | head -1 || echo 'not found')"
        echo ""
        echo "Usage:"
        echo "  devcontainer-podman-checkpoint status"
        echo "  devcontainer-podman-checkpoint checkpoint <container> [export-path]"
        echo "  devcontainer-podman-checkpoint restore <container> [import-path]"
        ;;
    checkpoint)
        if [ -z "$CONTAINER_NAME" ]; then
            echo "ERROR: Container name required."
            exit 1
        fi
        echo "Checkpointing container: $CONTAINER_NAME"
        podman container checkpoint "$CONTAINER_NAME" --export="$EXPORT_PATH" --file-locks || {
            echo "ERROR: Checkpoint failed. Ensure container is running and CRIU is installed."
            exit 1
        }
        echo "Checkpoint exported to: $EXPORT_PATH"
        ;;
    restore)
        if [ -z "$CONTAINER_NAME" ]; then
            echo "ERROR: Container name required."
            exit 1
        fi
        echo "Restoring container: $CONTAINER_NAME from $EXPORT_PATH"
        podman container restore "$CONTAINER_NAME" --import="$EXPORT_PATH" --file-locks || {
            echo "ERROR: Restore failed. Ensure checkpoint archive exists."
            exit 1
        }
        echo "Container restored successfully."
        ;;
    *)
        echo "ERROR: Unknown command '$COMMAND'. Use: status, checkpoint, restore"
        exit 1
        ;;
esac
EOF
chmod +x "$HELPER_SCRIPT"

# Ensure Podman is in PATH for the user
for PROFILE in "${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc"; do
    if [ -f "$PROFILE" ]; then
        if ! grep -q "podman" "$PROFILE" 2>/dev/null; then
            echo 'alias docker=podman 2>/dev/null || true' >> "$PROFILE"
            echo 'alias docker-compose="podman compose" 2>/dev/null || true' >> "$PROFILE"
        fi
    fi
done

echo "Podman Checkpoint Helper installed."
echo "  Podman: $(command -v podman || echo 'not found')"
echo "  CRIU: $(command -v criu || echo 'not found')"
echo "  CLI: devcontainer-podman-checkpoint"
