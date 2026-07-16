#!/bin/bash
set -e

# direnv-integration install script
# Installs direnv and hooks it into shell startup

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || true)
if [ -z "$REMOTE_HOME" ]; then
    if [ "$REMOTE_USER" = "root" ]; then
        REMOTE_HOME="/root"
    else
        REMOTE_HOME="/home/$REMOTE_USER"
    fi
fi

VERSION="${VERSION:-latest}"
SHELL_CHOICE="${SHELL:-auto}"
AUTO_ALLOW="${AUTOALLOW:-true}"

echo "direnv Integration"
echo "  User:   $REMOTE_USER"
echo "  Home:   $REMOTE_HOME"
echo "  Version: $VERSION"
echo "  Shell:  $SHELL_CHOICE"
echo "  Auto-allow: $AUTO_ALLOW"

# Try package manager first for 'latest'
if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    if command -v apt-get >/dev/null 2>&1; then
        echo "Installing direnv via apt-get..."
        apt-get update >/dev/null 2>&1 || true
        if apt-get install -y direnv >/dev/null 2>&1; then
            echo "direnv installed via apt-get"
            DIRECT_INSTALL="false"
        else
            echo "WARNING: apt-get install direnv failed; falling back to GitHub download"
            DIRECT_INSTALL="true"
        fi
    else
        DIRECT_INSTALL="true"
    fi
else
    DIRECT_INSTALL="true"
fi

# Download from GitHub if needed
if [ "$DIRECT_INSTALL" = "true" ]; then
    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            DIRENV_ARCH="amd64"
            ;;
        aarch64|arm64)
            DIRENV_ARCH="arm64"
            ;;
        *)
            echo "WARNING: Architecture $ARCH not explicitly supported; trying amd64"
            DIRENV_ARCH="amd64"
            ;;
    esac

    # Resolve version
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        # Try GitHub API first
        LATEST_TAG=$(curl -sL --retry 3 --max-time 10 \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/direnv/direnv/releases/latest" 2>/dev/null | \
            grep '"tag_name":' | head -n 1 | sed 's/.*"v\{0,1\}\([^"]*\)".*/\1/' || true)

        if [ -z "$LATEST_TAG" ]; then
            # Fallback: hardcoded known-good version
            LATEST_TAG="2.34.0"
            echo "WARNING: Could not resolve latest direnv version; falling back to v$LATEST_TAG"
        fi
        VERSION="$LATEST_TAG"
    fi

    # Strip 'v' prefix if present
    VERSION=$(echo "$VERSION" | sed 's/^v//')

    echo "Installing direnv v${VERSION} for linux-${DIRENV_ARCH}..."

    # Download direnv binary
    DIRENV_URL="https://github.com/direnv/direnv/releases/download/v${VERSION}/direnv.linux-${DIRENV_ARCH}"
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT

    HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" --retry 3 --max-time 60 -L "$DIRENV_URL")
    if [ "$HTTP_STATUS" != "200" ]; then
        echo "ERROR: GitHub returned HTTP $HTTP_STATUS for $DIRENV_URL"
        echo "       The version or architecture may not exist."
        exit 1
    fi

    if ! curl -fsSL --retry 3 --max-time 60 -o "$TMP_DIR/direnv" "$DIRENV_URL" 2>/dev/null; then
        echo "ERROR: Failed to download direnv from $DIRENV_URL"
        exit 1
    fi

    # Verify it's a valid binary
    if [ ! -s "$TMP_DIR/direnv" ]; then
        echo "ERROR: Downloaded file is empty"
        exit 1
    fi

    if ! file "$TMP_DIR/direnv" | grep -q "ELF.*executable"; then
        echo "ERROR: Downloaded file is not a valid ELF binary"
        exit 1
    fi

    chmod +x "$TMP_DIR/direnv"
    mv "$TMP_DIR/direnv" /usr/local/bin/direnv

    echo "direnv binary installed to /usr/local/bin/direnv"
fi

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
echo "  Binary:   /usr/local/bin/direnv"
echo "  Version:  $(direnv version 2>/dev/null || echo 'unknown')"
echo "  Shells:   $SHELLS_TO_HOOK"
echo ""
echo "Quick start:"
echo "  echo 'export MY_VAR=hello' > .envrc"
echo "  direnv allow"
echo "  cd .    # triggers reload"
