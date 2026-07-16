#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"

# Install Git LFS
if command -v git-lfs > /dev/null 2>&1; then
    echo "Git LFS already installed."
    git-lfs --version 2>/dev/null || true
    exit 0
fi

echo "Installing Git LFS..."

if command -v apt-get > /dev/null 2>&1; then
    apt-get update
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        apt-get install -y git-lfs
    else
        apt-get install -y "git-lfs=${VERSION}" || apt-get install -y git-lfs
    fi
elif command -v dnf > /dev/null 2>&1; then
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        dnf install -y git-lfs
    else
        dnf install -y "git-lfs-${VERSION}" || dnf install -y git-lfs
    fi
elif command -v yum > /dev/null 2>&1; then
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        yum install -y git-lfs
    else
        yum install -y "git-lfs-${VERSION}" || yum install -y git-lfs
    fi
elif command -v apk > /dev/null 2>&1; then
    apk add --no-cache git-lfs
else
    echo "ERROR: No supported package manager found for installing Git LFS."
    exit 1
fi

# Initialize Git LFS
git lfs install --system || echo "WARNING: Git LFS system-wide initialization failed"

# Verify installation
if command -v git-lfs > /dev/null 2>&1; then
    echo "Git LFS installed: $(git-lfs --version 2>&1 | head -n1 || echo 'version unknown')"
else
    echo "ERROR: Git LFS installation failed"
    exit 1
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-git-lfs"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    track)
        echo "Tracking files with Git LFS..."
        git lfs track "$@"
        ;;
    untrack)
        echo "Untracking files..."
        git lfs untrack "$@"
        ;;
    status)
        echo "Git LFS status"
        git lfs status "$@"
        ;;
    version)
        echo "Git LFS version"
        git-lfs --version 2>/dev/null || true
        echo ""
        echo "Usage:"
        echo "  devcontainer-git-lfs track '*.psd'   # Track file pattern"
        echo "  devcontainer-git-lfs untrack '*.psd' # Untrack file pattern"
        echo "  devcontainer-git-lfs status          # Show LFS status"
        ;;
    *)
        git lfs "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Git Large File Storage installed."
echo "  CLI: devcontainer-git-lfs"
echo "  Track: git lfs track"
echo "  Version: $(git-lfs --version 2>/dev/null | head -n1 || echo 'installed')"
