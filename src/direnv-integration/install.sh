#!/bin/bash
set -e

# direnv-integration install script
# Installs direnv via apt-get and hooks it into shell startup

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || true)
if [ -z "$REMOTE_HOME" ]; then
    if [ "$REMOTE_USER" = "root" ]; then
        REMOTE_HOME="/root"
    else
        REMOTE_HOME="/home/$REMOTE_USER"
    fi
fi

SHELL_CHOICE="${SHELL:-auto}"
AUTO_ALLOW="${AUTOALLOW:-true}"

echo "direnv Integration"
echo "  User:   $REMOTE_USER"
echo "  Home:   $REMOTE_HOME"
echo "  Shell:  $SHELL_CHOICE"
echo "  Auto-allow: $AUTO_ALLOW"

# Install direnv via package manager
if command -v apt-get >/dev/null 2>&1; then
    echo "Installing direnv via apt-get..."
    apt-get update >/dev/null 2>&1 || true
    apt-get install -y direnv >/dev/null 2>&1 || {
        echo "ERROR: Failed to install direnv via apt-get"
        exit 1
    }
else
    echo "ERROR: No supported package manager found (apt-get required)"
    exit 1
fi

echo "direnv installed via apt-get"

# Verify installation
if ! command -v direnv >/dev/null 2>&1; then
    echo "ERROR: direnv installation failed - binary not found in PATH"
    exit 1
fi

# Determine which shells to hook
if [ "$SHELL_CHOICE" = "auto" ]; then
    SHELLS_TO_HOOK=""
    if [ -f /bin/bash ] || [ -f /usr/bin/bash ] || command -v bash >/dev/null 2>&1; then
        SHELLS_TO_HOOK="bash"
    fi
    if [ -f /bin/zsh ] || [ -f /usr/bin/zsh ] || command -v zsh >/dev/null 2>&1; then
        SHELLS_TO_HOOK="${SHELLS_TO_HOOK:+$SHELLS_TO_HOOK,}zsh"
    fi
    if [ -f /usr/bin/fish ] || command -v fish >/dev/null 2>&1; then
        SHELLS_TO_HOOK="${SHELLS_TO_HOOK:+$SHELLS_TO_HOOK,}fish"
    fi
else
    SHELLS_TO_HOOK="$SHELL_CHOICE"
fi

# Create direnvrc
create_direnvrc() {
    local rc_file="$REMOTE_HOME/.direnvrc"

    cat > "$rc_file" <<'RC_EOF'
# direnv configuration for devcontainer environments
# See: https://direnv.net/man/direnv-stdlib.1.html

# Short timeout for slow env loading
export DIRENV_WARN_TIMEOUT=10s

# Suppress verbose output in devcontainers
export DIRENV_LOG_FORMAT=""

# Fail on unset variables in .envrc
strict_env
RC_EOF

    chown "$REMOTE_USER:$REMOTE_USER" "$rc_file" 2>/dev/null || true
    echo "Created $rc_file"
}

# Hook into shells
hook_bash() {
    local bashrc="$REMOTE_HOME/.bashrc"
    if [ ! -f "$bashrc" ]; then
        touch "$bashrc"
        chown "$REMOTE_USER:$REMOTE_USER" "$bashrc" 2>/dev/null || true
    fi

    if ! grep -q "direnv hook bash" "$bashrc" 2>/dev/null; then
        cat >> "$bashrc" <<'BASH_EOF'

# direnv hook (added by direnv-integration devcontainer feature)
eval "$(direnv hook bash)"
BASH_EOF
        echo "Hooked direnv into bash ($bashrc)"
    else
        echo "direnv bash hook already present"
    fi
}

hook_zsh() {
    local zshrc="$REMOTE_HOME/.zshrc"
    if [ ! -f "$zshrc" ]; then
        touch "$zshrc"
        chown "$REMOTE_USER:$REMOTE_USER" "$zshrc" 2>/dev/null || true
    fi

    if ! grep -q "direnv hook zsh" "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" <<'ZSH_EOF'

# direnv hook (added by direnv-integration devcontainer feature)
eval "$(direnv hook zsh)"
ZSH_EOF
        echo "Hooked direnv into zsh ($zshrc)"
    else
        echo "direnv zsh hook already present"
    fi
}

hook_fish() {
    local fish_config_dir="$REMOTE_HOME/.config/fish"
    local fish_config="$fish_config_dir/config.fish"

    mkdir -p "$fish_config_dir"
    if [ ! -f "$fish_config" ]; then
        touch "$fish_config"
    fi
    chown -R "$REMOTE_USER:$REMOTE_USER" "$fish_config_dir" 2>/dev/null || true

    if ! grep -q "direnv hook fish" "$fish_config" 2>/dev/null; then
        cat >> "$fish_config" <<'FISH_EOF'

# direnv hook (added by direnv-integration devcontainer feature)
direnv hook fish | source
FISH_EOF
        echo "Hooked direnv into fish ($fish_config)"
    else
        echo "direnv fish hook already present"
    fi
}

create_direnvrc

IFS=',' read -ra SHELLS <<< "$SHELLS_TO_HOOK"
for s in "${SHELLS[@]}"; do
    s=$(echo "$s" | tr -d ' ')
    case "$s" in
        bash)
            hook_bash
            ;;
        zsh)
            hook_zsh
            ;;
        fish)
            hook_fish
            ;;
        *)
            echo "WARNING: Unknown shell '$s'; skipping hook"
            ;;
    esac
done

# Auto-allow workspace .envrc files
if [ "$AUTO_ALLOW" = "true" ]; then
    echo "Auto-allowing workspace .envrc files..."

    auto_allow_dir() {
        local dir="$1"
        if [ -f "$dir/.envrc" ]; then
            echo "  Allowing .envrc in $dir"
            su - "$REMOTE_USER" -c "cd '$dir' && direnv allow" 2>/dev/null || \
                echo "    WARNING: Failed to allow .envrc in $dir"
        fi
    }

    # Check common workspace directories
    if [ -d "/workspaces" ]; then
        for ws in /workspaces/*; do
            if [ -d "$ws" ]; then
                auto_allow_dir "$ws"
            fi
        done
    fi

    if [ -d "/workspace" ]; then
        auto_allow_dir "/workspace"
    fi
fi

echo "direnv integration complete."
echo "  Binary:   $(command -v direnv)"
echo "  Version:  $(direnv version 2>/dev/null || echo 'unknown')"
echo "  Shells:   $SHELLS_TO_HOOK"
echo ""
echo "Quick start:"
echo "  echo 'export MY_VAR=hello' > .envrc"
echo "  direnv allow"
echo "  cd .    # triggers reload"
