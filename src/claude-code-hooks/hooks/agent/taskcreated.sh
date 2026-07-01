#!/usr/bin/env bash
# taskcreated.sh — TaskCreated hook.
#
# Fires: background task created.
# Matcher: (none — always fires).
# Stdin JSON: session_id, cwd, hook_event_name, task_id, task_type, task_input.
# hookSpecificOutput: additionalContext.
# Decision control: decision:"block" + reason (or continue:false).
#
# Behavior: logs occurrence to ~/.claude/state/agent/taskcreated.json (success/failure counts + ratio + by-key) and
# logs/taskcreated.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init taskcreated
hook_read_input
task_id=$(hook_get_field '.task_id' '')
task_type=$(hook_get_field '.task_type' '')

hook_update_ok task_type "$task_type"
hook_jq_state_update --argjson ts "$TS" --arg task_id "$task_id" --arg task_type "$task_type" '
  .last_task_id = $task_id |
  .last_task_type = $task_type
'
hook_jq_log_append --argjson ts "$TS" --arg task_id "$task_id" --arg task_type "$task_type" '{ts:$ts, task_id:$task_id, task_type:$task_type, ok:true}'

exit 0
