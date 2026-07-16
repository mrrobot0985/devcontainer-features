#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"

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

# Install VitePress
if ! command -v npx > /dev/null 2>&1; then
    echo "ERROR: npx not available. Cannot install VitePress."
    exit 1
fi

echo "Installing VitePress..."
if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    npm install -g vitepress
else
    npm install -g "vitepress@${VERSION}"
fi

# Verify installation
if command -v vitepress > /dev/null 2>&1; then
    echo "VitePress CLI installed."
else
    echo "WARNING: vitepress CLI not found in PATH after installation"
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-vitepress"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    init)
        echo "Initializing VitePress site..."
        npx vitepress init "$@"
        ;;
    dev)
        echo "Starting VitePress development server..."
        npx vitepress dev "$@"
        ;;
    build)
        echo "Building VitePress site..."
        npx vitepress build "$@"
        ;;
    preview)
        echo "Previewing VitePress site..."
        npx vitepress preview "$@"
        ;;
    status)
        echo "VitePress Documentation Site status"
        npx vitepress --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-vitepress init    # Initialize new site"
        echo "  devcontainer-vitepress dev     # Start dev server"
        echo "  devcontainer-vitepress build   # Build site"
        echo "  devcontainer-vitepress preview # Preview built site"
        ;;
    *)
        npx vitepress "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "VitePress Documentation Site installed."
echo "  CLI: devcontainer-vitepress"
echo "  Init: npx vitepress init"
echo "  Dev: npx vitepress dev"
