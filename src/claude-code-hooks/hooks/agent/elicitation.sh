#!/usr/bin/env bash
# elicitation.sh — Elicitation hook.
#
# Fires: MCP server requests user input during a tool call.
# Matcher: server_name (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, server_name, elicitation (schema).
# hookSpecificOutput: form values to accept (action: accept|decline|cancel, content).
# Decision control: returns accepted form values.
#
# Behavior: logs occurrence to ~/.claude/state/agent/elicitation.json (success/failure counts + ratio + by-key) and
# logs/elicitation.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init elicitation
hook_read_input
server_name=$(hook_get_field '.server_name' '')

# Always-ok observation keyed by server_name. Previously this script had a ratio
# bug (incremented successes but computed ratio = failures/total, and by_key.total
# used an uninitialized .fail). hook_update_ok computes ratio = successes/total and
# by_key.<v>.{ok,total,ratio} correctly, eliminating the uninitialized-.fail bug.
hook_update_ok server_name "$server_name"
hook_jq_state_update --argjson ts "$TS" --arg server_name "$server_name" '.last_server_name = $server_name'
hook_jq_log_append --argjson ts "$TS" --arg server_name "$server_name" '{ts:$ts, server_name:$server_name, ok:true}'

exit 0
