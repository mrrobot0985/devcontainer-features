#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-mcp-status
check "cli is executable" test -x /usr/local/bin/devcontainer-mcp-status
check "start cli exists" command -v devcontainer-mcp-start
check "example mcp.json installed" test -f /usr/local/share/mcp-server-manager/mcp.json.example

# Default config path for remote user
CONFIG=""
for candidate in \
    "${HOME}/.mcp/mcp-servers.json" \
    "/home/vscode/.mcp/mcp-servers.json" \
    "/root/.mcp/mcp-servers.json"; do
    if [ -f "$candidate" ]; then
        CONFIG="$candidate"
        break
    fi
done

check "config file exists" test -n "$CONFIG" -a -f "$CONFIG"
check "config is valid json" python3 -c "import json; json.load(open('$CONFIG'))"
check "default github server present" python3 -c "import json; assert 'github' in json.load(open('$CONFIG'))['mcpServers']"
check "github uses published package" python3 -c "import json; args=json.load(open('$CONFIG'))['mcpServers']['github']['args']; assert '@modelcontextprotocol/server-github' in args"

reportResults
