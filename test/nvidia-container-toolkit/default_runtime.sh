#!/bin/bash
set -e

source dev-container-features-test-lib

check "nvidia-container-runtime exists" command -v nvidia-container-runtime
check "daemon.json exists" test -f /etc/docker/daemon.json
check "daemon.json contains nvidia runtime" bash -c 'jq -e ".runtimes.nvidia" /etc/docker/daemon.json >/dev/null'
check "daemon.json has correct runtime path" bash -c 'jq -e ".runtimes.nvidia.path == \"/usr/bin/nvidia-container-runtime\"" /etc/docker/daemon.json >/dev/null'
check "default-runtime is nvidia" bash -c 'jq -e ".\"default-runtime\" == \"nvidia\"" /etc/docker/daemon.json >/dev/null'

reportResults
