#!/usr/bin/env bash
# taskcompleted.sh — TaskCompleted hook.
#
# Fires: background task completes.
# Matcher: (none — always fires).
# Stdin JSON: session_id, cwd, hook_event_name, task_id, task_type, result.
# hookSpecificOutput: additionalContext.
# Decision control: decision:"block" + reason (or continue:false).
#
# Behavior: logs occurrence to ~/.claude/state/agent/taskcompleted.json (success/failure counts + ratio + by-key) and
# logs/taskcompleted.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init taskcompleted
hook_read_input
task_id=$(hook_get_field '.task_id' '')
task_type=$(hook_get_field '.task_type' '')
result_len=$(hook_get_field '.result // "" | length' '0')

hook_update_ok task_type "$task_type"
hook_jq_state_update --argjson ts "$TS" --arg task_id "$task_id" --arg task_type "$task_type" --arg result_len "$result_len" '
  .last_task_id = $task_id |
  .last_task_type = $task_type |
  .last_result_len = $result_len
'
hook_jq_log_append --argjson ts "$TS" --arg task_id "$task_id" --arg task_type "$task_type" --arg result_len "$result_len" '{ts:$ts, task_id:$task_id, task_type:$task_type, result_len:$result_len, ok:true}'

exit 0
