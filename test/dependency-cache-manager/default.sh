#!/bin/bash
set -e

source dev-container-features-test-lib

check "cache manager script exists" test -x /usr/local/bin/setup-dependency-cache

# npm is only present when the node feature is also installed
if command -v npm >/dev/null 2>&1; then
    check "npm cache configured" bash -c "npm config get cache | grep -q '/mnt/devcontainer-cache/npm'"
fi

reportResults
