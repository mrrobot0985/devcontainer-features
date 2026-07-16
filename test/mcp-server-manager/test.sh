#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-mcp-status
check "config file exists" test -f /root/.mcp/mcp-servers.json

reportResults
