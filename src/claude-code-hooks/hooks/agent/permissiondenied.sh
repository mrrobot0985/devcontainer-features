#!/usr/bin/env bash
# permissiondenied.sh — PermissionDenied hook.
#
# Fires: a tool call is auto-denied.
# Matcher: tool_name (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, tool_name, denialReason.
# hookSpecificOutput: retry: true.
# Decision control: none (exit 0 = no decision, no block).
#
# Behavior: logs occurrence to ~/.claude/state/agent/permissiondenied.json (success/failure counts + ratio + by-key) and
# logs/permissiondenied.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init permissiondenied
hook_read_input
tool_name=$(hook_get_field '.tool_name' '')
denial_reason=$(hook_get_field '.denialReason' '')

hook_update_failure tool_name "$tool_name"
hook_jq_state_update --argjson ts "$TS" --arg tool_name "$tool_name" --arg denial_reason "$denial_reason" '
  .outcomes.last_denial_reason = $denial_reason |
  .last_tool_name = $tool_name
'
hook_jq_log_append --argjson ts "$TS" --arg tool_name "$tool_name" --arg denial_reason "$denial_reason" '{ts:$ts, tool_name:$tool_name, denial_reason:$denial_reason, ok:false}'

exit 0
