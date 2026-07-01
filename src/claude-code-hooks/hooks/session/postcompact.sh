#!/usr/bin/env bash
# postcompact.sh — PostCompact hook.
#
# Fires: after context compaction (trigger: manual|auto, summary produced).
# Matcher: manual|auto (this script: all).
# Stdin JSON: session_id, transcript_path, cwd, hook_event_name, trigger, summary.
# hookSpecificOutput: (none).
# Decision control: none (cannot block).
#
# Behavior: logs occurrence to ~/.claude/state/session/postcompact.json (success/failure counts + ratio + by-key) and
# logs/postcompact.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "postcompact"
hook_read_input
trigger=$(hook_get_field '.trigger')
summary_len=$(hook_get_field '.summary // "" | length' 0)

hook_update_ok trigger "$trigger"
hook_jq_state_update --argjson ts "$TS" --arg trigger "$trigger" --arg summary_len "$summary_len" '.last_trigger=$trigger | .last_summary_len=$summary_len | .last_ts=$ts'
hook_jq_log_append --argjson ts "$TS" --arg trigger "$trigger" --arg summary_len "$summary_len" '{ts:$ts, trigger:$trigger, summary_len:$summary_len, ok:true}'

exit 0
