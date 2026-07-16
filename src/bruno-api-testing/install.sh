#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"
GLOBAL_INSTALL="${GLOBALINSTALL:-true}"

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

# Ensure Node.js/npm is available
if ! command -v npm > /dev/null 2>&1; then
    echo "npm not found. Installing Node.js and npm..."
    if command -v apt-get > /dev/null 2>&1; then
        apt-get update && apt-get install -y nodejs npm
    elif command -v dnf > /dev/null 2>&1; then
        dnf install -y nodejs npm
    elif command -v yum > /dev/null 2>&1; then
        yum install -y nodejs npm
    elif command -v apk > /dev/null 2>&1; then
        apk add --no-cache nodejs npm
    else
        echo "ERROR: Cannot install npm: no supported package manager found."
        exit 1
    fi
fi

# Install Bruno CLI
if ! command -v bru > /dev/null 2>&1; then
    echo "Installing Bruno CLI..."

    if [ "$GLOBAL_INSTALL" = "true" ]; then
        if command -v npm > /dev/null 2>&1; then
            if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
                npm install -g @usebruno/cli
            else
                npm install -g "@usebruno/cli@${VERSION}"
            fi
        else
            echo "ERROR: Cannot install Bruno CLI: npm not available."
            exit 1
        fi
    else
        # Local install in user home
        mkdir -p "${USER_HOME}/.bruno"
        if command -v npm > /dev/null 2>&1; then
            if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
                npm install --prefix "${USER_HOME}/.bruno" @usebruno/cli
            else
                npm install --prefix "${USER_HOME}/.bruno" "@usebruno/cli@${VERSION}"
            fi
            # Add to PATH
            if ! grep -q "\.bruno/bin" "${USER_HOME}/.bashrc" 2>/dev/null; then
                echo 'export PATH="${HOME}/.bruno/bin:${PATH}"' >> "${USER_HOME}/.bashrc"
            fi
            if [ -f "${USER_HOME}/.zshrc" ] && ! grep -q "\.bruno/bin" "${USER_HOME}/.zshrc" 2>/dev/null; then
                echo 'export PATH="${HOME}/.bruno/bin:${PATH}"' >> "${USER_HOME}/.zshrc"
            fi
        else
            echo "ERROR: Cannot install Bruno CLI: npm not available."
            exit 1
        fi
    fi

    echo "Bruno CLI installed."
else
    echo "Bruno CLI already installed."
fi

# Set ownership for user
if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
    chown -R "${USERNAME}:" "${USER_HOME}/.bruno" 2>/dev/null || true
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-bruno"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-run}"
shift || true

case "$COMMAND" in
    run)
        echo "Running Bruno collection..."
        bru run "$@"
        ;;
    init)
        echo "Initializing new Bruno collection..."
        bru init "$@"
        ;;
    status)
        echo "Bruno CLI status"
        bru --version
        echo ""
        echo "Usage:"
        echo "  bru run                    # Run collection"
        echo "  bru run --env local        # Run with environment"
        echo "  bru init                   # Initialize collection"
        ;;
    *)
        bru "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Bruno API Testing installed."
echo "  CLI: devcontainer-bruno"
echo "  Run: bru run"
echo "  Init: bru init"
