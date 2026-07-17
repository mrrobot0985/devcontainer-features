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

# MongoDB org series for apt repos (not mongosh version)
MONGO_SERIES="8.0"
if [ "$VERSION" != "latest" ] && [ -n "$VERSION" ]; then
    MONGO_SERIES="$VERSION"
fi

architecture="$(uname -m)"
case "$architecture" in
    x86_64) APT_ARCH="amd64"; TOOLS_ARCH="x86_64"; MONGOSH_ARCH="x64" ;;
    aarch64|arm64) APT_ARCH="arm64"; TOOLS_ARCH="aarch64"; MONGOSH_ARCH="arm64" ;;
    *) APT_ARCH="amd64"; TOOLS_ARCH="x86_64"; MONGOSH_ARCH="x64" ;;
esac

http_ok() {
    # Return 0 if URL responds 2xx/3xx
    local url="$1"
    if command -v curl > /dev/null 2>&1; then
        curl -fsI "$url" > /dev/null 2>&1
    elif command -v wget > /dev/null 2>&1; then
        wget -q --spider "$url" > /dev/null 2>&1
    else
        return 1
    fi
}

download_file() {
    local url="$1"
    local dest="$2"
    if command -v curl > /dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest"
    elif command -v wget > /dev/null 2>&1; then
        wget -qO "$dest" "$url"
    else
        return 1
    fi
}

install_mongosh_from_tarball() {
    echo "Falling back to mongosh binary download..."
    local version_tag tarball_url tmpdir mongosh_bin
    version_tag=""
    if command -v curl > /dev/null 2>&1; then
        version_tag="$(curl -fsSL "https://api.github.com/repos/mongodb-js/mongosh/releases/latest" 2>/dev/null | sed -n 's/.*"tag_name": *"v\?\([^"]*\)".*/\1/p' | head -n1 || true)"
    fi
    if [ -z "$version_tag" ]; then
        version_tag="2.9.2"
    fi
    tarball_url="https://github.com/mongodb-js/mongosh/releases/download/v${version_tag}/mongosh-${version_tag}-linux-${MONGOSH_ARCH}.tgz"
    tmpdir="$(mktemp -d)"
    if download_file "$tarball_url" "${tmpdir}/mongosh.tgz"; then
        tar -xzf "${tmpdir}/mongosh.tgz" -C "$tmpdir"
        mongosh_bin="$(find "$tmpdir" -type f -name mongosh | head -n1)"
        if [ -n "$mongosh_bin" ]; then
            cp "$mongosh_bin" /usr/local/bin/mongosh
            chmod +x /usr/local/bin/mongosh
            echo "mongosh installed from GitHub release v${version_tag}"
        fi
    else
        echo "WARNING: mongosh binary download failed from ${tarball_url}"
    fi
    rm -rf "$tmpdir"
}

install_tools_from_tarball() {
    echo "Falling back to MongoDB Database Tools binary download..."
    # Prefer Ubuntu 22.04 packages; tools are mostly statically linked / portable enough
    local tools_ver candidates url tmpdir extracted
    tools_ver="100.12.2"
    candidates=(
        "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-${TOOLS_ARCH}-${tools_ver}.tgz"
        "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2404-${TOOLS_ARCH}-${tools_ver}.tgz"
        "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2004-${TOOLS_ARCH}-${tools_ver}.tgz"
    )
    tmpdir="$(mktemp -d)"
    for url in "${candidates[@]}"; do
        if download_file "$url" "${tmpdir}/tools.tgz"; then
            tar -xzf "${tmpdir}/tools.tgz" -C "$tmpdir"
            extracted="$(find "$tmpdir" -type d -name 'mongodb-database-tools-*' | head -n1)"
            if [ -n "$extracted" ] && [ -d "${extracted}/bin" ]; then
                cp "${extracted}/bin/"* /usr/local/bin/
                chmod +x /usr/local/bin/mongodump /usr/local/bin/mongorestore /usr/local/bin/mongoimport /usr/local/bin/mongoexport 2>/dev/null || true
                echo "MongoDB Database Tools installed from ${url}"
                rm -rf "$tmpdir"
                return 0
            fi
        fi
    done
    echo "WARNING: MongoDB Database Tools binary download failed"
    rm -rf "$tmpdir"
    return 0
}

