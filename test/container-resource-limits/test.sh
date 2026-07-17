#!/bin/bash
set -e

source dev-container-features-test-lib

check "helper CLI exists" command -v devcontainer-resource-limits
check "helper script runs" devcontainer-resource-limits "0.5" "512m" "" "100"
check "cgroup present" test -d /sys/fs/cgroup

reportResults
