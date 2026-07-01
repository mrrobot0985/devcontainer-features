#!/usr/bin/env bash
# subagentstart.sh — SubagentStart hook.
#
# Fires: subagent launched.
# Matcher: agent_type (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, agent_type, agent_id, prompt.
# hookSpecificOutput: additionalContext.
# Decision control: none.
#
# Behavior: logs occurrence to ~/.claude/state/agent/subagentstart.json (success/failure counts + ratio + by-key) and
# logs/subagentstart.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init subagentstart
hook_read_input
agent_type=$(hook_get_field '.agent_type' '')
agent_id=$(hook_get_field '.agent_id' '')
prompt_len=$(hook_get_field '.prompt // "" | length' '0')

hook_update_ok agent_type "$agent_type"
hook_jq_state_update --argjson ts "$TS" --arg agent_type "$agent_type" --arg agent_id "$agent_id" --arg prompt_len "$prompt_len" '
  .last_agent_type = $agent_type |
  .last_agent_id = $agent_id |
  .last_prompt_len = $prompt_len
'
hook_jq_log_append --argjson ts "$TS" --arg agent_type "$agent_type" --arg agent_id "$agent_id" --arg prompt_len "$prompt_len" '{ts:$ts, agent_type:$agent_type, agent_id:$agent_id, prompt_len:$prompt_len, ok:true}'

exit 0
