#!/usr/bin/env bash
# userpromptsubmit.sh — UserPromptSubmit hook.
#
# Fires: user submits a prompt, before Claude processes it.
# Matcher: (none — always fires).
# Stdin JSON: session_id, cwd, hook_event_name, prompt.
# hookSpecificOutput: additionalContext.
# Decision control: top-level decision:"block" + reason (exit 2 blocks).
#
# Behavior: logs occurrence to ~/.claude/state/turn/userpromptsubmit.json (success/total
# counts + ratio + by-key) and logs/userpromptsubmit.log. Silent on stdout.
# Exit 0 (no decision / no block) — observer only, never blocks.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init userpromptsubmit
hook_read_input
prompt_len=$(hook_get_field '.prompt // "" | length' 0)

hook_update_ok prompt "prompt"
hook_jq_state_update --arg prompt_len "$prompt_len" '.last_prompt_len = $prompt_len'
hook_jq_log_append --argjson ts "$TS" --arg prompt_len "$prompt_len" --argjson ok true \
  '{ts:$ts, prompt_len:$prompt_len, ok:$ok}'

exit 0
