#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-mcp-status
check "cli is executable" test -x /usr/local/bin/devcontainer-mcp-status

reportResults
