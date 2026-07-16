#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
SOCKET_PATH="${SSHAGENTFORWARDSOCKETPATH:-auto}"
FORWARD_TO_USER="${SSHAGENTFORWARDFORWARDTOUSER:-true}"

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

# Determine the socket path inside the container
if [ "$SOCKET_PATH" = "auto" ] || [ "$SOCKET_PATH" = "automatic" ]; then
    # Default to the standard devcontainer mount location
    SOCKET_PATH="/tmp/vscode-ssh-auth-sock"
fi

# Write a systemd-style service unit or init script that manages the symlink
# Since devcontainer features run at build time, we install a lifecycle helper
# that will be invoked by postStartCommand or an entrypoint
SCRIPT_DIR="/usr/local/share/ssh-agent-forward"
mkdir -p "$SCRIPT_DIR"

cat > "$SCRIPT_DIR/setup-ssh-agent.sh" << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -euo pipefail

# This script runs inside the container at startup to wire the SSH agent
# from the host (mounted by devcontainer.json remoteEnv / mounts) into
# the container user's environment.

SOCKET_PATH="__SOCKET_PATH__"
FORWARD_TO_USER="__FORWARD_TO_USER__"
USERNAME="__USERNAME__"
USER_HOME="__USER_HOME__"

# Look for the host-provided socket.
# VS Code/Codespaces mount the host SSH_AUTH_SOCK into the container
# and set SSH_AUTH_SOCK in the remote environment.
HOST_SOCK="${SSH_AUTH_SOCK:-}"

if [ -z "$HOST_SOCK" ] || [ ! -S "$HOST_SOCK" ]; then
    echo "ssh-agent-forward: no host SSH agent socket detected (SSH_AUTH_SOCK='$HOST_SOCK'). Skipping."
    exit 0
fi

# Create the forward socket directory
FORWARD_DIR="$(dirname "$SOCKET_PATH")"
mkdir -p "$FORWARD_DIR"

# Symlink host socket to our known path for stability
if [ -L "$SOCKET_PATH" ] || [ -e "$SOCKET_PATH" ]; then
    rm -f "$SOCKET_PATH"
fi
ln -s "$HOST_SOCK" "$SOCKET_PATH"

# Set ownership if running as root and target user exists
if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
    chown -h "${USERNAME}:" "$SOCKET_PATH" 2>/dev/null || true
fi

# If requested, also symlink into the user's home for tools that ignore env vars
if [ "$FORWARD_TO_USER" = "true" ] && [ -n "$USER_HOME" ]; then
    USER_SOCK="${USER_HOME}/.ssh/agent.sock"
    mkdir -p "$(dirname "$USER_SOCK")"
    if [ -L "$USER_SOCK" ] || [ -e "$USER_SOCK" ]; then
        rm -f "$USER_SOCK"
    fi
    ln -s "$HOST_SOCK" "$USER_SOCK"
    if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
        chown -h "${USERNAME}:" "$USER_SOCK" 2>/dev/null || true
    fi
fi

# Ensure SSH_AUTH_SOCK points to our stable path in shell profiles
PROFILE_FILE="${USER_HOME}/.bashrc"
if [ -f "$PROFILE_FILE" ]; then
    if ! grep -q "SSH_AUTH_SOCK" "$PROFILE_FILE"; then
        echo "export SSH_AUTH_SOCK='${SOCKET_PATH}'" >> "$PROFILE_FILE"
    fi
fi

PROFILE_FILE="${USER_HOME}/.zshrc"
if [ -f "$PROFILE_FILE" ]; then
    if ! grep -q "SSH_AUTH_SOCK" "$PROFILE_FILE"; then
        echo "export SSH_AUTH_SOCK='${SOCKET_PATH}'" >> "$PROFILE_FILE"
    fi
fi

echo "ssh-agent-forward: forwarded host SSH agent from ${HOST_SOCK} to ${SOCKET_PATH}"
SCRIPT_EOF

# Substitute placeholders
sed -i "s|__SOCKET_PATH__|${SOCKET_PATH}|g" "$SCRIPT_DIR/setup-ssh-agent.sh"
sed -i "s|__FORWARD_TO_USER__|${FORWARD_TO_USER}|g" "$SCRIPT_DIR/setup-ssh-agent.sh"
sed -i "s|__USERNAME__|${USERNAME}|g" "$SCRIPT_DIR/setup-ssh-agent.sh"
sed -i "s|__USER_HOME__|${USER_HOME}|g" "$SCRIPT_DIR/setup-ssh-agent.sh"

chmod +x "$SCRIPT_DIR/setup-ssh-agent.sh"

# Symlink a convenience command
ln -sf "$SCRIPT_DIR/setup-ssh-agent.sh" /usr/local/bin/devcontainer-ssh-agent-forward

echo "ssh-agent-forward installed. Run 'devcontainer-ssh-agent-forward' after container startup."
