#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"
RUNNER_IMAGE="${RUNNERIMAGE:-medium}"
CONFIGURE_DOCKER="${CONFIGUREDOCKER:-true}"

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

# Install act
if ! command -v act > /dev/null 2>&1; then
    echo "Installing act (GitHub Actions local runner)..."

    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        # Install latest via official script
        curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s -- -b /usr/local/bin
    else
        # Install specific version
        ARCH="x86_64"
        case "$(uname -m)" in
            aarch64|arm64) ARCH="arm64" ;;
            x86_64) ARCH="x86_64" ;;
        esac

        DOWNLOAD_URL="https://github.com/nektos/act/releases/download/v${VERSION}/act_Linux_${ARCH}.tar.gz"
        curl -fsSL "$DOWNLOAD_URL" -o /tmp/act.tar.gz
        tar -xzf /tmp/act.tar.gz -C /usr/local/bin/ act
        rm -f /tmp/act.tar.gz
        chmod +x /usr/local/bin/act
    fi

    echo "act installed."
else
    echo "act already installed."
fi

# Verify installation
act --version

# Configure Docker access for act
if [ "$CONFIGURE_DOCKER" = "true" ]; then
    echo "Configuring Docker access for act..."

    # Ensure Docker CLI is available
    if ! command -v docker > /dev/null 2>&1; then
        echo "WARNING: Docker CLI not found. Install docker-in-docker feature for act to work."
    fi

    # Write .actrc with runner image configuration
    ACTRC="${USER_HOME}/.actrc"
    case "$RUNNER_IMAGE" in
        micro)
            echo "-P ubuntu-latest=node:16-buster-slim" > "$ACTRC"
            echo "-P ubuntu-22.04=node:16-buster-slim" >> "$ACTRC"
            ;;
        medium)
            echo "-P ubuntu-latest=catthehacker/ubuntu:act-latest" > "$ACTRC"
            echo "-P ubuntu-22.04=catthehacker/ubuntu:act-22.04" >> "$ACTRC"
            ;;
        large)
            echo "-P ubuntu-latest=catthehacker/ubuntu:full-latest" > "$ACTRC"
            echo "-P ubuntu-22.04=catthehacker/ubuntu:full-22.04" >> "$ACTRC"
            ;;
        *)
            echo "WARNING: Unknown runner image '$RUNNER_IMAGE'. Using medium."
            echo "-P ubuntu-latest=catthehacker/ubuntu:act-latest" > "$ACTRC"
            echo "-P ubuntu-22.04=catthehacker/ubuntu:act-22.04" >> "$ACTRC"
            ;;
    esac

    if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
        chown "${USERNAME}:" "$ACTRC" 2>/dev/null || true
    fi

    echo "act configuration written to $ACTRC"
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-act"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-run}"
shift || true

case "$COMMAND" in
    run)
        echo "Running GitHub Actions locally with act..."
        act "$@"
        ;;
    list)
        echo "Available workflows and jobs:"
        act -l "$@"
        ;;
    secrets)
        echo "Running with secrets file..."
        act --secret-file .secrets "$@"
        ;;
    status)
        echo "act status"
        act --version
        echo ""
        echo "Runner images configured in ~/.actrc:"
        cat "${HOME}/.actrc" 2>/dev/null || echo "  No .actrc found"
        ;;
    *)
        act "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

# Add shell aliases
for PROFILE in "${USER_HOME}/.bashrc" "${USER_HOME}/.zshrc"; do
    if [ -f "$PROFILE" ]; then
        if ! grep -q "devcontainer-act" "$PROFILE" 2>/dev/null; then
            echo "alias act-local='devcontainer-act'" >> "$PROFILE"
        fi
    fi
done

echo "GitHub Actions Local Runner (act) installed."
echo "  CLI: devcontainer-act"
echo "  Run: act"
echo "  List: act -l"
echo "  Runner image: $RUNNER_IMAGE"
