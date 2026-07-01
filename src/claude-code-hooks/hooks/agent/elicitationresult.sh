#!/usr/bin/env bash
# elicitationresult.sh — ElicitationResult hook.
#
# Fires: user responds to an MCP elicitation.
# Matcher: server_name (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, server_name, action, content.
# hookSpecificOutput: override user response (action, content).
# Decision control: can override response.
#
# Behavior: logs occurrence to ~/.claude/state/agent/elicitationresult.json (success/failure counts + ratio + by-key) and
# logs/elicitationresult.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init elicitationresult
hook_read_input
server_name=$(hook_get_field '.server_name' '')
action=$(hook_get_field '.action' '')

# Always-ok observation keyed by action. (Legacy script had the same ratio bug as
# elicitation.sh — successes incremented but ratio computed from failures and an
# uninitialized .fail. hook_update_ok fixes both.)
hook_update_ok action "$action"
hook_jq_state_update --argjson ts "$TS" --arg server_name "$server_name" --arg action "$action" '
  .last_server_name = $server_name |
  .last_action = $action
'
hook_jq_log_append --argjson ts "$TS" --arg server_name "$server_name" --arg action "$action" '{ts:$ts, server_name:$server_name, action:$action, ok:true}'

exit 0
