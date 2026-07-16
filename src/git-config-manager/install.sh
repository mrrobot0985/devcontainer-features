#!/bin/bash
set -e

# git-config-manager install script
# Standardizes git configuration for devcontainer users

USER_NAME="${USERNAME:-}"
USER_EMAIL="${USEREMAIL:-}"
GPG_KEY="${GPGSIGNINGKEY:-}"
COMMIT_GPG_SIGN="${COMMITGPGSIGN:-false}"
DEFAULT_BRANCH="${DEFAULTBRANCH:-main}"
SAFE_DIRS="${SAFEDIRECTORIES:-*}"
CORE_AUTOCRLF="${COREAUTOCRLF:-input}"

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || true)
if [ -z "$REMOTE_HOME" ]; then
    if [ "$REMOTE_USER" = "root" ]; then
        REMOTE_HOME="/root"
    else
        REMOTE_HOME="/home/$REMOTE_USER"
    fi
fi

# Fallback to host environment variables if options are empty
if [ -z "$USER_NAME" ]; then
    USER_NAME="${GIT_USER_NAME:-}"
fi
if [ -z "$USER_EMAIL" ]; then
    USER_EMAIL="${GIT_USER_EMAIL:-}"
fi
if [ -z "$GPG_KEY" ]; then
    GPG_KEY="${GIT_SIGNING_KEY:-}"
fi

echo "Git Config Manager"
echo "  User: $REMOTE_USER"
echo "  Home: $REMOTE_HOME"

# Build git config file content
GIT_CONFIG_FILE="$REMOTE_HOME/.gitconfig"
mkdir -p "$REMOTE_HOME"

{
    echo "[init]"
    echo "    defaultBranch = $DEFAULT_BRANCH"
    echo "[core]"
    echo "    autocrlf = $CORE_AUTOCRLF"

    if [ "$SAFE_DIRS" = "*" ]; then
        echo "[safe]"
        echo "    directory = *"
    else
        echo "[safe]"
        IFS=',' read -ra DIRS <<< "$SAFE_DIRS"
        for dir in "${DIRS[@]}"; do
            dir=$(echo "$dir" | tr -d '[:space:]')
            if [ -n "$dir" ]; then
                echo "    directory = $dir"
            fi
        done
    fi

    if [ "$COMMIT_GPG_SIGN" = "true" ]; then
        echo "[commit]"
        echo "    gpgsign = true"
        if [ -n "$GPG_KEY" ]; then
            echo "[user]"
            echo "    signingkey = $GPG_KEY"
        fi
    else
        echo "[commit]"
        echo "    gpgsign = false"
    fi

    if [ -n "$USER_NAME" ]; then
        echo "[user]"
        echo "    name = $USER_NAME"
    fi

    if [ -n "$USER_EMAIL" ]; then
        # If [user] section already started above, don't repeat header
        if [ -z "$USER_NAME" ]; then
            echo "[user]"
        fi
        echo "    email = $USER_EMAIL"
    fi
} > "$GIT_CONFIG_FILE"

chown "$REMOTE_USER:$REMOTE_USER" "$GIT_CONFIG_FILE" 2>/dev/null || true
chmod 644 "$GIT_CONFIG_FILE" 2>/dev/null || true

echo "Git configuration written to $GIT_CONFIG_FILE"

# Install helper script
cat > /usr/local/bin/git-config-status <<'EOF'
#!/bin/bash
# git-config-status — show current git configuration

echo "Git Configuration Status"
echo "========================"

echo ""
echo "User identity:"
git config --global user.name 2>/dev/null || echo "  user.name: not set"
git config --global user.email 2>/dev/null || echo "  user.email: not set"

echo ""
echo "Core settings:"
git config --global init.defaultBranch 2>/dev/null || echo "  init.defaultBranch: not set"
git config --global core.autocrlf 2>/dev/null || echo "  core.autocrlf: not set"
git config --global commit.gpgsign 2>/dev/null || echo "  commit.gpgsign: not set"
git config --global user.signingkey 2>/dev/null || echo "  user.signingkey: not set"

echo ""
echo "Safe directories:"
git config --global --get-all safe.directory 2>/dev/null || echo "  None configured"
EOF

chmod +x /usr/local/bin/git-config-status

echo ""
echo "git-config-manager installed."
echo "  Run 'git-config-status' to view current configuration."
