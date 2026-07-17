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
check "config is valid json" python3 -c "import json; json.load(open('$CONFIG'))"
check "github configured" python3 -c "import json; assert 'github' in json.load(open('$CONFIG'))['mcpServers']"
check "playwright configured" python3 -c "import json; assert 'playwright' in json.load(open('$CONFIG'))['mcpServers']"
check "fetch configured" python3 -c "import json; assert 'fetch' in json.load(open('$CONFIG'))['mcpServers']"
check "playwright uses @playwright/mcp" python3 -c "import json; args=json.load(open('$CONFIG'))['mcpServers']['playwright']['args']; assert '@playwright/mcp' in args"

reportResults
