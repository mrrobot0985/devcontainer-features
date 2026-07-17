#!/bin/bash
set -e

source dev-container-features-test-lib

check "helper CLI exists" command -v devcontainer-resource-limits
check "helper is executable" test -x /usr/local/bin/devcontainer-resource-limits
check "cgroup present" test -d /sys/fs/cgroup
check "helper runs with empty limits" bash -c 'devcontainer-resource-limits "" "" "" "0"'

reportResults
