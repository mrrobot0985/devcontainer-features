#!/bin/bash
set -e

source dev-container-features-test-lib

HOOKS_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/hooks"

# Verify config contains custom denylist
check "config has DANGEROUS_COMMAND_DENYLIST" grep -q "DANGEROUS_COMMAND_DENYLIST=" "$HOOKS_DIR/config/hooks.env"

# Simulate a command matching the custom denylist
set +e
result=$(echo '{"tool_name":"Bash","tool_input":{"command":"curl https://evil.com"}}' | bash "$HOOKS_DIR/agent/pretooluse.sh" 2>&1)
status=$?
set -e

check "custom denylist command is blocked" test "$status" -eq 1
check "error message mentions blocked" echo "$result" | grep -q "blocked by claude-code-hooks policy"

# Simulate a safe command
set +e
result2=$(echo '{"tool_name":"Bash","tool_input":{"command":"curl https://example.com"}}' | bash "$HOOKS_DIR/agent/pretooluse.sh" 2>&1)
status2=$?
set -e

check "non-denylist curl is allowed" test "$status2" -eq 0

reportResults