setup_mongodb_apt_repo() {
    local os_id os_codename repo_distro series key_url list_file keyring candidates c release_url
    os_id="$(. /etc/os-release && echo "$ID")"
    os_codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    series="$MONGO_SERIES"

    case "$os_id" in
        ubuntu) repo_distro="ubuntu" ;;
        debian) repo_distro="debian" ;;
        *)
            echo "WARNING: Unsupported apt distro '${os_id}' for MongoDB repo"
            return 1
            ;;
    esac

    # Probe for a codename MongoDB actually publishes (e.g. resolute is too new)
    candidates=("$os_codename")
    if [ "$repo_distro" = "ubuntu" ]; then
        candidates+=("noble" "jammy" "focal")
    else
        candidates+=("bookworm" "bullseye")
    fi

    REPO_CODENAME=""
    for c in "${candidates[@]}"; do
        [ -z "$c" ] && continue
        release_url="https://repo.mongodb.org/apt/${repo_distro}/dists/${c}/mongodb-org/${series}/Release"
        if http_ok "$release_url"; then
            REPO_CODENAME="$c"
            break
        fi
    done

    # If requested series is unavailable, try 8.0 then 7.0 on known codenames
    if [ -z "$REPO_CODENAME" ]; then
        for series in "8.0" "7.0"; do
            for c in "${candidates[@]}"; do
                [ -z "$c" ] && continue
                release_url="https://repo.mongodb.org/apt/${repo_distro}/dists/${c}/mongodb-org/${series}/Release"
                if http_ok "$release_url"; then
                    REPO_CODENAME="$c"
                    MONGO_SERIES="$series"
                    break 2
                fi
            done
        done
    fi

    if [ -z "$REPO_CODENAME" ]; then
        echo "WARNING: No matching MongoDB apt repository found for ${os_id}/${os_codename}"
        return 1
    fi

    if [ "$REPO_CODENAME" != "$os_codename" ]; then
        echo "MongoDB has no repo for ${os_codename}; using ${REPO_CODENAME}/mongodb-org/${MONGO_SERIES}"
    else
        echo "Using MongoDB repo ${repo_distro} ${REPO_CODENAME}/mongodb-org/${MONGO_SERIES}"
    fi

    apt-get install -y --no-install-recommends ca-certificates curl gnupg > /dev/null

    key_url="https://pgp.mongodb.com/server-${MONGO_SERIES}.asc"
    if ! http_ok "$key_url"; then
        key_url="https://www.mongodb.org/static/pgp/server-${MONGO_SERIES}.asc"
    fi

    keyring="/usr/share/keyrings/mongodb-server-${MONGO_SERIES}.gpg"
    mkdir -p /usr/share/keyrings
    rm -f "$keyring"
    curl -fsSL "$key_url" | gpg --dearmor -o "$keyring"
    chmod 644 "$keyring"

    list_file="/etc/apt/sources.list.d/mongodb-org-${MONGO_SERIES}.list"
    echo "deb [ arch=${APT_ARCH} signed-by=${keyring} ] https://repo.mongodb.org/apt/${repo_distro} ${REPO_CODENAME}/mongodb-org/${MONGO_SERIES} multiverse" > "$list_file"

    if ! apt-get update; then
        echo "WARNING: apt-get update failed after adding MongoDB repo; removing it"
        rm -f "$list_file"
        apt-get update || true
        return 1
    fi
    return 0
}

# Install MongoDB tools
if command -v apt-get > /dev/null 2>&1; then
    echo "Installing MongoDB tools via apt-get..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update

    # Prefer packages already in the distro
    if apt-cache show mongodb-mongosh > /dev/null 2>&1 || apt-cache show mongosh > /dev/null 2>&1; then
        apt-get install -y mongodb-mongosh 2>/dev/null || apt-get install -y mongosh || true
        if [ "$INSTALL_TOOLS" = "true" ]; then
            apt-get install -y mongodb-database-tools 2>/dev/null || true
        fi
    fi

    # Add official MongoDB repository when packages are missing
    if ! command -v mongosh > /dev/null 2>&1; then
        if setup_mongodb_apt_repo; then
            apt-get install -y mongodb-mongosh || apt-get install -y mongosh || true
            if [ "$INSTALL_TOOLS" = "true" ]; then
                apt-get install -y mongodb-database-tools || true
            fi
        fi
    elif [ "$INSTALL_TOOLS" = "true" ] && ! command -v mongodump > /dev/null 2>&1; then
        if setup_mongodb_apt_repo; then
            apt-get install -y mongodb-database-tools || true
        fi
    fi

    # Binary fallbacks if apt path did not deliver tools
    if ! command -v mongosh > /dev/null 2>&1; then
        install_mongosh_from_tarball
    fi
    if [ "$INSTALL_TOOLS" = "true" ] && ! command -v mongodump > /dev/null 2>&1; then
        install_tools_from_tarball
    fi

elif command -v dnf > /dev/null 2>&1; then
    echo "Installing MongoDB tools via dnf..."
    dnf install -y mongodb-mongosh || true
    if [ "$INSTALL_TOOLS" = "true" ]; then
        dnf install -y mongodb-database-tools || true
    fi
    if ! command -v mongosh > /dev/null 2>&1; then
        install_mongosh_from_tarball
    fi
    if [ "$INSTALL_TOOLS" = "true" ] && ! command -v mongodump > /dev/null 2>&1; then
        install_tools_from_tarball
    fi

elif command -v yum > /dev/null 2>&1; then
    echo "Installing MongoDB tools via yum..."
    yum install -y mongodb-mongosh || true
    if [ "$INSTALL_TOOLS" = "true" ]; then
        yum install -y mongodb-database-tools || true
    fi
    if ! command -v mongosh > /dev/null 2>&1; then
        install_mongosh_from_tarball
    fi
    if [ "$INSTALL_TOOLS" = "true" ] && ! command -v mongodump > /dev/null 2>&1; then
        install_tools_from_tarball
    fi

elif command -v apk > /dev/null 2>&1; then
    echo "Installing MongoDB tools via apk..."
    apk add --no-cache mongosh || true
    if ! command -v mongosh > /dev/null 2>&1; then
        install_mongosh_from_tarball
    fi
    if [ "$INSTALL_TOOLS" = "true" ] && ! command -v mongodump > /dev/null 2>&1; then
        install_tools_from_tarball
    fi

else
    echo "No supported package manager found. Attempting binary download..."
    install_mongosh_from_tarball
    if [ "$INSTALL_TOOLS" = "true" ]; then
        install_tools_from_tarball
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
