#!/bin/bash
set -e

# dotfiles-sync install script
# Clones a dotfiles repository and applies it to the container user

REPOSITORY="${REPOSITORY:-}"
INSTALL_COMMAND="${INSTALLCOMMAND:-}"
SYNC_METHOD="${SYNCMETHOD:-auto}"

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || true)
if [ -z "$REMOTE_HOME" ]; then
    if [ "$REMOTE_USER" = "root" ]; then
        REMOTE_HOME="/root"
    else
        REMOTE_HOME="/home/$REMOTE_USER"
    fi
fi

echo "Dotfiles Sync"
echo "  User: $REMOTE_USER"
echo "  Home: $REMOTE_HOME"

if [ -z "$REPOSITORY" ]; then
    echo "INFO: No dotfiles repository specified."
    echo "      Set the 'repository' option to enable dotfiles sync."
    echo "      Example: https://github.com/yourusername/dotfiles.git"
    exit 0
fi

DOTFILES_DIR="$REMOTE_HOME/.dotfiles"

# Ensure git is available
if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    apt-get update && apt-get install -y git 2>/dev/null || true
fi

# Clone the repository
if [ -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles directory already exists at $DOTFILES_DIR"
    echo "Pulling latest changes..."
    cd "$DOTFILES_DIR"
    git pull || true
else
    echo "Cloning dotfiles from $REPOSITORY..."
    git clone "$REPOSITORY" "$DOTFILES_DIR" 2>/dev/null || true
fi

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "ERROR: Failed to clone dotfiles repository"
    exit 1
fi

chown -R "$REMOTE_USER:$REMOTE_USER" "$DOTFILES_DIR" 2>/dev/null || true

cd "$DOTFILES_DIR"

# Detect install command if not specified
if [ -z "$INSTALL_COMMAND" ]; then
    if [ -x "./install" ]; then
        INSTALL_COMMAND="./install"
    elif [ -x "./install.sh" ]; then
        INSTALL_COMMAND="./install.sh"
    elif [ -x "./setup" ]; then
        INSTALL_COMMAND="./setup"
    elif [ -x "./setup.sh" ]; then
        INSTALL_COMMAND="./setup.sh"
    elif [ -f "Makefile" ] && grep -q "install" Makefile 2>/dev/null; then
        INSTALL_COMMAND="make install"
    fi
fi

# Run install command if found
if [ -n "$INSTALL_COMMAND" ]; then
    echo "Running install command: $INSTALL_COMMAND"
    su - "$REMOTE_USER" -c "cd '$DOTFILES_DIR' && $INSTALL_COMMAND" 2>/dev/null || \
        echo "WARNING: Install command failed or requires manual intervention"
else
    echo "No install command found or specified"

    # Auto-sync files if no install command
    if [ "$SYNC_METHOD" = "auto" ] || [ "$SYNC_METHOD" = "symlink" ]; then
        echo "Symlinking dotfiles to $REMOTE_HOME..."
        for file in .bashrc .zshrc .vimrc .tmux.conf .gitconfig .profile .aliases .exports; do
            if [ -f "$DOTFILES_DIR/$file" ] && [ ! -L "$REMOTE_HOME/$file" ]; then
                if [ -f "$REMOTE_HOME/$file" ]; then
                    mv "$REMOTE_HOME/$file" "$REMOTE_HOME/$file.bak.$(date +%s)" 2>/dev/null || true
                fi
                su - "$REMOTE_USER" -c "ln -s '$DOTFILES_DIR/$file' '$REMOTE_HOME/$file'" 2>/dev/null || true
                echo "  Linked $file"
            fi
        done
    elif [ "$SYNC_METHOD" = "copy" ]; then
        echo "Copying dotfiles to $REMOTE_HOME..."
        for file in .bashrc .zshrc .vimrc .tmux.conf .gitconfig .profile .aliases .exports; do
            if [ -f "$DOTFILES_DIR/$file" ]; then
                cp "$DOTFILES_DIR/$file" "$REMOTE_HOME/$file" 2>/dev/null || true
                chown "$REMOTE_USER:$REMOTE_USER" "$REMOTE_HOME/$file" 2>/dev/null || true
                echo "  Copied $file"
            fi
        done
    fi
fi

# Install helper script
cat > /usr/local/bin/dotfiles-status <<'EOF'
#!/bin/bash
# dotfiles-status — show dotfiles sync status

DOTFILES_DIR="$HOME/.dotfiles"

echo "Dotfiles Sync Status"
echo "===================="

if [ -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles directory: $DOTFILES_DIR"
    if [ -d "$DOTFILES_DIR/.git" ]; then
        cd "$DOTFILES_DIR"
        echo "Repository: $(git remote get-url origin 2>/dev/null || echo 'unknown')"
        echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    fi
else
    echo "No dotfiles directory found at $DOTFILES_DIR"
    echo "Set the 'repository' option in your devcontainer.json to enable dotfiles sync"
fi
EOF

chmod +x /usr/local/bin/dotfiles-status

echo "Dotfiles sync complete."
echo "Run 'dotfiles-status' to check sync status."
