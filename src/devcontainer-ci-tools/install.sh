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
        version=""
    fi

    # Use the official install script which bundles its own Node.js runtime
    local install_url="https://raw.githubusercontent.com/devcontainers/cli/main/scripts/install.sh"
    echo "Downloading devcontainer CLI via official install script..."
    local install_args=""
    if [ -n "$version" ] && [ "$version" != "latest" ]; then
        install_args="--version $version"
    fi
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$install_url" | sh -s -- $install_args
    else
        wget -qO- "$install_url" | sh -s -- $install_args
    fi

    # The official script installs to ~/.devcontainer; link to /usr/local/bin
    if [ -f "${HOME}/.devcontainer/devcontainer" ]; then
        ln -sf "${HOME}/.devcontainer/devcontainer" /usr/local/bin/devcontainer
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
