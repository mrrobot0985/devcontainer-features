#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"
INSTALL_REPORTERS="${INSTALLREPORTERS:-true}"

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

# Install Newman
if ! command -v npx > /dev/null 2>&1; then
    echo "ERROR: npx not available. Cannot install Newman."
    exit 1
fi

echo "Installing Newman..."
if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    npm install -g newman
else
    npm install -g "newman@${VERSION}"
fi

# Install reporters
if [ "$INSTALL_REPORTERS" = "true" ]; then
    echo "Installing Newman reporters..."
    npm install -g newman-reporter-htmlextra || echo "WARNING: htmlextra reporter not installed"
    npm install -g newman-reporter-junit || echo "WARNING: junit reporter not installed"
fi

# Verify installation
if command -v newman > /dev/null 2>&1; then
    echo "Newman installed: $(newman --version)"
else
    echo "WARNING: newman CLI not found in PATH after installation"
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-newman"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    run)
        echo "Running Postman collection..."
        newman run "$@"
        ;;
    html)
        echo "Running collection with HTML report..."
        newman run "$@" -r htmlextra
        ;;
    junit)
        echo "Running collection with JUnit report..."
        newman run "$@" -r junit
        ;;
    status)
        echo "Postman Newman Testing status"
        newman --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-newman run collection.json      # Run collection"
        echo "  devcontainer-newman html collection.json       # Run with HTML report"
        echo "  devcontainer-newman junit collection.json      # Run with JUnit report"
        ;;
    *)
        newman "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Postman Newman Testing installed."
echo "  CLI: devcontainer-newman"
echo "  Run: newman run collection.json"
echo "  Reporters: htmlextra, junit"
