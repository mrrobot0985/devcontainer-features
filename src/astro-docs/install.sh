#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"
INSTALL_TYPESCRIPT="${INSTALLTYPESCRIPT:-true}"

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

# Install Astro
if ! command -v npx > /dev/null 2>&1; then
    echo "ERROR: npx not available. Cannot install Astro."
    exit 1
fi

echo "Installing Astro..."
if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    npm install -g astro
else
    npm install -g "astro@${VERSION}"
fi

# Install TypeScript support
if [ "$INSTALL_TYPESCRIPT" = "true" ]; then
    echo "Installing TypeScript support..."
    npm install -g typescript || echo "WARNING: TypeScript not installed"
fi

# Verify installation
if command -v astro > /dev/null 2>&1; then
    echo "Astro CLI installed."
else
    echo "WARNING: astro CLI not found in PATH after installation"
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-astro"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    dev)
        echo "Starting Astro development server..."
        npx astro dev "$@"
        ;;
    build)
        echo "Building Astro site..."
        npx astro build "$@"
        ;;
    preview)
        echo "Previewing Astro site..."
        npx astro preview "$@"
        ;;
    check)
        echo "Running Astro type check..."
        npx astro check "$@"
        ;;
    status)
        echo "Astro Static Site status"
        npx astro --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-astro dev     # Start dev server"
        echo "  devcontainer-astro build   # Build site"
        echo "  devcontainer-astro preview # Preview built site"
        echo "  devcontainer-astro check # Type check"
        ;;
    *)
        npx astro "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Astro Static Site installed."
echo "  CLI: devcontainer-astro"
echo "  Dev: npx astro dev"
echo "  Build: npx astro build"
