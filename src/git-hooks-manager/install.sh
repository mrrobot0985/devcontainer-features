#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
HOOKS="${HOOKS:-pre-commit}"
AUTO_INSTALL="${AUTOINSTALL:-true}"
CONFIG_PATH="${CONFIGPATH:-.pre-commit-config.yaml}"

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

# Ensure Python/pip is available for pre-commit
if ! command -v pip3 > /dev/null 2>&1 && ! command -v pip > /dev/null 2>&1; then
    echo "pip not found. Installing python3-pip..."
    if command -v apt-get > /dev/null 2>&1; then
        apt-get update && apt-get install -y python3-pip
    elif command -v dnf > /dev/null 2>&1; then
        dnf install -y python3-pip
    elif command -v yum > /dev/null 2>&1; then
        yum install -y python3-pip
    elif command -v apk > /dev/null 2>&1; then
        apk add --no-cache py3-pip
    else
        echo "ERROR: Cannot install pip: no supported package manager found."
        exit 1
    fi
fi

# Install pre-commit framework
if ! command -v pre-commit > /dev/null 2>&1; then
    echo "Installing pre-commit..."
    if command -v pip3 > /dev/null 2>&1; then
        pip3 install --break-system-packages pre-commit 2>/dev/null || pip3 install pre-commit
    elif command -v pip > /dev/null 2>&1; then
        pip install --break-system-packages pre-commit 2>/dev/null || pip install pre-commit
    else
        echo "ERROR: Cannot install pre-commit: pip not available."
        exit 1
    fi
else
    echo "pre-commit already installed."
fi

# Install Node.js-based tools if requested
IFS=',' read -ra HOOK_LIST <<< "$HOOKS"
for HOOK in "${HOOK_LIST[@]}"; do
    HOOK="$(echo "$HOOK" | tr -d '[:space:]')"
    case "$HOOK" in
        commitlint)
            if ! command -v commitlint > /dev/null 2>&1; then
                echo "Installing commitlint..."
                if command -v npm > /dev/null 2>&1; then
                    npm install -g @commitlint/cli @commitlint/config-conventional 2>/dev/null || echo "WARNING: commitlint install failed"
                else
                    echo "WARNING: npm not available; skipping commitlint installation."
                fi
            fi
            ;;
        prettier)
            if ! command -v prettier > /dev/null 2>&1; then
                echo "Installing prettier..."
                if command -v npm > /dev/null 2>&1; then
                    npm install -g prettier 2>/dev/null || echo "WARNING: prettier install failed"
                else
                    echo "WARNING: npm not available; skipping prettier installation."
                fi
            fi
            ;;
        lint-staged)
            if ! command -v lint-staged > /dev/null 2>&1; then
                echo "Installing lint-staged..."
                if command -v npm > /dev/null 2>&1; then
                    npm install -g lint-staged 2>/dev/null || echo "WARNING: lint-staged install failed"
                else
                    echo "WARNING: npm not available; skipping lint-staged installation."
                fi
            fi
            ;;
    esac
done

# Write a default pre-commit config if one doesn't exist
DEFAULT_CONFIG="${USER_HOME}/${CONFIG_PATH}"
if [ ! -f "$DEFAULT_CONFIG" ] && [ "$AUTO_INSTALL" = "true" ]; then
    mkdir -p "$(dirname "$DEFAULT_CONFIG")"
    cat > "$DEFAULT_CONFIG" << 'CONFIG_EOF'
# Default pre-commit configuration for devcontainer projects
# Customize this file to add your own hooks
# See https://pre-commit.com/hooks.html for more hooks

repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-added-large-files
      - id: detect-private-key

  - repo: https://github.com/alessandrojcm/commitlint-pre-commit-hook
    rev: v9.16.0
    hooks:
      - id: commitlint
        stages: [commit-msg]
        additional_dependencies: ['@commitlint/config-conventional']
CONFIG_EOF
    if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
        chown -R "${USERNAME}:" "$(dirname "$DEFAULT_CONFIG")" 2>/dev/null || true
    fi
    echo "Default pre-commit config written to $DEFAULT_CONFIG"
fi

# Install a helper script for auto-installing hooks
HELPER_SCRIPT="/usr/local/bin/devcontainer-git-hooks-install"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="${1:-$(pwd)}"
CONFIG="${2:-.pre-commit-config.yaml}"

cd "$WORKSPACE"

if [ ! -d .git ]; then
    echo "WARNING: $WORKSPACE is not a git repository. Skipping hook installation."
    exit 0
fi

if [ -f "$CONFIG" ]; then
    echo "Installing pre-commit hooks from $CONFIG..."
    pre-commit install
    if grep -q "commit-msg" "$CONFIG" 2>/dev/null; then
        pre-commit install --hook-type commit-msg
    fi
    echo "Hooks installed successfully."
else
    echo "WARNING: Pre-commit config not found at $CONFIG. Run 'pre-commit sample-config > .pre-commit-config.yaml' to create one."
fi
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

# Add shell aliases for convenience
for PROFILE in "${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc"; do
    if [ -f "$PROFILE" ]; then
        if ! grep -q "devcontainer-git-hooks-install" "$PROFILE" 2>/dev/null; then
            echo "alias git-hooks-install='devcontainer-git-hooks-install'" >> "$PROFILE"
        fi
    fi
done

echo "Git Hooks Manager installed."
echo "  CLI: devcontainer-git-hooks-install [workspace-path] [config-path]"
