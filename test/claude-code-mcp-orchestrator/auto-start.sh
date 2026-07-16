#!/bin/bash
set -e

source dev-container-features-test-lib

check "mcp-ctl exists" test -x /usr/local/bin/mcp-ctl

# Create a mock .mcp.json with a simple sleep server
cat > /tmp/test-mcp.json <<'EOF'
{
  "test-server": {
    "command": "sleep",
    "args": ["60"]
  }
}
EOF

mcp-ctl start

check "server started" bash -c "mcp-ctl status | grep -q 'test-server: running'"

mcp-ctl stop

check "server stopped" bash -c "mcp-ctl status | grep -q 'test-server: not running'"

rm -f /tmp/test-mcp.json

reportResults
