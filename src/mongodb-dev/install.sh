#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"
INSTALL_TOOLS="${INSTALLTOOLS:-true}"

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

# Install MongoDB tools
if command -v apt-get > /dev/null 2>&1; then
    echo "Installing MongoDB tools via apt-get..."
    apt-get update

    # Try to install mongosh and tools from MongoDB repository or default repo
    if apt-cache show mongosh > /dev/null 2>&1; then
        apt-get install -y mongosh
    else
        # Try adding MongoDB repository
        if command -v wget > /dev/null 2>&1 || command -v curl > /dev/null 2>&1; then
            echo "Adding MongoDB repository..."
            wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add - 2>/dev/null || \
                curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add - 2>/dev/null || \
                echo "WARNING: Could not add MongoDB GPG key"

            OS_CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
            if [ -n "$OS_CODENAME" ]; then
                echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu ${OS_CODENAME}/mongodb-org/7.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-7.0.list
                apt-get update
                apt-get install -y mongosh || echo "WARNING: mongosh not available"
                if [ "$INSTALL_TOOLS" = "true" ]; then
                    apt-get install -y mongodb-database-tools || echo "WARNING: MongoDB tools not available"
                fi
            fi
        else
            echo "WARNING: Cannot add MongoDB repository"
        fi
    fi

    # Fallback: try mongodb-clients or mongodb-org-tools
    if ! command -v mongosh > /dev/null 2>&1; then
        apt-get install -y mongodb-clients || apt-get install -y mongodb-org-shell || echo "WARNING: mongosh installation failed"
    fi

elif command -v dnf > /dev/null 2>&1; then
    echo "Installing MongoDB tools via dnf..."
    dnf install -y mongodb-mongosh || echo "WARNING: mongosh not available"
    if [ "$INSTALL_TOOLS" = "true" ]; then
        dnf install -y mongodb-database-tools || echo "WARNING: MongoDB tools not available"
    fi

elif command -v yum > /dev/null 2>&1; then
    echo "Installing MongoDB tools via yum..."
    yum install -y mongodb-mongosh || echo "WARNING: mongosh not available"
    if [ "$INSTALL_TOOLS" = "true" ]; then
        yum install -y mongodb-database-tools || echo "WARNING: MongoDB tools not available"
    fi

elif command -v apk > /dev/null 2>&1; then
    echo "Installing MongoDB tools via apk..."
    apk add --no-cache mongosh || echo "WARNING: mongosh not available"

else
    echo "WARNING: No supported package manager found. Attempting binary download..."

    ARCH="x86_64"
    case "$(uname -m)" in
        aarch64|arm64) ARCH="aarch64" ;;
        x86_64) ARCH="x86_64" ;;
    esac

    MONGO_VERSION="7.0"
    if [ "$VERSION" != "latest" ] && [ "$VERSION" != "" ]; then
        MONGO_VERSION="$VERSION"
    fi

    MONGO_URL="https://downloads.mongodb.com/compass/mongosh-${MONGO_VERSION}-linux-${ARCH}.tgz"
    curl -fsSL "$MONGO_URL" -o /tmp/mongosh.tgz || echo "WARNING: mongosh binary download failed"
    if [ -f /tmp/mongosh.tgz ]; then
        tar -xzf /tmp/mongosh.tgz -C /tmp
        cp /tmp/mongosh-*/bin/mongosh /usr/local/bin/mongosh 2>/dev/null || true
        chmod +x /usr/local/bin/mongosh 2>/dev/null || true
        rm -rf /tmp/mongosh*
    fi
fi

# Verify mongosh
if command -v mongosh > /dev/null 2>&1; then
    echo "mongosh installed: $(mongosh --version 2>&1 || echo 'version unknown')"
else
    echo "WARNING: mongosh not found after installation"
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-mongodb"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    connect)
        echo "Connecting to MongoDB..."
        mongosh "$@"
        ;;
    dump)
        echo "Running mongodump..."
        mongodump "$@"
        ;;
    restore)
        echo "Running mongorestore..."
        mongorestore "$@"
        ;;
    import)
        echo "Running mongoimport..."
        mongoimport "$@"
        ;;
    export)
        echo "Running mongoexport..."
        mongoexport "$@"
        ;;
    status)
        echo "MongoDB Development Tools status"
        mongosh --version 2>/dev/null || true
        echo ""
        echo "Available commands:"
        echo "  mongosh, mongodump, mongorestore, mongoimport, mongoexport"
        echo "  devcontainer-mongodb connect   # Interactive mongosh"
        echo "  devcontainer-mongodb dump    # mongodump wrapper"
        echo "  devcontainer-mongodb restore # mongorestore wrapper"
        echo "  devcontainer-mongodb import  # mongoimport wrapper"
        echo "  devcontainer-mongodb export  # mongoexport wrapper"
        ;;
    *)
        mongosh "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "MongoDB Development Tools installed."
echo "  CLI: devcontainer-mongodb"
echo "  mongosh: $(mongosh --version 2>/dev/null || echo 'installed')"
