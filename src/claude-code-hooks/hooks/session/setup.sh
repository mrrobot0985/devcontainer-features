#!/usr/bin/env bash
# setup.sh — Setup hook.
#
# Fires: claude --init-only or maintenance (trigger: init|maintenance).
# Matcher: init|maintenance (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, trigger.
# hookSpecificOutput: additionalContext.
# Decision control: none.
#
# Behavior: logs occurrence to ~/.claude/state/session/setup.json (success/failure counts + ratio + by-key) and
# logs/setup.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "setup"
hook_read_input
trigger=$(hook_get_field '.trigger')

hook_update_ok trigger "$trigger"
hook_jq_state_update --argjson ts "$TS" --arg trigger "$trigger" '.last_trigger=$trigger | .last_ts=$ts'
hook_jq_log_append --argjson ts "$TS" --arg trigger "$trigger" '{ts:$ts, trigger:$trigger, ok:true}'

exit 0
