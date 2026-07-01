#!/usr/bin/env bash
# precompact.sh — PreCompact hook.
#
# Fires: before context compaction (trigger: manual|auto).
# Matcher: manual|auto (this script: all).
# Stdin JSON: session_id, transcript_path, cwd, hook_event_name, trigger.
# hookSpecificOutput: additionalContext.
# Decision control: decision:"block" + reason (blocks compaction).
#
# Behavior: logs occurrence to ~/.claude/state/session/precompact.json (success/failure counts + ratio + by-key) and
# logs/precompact.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "precompact"
hook_read_input
trigger=$(hook_get_field '.trigger')

hook_update_ok trigger "$trigger"
hook_jq_state_update --argjson ts "$TS" --arg trigger "$trigger" '.last_trigger=$trigger | .last_ts=$ts'
hook_jq_log_append --argjson ts "$TS" --arg trigger "$trigger" '{ts:$ts, trigger:$trigger, ok:true}'

exit 0
