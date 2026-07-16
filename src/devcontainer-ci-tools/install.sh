#!/bin/bash
set -e

# devcontainer-ci-tools install script
# Installs devcontainer CLI, docker-buildx, and act.

DEVCONTAINER_CLI_VERSION="__DEVCONTAINERCLIVERSION__"
INSTALL_ACT="__INSTALLACT__"
INSTALL_BUILDX="__INSTALLBUILDX__"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    arm64) ARCH="arm64" ;;
esac

install_nodejs() {
    echo "=== Installing Node.js ==="
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        echo "Node.js already installed: $(node --version)"
        return
    fi

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y --no-install-recommends curl ca-certificates
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y --no-install-recommends nodejs
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache nodejs npm curl ca-certificates
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl
        curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
        yum install -y nodejs
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y curl
        curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
        dnf install -y nodejs
    else
        echo "WARN [devcontainer-ci-tools]: No supported package manager found for Node.js; skipping devcontainer CLI."
        return 1
    fi
}

install_devcontainer_cli() {
    echo "=== Installing devcontainer CLI ==="
    if ! command -v npm >/dev/null 2>&1; then
        if ! install_nodejs; then
            echo "WARN [devcontainer-ci-tools]: Node.js not available; skipping devcontainer CLI."
            return
        fi
    fi

    local version="$DEVCONTAINER_CLI_VERSION"
    if [ "$version" = "latest" ] || [ -z "$version" ]; then
        npm install -g @devcontainers/cli
    else
        npm install -g "@devcontainers/cli@${version}"
    fi

    if command -v devcontainer >/dev/null 2>&1; then
        echo "devcontainer CLI installed: $(devcontainer --version)"
    else
        echo "WARN [devcontainer-ci-tools]: devcontainer CLI not found in PATH after install."
    fi
}

install_buildx() {
    echo "=== Installing docker-buildx ==="
    if command -v docker >/dev/null 2>&1; then
        local buildx_version
        buildx_version=$(curl -fsSL https://api.github.com/repos/docker/buildx/releases/latest | grep -oP '"tag_name": "\K[^"]+' || true)
        if [ -z "$buildx_version" ]; then
            buildx_version="v0.18.0"
        fi

        local plugin_dir="${HOME}/.docker/cli-plugins"
        mkdir -p "$plugin_dir"

        local url="https://github.com/docker/buildx/releases/download/${buildx_version}/buildx-${buildx_version}.linux-${ARCH}"
        curl -fsSL "$url" -o "$plugin_dir/docker-buildx"
        chmod +x "$plugin_dir/docker-buildx"
        echo "docker-buildx installed: ${buildx_version}"
    else
        echo "WARN [devcontainer-ci-tools]: Docker not available; skipping docker-buildx installation."
    fi
}

install_act() {
    echo "=== Installing act ==="
    local act_version
    act_version=$(curl -fsSL https://api.github.com/repos/nektos/act/releases/latest | grep -oP '"tag_name": "\K[^"]+' || true)
    if [ -z "$act_version" ]; then
        act_version="v0.2.70"
    fi

    local url="https://github.com/nektos/act/releases/download/${act_version}/act_Linux_${ARCH}.tar.gz"
    curl -fsSL "$url" | tar -xzv -C /usr/local/bin act
    chmod +x /usr/local/bin/act
    echo "act installed: $(act --version)"
}

main() {
    install_devcontainer_cli

    if [ "$INSTALL_BUILDX" = "true" ]; then
        install_buildx
    fi

    if [ "$INSTALL_ACT" = "true" ]; then
        install_act
    fi

    echo "=== Devcontainer CI Tools complete ==="
}

main
