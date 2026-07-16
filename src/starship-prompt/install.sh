#!/bin/bash
set -e

# starship-prompt install script
# Installs Starship cross-shell prompt and configures supported shells

STARSHIP_VERSION="${STARSHIPVERSION:-latest}"
SHELLS="${SHELLS:-bash,zsh}"
PRESET="${PRESET:-}"

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || true)
if [ -z "$REMOTE_HOME" ]; then
    if [ "$REMOTE_USER" = "root" ]; then
        REMOTE_HOME="/root"
    else
        REMOTE_HOME="/home/$REMOTE_USER"
    fi
fi

# Determine architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64) ARCH="aarch64" ;;
    arm64) ARCH="aarch64" ;;
    *)
        echo "WARNING: Unsupported architecture $ARCH, attempting x86_64 fallback"
        ARCH="x86_64"
        ;;
esac

# Determine OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
    linux) OS="unknown-linux-gnu" ;;
    darwin) OS="apple-darwin" ;;
    *)
        echo "WARNING: Unsupported OS $OS, attempting linux fallback"
        OS="unknown-linux-gnu"
        ;;
esac

# Install Starship
if [ "$STARSHIP_VERSION" = "latest" ] || [ -z "$STARSHIP_VERSION" ]; then
    echo "Installing latest Starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir /usr/local/bin
else
    echo "Installing Starship $STARSHIP_VERSION..."
    curl -fsSL "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-${ARCH}-${OS}.tar.gz" | tar -xz -C /tmp
    mv /tmp/starship /usr/local/bin/starship 2>/dev/null || true
fi

chmod +x /usr/local/bin/starship 2>/dev/null || true

if ! command -v starship >/dev/null 2>&1; then
    echo "ERROR: Starship installation failed"
    exit 1
fi

starship_version=$(starship --version 2>/dev/null | head -1 || true)
echo "Starship installed: $starship_version"

# Configure preset if specified
if [ -n "$PRESET" ]; then
    echo "Applying preset: $PRESET"
    mkdir -p "$REMOTE_HOME/.config"
    starship preset "$PRESET" -o "$REMOTE_HOME/.config/starship.toml" 2>/dev/null || \
        echo "WARNING: Could not apply preset $PRESET"
fi

# Configure shell integration
IFS=',' read -ra SHELL_LIST <<< "$SHELLS"
for shell in "${SHELL_LIST[@]}"; do
    shell=$(echo "$shell" | tr -d '[:space:]')
    case "$shell" in
        bash)
            RC_FILE="$REMOTE_HOME/.bashrc"
            mkdir -p "$(dirname "$RC_FILE")"
            if ! grep -q 'eval "\$(starship init bash)"' "$RC_FILE" 2>/dev/null; then
                echo 'eval "$(starship init bash)"' >> "$RC_FILE"
                echo "Configured Starship for bash"
            fi
            ;;
        zsh)
            RC_FILE="$REMOTE_HOME/.zshrc"
            mkdir -p "$(dirname "$RC_FILE")"
            if ! grep -q 'eval "\$(starship init zsh)"' "$RC_FILE" 2>/dev/null; then
                echo 'eval "$(starship init zsh)"' >> "$RC_FILE"
                echo "Configured Starship for zsh"
            fi
            ;;
        fish)
            FISH_DIR="$REMOTE_HOME/.config/fish/conf.d"
            mkdir -p "$FISH_DIR"
            if [ ! -f "$FISH_DIR/starship.fish" ]; then
                echo 'starship init fish | source' > "$FISH_DIR/starship.fish"
                echo "Configured Starship for fish"
            fi
            ;;
        *)
            echo "WARNING: Unknown shell '$shell', skipping"
            ;;
    esac
done

# Ensure ownership
chown -R "$REMOTE_USER:$REMOTE_USER" "$REMOTE_HOME" 2>/dev/null || true

echo "starship-prompt installed."
echo "  Version: $STARSHIP_VERSION"
echo "  Shells: $SHELLS"
echo "  Preset: ${PRESET:-default}"
echo "  Run 'starship explain' to see your prompt configuration."
