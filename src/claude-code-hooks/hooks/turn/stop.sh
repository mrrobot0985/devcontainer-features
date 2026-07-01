#!/usr/bin/env bash
# stop.sh — Stop hook.
#
# Fires: Claude finishes responding.
# Matcher: (none — always fires).
# Stdin JSON: session_id, cwd, hook_event_name, stop_reason, stop_hook_active.
# hookSpecificOutput: additionalContext.
# Decision control: decision:"block" + reason (exit 2 keeps Claude going).
#
# Behavior: logs occurrence to ~/.claude/state/turn/stop.json (success/total counts +
# ratio + by-key) and logs/stop.log. Silent on stdout. Exit 0 (no decision /
# no block) — observer only, never blocks.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init stop
hook_read_input
stop_reason=$(hook_get_field '.stop_reason // ""' "")

hook_update_ok stop_reason "$stop_reason"
hook_jq_state_update --arg stop_reason "$stop_reason" '.last_stop_reason = $stop_reason'
hook_jq_log_append --argjson ts "$TS" --arg stop_reason "$stop_reason" --argjson ok true \
  '{ts:$ts, stop_reason:$stop_reason, ok:$ok}'

exit 0
