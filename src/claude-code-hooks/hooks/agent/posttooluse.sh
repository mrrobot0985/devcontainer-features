#!/usr/bin/env bash
# posttooluse.sh — generic PostToolUse + PostToolUseFailure hook.
#
# Tracks success/failure rate per tool and overall. Updates
# ~/.claude/state/agent/posttooluse.json with counts and a failure-rate ratio
# (.ratio = failures/total) plus a per-tool by_tool schema (ok/fail/total/ratio).
# Appends to logs/posttooluse.log. Auto-fixes markdown files after Write/Edit
# and tracks violations in the same state file. Silent on stdout.
set -euo pipefail

# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init posttooluse
hook_read_input

event=$(hook_get_field '.hook_event_name' 'PostToolUse')
tool=$(hook_get_field '.tool_name' 'unknown')
err=$(hook_get_field '.error' '')
file=$(hook_get_field '.tool_input.file_path' '')

case "$event" in
  PostToolUseFailure) signal=1; ok=0 ;;
  *)                  signal=0; ok=1 ;;
esac

# Main per-tool outcome update. Custom schema (needs both ok + fail per tool
# and a failure-rate ratio = failures/total), so go through
# hook_jq_state_update directly rather than the generic helpers.
hook_jq_state_update --argjson ts "$TS" --arg tool "$tool" --argjson ok "$ok" --argjson fail "$signal" --arg err "$err" --arg file "$file" '
  .outcomes.successes = ((.outcomes.successes // 0) + $ok) |
  .outcomes.failures = ((.outcomes.failures // 0) + $fail) |
  .outcomes.total = (.outcomes.successes + .outcomes.failures) |
  .ratio = (if .outcomes.total > 0 then .outcomes.failures / .outcomes.total else 0 end) |
  .outcomes.by_tool[$tool].ok = ((.outcomes.by_tool[$tool].ok // 0) + $ok) |
  .outcomes.by_tool[$tool].fail = ((.outcomes.by_tool[$tool].fail // 0) + $fail) |
  .outcomes.by_tool[$tool].total = (.outcomes.by_tool[$tool].ok + .outcomes.by_tool[$tool].fail) |
  .outcomes.by_tool[$tool].ratio = (if .outcomes.by_tool[$tool].total > 0 then .outcomes.by_tool[$tool].fail / .outcomes.by_tool[$tool].total else 0 end) |
  (if $fail == 1 then .outcomes.last_error = $err else . end) |
  .last_ts = $ts
'

hook_jq_log_append --argjson ts "$TS" --arg event "$event" --arg tool "$tool" --argjson ok "$ok" --argjson fail "$signal" '{ts:$ts,event:$event,tool:$tool,ok:$ok,fail:$fail}'

# Auto-fix markdown after Write/Edit + track violations in same state file.
# Guard the whole block so a missing npx can't break the hook.
if [[ "$tool" =~ ^(Write|Edit)$ ]] && [[ "$file" == *.md ]] && command -v npx >/dev/null 2>&1; then
  violations_before=$(timeout 30s npx --yes markdownlint-cli "$file" 2>/dev/null | wc -l || printf 0)
  violations_before=${violations_before//[^0-9]/}
  : "${violations_before:=0}"

  # Auto-fix (best effort).
  timeout 30s npx --yes markdownlint-cli --fix "$file" >/dev/null 2>&1 || true

  violations_after=$(timeout 30s npx --yes markdownlint-cli "$file" 2>/dev/null | wc -l || printf 0)
  violations_after=${violations_after//[^0-9]/}
  : "${violations_after:=0}"

  hook_jq_state_update --argjson ts "$TS" --arg file "$file" --argjson before "$violations_before" --argjson after "$violations_after" '
    .markdown.files[$file].violations_before = $before |
    .markdown.files[$file].violations_after = $after |
    .markdown.files[$file].last_check = $ts |
    .markdown.total_violations_before = ((.markdown.total_violations_before // 0) + $before) |
    .markdown.total_violations_after = ((.markdown.total_violations_after // 0) + $after) |
    .markdown.files_checked = ((.markdown.files_checked // 0) + 1)
  '

  # Signal failure only when npx is available AND unfixable violations remain.
  if [ "$violations_after" -gt 0 ]; then
    exit 1
  fi
fi

exit 0
