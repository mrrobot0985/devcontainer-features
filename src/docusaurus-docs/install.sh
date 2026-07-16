#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"
INIT_TEMPLATE="${INITTEMPLATE:-classic}"

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

# Install Docusaurus
if ! command -v npx > /dev/null 2>&1; then
    echo "ERROR: npx not available. Cannot install Docusaurus."
    exit 1
fi

echo "Installing Docusaurus..."
if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    npm install -g @docusaurus/core @docusaurus/preset-classic
else
    npm install -g "@docusaurus/core@${VERSION}" "@docusaurus/preset-classic@${VERSION}"
fi

# Verify installation
if command -v docusaurus > /dev/null 2>&1; then
    echo "Docusaurus CLI installed."
else
    echo "WARNING: docusaurus CLI not found in PATH after installation"
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-docusaurus"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    init)
        echo "Initializing Docusaurus site..."
        npx create-docusaurus@latest "$@"
        ;;
    start)
        echo "Starting Docusaurus development server..."
        npx docusaurus start "$@"
        ;;
    build)
        echo "Building Docusaurus site..."
        npx docusaurus build "$@"
        ;;
    serve)
        echo "Serving Docusaurus site..."
        npx docusaurus serve "$@"
        ;;
    swizzle)
        echo "Swizzling Docusaurus component..."
        npx docusaurus swizzle "$@"
        ;;
    status)
        echo "Docusaurus Documentation Site status"
        npx docusaurus --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-docusaurus init    # Initialize new site"
        echo "  devcontainer-docusaurus start   # Start dev server"
        echo "  devcontainer-docusaurus build   # Build site"
        echo "  devcontainer-docusaurus serve   # Serve built site"
        ;;
    *)
        npx docusaurus "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Docusaurus Documentation Site installed."
echo "  CLI: devcontainer-docusaurus"
echo "  Init: npx create-docusaurus@latest"
echo "  Start: npx docusaurus start"
echo "  Template: $INIT_TEMPLATE"
