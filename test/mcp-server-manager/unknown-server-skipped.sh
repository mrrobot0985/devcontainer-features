#!/bin/bash
set -e

source dev-container-features-test-lib

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
# Unknown names must be skipped without breaking JSON or dropping valid servers
check "config is valid json despite unknown name" node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$CONFIG"
check "github kept" node -e "const c=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); if(!c.mcpServers.github) process.exit(1)" "$CONFIG"
check "memory kept" node -e "const c=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); if(!c.mcpServers.memory) process.exit(1)" "$CONFIG"
check "unknown not present" node -e "const c=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); if(c.mcpServers['not-a-real-server']) process.exit(1)" "$CONFIG"
check "exactly two servers" node -e "const c=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); if(Object.keys(c.mcpServers).length!==2) process.exit(1)" "$CONFIG"

reportResults
