#!/usr/bin/env bash
# filechanged.sh — FileChanged hook.
#
# Fires: a watched file changes.
# Matcher: literal filename (this script: all).
# Stdin JSON: session_id, hook_event_name, file_path, change_type (CLAUDE_ENV_FILE available).
# hookSpecificOutput: (none).
# Decision control: none.
#
# Behavior: logs occurrence to ~/.claude/state/session/filechanged.json (success/failure counts + ratio + by-key) and
# logs/filechanged.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "filechanged"
hook_read_input
file_path=$(hook_get_field '.file_path')
change_type=$(hook_get_field '.change_type')

hook_update_ok change_type "$change_type"
hook_jq_state_update --argjson ts "$TS" --arg file_path "$file_path" --arg change_type "$change_type" '.last_file_path=$file_path | .last_change_type=$change_type | .last_ts=$ts'
hook_jq_log_append --argjson ts "$TS" --arg file_path "$file_path" --arg change_type "$change_type" '{ts:$ts, file_path:$file_path, change_type:$change_type, ok:true}'

exit 0
