#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"
BROWSERS="${BROWSERS:-chromium}"
INSTALL_DEPS="${INSTALLDEPS:-true}"
GLOBAL_INSTALL="${GLOBALINSTALL:-false}"

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

# Install Playwright
if ! command -v npx > /dev/null 2>&1; then
    echo "ERROR: npx not available. Cannot install Playwright."
    exit 1
fi

INSTALL_DIR=""
if [ "$GLOBAL_INSTALL" = "true" ]; then
    echo "Installing Playwright globally..."
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        npm install -g @playwright/test
    else
        npm install -g "@playwright/test@${VERSION}"
    fi
    INSTALL_DIR="$(npm root -g)/@playwright/test"
else
    echo "Installing Playwright in workspace..."
    WORKSPACE_DIR="${USER_HOME}/.playwright"
    mkdir -p "$WORKSPACE_DIR"
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        npm install --prefix "$WORKSPACE_DIR" @playwright/test
    else
        npm install --prefix "$WORKSPACE_DIR" "@playwright/test@${VERSION}"
    fi
    # Add to PATH
    if ! grep -q "\.playwright/bin" "${USER_HOME}/.bashrc" 2>/dev/null; then
        echo 'export PATH="${HOME}/.playwright/bin:${PATH}"' >> "${USER_HOME}/.bashrc"
    fi
    if [ -f "${USER_HOME}/.zshrc" ] && ! grep -q "\.playwright/bin" "${USER_HOME}/.zshrc" 2>/dev/null; then
        echo 'export PATH="${HOME}/.playwright/bin:${PATH}"' >> "${USER_HOME}/.zshrc"
    fi
fi

# Install system dependencies
if [ "$INSTALL_DEPS" = "true" ]; then
    echo "Installing system dependencies for browsers..."
    if [ "$GLOBAL_INSTALL" = "true" ]; then
        npx playwright install-deps || true
    else
        "${WORKSPACE_DIR}/node_modules/.bin/playwright" install-deps || true
    fi
fi

# Install browser binaries
if [ -n "$BROWSERS" ]; then
    echo "Installing browser binaries: $BROWSERS"
    IFS=',' read -ra BROWSER_LIST <<< "$BROWSERS"
    for browser in "${BROWSER_LIST[@]}"; do
        browser="$(echo "$browser" | xargs)"
        case "$browser" in
            chromium|firefox|webkit)
                echo "  - Installing $browser"
                if [ "$GLOBAL_INSTALL" = "true" ]; then
                    npx playwright install "$browser" || true
                else
                    "${WORKSPACE_DIR}/node_modules/.bin/playwright" install "$browser" || true
                fi
                ;;
            all)
                echo "  - Installing all browsers"
                if [ "$GLOBAL_INSTALL" = "true" ]; then
                    npx playwright install || true
                else
                    "${WORKSPACE_DIR}/node_modules/.bin/playwright" install || true
                fi
                ;;
            *)
                echo "WARNING: Unknown browser '$browser'. Skipping."
                ;;
        esac
    done
fi

# Set ownership for user
if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
    if [ "$GLOBAL_INSTALL" = "false" ]; then
        chown -R "${USERNAME}:" "${USER_HOME}/.playwright" 2>/dev/null || true
    fi
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-playwright"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    test)
        echo "Running Playwright tests..."
        npx playwright test "$@"
        ;;
    codegen)
        echo "Launching Playwright codegen..."
        npx playwright codegen "$@"
        ;;
    report)
        echo "Starting Playwright report server..."
        npx playwright show-report "$@"
        ;;
    install)
        echo "Installing browser binaries..."
        npx playwright install "$@"
        ;;
    status)
        echo "Playwright status"
        npx playwright --version 2>/dev/null || echo "  Playwright not found in PATH"
        echo ""
        echo "Usage:"
        echo "  devcontainer-playwright test         # Run tests"
        echo "  devcontainer-playwright codegen      # Record interactions"
        echo "  devcontainer-playwright report       # Show HTML report"
        echo "  devcontainer-playwright install      # Install browsers"
        ;;
    *)
        npx playwright "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Playwright Testing installed."
echo "  CLI: devcontainer-playwright"
echo "  Test: npx playwright test"
echo "  Codegen: npx playwright codegen"
echo "  Browsers: $BROWSERS"
