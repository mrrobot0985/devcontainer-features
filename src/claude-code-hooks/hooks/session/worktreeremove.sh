#!/usr/bin/env bash
# worktreeremove.sh — WorktreeRemove hook.
#
# Fires: git worktree removed.
# Matcher: (none — always fires).
# Stdin JSON: session_id, hook_event_name, worktree_path.
# hookSpecificOutput: (none).
# Decision control: none.
#
# Behavior: logs occurrence to ~/.claude/state/session/worktreeremove.json (success/failure counts + ratio + by-key) and
# logs/worktreeremove.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "worktreeremove"
hook_read_input

worktree_path=$(hook_get_field '.worktree_path' '')

# Always-ok counter keyed by literal "remove"; .fail preserved from prior value.
hook_update_success remove "remove"
# Follow-up: record .last_* context fields.
hook_jq_state_update --argjson ts "$TS" --arg worktree_path "$worktree_path" '
  .last_ts = $ts |
  .last_worktree_path = $worktree_path
'
hook_jq_log_append --argjson ts "$TS" --arg worktree_path "$worktree_path" --argjson ok true \
  '{ts:$ts, worktree_path:$worktree_path, ok:$ok}'

exit 0
