#!/bin/sh
set -e

echo "Activating feature 'nvidia-container-toolkit'"

ENABLE="${ENABLE:-true}"

if [ "$ENABLE" = "false" ]; then
    echo "Feature is disabled (enable=false). Skipping NVIDIA Container Toolkit installation."
    exit 0
fi

DEFAULT_RUNTIME="${DEFAULTRUNTIME:-false}"
RESTART_DOCKERD="${RESTARTDOCKERD:-true}"

# Only apt-based systems are supported in v1
install_nvidia_container_toolkit() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y --no-install-recommends curl ca-certificates gnupg lsb-release jq

        # Add NVIDIA GPG key
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
            | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

        # Add NVIDIA repository
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
            | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
            | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

        apt-get update
        apt-get install -y --no-install-recommends nvidia-container-toolkit
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    else
        echo "ERROR: nvidia-container-toolkit installation is only supported on apt-based systems in this version"
        exit 1
    fi
}

# Install the toolkit if not already present
if ! command -v nvidia-container-runtime >/dev/null 2>&1; then
    echo "Installing NVIDIA Container Toolkit..."
    install_nvidia_container_toolkit
else
    echo "NVIDIA Container Toolkit already installed"
    # Ensure jq is available for daemon.json manipulation
    if ! command -v jq >/dev/null 2>&1; then
        apt-get update
        apt-get install -y --no-install-recommends jq
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    fi
fi

# Configure Docker daemon
echo "Configuring Docker daemon with NVIDIA runtime..."

mkdir -p /etc/docker

if [ -f /etc/docker/daemon.json ]; then
    echo "Existing daemon.json found, merging NVIDIA runtime configuration..."

    if [ "$DEFAULT_RUNTIME" = "true" ]; then
        jq '.runtimes.nvidia = { path: "/usr/bin/nvidia-container-runtime", runtimeArgs: [] } | ."default-runtime" = "nvidia"' \
            /etc/docker/daemon.json > /etc/docker/daemon.json.tmp \
            && mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
    else
        jq '.runtimes.nvidia = { path: "/usr/bin/nvidia-container-runtime", runtimeArgs: [] } | del(."default-runtime")' \
            /etc/docker/daemon.json > /etc/docker/daemon.json.tmp \
            && mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
    fi
else
    if [ "$DEFAULT_RUNTIME" = "true" ]; then
        cat > /etc/docker/daemon.json << 'EOF'
{
  "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "default-runtime": "nvidia"
}
EOF
    else
        cat > /etc/docker/daemon.json << 'EOF'
{
  "runtimes": {
    "nvidia": {
      "path": "/usr/bin/nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
EOF
    fi
fi

# Validate JSON
if ! jq empty /etc/docker/daemon.json >/dev/null 2>&1; then
    echo "ERROR: Generated daemon.json is not valid JSON"
    exit 1
fi

echo "Docker daemon configuration updated"

# Restart dockerd if requested and running
if [ "$RESTART_DOCKERD" = "true" ]; then
    if pgrep -x dockerd >/dev/null 2>&1 || pgrep -f "dockerd" >/dev/null 2>&1; then
        echo "Reloading dockerd to apply new runtime configuration..."
        pkill -SIGHUP dockerd >/dev/null 2>&1 || true
        sleep 2

        if pgrep -x dockerd >/dev/null 2>&1 || pgrep -f "dockerd" >/dev/null 2>&1; then
            echo "dockerd reloaded successfully"
        else
            echo "WARNING: dockerd may have exited after SIGHUP. It will be restarted by the docker-in-docker init script."
        fi
    else
        echo "dockerd is not currently running. The NVIDIA runtime will be available when dockerd starts."
    fi
else
    echo "dockerd reload skipped (restartDockerd=false). The NVIDIA runtime will be available after the next dockerd restart."
fi

echo "NVIDIA Container Toolkit feature installation complete"
