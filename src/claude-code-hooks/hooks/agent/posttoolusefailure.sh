#!/usr/bin/env bash
# posttoolusefailure.sh — PostToolUseFailure hook.
#
# Fires: a tool call fails (tool_error present).
# Matcher: tool_name (this script: .*).
# Stdin JSON: session_id, cwd, hook_event_name, tool_name, tool_input, tool_error.
# hookSpecificOutput: additionalContext.
# Decision control: decision:"block" + reason.
#
# Behavior: logs occurrence to ~/.claude/state/agent/posttoolusefailure.json (failure
# counts + ratio + by_key keyed by tool_name) and logs/posttoolusefailure.log.
# Silent on stdout. Exit 0 (no decision / no block).
set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init posttoolusefailure
hook_read_input

tool_name=$(hook_get_field '.tool_name' '')
tool_error=$(hook_get_field '.tool_error' '')

hook_update_failure tool_name "$tool_name"
# hook_update_failure does not record the error text or last tool name — restore them.
hook_jq_state_update --argjson ts "$TS" --arg tool_name "$tool_name" --arg tool_error "$tool_error" '
  .outcomes.last_tool_error = $tool_error |
  .last_tool_name = $tool_name
'
hook_jq_log_append --argjson ts "$TS" --arg tool_name "$tool_name" --arg tool_error "$tool_error" '{ts:$ts, tool_name:$tool_name, tool_error:$tool_error, ok:false}'

exit 0
