#!/usr/bin/env bash
set -euo pipefail

echo "Running container-resource-limits tests..."

# Test: helper CLI exists
if ! command -v devcontainer-resource-limits > /dev/null 2>&1; then
    echo "FAILED: devcontainer-resource-limits helper not found"
    exit 1
fi
echo "OK — helper CLI exists"

# Test: apply limits without error
if ! devcontainer-resource-limits "0.5" "512m" "" "100" > /dev/null 2>&1; then
    echo "FAILED: helper script failed to run"
    exit 1
fi
echo "OK — helper script runs successfully"

# Test: detect cgroup version
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    echo "OK — cgroup v2 detected"
else
    echo "OK — cgroup v1 detected"
fi

echo "container-resource-limits tests passed."
