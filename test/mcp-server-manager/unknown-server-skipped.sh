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
check "config is valid json despite unknown name" python3 -c "import json; json.load(open('$CONFIG'))"
check "github kept" python3 -c "import json; s=json.load(open('$CONFIG'))['mcpServers']; assert 'github' in s"
check "memory kept" python3 -c "import json; s=json.load(open('$CONFIG'))['mcpServers']; assert 'memory' in s"
check "unknown not present" python3 -c "import json; s=json.load(open('$CONFIG'))['mcpServers']; assert 'not-a-real-server' not in s"
check "exactly two servers" python3 -c "import json; assert len(json.load(open('$CONFIG'))['mcpServers']) == 2"

reportResults
