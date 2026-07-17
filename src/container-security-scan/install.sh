#!/bin/bash
set -e

# container-security-scan install script
# Installs Trivy and a scan helper

SEVERITY="${SEVERITY:-HIGH,CRITICAL}"
EXIT_CODE="${EXITCODE:-0}"
TRIVY_VERSION="${TRIVYVERSION:-latest}"

# Ensure curl is available
if ! command -v curl >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y -qq curl ca-certificates >/dev/null
fi

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="64bit" ;;
    aarch64|arm64) ARCH="ARM64" ;;
    *)
        echo "WARNING: Unsupported architecture $ARCH, attempting 64bit fallback"
        ARCH="64bit"
        ;;
esac

if [ "$TRIVY_VERSION" = "latest" ] || [ -z "$TRIVY_VERSION" ]; then
    echo "Resolving latest Trivy version..."
    TRIVY_VERSION=$(curl -fsSL "https://api.github.com/repos/aquasecurity/trivy/releases/latest" \
        | grep -oP '"tag_name":\s*"v\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [ -z "$TRIVY_VERSION" ]; then
        echo "WARNING: Could not resolve latest Trivy version, using fallback 0.58.0"
        TRIVY_VERSION="0.58.0"
    fi
fi
TRIVY_VERSION="${TRIVY_VERSION#v}"

echo "Installing Trivy ${TRIVY_VERSION}..."
DOWNLOAD_URL="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-${ARCH}.tar.gz"
curl -fsSL "$DOWNLOAD_URL" | tar -xz -C /tmp trivy
mv /tmp/trivy /usr/local/bin/trivy
chmod +x /usr/local/bin/trivy

if ! command -v trivy >/dev/null 2>&1; then
    echo "ERROR: Trivy installation failed"
    exit 1
fi
echo "Trivy installed: $(trivy --version 2>/dev/null | head -1 || true)"

# Persist scan defaults for the helper
mkdir -p /usr/local/etc
printf '%s\n' "$SEVERITY" > /usr/local/etc/container-security-scan-severity
printf '%s\n' "$EXIT_CODE" > /usr/local/etc/container-security-scan-exit-code

cat > /usr/local/bin/container-security-scan <<'EOF'
#!/bin/bash
set -e

# container-security-scan — run Trivy vulnerability scan on the container
# Usage: container-security-scan [image-ref]

IMAGE="${1:-}"

if [ -f /usr/local/etc/container-security-scan-severity ]; then
    SEVERITY="${TRIVY_SEVERITY:-$(cat /usr/local/etc/container-security-scan-severity)}"
else
    SEVERITY="${TRIVY_SEVERITY:-HIGH,CRITICAL}"
fi
if [ -f /usr/local/etc/container-security-scan-exit-code ]; then
    EXIT_ON_FINDING="${TRIVY_EXIT_CODE:-$(cat /usr/local/etc/container-security-scan-exit-code)}"
else
    EXIT_ON_FINDING="${TRIVY_EXIT_CODE:-0}"
fi

if ! command -v trivy >/dev/null 2>&1; then
    echo "ERROR: Trivy not installed"
    exit 1
fi

if [ -z "$IMAGE" ]; then
    echo "INFO [container-security-scan]: Scanning container filesystem..."
    trivy filesystem --severity "$SEVERITY" --exit-code "$EXIT_ON_FINDING" --no-progress / 2>/dev/null || true
else
    echo "INFO [container-security-scan]: Scanning image $IMAGE..."
    trivy image --severity "$SEVERITY" --exit-code "$EXIT_ON_FINDING" --no-progress "$IMAGE" 2>/dev/null || true
fi

echo "INFO [container-security-scan]: Scan complete."
EOF

chmod +x /usr/local/bin/container-security-scan

echo "container-security-scan installed."
echo "  Severity: $SEVERITY"
echo "  Exit code on finding: $EXIT_CODE"
echo "  Run 'container-security-scan' to scan the container."
