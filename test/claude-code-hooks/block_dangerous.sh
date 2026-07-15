#!/bin/bash
set -e

source dev-container-features-test-lib

HOOKS_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/hooks"
SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"

# Verify hook files exist
check "pretooluse.sh exists" test -f "$HOOKS_DIR/agent/pretooluse.sh"
check "config/hooks.env exists" test -f "$HOOKS_DIR/config/hooks.env"

# Verify config contains blockDangerousCommands=true
check "config has BLOCK_DANGEROUS_COMMANDS=true" grep -q "BLOCK_DANGEROUS_COMMANDS=true" "$HOOKS_DIR/config/hooks.env"

# Simulate a dangerous Bash command through the PreToolUse hook
set +e
result=$(echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' | bash "$HOOKS_DIR/agent/pretooluse.sh" 2>&1)
status=$?
set -e

check "dangerous command is blocked" test "$status" -eq 1
check "error message mentions blocked" echo "$result" | grep -q "blocked by claude-code-hooks policy"

# Simulate a safe command
set +e
result2=$(echo '{"tool_name":"Bash","tool_input":{"command":"echo hello"}}' | bash "$HOOKS_DIR/agent/pretooluse.sh" 2>&1)
status2=$?
set -e

check "safe command is allowed" test "$status2" -eq 0

reportResults
