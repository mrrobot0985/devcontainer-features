#!/bin/bash
set -e

# mise install script
# Installs mise (modern dev tool manager) and configures shell integration

VERSION="__MISEVERSION__"
SHELLS="__SHELLS__"
AUTO_ACTIVATE="__AUTOACTIVATE__"
TRUST_CONFIG="__TRUSTWORKSPACECONFIG__"

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME="/home/$REMOTE_USER"

# Determine architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="x64" ;;
    aarch64) ARCH="arm64" ;;
    arm64) ARCH="arm64" ;;
    *)
        echo "WARNING: Unsupported architecture $ARCH, attempting x64 fallback"
        ARCH="x64"
        ;;
esac

# Determine platform
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$PLATFORM" in
    linux) PLATFORM="linux" ;;
    darwin) PLATFORM="macos" ;;
    *)
        echo "WARNING: Unsupported platform $PLATFORM, attempting linux fallback"
        PLATFORM="linux"
        ;;
esac

# Install mise
if [ "$VERSION" = "latest" ] || [ -z "$VERSION" ]; then
    echo "Installing latest mise..."
    curl -fsSL https://mise.run | sh
else
    echo "Installing mise $VERSION..."
    curl -fsSL "https://github.com/jdx/mise/releases/download/v${VERSION}/mise-v${VERSION}-${PLATFORM}-${ARCH}.tar.gz" | tar -xz -C /tmp
    mv "/tmp/mise-v${VERSION}-${PLATFORM}-${ARCH}/mise" /usr/local/bin/mise 2>/dev/null || mv /tmp/mise /usr/local/bin/mise 2>/dev/null || true
fi

# Ensure mise is in PATH for subsequent commands
export PATH="/usr/local/bin:$PATH"

if ! command -v mise >/dev/null 2>&1; then
    echo "ERROR: mise installation failed"
    exit 1
fi

mise_version=$(mise --version 2>/dev/null || true)
echo "mise installed: $mise_version"

# Configure shell integration
IFS=',' read -ra SHELL_LIST <<< "$SHELLS"
for shell in "${SHELL_LIST[@]}"; do
    shell=$(echo "$shell" | tr -d '[:space:]')
    case "$shell" in
        bash)
            RC_FILE="$REMOTE_HOME/.bashrc"
            if [ "$AUTO_ACTIVATE" = "true" ]; then
                if ! grep -q 'eval "\$(mise activate bash)"' "$RC_FILE" 2>/dev/null; then
                    echo 'eval "$(mise activate bash)"' >> "$RC_FILE"
                    echo "Configured mise activation for bash"
                fi
            fi
            ;;
        zsh)
            RC_FILE="$REMOTE_HOME/.zshrc"
            if [ "$AUTO_ACTIVATE" = "true" ]; then
                if ! grep -q 'eval "\$(mise activate zsh)"' "$RC_FILE" 2>/dev/null; then
                    echo 'eval "$(mise activate zsh)"' >> "$RC_FILE"
                    echo "Configured mise activation for zsh"
                fi
            fi
            ;;
        fish)
            FISH_DIR="$REMOTE_HOME/.config/fish/conf.d"
            mkdir -p "$FISH_DIR"
            if [ "$AUTO_ACTIVATE" = "true" ]; then
                if [ ! -f "$FISH_DIR/mise.fish" ]; then
                    echo 'mise activate fish | source' > "$FISH_DIR/mise.fish"
                    echo "Configured mise activation for fish"
                fi
            fi
            ;;
        *)
            echo "WARNING: Unknown shell '$shell', skipping"
            ;;
    esac
done

# Ensure ownership
chown -R "$REMOTE_USER:$REMOTE_USER" "$REMOTE_HOME" 2>/dev/null || true

# Trust workspace mise config if present
if [ "$TRUST_CONFIG" = "true" ] && [ -f "/workspaces/.mise.toml" ]; then
    echo "Trusting workspace mise configuration..."
    su - "$REMOTE_USER" -c "mise trust /workspaces/.mise.toml" 2>/dev/null || true
elif [ "$TRUST_CONFIG" = "true" ] && [ -f "/workspace/.mise.toml" ]; then
    echo "Trusting workspace mise configuration..."
    su - "$REMOTE_USER" -c "mise trust /workspace/.mise.toml" 2>/dev/null || true
fi

echo "mise feature installed."
echo "  Version: $VERSION"
echo "  Shells: $SHELLS"
echo "  Auto-activate: $AUTO_ACTIVATE"
echo "  Run 'mise --help' to get started."
