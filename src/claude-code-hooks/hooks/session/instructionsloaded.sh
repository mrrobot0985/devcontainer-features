#!/usr/bin/env bash
# instructionsloaded.sh — InstructionsLoaded hook.
#
# Fires: instruction / rule file loaded into context.
# Matcher: load_reason (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, file_path, memory_type, load_reason.
# hookSpecificOutput: (none).
# Decision control: none.
#
# Behavior: logs occurrence to ~/.claude/state/session/instructionsloaded.json (success/failure counts + ratio + by-key) and
# logs/instructionsloaded.log. Silent on stdout. Exit 0 (no decision / no block).
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init "instructionsloaded"
hook_read_input
file_path=$(hook_get_field '.file_path')
memory_type=$(hook_get_field '.memory_type')
load_reason=$(hook_get_field '.load_reason')
token_count=$(hook_get_field '.token_count // 0' 0)

# Fixed: use hook_update_success so ratio = successes/total (was failures/total, always 0).
hook_update_success load_reason "$load_reason"
hook_jq_state_update --argjson ts "$TS" --arg file_path "$file_path" --arg memory_type "$memory_type" --arg load_reason "$load_reason" --argjson token_count "$token_count" '
  .last_file_path=$file_path |
  .last_memory_type=$memory_type |
  .last_load_reason=$load_reason |
  .tokens.total = ((.tokens.total // 0) + $token_count) |
  .tokens.by_file[$file_path] = ((.tokens.by_file[$file_path] // 0) + $token_count) |
  .last_ts=$ts
'
hook_jq_log_append --argjson ts "$TS" --arg file_path "$file_path" --arg memory_type "$memory_type" --arg load_reason "$load_reason" --argjson token_count "$token_count" '{ts:$ts, file_path:$file_path, memory_type:$memory_type, load_reason:$load_reason, tokens:$token_count, ok:true}'

exit 0
