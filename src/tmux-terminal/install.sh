#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"
INSTALL_CONFIG="${INSTALLCONFIG:-false}"

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

# Install tmux
if command -v tmux > /dev/null 2>&1; then
    echo "tmux already installed."
    tmux -V 2>/dev/null || true
    exit 0
fi

echo "Installing tmux..."

if command -v apt-get > /dev/null 2>&1; then
    apt-get update
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        apt-get install -y tmux
    else
        apt-get install -y "tmux=${VERSION}" || apt-get install -y tmux
    fi
elif command -v dnf > /dev/null 2>&1; then
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        dnf install -y tmux
    else
        dnf install -y "tmux-${VERSION}" || dnf install -y tmux
    fi
elif command -v yum > /dev/null 2>&1; then
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        yum install -y tmux
    else
        yum install -y "tmux-${VERSION}" || yum install -y tmux
    fi
elif command -v apk > /dev/null 2>&1; then
    apk add --no-cache tmux
else
    echo "ERROR: No supported package manager found for installing tmux."
    exit 1
fi

# Verify installation
if command -v tmux > /dev/null 2>&1; then
    echo "tmux installed: $(tmux -V 2>&1 || echo 'version unknown')"
else
    echo "ERROR: tmux installation failed"
    exit 1
fi

# Install default config
if [ "$INSTALL_CONFIG" = "true" ]; then
    echo "Installing default tmux configuration..."
    TMUX_CONF="${USER_HOME}/.tmux.conf"
    cat > "$TMUX_CONF" << 'TMUXCONF_EOF'
# Sensible tmux defaults
set -g mouse on
set -g history-limit 10000
set -g default-terminal "screen-256color"

# Prefix key
set -g prefix C-b
bind C-b send-prefix

# Window/Pane navigation
bind | split-window -h
bind - split-window -v
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Status bar
set -g status-bg colour235
set -g status-fg colour250
set -g status-left "[#S] "
set -g status-right " %H:%M"
TMUXCONF_EOF
    chown "${USERNAME}:" "$TMUX_CONF" 2>/dev/null || true
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-tmux"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    new)
        echo "Starting new tmux session..."
        tmux new-session "$@"
        ;;
    attach)
        echo "Attaching to tmux session..."
        tmux attach "$@"
        ;;
    list)
        echo "Listing tmux sessions..."
        tmux list-sessions "$@"
        ;;
    status)
        echo "tmux Terminal Multiplexer status"
        tmux -V 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-tmux new     # New session"
        echo "  devcontainer-tmux attach  # Attach to session"
        echo "  devcontainer-tmux list    # List sessions"
        echo ""
        echo "Key bindings:"
        echo "  Ctrl+b c       # New window"
        echo "  Ctrl+b n       # Next window"
        echo "  Ctrl+b p       # Previous window"
        echo "  Ctrl+b %       # Split vertically"
        echo "  Ctrl+b \"       # Split horizontally"
        ;;
    *)
        tmux "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "tmux Terminal Multiplexer installed."
echo "  CLI: devcontainer-tmux"
echo "  New: tmux new-session"
echo "  Attach: tmux attach"
echo "  Version: $(tmux -V 2>/dev/null || echo 'installed')"
