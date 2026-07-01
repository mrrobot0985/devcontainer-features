#!/usr/bin/env bash
# worktreecreate.sh — WorktreeCreate hook.
#
# Fires: git worktree created.
# Matcher: (none — always fires).
# Stdin JSON: session_id, hook_event_name, worktree_path, branch.
# hookSpecificOutput: worktreePath (stdout = selected path).
# Decision control: any non-zero exit aborts creation — MUST stay silent on stdout, exit 0.
#
# Behavior: logs occurrence to ~/.claude/state/session/worktreecreate.json (success/failure counts + ratio + by-key) and
# logs/worktreecreate.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "worktreecreate"
hook_read_input

branch=$(hook_get_field '.branch' '')
worktree_path=$(hook_get_field '.worktree_path' '')

# Always-ok counter keyed by branch; .fail preserved from prior value.
hook_update_success branch "$branch"
# Follow-up: record .last_* context fields.
hook_jq_state_update --argjson ts "$TS" --arg worktree_path "$worktree_path" --arg branch "$branch" '
  .last_ts = $ts |
  .last_worktree_path = $worktree_path |
  .last_branch = $branch
'
hook_jq_log_append --argjson ts "$TS" --arg worktree_path "$worktree_path" --arg branch "$branch" --argjson ok true \
  '{ts:$ts, worktree_path:$worktree_path, branch:$branch, ok:$ok}'

exit 0
