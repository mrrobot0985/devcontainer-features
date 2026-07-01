#!/bin/bash
set -e

source dev-container-features-test-lib

SETTINGS_FILE="${_REMOTE_USER_HOME:-$HOME}/.claude/settings.json"
HOOKS_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/hooks"

check "settings.json exists" test -f "$SETTINGS_FILE"
check "hooks directory exists" test -d "$HOOKS_DIR"
check "lib directory exists" test -d "$HOOKS_DIR/lib"
check "common.sh exists" test -f "$HOOKS_DIR/lib/common.sh"

# Session hooks
check "session/start.sh exists" test -f "$HOOKS_DIR/session/start.sh"
check "session/end.sh exists" test -f "$HOOKS_DIR/session/end.sh"
check "session/setup.sh exists" test -f "$HOOKS_DIR/session/setup.sh"
check "session/precompact.sh exists" test -f "$HOOKS_DIR/session/precompact.sh"
check "session/postcompact.sh exists" test -f "$HOOKS_DIR/session/postcompact.sh"
check "session/configchange.sh exists" test -f "$HOOKS_DIR/session/configchange.sh"
check "session/cwdchanged.sh exists" test -f "$HOOKS_DIR/session/cwdchanged.sh"
check "session/filechanged.sh exists" test -f "$HOOKS_DIR/session/filechanged.sh"
check "session/instructionsloaded.sh exists" test -f "$HOOKS_DIR/session/instructionsloaded.sh"
check "session/statusline.sh exists" test -f "$HOOKS_DIR/session/statusline.sh"
check "session/teammateidle.sh exists" test -f "$HOOKS_DIR/session/teammateidle.sh"
check "session/worktreecreate.sh exists" test -f "$HOOKS_DIR/session/worktreecreate.sh"
check "session/worktreeremove.sh exists" test -f "$HOOKS_DIR/session/worktreeremove.sh"

# Agent hooks
check "agent/pretooluse.sh exists" test -f "$HOOKS_DIR/agent/pretooluse.sh"
check "agent/posttooluse.sh exists" test -f "$HOOKS_DIR/agent/posttooluse.sh"
check "agent/posttoolusefailure.sh exists" test -f "$HOOKS_DIR/agent/posttoolusefailure.sh"
check "agent/posttoolbatch.sh exists" test -f "$HOOKS_DIR/agent/posttoolbatch.sh"
check "agent/permissionrequest.sh exists" test -f "$HOOKS_DIR/agent/permissionrequest.sh"
check "agent/permissiondenied.sh exists" test -f "$HOOKS_DIR/agent/permissiondenied.sh"
check "agent/elicitation.sh exists" test -f "$HOOKS_DIR/agent/elicitation.sh"
check "agent/elicitationresult.sh exists" test -f "$HOOKS_DIR/agent/elicitationresult.sh"
check "agent/subagentstart.sh exists" test -f "$HOOKS_DIR/agent/subagentstart.sh"
check "agent/subagentstop.sh exists" test -f "$HOOKS_DIR/agent/subagentstop.sh"
check "agent/taskcreated.sh exists" test -f "$HOOKS_DIR/agent/taskcreated.sh"
check "agent/taskcompleted.sh exists" test -f "$HOOKS_DIR/agent/taskcompleted.sh"

# Turn hooks
check "turn/userpromptsubmit.sh exists" test -f "$HOOKS_DIR/turn/userpromptsubmit.sh"
check "turn/userpromptexpansion.sh exists" test -f "$HOOKS_DIR/turn/userpromptexpansion.sh"
check "turn/stop.sh exists" test -f "$HOOKS_DIR/turn/stop.sh"
check "turn/stopfailure.sh exists" test -f "$HOOKS_DIR/turn/stopfailure.sh"
check "turn/notification.sh exists" test -f "$HOOKS_DIR/turn/notification.sh"

# Executable permissions
check "hooks are executable" bash -c "find '$HOOKS_DIR' -name '*.sh' ! -perm /111 | wc -l | grep -q '^0$'"

# Settings validation
check "settings has hooks key" bash -c "jq -e '.hooks' '$SETTINGS_FILE' >/dev/null"
check "settings has SessionStart hook" bash -c "jq -e '.hooks.SessionStart' '$SETTINGS_FILE' >/dev/null"
check "settings has statusLine" bash -c "jq -e '.statusLine' '$SETTINGS_FILE' >/dev/null"

reportResults
