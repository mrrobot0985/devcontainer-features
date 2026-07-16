#!/bin/bash
set -e

# container-security-scan install script
# Installs Trivy and a scan helper

SEVERITY="__SEVERITY__"
EXIT_CODE="__EXITCODE__"

cat > /usr/local/bin/container-security-scan <<'EOF'
#!/bin/bash
set -e

# container-security-scan — run Trivy vulnerability scan on the container
# Usage: container-security-scan [image-ref]

IMAGE="${1:-}"
SEVERITY="${TRIVY_SEVERITY:-HIGH,CRITICAL}"
EXIT_ON_FINDING="${TRIVY_EXIT_CODE:-0}"

if ! command -v trivy >/dev/null 2>&1; then
    echo "ERROR: Trivy not installed"
    exit 1
fi

if [ -z "$IMAGE" ]; then
    # Scan the current container filesystem
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
