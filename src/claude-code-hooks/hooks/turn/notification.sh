#!/usr/bin/env bash
# notification.sh — Notification hook.
#
# Fires: Claude Code status notification (permission_prompt, idle_prompt, auth_success, ...).
# Matcher: notification_type (this script: all).
# Stdin JSON: session_id, cwd, hook_event_name, notification_type, message.
# hookSpecificOutput: (none).
# Decision control: none (observability; forward to Slack/PagerDuty).
#
# Behavior: logs occurrence to ~/.claude/state/turn/notification.json (success/total
# counts + ratio + by-key) and logs/notification.log. Silent on stdout.
# Exit 0 — observer only.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

hook_init notification
hook_read_input
notification_type=$(hook_get_field '.notification_type // ""' "")
message=$(hook_get_field '.message // ""' "")

hook_update_success notification_type "$notification_type"
hook_jq_state_update --arg notification_type "$notification_type" --arg message "$message" \
  '.last_notification_type = $notification_type | .last_message = $message'
hook_jq_log_append --argjson ts "$TS" --arg notification_type "$notification_type" --arg message "$message" \
  '{ts:$ts, notification_type:$notification_type, message:$message, ok:true}'

exit 0
