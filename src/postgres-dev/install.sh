#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
VERSION="${VERSION:-latest}"
INSTALL_PGFORMATTER="${INSTALLPGFORMATTER:-true}"
INSTALL_PGTOP="${INSTALLPGTOP:-false}"

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

# Install PostgreSQL client tools
if command -v apt-get > /dev/null 2>&1; then
    echo "Installing PostgreSQL client tools via apt-get..."
    apt-get update

    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        apt-get install -y postgresql-client
    else
        # Try to install specific version
        if apt-cache show "postgresql-client-${VERSION}" > /dev/null 2>&1; then
            apt-get install -y "postgresql-client-${VERSION}"
        else
            echo "WARNING: postgresql-client-${VERSION} not found. Falling back to default."
            apt-get install -y postgresql-client
        fi
    fi

    # Install pgFormatter
    if [ "$INSTALL_PGFORMATTER" = "true" ]; then
        apt-get install -y pgformatter || echo "WARNING: pgFormatter not available in repository"
    fi

    # Install pgtop
    if [ "$INSTALL_PGTOP" = "true" ]; then
        apt-get install -y pgtop || echo "WARNING: pgtop not available in repository"
    fi

elif command -v dnf > /dev/null 2>&1; then
    echo "Installing PostgreSQL client tools via dnf..."
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        dnf install -y postgresql
    else
        dnf install -y "postgresql${VERSION}" || dnf install -y postgresql
    fi

    if [ "$INSTALL_PGFORMATTER" = "true" ]; then
        dnf install -y pgformatter || echo "WARNING: pgFormatter not available"
    fi

    if [ "$INSTALL_PGTOP" = "true" ]; then
        dnf install -y pgtop || echo "WARNING: pgtop not available"
    fi

elif command -v yum > /dev/null 2>&1; then
    echo "Installing PostgreSQL client tools via yum..."
    if [ "$VERSION" = "latest" ] || [ "$VERSION" = "" ]; then
        yum install -y postgresql
    else
        yum install -y "postgresql${VERSION}" || yum install -y postgresql
    fi

elif command -v apk > /dev/null 2>&1; then
    echo "Installing PostgreSQL client tools via apk..."
    apk add --no-cache postgresql-client

    if [ "$INSTALL_PGFORMATTER" = "true" ]; then
        apk add --no-cache pgformatter || echo "WARNING: pgFormatter not available"
    fi

    if [ "$INSTALL_PGTOP" = "true" ]; then
        apk add --no-cache pgtop || echo "WARNING: pgtop not available"
    fi

else
    echo "ERROR: No supported package manager found for installing PostgreSQL client tools."
    exit 1
fi

# Verify installation
if command -v psql > /dev/null 2>&1; then
    echo "psql installed: $(psql --version | head -n1)"
else
    echo "ERROR: psql installation failed"
    exit 1
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-postgres"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    connect)
        echo "Connecting to PostgreSQL..."
        psql "$@"
        ;;
    dump)
        echo "Running pg_dump..."
        pg_dump "$@"
        ;;
    restore)
        echo "Running pg_restore..."
        pg_restore "$@"
        ;;
    format)
        echo "Formatting SQL..."
        pg_format "$@"
        ;;
    monitor)
        echo "Starting pgtop..."
        pgtop "$@"
        ;;
    status)
        echo "PostgreSQL client tools status"
        psql --version 2>/dev/null || true
        pg_dump --version 2>/dev/null || true
        echo ""
        echo "Available commands:"
        echo "  psql, pg_dump, pg_restore, pg_isready, pg_basebackup"
        echo "  devcontainer-postgres connect   # Interactive psql"
        echo "  devcontainer-postgres dump      # pg_dump wrapper"
        echo "  devcontainer-postgres restore   # pg_restore wrapper"
        if command -v pg_format > /dev/null 2>&1; then
            echo "  devcontainer-postgres format    # SQL formatter"
        fi
        if command -v pgtop > /dev/null 2>&1; then
            echo "  devcontainer-postgres monitor   # Real-time monitoring"
        fi
        ;;
    *)
        psql "$COMMAND" "$@"
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "PostgreSQL Development Tools installed."
echo "  CLI: devcontainer-postgres"
echo "  psql: $(psql --version | head -n1)"
