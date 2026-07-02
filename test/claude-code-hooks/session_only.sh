#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"
HOOKS_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/hooks"

check "settings.json exists" test -f "$SETTINGS_FILE"
check "hooks directory exists" test -d "$HOOKS_DIR"
check "lib directory exists" test -d "$HOOKS_DIR/lib"
check "common.sh exists" test -f "$HOOKS_DIR/lib/common.sh"

# Session hooks should be present
check "session/start.sh exists" test -f "$HOOKS_DIR/session/start.sh"
check "session/end.sh exists" test -f "$HOOKS_DIR/session/end.sh"
check "session/setup.sh exists" test -f "$HOOKS_DIR/session/setup.sh"

# Agent hooks should NOT be present
check "agent directory absent" test ! -d "$HOOKS_DIR/agent"

# Turn hooks should NOT be present
check "turn directory absent" test ! -d "$HOOKS_DIR/turn"

# Status line should be present
check "statusLine present" bash -c "jq -e '.statusLine' '$SETTINGS_FILE' >/dev/null"

# Session hooks in settings
check "settings has SessionStart hook" bash -c "jq -e '.hooks.SessionStart' '$SETTINGS_FILE' >/dev/null"

# Agent hooks should NOT be in settings
check "settings has no PreToolUse hook" bash -c "! jq -e '.hooks.PreToolUse' '$SETTINGS_FILE' >/dev/null 2>&1"

# Turn hooks should NOT be in settings
check "settings has no UserPromptSubmit hook" bash -c "! jq -e '.hooks.UserPromptSubmit' '$SETTINGS_FILE' >/dev/null 2>&1"

reportResults
