#!/usr/bin/env bash
# permissionrequest.sh — PermissionRequest hook.
#
# Fires: permission dialog shown for a tool call.
# Matcher: tool_name (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, tool_name, tool_input.
# hookSpecificOutput: decision:{behavior: allow|deny, updatedInput?, updatedRules?}.
# Decision control: decision.behavior allow|deny.
#
# Behavior: logs occurrence to ~/.claude/state/agent/permissionrequest.json (success/failure counts + ratio + by-key) and
# logs/permissionrequest.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init permissionrequest
hook_read_input
tool_name=$(hook_get_field '.tool_name' '')

hook_update_ok tool_name "$tool_name"
hook_jq_state_update --argjson ts "$TS" --arg tool_name "$tool_name" '.last_tool_name = $tool_name'
hook_jq_log_append --argjson ts "$TS" --arg tool_name "$tool_name" '{ts:$ts, tool_name:$tool_name, ok:true}'

exit 0
