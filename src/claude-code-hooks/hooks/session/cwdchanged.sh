#!/usr/bin/env bash
# cwdchanged.sh — CwdChanged hook.
#
# Fires: working directory changes.
# Matcher: (none — always fires).
# Stdin JSON: session_id, hook_event_name, old_cwd, new_cwd (CLAUDE_ENV_FILE available).
# hookSpecificOutput: (none).
# Decision control: none.
#
# Behavior: logs occurrence to ~/.claude/state/session/cwdchanged.json (success/failure counts + ratio + by-key) and
# logs/cwdchanged.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "cwdchanged"
hook_read_input
old_cwd=$(hook_get_field '.old_cwd')
new_cwd=$(hook_get_field '.new_cwd')

hook_update_ok new_cwd "$new_cwd"
hook_jq_state_update --argjson ts "$TS" --arg old_cwd "$old_cwd" --arg new_cwd "$new_cwd" '.last_old_cwd=$old_cwd | .last_new_cwd=$new_cwd | .last_ts=$ts'
hook_jq_log_append --argjson ts "$TS" --arg old_cwd "$old_cwd" --arg new_cwd "$new_cwd" '{ts:$ts, old_cwd:$old_cwd, new_cwd:$new_cwd, ok:true}'

exit 0
