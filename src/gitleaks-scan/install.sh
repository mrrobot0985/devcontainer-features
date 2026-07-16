#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"
INSTALL_HOOK="${INSTALLPRECOMMITHOOK:-false}"

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

# Install gitleaks
if command -v gitleaks > /dev/null 2>&1; then
    echo "Gitleaks already installed."
    gitleaks --version 2>/dev/null || true
    exit 0
fi

echo "Installing Gitleaks..."

ARCH="x64"
case "$(uname -m)" in
    aarch64|arm64) ARCH="arm64" ;;
    x86_64) ARCH="x64" ;;
esac

if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_${VERSION}_linux_${ARCH}.tar.gz"
else
    DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_linux_${ARCH}.tar.gz"
fi

# Download and extract
curl -fsSL "$DOWNLOAD_URL" -o /tmp/gitleaks.tar.gz || {
    echo "ERROR: Failed to download Gitleaks from $DOWNLOAD_URL"
    exit 1
}

tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks
rm -f /tmp/gitleaks.tar.gz
chmod +x /usr/local/bin/gitleaks

# Verify installation
if command -v gitleaks > /dev/null 2>&1; then
    echo "Gitleaks installed: $(gitleaks --version 2>&1 || echo 'version unknown')"
else
    echo "ERROR: Gitleaks installation failed"
    exit 1
fi

# Install pre-commit hook if requested
if [ "$INSTALL_HOOK" = "true" ]; then
    if [ -d "/workspaces" ]; then
        for repo in /workspaces/*; do
            if [ -d "$repo/.git" ]; then
                echo "Installing gitleaks pre-commit hook in $repo..."
                cat > "$repo/.git/hooks/pre-commit" << 'HOOK_EOF'
#!/bin/bash
# Gitleaks pre-commit hook — scan staged changes for secrets
if command -v gitleaks > /dev/null 2>&1; then
    gitleaks protect --staged --verbose
    if [ $? -ne 0 ]; then
        echo "ERROR: Gitleaks detected potential secrets in your commit."
        echo "Review and remove secrets before committing."
        exit 1
    fi
fi
HOOK_EOF
                chmod +x "$repo/.git/hooks/pre-commit"
                chown "${USERNAME}:" "$repo/.git/hooks/pre-commit" 2>/dev/null || true
            fi
        done
    fi
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-gitleaks"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    detect)
        echo "Detecting secrets in repository..."
        gitleaks detect "$@"
        ;;
    protect)
        echo "Protecting repository from secrets..."
        gitleaks protect "$@"
        ;;
    status)
        echo "Gitleaks Secret Scanner status"
        gitleaks --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-gitleaks detect    # Scan repository"
        echo "  devcontainer-gitleaks protect   # Scan staged changes"
        echo ""
        echo "Direct usage:"
        echo "  gitleaks detect --source . --verbose"
        echo "  gitleaks protect --staged --verbose"
        ;;
    *)
        gitleaks "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Gitleaks Secret Scanner installed."
echo "  CLI: devcontainer-gitleaks"
echo "  Detect: gitleaks detect"
echo "  Protect: gitleaks protect"
echo "  Version: $(gitleaks --version 2>/dev/null || echo 'installed')"
