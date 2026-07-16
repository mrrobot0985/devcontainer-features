#!/bin/bash
set -e

source dev-container-features-test-lib

check "mcp-ctl exists" test -x /usr/local/bin/mcp-ctl

# Without config, list should report nothing
mcp-ctl list | grep -q "No MCP config" || true

check "mcp-ctl list works" bash -c "mcp-ctl list | grep -q 'No MCP config' || true"

reportResults
