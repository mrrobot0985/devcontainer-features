#!/usr/bin/env bash
# teammateidle.sh — TeammateIdle hook.
#
# Fires: teammate about to idle.
# Matcher: (none — always fires).
# Stdin JSON: session_id, cwd, hook_event_name, teammate_id, teammate_type.
# hookSpecificOutput: (none).
# Decision control: exit 2 or {continue:false} to block idle.
#
# Behavior: logs occurrence to ~/.claude/state/session/teammateidle.json (success/failure counts + ratio + by-key) and
# logs/teammateidle.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "teammateidle"
hook_read_input

teammate_id=$(hook_get_field '.teammate_id' '')
teammate_type=$(hook_get_field '.teammate_type' '')

# Always-ok counter keyed by teammate_type; .fail preserved from prior value.
hook_update_success teammate_type "$teammate_type"
# Follow-up: record .last_* context fields.
hook_jq_state_update --argjson ts "$TS" --arg teammate_id "$teammate_id" --arg teammate_type "$teammate_type" '
  .last_ts = $ts |
  .last_teammate_id = $teammate_id |
  .last_teammate_type = $teammate_type
'
hook_jq_log_append --argjson ts "$TS" --arg teammate_id "$teammate_id" --arg teammate_type "$teammate_type" --argjson ok true \
  '{ts:$ts, teammate_id:$teammate_id, teammate_type:$teammate_type, ok:$ok}'

exit 0
