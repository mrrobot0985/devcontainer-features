#!/usr/bin/env bash
# posttoolbatch.sh — PostToolBatch hook.
#
# Fires: after a batch of tool uses resolves.
# Matcher: (none — always fires).
# Stdin JSON: session_id, cwd, hook_event_name, tool_uses[].
# hookSpecificOutput: additionalContext.
# Decision control: decision:"block" + reason.
#
# Behavior: logs occurrence to ~/.claude/state/agent/posttoolbatch.json (always-ok
# counts + ratio + by_key keyed by n_tools) and logs/posttoolbatch.log.
# Silent on stdout. Exit 0 (no decision / no block).
set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init posttoolbatch
hook_read_input

n_tools=$(hook_get_field '.tool_uses // [] | length' 0)

hook_update_ok n_tools "$n_tools"
# hook_update_ok sets .last_ts but not .last_n_tools — restore it here.
hook_jq_state_update --argjson ts "$TS" --argjson n_tools "$n_tools" '.last_n_tools = $n_tools'
hook_jq_log_append --argjson ts "$TS" --arg n_tools "$n_tools" '{ts:$ts, n_tools:$n_tools, ok:true}'

exit 0
