#!/usr/bin/env bash
# sessionend.sh — SessionEnd hook.
#
# Fires: session terminates (reason: clear|resume|logout|prompt_input_exit|...).
# Matcher: clear|resume|logout|prompt_input_exit|bypass_permissions_disabled|other (this script: all).
# Stdin JSON: session_id, transcript_path, cwd, hook_event_name, reason.
# hookSpecificOutput: (none).
# Decision control: none (cannot block).
#
# Behavior: logs occurrence to ~/.claude/state/session/sessionend.json (success/failure counts + ratio + by-key) and
# logs/sessionend.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "sessionend"
hook_read_input
reason=$(hook_get_field '.reason')

hook_update_ok reason "$reason"
hook_jq_state_update --argjson ts "$TS" --arg reason "$reason" '.last_reason=$reason | .last_ts=$ts'
hook_jq_log_append --argjson ts "$TS" --arg reason "$reason" '{ts:$ts, reason:$reason, ok:true}'

exit 0
