#!/usr/bin/env bash
# subagentstop.sh — SubagentStop hook.
#
# Fires: subagent finishes.
# Matcher: agent_type (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, agent_type, agent_id, result.
# hookSpecificOutput: additionalContext.
# Decision control: decision:"block" + reason.
#
# Behavior: logs occurrence to ~/.claude/state/agent/subagentstop.json (success/failure counts + ratio + by-key) and
# logs/subagentstop.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init subagentstop
hook_read_input
agent_type=$(hook_get_field '.agent_type' '')
agent_id=$(hook_get_field '.agent_id' '')
result_len=$(hook_get_field '.result // "" | length' '0')

hook_update_ok agent_type "$agent_type"
hook_jq_state_update --argjson ts "$TS" --arg agent_type "$agent_type" --arg agent_id "$agent_id" --arg result_len "$result_len" '
  .last_agent_type = $agent_type |
  .last_agent_id = $agent_id |
  .last_result_len = $result_len
'
hook_jq_log_append --argjson ts "$TS" --arg agent_type "$agent_type" --arg agent_id "$agent_id" --arg result_len "$result_len" '{ts:$ts, agent_type:$agent_type, agent_id:$agent_id, result_len:$result_len, ok:true}'

exit 0
