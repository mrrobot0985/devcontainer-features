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

echo "Git Config Manager"
echo "  User: $REMOTE_USER"
echo "  Home: $REMOTE_HOME"

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

# Configure git system-wide so all users benefit, plus per-user for the remote user
# System config
if [ -n "$DEFAULT_BRANCH" ]; then
    echo "Setting git init.defaultBranch: $DEFAULT_BRANCH"
    git config --system init.defaultBranch "$DEFAULT_BRANCH" 2>/dev/null || true
fi

echo "Setting git core.autocrlf: $CORE_AUTOCRLF"
git config --system core.autocrlf "$CORE_AUTOCRLF" 2>/dev/null || true

# Configure safe directories system-wide
if [ "$SAFE_DIRS" = "*" ]; then
    echo "Adding all directories to git safe.directory"
    git config --system --add safe.directory '*' 2>/dev/null || true
else
    IFS=',' read -ra DIRS <<< "$SAFE_DIRS"
    for dir in "${DIRS[@]}"; do
        dir=$(echo "$dir" | tr -d '[:space:]')
        if [ -n "$dir" ]; then
            echo "Adding safe.directory: $dir"
            git config --system --add safe.directory "$dir" 2>/dev/null || true
        fi
    done
fi

# Configure GPG signing system-wide
if [ "$COMMIT_GPG_SIGN" = "true" ]; then
    echo "Enabling GPG commit signing"
    git config --system commit.gpgsign true 2>/dev/null || true

    if [ -n "$GPG_KEY" ]; then
        echo "Setting GPG signing key: $GPG_KEY"
        git config --system user.signingkey "$GPG_KEY" 2>/dev/null || true
    fi
else
    echo "GPG commit signing disabled"
    git config --system commit.gpgsign false 2>/dev/null || true
fi

# Also set per-user identity if provided
run_as_user() {
    su - "$REMOTE_USER" -c "$1" 2>/dev/null || true
}

if [ -n "$USER_NAME" ]; then
    echo "Setting git user.name: $USER_NAME"
    run_as_user "git config --global user.name '$USER_NAME'"
fi

if [ -n "$USER_EMAIL" ]; then
    echo "Setting git user.email: $USER_EMAIL"
    run_as_user "git config --global user.email '$USER_EMAIL'"
fi

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
