#!/usr/bin/env bash
# sessionstart.sh — SessionStart hook.
#
# Fires: session begins / resumes / clears / compacts (source: startup|resume|clear|compact).
# Matcher: startup|resume|clear|compact (this script: all).
# Stdin JSON: session_id, transcript_path, cwd, permission_mode, hook_event_name, source.
# hookSpecificOutput: additionalContext, initialUserMessage, sessionTitle, watchPaths, reloadSkills.
# Decision control: none (cannot block).
#
# Behavior: logs occurrence to ~/.claude/state/session/sessionstart.json (success/failure counts + ratio + by-key) and
# logs/sessionstart.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "sessionstart"
hook_read_input
source=$(hook_get_field '.source')
cwd=$(hook_get_field '.cwd')

hook_update_ok source "$source"
hook_jq_state_update --argjson ts "$TS" --arg source "$source" --arg cwd "$cwd" '.last_source=$source | .last_cwd=$cwd | .last_ts=$ts'
hook_jq_log_append --argjson ts "$TS" --arg source "$source" --arg cwd "$cwd" '{ts:$ts, source:$source, cwd:$cwd, ok:true}'

exit 0
