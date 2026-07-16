#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"

# Install SonarScanner CLI
if command -v sonar-scanner > /dev/null 2>&1; then
    echo "SonarScanner already installed."
    sonar-scanner --version 2>/dev/null || true
    exit 0
fi

echo "Installing SonarScanner CLI..."

ARCH="x64"
case "$(uname -m)" in
    aarch64|arm64) ARCH="aarch64" ;;
    x86_64) ARCH="x64" ;;
esac

if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
    # Download latest
    DOWNLOAD_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.2.1.4610-linux-${ARCH}.zip"
else
    DOWNLOAD_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${VERSION}-linux-${ARCH}.zip"
fi

# Download and extract
curl -fsSL "$DOWNLOAD_URL" -o /tmp/sonar-scanner.zip || {
    echo "ERROR: Failed to download SonarScanner from $DOWNLOAD_URL"
    exit 1
}

unzip -q /tmp/sonar-scanner.zip -d /opt
rm -f /tmp/sonar-scanner.zip

# Find extracted directory
SONAR_DIR="$(find /opt -maxdepth 1 -type d -name 'sonar-scanner-*' | head -n1)"
if [ -z "$SONAR_DIR" ]; then
    echo "ERROR: Could not find extracted sonar-scanner directory"
    exit 1
fi

# Create symlinks
ln -sf "${SONAR_DIR}/bin/sonar-scanner" /usr/local/bin/sonar-scanner
ln -sf "${SONAR_DIR}/bin/sonar-scanner-debug" /usr/local/bin/sonar-scanner-debug || true

# Verify installation
if command -v sonar-scanner > /dev/null 2>&1; then
    echo "SonarScanner CLI installed."
    sonar-scanner --version 2>/dev/null || true
else
    echo "ERROR: sonar-scanner installation failed"
    exit 1
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-sonar"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    scan)
        echo "Running SonarScanner analysis..."
        sonar-scanner "$@"
        ;;
    debug)
        echo "Running SonarScanner in debug mode..."
        sonar-scanner-debug "$@"
        ;;
    status)
        echo "SonarScanner CLI status"
        sonar-scanner --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-sonar scan   # Run analysis"
        echo "  devcontainer-sonar debug  # Debug mode"
        echo ""
        echo "Environment variables:"
        echo "  SONAR_TOKEN    # Authentication token"
        echo "  SONAR_HOST_URL # Server URL"
        ;;
    *)
        sonar-scanner "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "SonarScanner CLI installed."
echo "  CLI: devcontainer-sonar"
echo "  Scan: sonar-scanner"
echo "  Version: $(sonar-scanner --version 2>/dev/null || echo 'installed')"
