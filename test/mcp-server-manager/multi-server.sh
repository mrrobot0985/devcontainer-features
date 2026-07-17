#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-mcp-status

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
check "github configured" node -e "const c=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); if(!c.mcpServers.github) process.exit(1)" "$CONFIG"
check "playwright configured" node -e "const c=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); if(!c.mcpServers.playwright) process.exit(1)" "$CONFIG"
check "fetch configured" node -e "const c=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); if(!c.mcpServers.fetch) process.exit(1)" "$CONFIG"
check "playwright uses @playwright/mcp" node -e "const c=JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); const a=(c.mcpServers.playwright.args)||[]; if(!a.some(x=>String(x).includes('@playwright/mcp'))) process.exit(1)" "$CONFIG"

reportResults
