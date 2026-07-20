#!/bin/bash
set -e

# grok-build install script
# Installs xAI Grok Build CLI and configures home directory persistence

VERSION="${VERSION:-latest}"
REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || true)

if [ -z "$REMOTE_HOME" ]; then
    if [ "$REMOTE_USER" = "root" ]; then
        REMOTE_HOME="/root"
    else
        REMOTE_HOME="/home/$REMOTE_USER"
    fi
fi

GROK_HOME="$REMOTE_HOME/.grok"
GROK_LIB_DIR="/var/lib/grok-build"

echo "Grok Build installation"
echo "  User: $REMOTE_USER"
echo "  Home: $REMOTE_HOME"
echo "  Version: $VERSION"

# Ensure git and curl are available
if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    apt-get update && apt-get install -y git 2>/dev/null || true
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "Installing curl..."
    apt-get update && apt-get install -y curl 2>/dev/null || true
fi

# Create the persistence directory
mkdir -p "$GROK_LIB_DIR"
chown "$REMOTE_USER:$REMOTE_USER" "$GROK_LIB_DIR" 2>/dev/null || true

# Check if grok is already installed
if command -v grok >/dev/null 2>&1 || [ -f "$REMOTE_HOME/.grok/bin/grok" ]; then
    echo "Grok Build is already installed."
    CURRENT_VERSION=$(grok --version 2>/dev/null || echo "unknown")
    echo "  Current version: $CURRENT_VERSION"
else
    echo "Installing Grok Build CLI..."

    # Download and install grok-build (xai-cli)
    # Official installation via curl pipe
    echo "Downloading and installing Grok Build CLI..."
    curl -fsSL https://x.ai/cli/install.sh | bash

    # Verify installation
    if command -v grok >/dev/null 2>&1; then
        echo "Grok Build installed successfully."
    elif [ -f "$REMOTE_HOME/.grok/bin/grok" ]; then
        # Add to PATH if installed in .grok/bin
        mkdir -p "$REMOTE_HOME/.grok/bin"
        export PATH="$REMOTE_HOME/.grok/bin:$PATH"
        echo "Grok Build installed to ~/.grok/bin"
    else
        echo "WARNING: Grok Build installation may have failed."
        echo "Please check https://docs.x.ai/grok for installation instructions."
    fi
fi

# Set up home directory persistence
# The feature bind-mounts host ~/.grok to /var/lib/grok-build
# and symlinks ~/.grok inside the container

# Create the symlink if it doesn't exist
if [ ! -L "$GROK_HOME" ] && [ ! -d "$GROK_HOME" ]; then
    echo "Setting up home directory persistence..."
    # If /var/lib/grok-build has content (from bind mount), use it
    if [ -d "$GROK_LIB_DIR" ] && [ "$(ls -A "$GROK_LIB_DIR" 2>/dev/null)" ]; then
        ln -sf "$GROK_LIB_DIR" "$GROK_HOME"
        echo "  Symlinked $GROK_HOME -> $GROK_LIB_DIR"
    else
        # Otherwise, initialize from existing .grok if present
        if [ -d "$REMOTE_HOME/.grok" ] && [ "$(ls -A "$REMOTE_HOME/.grok" 2>/dev/null)" ]; then
            # Move existing content to lib dir
            cp -a "$REMOTE_HOME/.grok/"* "$GROK_LIB_DIR/" 2>/dev/null || true
            cp -a "$REMOTE_HOME/.grok"/.* "$GROK_LIB_DIR/" 2>/dev/null || true
            rm -rf "$REMOTE_HOME/.grok"
            ln -sf "$GROK_LIB_DIR" "$GROK_HOME"
            echo "  Migrated existing .grok to persistence location"
        else
            # Just create the symlink to empty lib dir
            ln -sf "$GROK_LIB_DIR" "$GROK_HOME"
            echo "  Created symlink $GROK_HOME -> $GROK_LIB_DIR"
        fi
    fi
    chown -h "$REMOTE_USER:$REMOTE_USER" "$GROK_HOME" 2>/dev/null || true
elif [ -L "$GROK_HOME" ]; then
    echo "Home directory persistence already configured."
elif [ -d "$GROK_HOME" ]; then
    echo "WARNING: $GROK_HOME exists as a directory (not a symlink)."
    echo "  This may indicate manual configuration or a conflict."
    echo "  For proper persistence, use a bind mount from host:"
    echo "    source=\${localEnv:HOME}/.grok,target=/var/lib/grok-build,type=bind"
fi

# Ensure PATH includes grok
GROK_BIN_DIR="$GROK_HOME/bin"
if [ -d "$GROK_BIN_DIR" ] && [[ ":$PATH:" != *":$GROK_BIN_DIR:"* ]]; then
    # Add to profile.d for persistence
    echo "export PATH=\"\$PATH:$GROK_BIN_DIR\"" > /etc/profile.d/grok-build.sh
    chmod +x /etc/profile.d/grok-build.sh
    export PATH="$PATH:$GROK_BIN_DIR"
    echo "  Added $GROK_BIN_DIR to PATH"
fi

echo ""
echo "=== grok-build mount configuration ==="
echo "Add the following to devcontainer.json to persist across rebuilds:"
echo ""
echo '  "mounts": ['
echo '    "source=${localEnv:HOME}/.grok,target=/var/lib/grok-build,type=bind,consistency=cached"'
echo '  ]'
echo ""
echo "Grok Build installation complete."
echo "  Run 'grok --version' to verify."
echo "  Run 'grok login' to authenticate."