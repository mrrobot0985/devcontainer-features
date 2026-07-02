#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"
HOOKS_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/hooks"

check "settings.json exists" test -f "$SETTINGS_FILE"
check "hooks directory exists" test -d "$HOOKS_DIR"
check "lib directory exists" test -d "$HOOKS_DIR/lib"
check "common.sh exists" test -f "$HOOKS_DIR/lib/common.sh"

# Session hooks should NOT be present
check "session directory absent" test ! -d "$HOOKS_DIR/session"

# Agent hooks should NOT be present
check "agent directory absent" test ! -d "$HOOKS_DIR/agent"

# Turn hooks should be present
check "turn/userpromptsubmit.sh exists" test -f "$HOOKS_DIR/turn/userpromptsubmit.sh"
check "turn/stop.sh exists" test -f "$HOOKS_DIR/turn/stop.sh"
check "turn/notification.sh exists" test -f "$HOOKS_DIR/turn/notification.sh"

# Status line should NOT be present
check "statusLine not present" bash -c "! jq -e '.statusLine' '$SETTINGS_FILE' >/dev/null 2>&1"

# Session hooks should NOT be in settings
check "settings has no SessionStart hook" bash -c "! jq -e '.hooks.SessionStart' '$SETTINGS_FILE' >/dev/null 2>&1"

# Agent hooks should NOT be in settings
check "settings has no PreToolUse hook" bash -c "! jq -e '.hooks.PreToolUse' '$SETTINGS_FILE' >/dev/null 2>&1"

# Turn hooks in settings
check "settings has UserPromptSubmit hook" bash -c "jq -e '.hooks.UserPromptSubmit' '$SETTINGS_FILE' >/dev/null"
check "settings has Stop hook" bash -c "jq -e '.hooks.Stop' '$SETTINGS_FILE' >/dev/null"

reportResults
