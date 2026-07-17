#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-mcp-status
check "cli is executable" test -x /usr/local/bin/devcontainer-mcp-status
check "start cli exists" command -v devcontainer-mcp-start
check "example mcp.json installed" test -f /usr/local/share/mcp-server-manager/mcp.json.example

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
check "config is valid json" node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$CONFIG"
check "default github server present" node -e "const c=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); if(!c.mcpServers||!c.mcpServers.github) process.exit(1)" "$CONFIG"
check "github uses published package" node -e "const c=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); const a=(c.mcpServers.github.args)||[]; if(!a.some(x=>String(x).includes('@modelcontextprotocol/server-github'))) process.exit(1)" "$CONFIG"

reportResults
