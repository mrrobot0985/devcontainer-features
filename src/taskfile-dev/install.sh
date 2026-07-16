#!/bin/bash
set -e

# taskfile-dev install script
# Installs Task (go-task) command runner

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
CREATE_ALIAS="${ALIAS:-true}"
INSTALL_COMPLETIONS="${COMPLETIONS:-true}"
DETECT_TASKFILE="${DETECTTASKFILE:-true}"

echo "Taskfile Development"
echo "  User:       $REMOTE_USER"
echo "  Version:    $VERSION"
echo "  Alias:      $CREATE_ALIAS"
echo "  Completions: $INSTALL_COMPLETIONS"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        TASK_ARCH="amd64"
        ;;
    aarch64|arm64)
        TASK_ARCH="arm64"
        ;;
    *)
        echo "WARNING: Architecture $ARCH not explicitly supported; trying amd64"
        TASK_ARCH="amd64"
        ;;
esac

# Resolve version
if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    LATEST_TAG=$(curl -sL --retry 3 --max-time 10 \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/go-task/task/releases/latest" 2>/dev/null | \
        grep '"tag_name":' | head -n 1 | sed 's/.*"v\{0,1\}\([^"]*\)".*/\1/' || true)

    if [ -z "$LATEST_TAG" ]; then
        LATEST_TAG="3.39.0"
        echo "WARNING: Could not resolve latest Task version; falling back to v$LATEST_TAG"
    fi
    VERSION="$LATEST_TAG"
fi

# Strip 'v' prefix if present
VERSION=$(echo "$VERSION" | sed 's/^v//')

echo "Installing Task v${VERSION} for linux-${TASK_ARCH}..."

# Download Task release tarball
TASK_URL="https://github.com/go-task/task/releases/download/v${VERSION}/task_linux_${TASK_ARCH}.tar.gz"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if ! curl -fsSL --retry 3 --max-time 120 -o "$TMP_DIR/task.tar.gz" "$TASK_URL" 2>/dev/null; then
    echo "ERROR: Failed to download Task from $TASK_URL"
    exit 1
fi

# Extract tarball
cd "$TMP_DIR"
if ! tar -xzf "task.tar.gz" 2>/dev/null; then
    echo "ERROR: Failed to extract task.tar.gz"
    exit 1
fi

# Verify binary exists and is executable
if [ ! -f "$TMP_DIR/task" ]; then
    echo "ERROR: Extracted archive does not contain 'task' binary"
    ls -la "$TMP_DIR/"
    exit 1
fi

chmod +x "$TMP_DIR/task"
mv "$TMP_DIR/task" /usr/local/bin/task

echo "Task binary installed to /usr/local/bin/task"

# Install completions
if [ "$INSTALL_COMPLETIONS" = "true" ]; then
    mkdir -p /usr/local/share/bash-completion/completions
    mkdir -p /usr/local/share/zsh/site-functions

    if [ -f "$TMP_DIR/completions/task.bash" ]; then
        cp "$TMP_DIR/completions/task.bash" /usr/local/share/bash-completion/completions/task
        echo "Bash completions installed"
    fi

    if [ -f "$TMP_DIR/completions/task.zsh" ]; then
        cp "$TMP_DIR/completions/task.zsh" /usr/local/share/zsh/site-functions/_task
        echo "Zsh completions installed"
    fi
fi

# Shell alias
if [ "$CREATE_ALIAS" = "true" ]; then
    add_alias_bash() {
        local bashrc="$REMOTE_HOME/.bashrc"
        if [ ! -f "$bashrc" ]; then
            touch "$bashrc"
            chown "$REMOTE_USER:$REMOTE_USER" "$bashrc" 2>/dev/null || true
        fi
        if ! grep -q "alias t='task'" "$bashrc" 2>/dev/null; then
            cat >> "$bashrc" <<'ALIAS_EOF'

# Task alias (added by taskfile-dev devcontainer feature)
alias t='task'
ALIAS_EOF
            echo "Added 't' alias to bash ($bashrc)"
        fi
    }

    add_alias_zsh() {
        local zshrc="$REMOTE_HOME/.zshrc"
        if [ ! -f "$zshrc" ]; then
            touch "$zshrc"
            chown "$REMOTE_USER:$REMOTE_USER" "$zshrc" 2>/dev/null || true
        fi
        if ! grep -q "alias t='task'" "$zshrc" 2>/dev/null; then
            cat >> "$zshrc" <<'ALIAS_EOF'

# Task alias (added by taskfile-dev devcontainer feature)
alias t='task'
ALIAS_EOF
            echo "Added 't' alias to zsh ($zshrc)"
        fi
    }

    add_alias_bash
    add_alias_zsh
fi

# Detect Taskfile in workspace
if [ "$DETECT_TASKFILE" = "true" ]; then
    if [ -d "/workspaces" ]; then
        for ws in /workspaces/*; do
            if [ -f "$ws/Taskfile.yml" ] || [ -f "$ws/Taskfile.yaml" ]; then
                echo "Hint: Found Taskfile in $ws"
                echo "      Run 'task --list' to see available tasks."
            fi
        done
    fi
    if [ -f "/workspace/Taskfile.yml" ] || [ -f "/workspace/Taskfile.yaml" ]; then
        echo "Hint: Found Taskfile in /workspace"
        echo "      Run 'task --list' to see available tasks."
    fi
fi

echo "Taskfile development setup complete."
echo "  Binary:     /usr/local/bin/task"
echo "  Version:    $(task --version 2>/dev/null || echo 'unknown')"
if [ "$CREATE_ALIAS" = "true" ]; then
    echo "  Alias:      t -> task"
fi
echo ""
echo "Quick start:"
echo "  task --list        # List available tasks"
echo "  task init          # Create a new Taskfile.yml"
echo "  task <task-name>   # Run a task"
