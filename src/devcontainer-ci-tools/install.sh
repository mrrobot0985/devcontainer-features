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

install_devcontainer_cli() {
    echo "=== Installing devcontainer CLI ==="
    local version="$DEVCONTAINER_CLI_VERSION"
    if [ "$version" = "latest" ]; then
        version=$(curl -fsSL https://api.github.com/repos/devcontainers/cli/releases/latest | grep -oP '"tag_name": "\K[^"]+' || true)
        if [ -z "$version" ]; then
            echo "WARN [devcontainer-ci-tools]: Could not fetch latest version; falling back to v0.73.0"
            version="v0.73.0"
        fi
    fi

    local url="https://github.com/devcontainers/cli/releases/download/${version}/devcontainer-${ARCH}-linux.tar.gz"
    echo "Downloading devcontainer CLI ${version} for ${ARCH}..."
    curl -fsSL "$url" | tar -xzv -C /usr/local/bin devcontainer
    chmod +x /usr/local/bin/devcontainer
    echo "devcontainer CLI installed: $(devcontainer --version)"
}

install_buildx() {
    echo "=== Installing docker-buildx ==="
    if command -v docker >/dev/null 2>&1; then
        # buildx is typically installed as a Docker CLI plugin
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
