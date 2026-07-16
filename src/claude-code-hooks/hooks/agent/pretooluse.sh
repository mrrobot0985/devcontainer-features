#!/usr/bin/env bash
# pretooluse.sh — generic PreToolUse hook (Bash matcher).
#
# Tracks dangerous command attempts. Updates pretooluse.json with
# dangerous + total counts and ratio (danger rate). Appends to
# logs/pretooluse.log. Non-blocking: exit 0 always.
set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init pretooluse
hook_read_input

# Bash-only early exit (no state write for non-Bash tools).
tool=$(hook_get_field '.tool_name' '')
[ "$tool" = "Bash" ] || exit 0
cmd=$(hook_get_field '.tool_input.command' '')
[ -n "$cmd" ] || exit 0

dangerous_re='rm[[:space:]]+(-[rRfF]+[[:space:]]+)+/($|[[:space:]])|sudo[[:space:]]+rm|dd\b.*of=/dev/|mkfs\b|:[(][)]\{|chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/>[[:space:]]*/dev/sd[a-z]|git[[:space:]]+push.*--force\b.*(main|master)|\b(shutdown|reboot|halt|poweroff)\b|kill[[:space:]]+-9[[:space:]]+-1|mv[[:space:]]+/[[:space:]]*\*'

# Append custom denylist patterns if provided
if [ -n "${DANGEROUS_COMMAND_DENYLIST:-}" ]; then
    # Convert comma-separated list to alternation group, escaping each pattern lightly
    custom_re=$(printf '%s' "$DANGEROUS_COMMAND_DENYLIST" | sed 's/,/|/g')
    dangerous_re="${dangerous_re}|${custom_re}"
fi

is_dangerous=0
if printf '%s' "$cmd" | grep -qE "$dangerous_re"; then
  is_dangerous=1
  hook_jq_state_update --argjson ts "$TS" --arg cmd "$cmd" '
    .outcomes.dangerous = ((.outcomes.dangerous // 0) + 1) |
    .outcomes.total = ((.outcomes.total // 0) + 1) |
    .ratio = (if .outcomes.total > 0 then .outcomes.dangerous / .outcomes.total else 0 end) |
    .last_cmd = $cmd |
    .last_ts = $ts
  '
  hook_jq_log_append --argjson ts "$TS" --arg cmd "$cmd" '{ts:$ts,tool:"Bash",dangerous:true,cmd:$cmd}'
  hook_prune_state
fi

if [ "$is_dangerous" -eq 1 ] && [ "${BLOCK_DANGEROUS_COMMANDS:-false}" = "true" ]; then
  echo "ERROR: Dangerous Bash command blocked by claude-code-hooks policy: $cmd" >&2
  exit 1
fi

exit 0
