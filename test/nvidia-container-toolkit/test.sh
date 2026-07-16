#!/bin/bash
set -e

source dev-container-features-test-lib

# The feature auto-skips when no NVIDIA GPU is present.
# Tests must handle both GPU and non-GPU environments gracefully.

if [ -c /dev/nvidia0 ] || { command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; }; then
    echo "GPU detected — verifying installation"
    check "nvidia-container-runtime exists" command -v nvidia-container-runtime
    check "daemon.json exists" test -f /etc/docker/daemon.json
    check "daemon.json contains nvidia runtime" bash -c 'jq -e ".runtimes.nvidia" /etc/docker/daemon.json >/dev/null'
    check "daemon.json has nvidia runtime path" bash -c 'jq -e ".runtimes.nvidia.path | length > 0" /etc/docker/daemon.json >/dev/null'
else
    echo "No GPU detected — verifying graceful skip"
    check "nvidia-container-runtime not installed" bash -c "! command -v nvidia-container-runtime"
    check "daemon.json not modified with nvidia" bash -c "! test -f /etc/docker/daemon.json || ! jq -e '.runtimes.nvidia' /etc/docker/daemon.json >/dev/null 2>&1"
fi

reportResults
