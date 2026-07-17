#!/bin/bash
set -e

source dev-container-features-test-lib

check "mcp-ctl exists" test -x /usr/local/bin/mcp-ctl

cat > /tmp/test-mcp.json <<'EOF'
{
  "test-server": {
    "command": "sleep",
    "args": ["60"]
  }
}
EOF

check "mcp-ctl list works" bash -c "mcp-ctl list | grep -q test-server"

rm -f /tmp/test-mcp.json

reportResults
