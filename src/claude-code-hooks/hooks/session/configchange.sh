#!/usr/bin/env bash
# configchange.sh — ConfigChange hook.
#
# Fires: settings / config changes.
# Matcher: config_source (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, config_source, changes.
# hookSpecificOutput: (none).
# Decision control: decision:"block" + reason.
#
# Behavior: logs occurrence to ~/.claude/state/session/configchange.json (success/failure counts + ratio + by-key) and
# logs/configchange.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "configchange"
hook_read_input
config_source=$(hook_get_field '.config_source')
n_changes=$(hook_get_field '.changes // [] | length' 0)

hook_update_ok config_source "$config_source"
hook_jq_state_update --argjson ts "$TS" --arg config_source "$config_source" --arg n_changes "$n_changes" '.last_config_source=$config_source | .last_n_changes=$n_changes | .last_ts=$ts'
hook_jq_log_append --argjson ts "$TS" --arg config_source "$config_source" --arg n_changes "$n_changes" '{ts:$ts, config_source:$config_source, n_changes:$n_changes, ok:true}'

exit 0
