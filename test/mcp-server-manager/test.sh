#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-mcp-status
check "cli is executable" test -x /usr/local/bin/devcontainer-mcp-status
check "example mcp.json installed" test -f /usr/local/share/mcp-server-manager/mcp.json.example

reportResults
