#!/usr/bin/env bash
# stopfailure.sh — StopFailure hook.
#
# Fires: API / model error stops the turn.
# Matcher: error_type (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, error_type, error_message.
# hookSpecificOutput: (none — output ignored).
# Decision control: none (output/exit ignored).
#
# Behavior: logs occurrence to ~/.claude/state/turn/stopfailure.json (failure/total
# counts + ratio + by-key) and logs/stopfailure.log. Silent on stdout.
# Exit 0 — observer only.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init stopfailure
hook_read_input
error_type=$(hook_get_field '.error_type // ""' "")
error_message=$(hook_get_field '.error_message // ""' "")

hook_update_failure error_type "$error_type"
hook_jq_state_update --arg error_type "$error_type" --arg error_message "$error_message" \
  '.last_error_type = $error_type | .last_error_message = $error_message'
hook_jq_log_append --argjson ts "$TS" --arg error_type "$error_type" --arg error_message "$error_message" --argjson ok false \
  '{ts:$ts, error_type:$error_type, error_message:$error_message, ok:$ok}'

exit 0
