#!/usr/bin/env bash
# userpromptexpansion.sh — UserPromptExpansion hook.
#
# Fires: slash command / skill expands into a prompt.
# Matcher: command name (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, prompt, command.
# hookSpecificOutput: additionalContext.
# Decision control: decision:"block" + reason.
#
# Behavior: logs occurrence to ~/.claude/state/turn/userpromptexpansion.json (success/total
# counts + ratio + by-key) and logs/userpromptexpansion.log. Silent on stdout.
# Exit 0 (no decision / no block) — observer only, never blocks, emits no context.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init userpromptexpansion
hook_read_input
command=$(hook_get_field '.command // ""' "")
prompt_len=$(hook_get_field '.prompt // "" | length' 0)

hook_update_ok command "$command"
hook_jq_state_update --arg command "$command" --arg prompt_len "$prompt_len" \
  '.last_command = $command | .last_prompt_len = $prompt_len'
hook_jq_log_append --argjson ts "$TS" --arg command "$command" --arg prompt_len "$prompt_len" --argjson ok true \
  '{ts:$ts, command:$command, prompt_len:$prompt_len, ok:$ok}'

exit 0
