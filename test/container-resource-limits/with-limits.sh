#!/bin/bash
set -e

source dev-container-features-test-lib

check "helper CLI exists" command -v devcontainer-resource-limits
check "helper is executable" test -x /usr/local/bin/devcontainer-resource-limits
check "cgroup present" test -d /sys/fs/cgroup
check "helper runs with limits" devcontainer-resource-limits "0.5" "512m" "" "100"

reportResults
