#!/usr/bin/env bash
# common.sh — shared utilities for all hook scripts.
#
# Source from a category dir (agent/ session/ turn/):
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
#
# Contract:
#   hook_init <slug> [scope]          # required first call; scoped paths anchored to CLAUDE_PROJECT_DIR
#   hook_read_input                  # slurp stdin JSON into $INPUT
#   hook_get_field '<jq_path>' [def] # extract a field from $INPUT (safe default)
#   hook_update_ok      <k> <v> [jq-args...]   # always-succeeds counter (successes/total)
#   hook_update_success <k> <v> [jq-args...]   # success counter
#   hook_update_failure <k> <v> [jq-args...]   # failure counter (ratio = failures/total)
#   hook_jq_state_update <jq-args...> <filter> # custom state write; filter MUST be the last arg
#   hook_jq_log_append   <jq-args...> <expr>   # NDJSON log append; expr MUST be the last arg
#   hook_with_lock '<command string>'          # run a block under the slug's flock (current shell)
#
# All state/log writers acquire the slug's flock internally and clean up their
# temp file on failure, so callers do NOT need to manage locking themselves.
# jq argument convention: pass --arg/--argjson flags first, the jq filter last.

set -euo pipefail

# Source runtime config if available (written by install.sh).
CONFIG_ENV="${HOME}/.claude/hooks/config/hooks.env"
if [ -f "$CONFIG_ENV" ]; then
    # shellcheck source=/dev/null
    . "$CONFIG_ENV"
fi

# Derive a slug from the sourcing script's filename (fallback only).
# Prefer passing the slug explicitly to hook_init so state-file names are stable
# across restructures (e.g. session_start.sh -> slug "sessionstart", not "start").
hook_HOOK_SLUG() {
  local script_name="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
  script_name="${script_name##*/}"
  script_name="${script_name#agent_}"
  script_name="${script_name#session_}"
  script_name="${script_name#turn_}"
  script_name="${script_name%.sh}"
  printf '%s' "$script_name"
}

# Initialize paths. Respect CLAUDE_CONFIG_DIR when set (devcontainer and
# custom-config scenarios); fall back to $HOME/.claude so state lands in the
# user's global config directory regardless of the hook process's cwd.
# State, locks, and logs are scoped by lifecycle dir (agent/ session/ turn/)
# so independent hooks keep independent files, locks, and blast radius.
# Scope is derived from the calling hook's directory, defaulting to "misc"
# when called outside a hook dir (e.g. from tests). Usage: hook_init <slug> [scope]
hook_init() {
  HOOK_SLUG="${1:?hook_init requires a slug}"
  local base="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
  # Ensure absolute path so state never leaks into the process's cwd.
  # If CLAUDE_CONFIG_DIR or HOME is relative, resolve it.
  if [[ "$base" != /* ]]; then
    base="${HOME}/$base"
  fi
  if [[ "$base" != /* ]]; then
    base="$(pwd)/$base"
  fi
  local scope="${2:-}"
  if [ -z "$scope" ]; then
    local caller_dir
    caller_dir=$(basename "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")")
    case "$caller_dir" in
      agent|session|turn) scope="$caller_dir" ;;
      *) scope="misc" ;;
    esac
  fi
  HOOK_SCOPE="$scope"
  CACHE_DIR="$base/state"
  LOG_DIR="$CACHE_DIR/logs"
  STATE_FILE="$CACHE_DIR/$scope/${HOOK_SLUG}.json"
  LOCK_FILE="$CACHE_DIR/$scope/${HOOK_SLUG}.lock"
  LOG_FILE="$LOG_DIR/$scope/${HOOK_SLUG}.log"
  TS=$(date +%s)
  mkdir -p "$CACHE_DIR/$scope" "$LOG_DIR/$scope"
}

# Atomic, locked state update. All args are forwarded to jq; the filter must be
# the LAST argument (jq requires options before the filter). Temp file is removed
# if jq fails. Usage: hook_jq_state_update --argjson ts "$TS" --arg k "$v" '<filter>'
hook_jq_state_update() {
  local tmp; tmp=$(mktemp "$CACHE_DIR/$HOOK_SCOPE/.${HOOK_SLUG}.XXXXXX")
  {
    flock 9
    if ( cat "$STATE_FILE" 2>/dev/null || printf '{}' ) | jq "$@" > "$tmp"; then
      mv "$tmp" "$STATE_FILE"
    else
      rm -f "$tmp"
      return 1
    fi
  } 9>"$LOCK_FILE"
}

# Append one NDJSON line to the log under lock; auto-truncate to 250 lines past
# 500. All args forwarded to jq; the expression must be the LAST argument.
# Usage: hook_jq_log_append --argjson ts "$TS" --arg k "$v" '{ts:$ts,k:$k}'
hook_jq_log_append() {
  {
    flock 9
    jq -nc "$@" >> "$LOG_FILE"
    local ln; ln=$(wc -l < "$LOG_FILE" 2>/dev/null || printf 0)
    if [ "${ln:-0}" -gt 500 ]; then
      tail -n 250 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
  } 9>"$LOCK_FILE"
}

# Always-succeeds counter: successes+1, total+1, ratio=successes/total, plus
# by_key.<v>.{ok,total,ratio}. Failures key is preserved (kept at its prior value)
# so the schema matches the legacy always-ok scripts. Extra jq args are forwarded.
# Usage: hook_update_ok <key_var> <key_value> [extra jq args...]
hook_update_ok() {
  local _key_var="$1" key_val="$2"; shift 2
  hook_jq_state_update --argjson ts "$TS" --arg k "$key_val" "$@" '
    .outcomes.successes = ((.outcomes.successes // 0) + 1) |
    .outcomes.total = ((.outcomes.total // 0) + 1) |
    .outcomes.ratio = (if .outcomes.total > 0 then .outcomes.successes / .outcomes.total else 0 end) |
    .outcomes.by_key[$k].ok = ((.outcomes.by_key[$k].ok // 0) + 1) |
    .outcomes.by_key[$k].total = ((.outcomes.by_key[$k].total // 0) + 1) |
    .outcomes.by_key[$k].ratio = (if .outcomes.by_key[$k].total > 0 then .outcomes.by_key[$k].ok / .outcomes.by_key[$k].total else 0 end) |
    .last_ts = $ts
  '
}

# Success counter (no failure key maintained). Same shape as hook_update_ok.
# Usage: hook_update_success <key_var> <key_value> [extra jq args...]
hook_update_success() {
  local _key_var="$1" key_val="$2"; shift 2
  hook_jq_state_update --argjson ts "$TS" --arg k "$key_val" "$@" '
    .outcomes.successes = ((.outcomes.successes // 0) + 1) |
    .outcomes.total = ((.outcomes.total // 0) + 1) |
    .outcomes.ratio = (if .outcomes.total > 0 then .outcomes.successes / .outcomes.total else 0 end) |
    .outcomes.by_key[$k].ok = ((.outcomes.by_key[$k].ok // 0) + 1) |
    .outcomes.by_key[$k].total = ((.outcomes.by_key[$k].total // 0) + 1) |
    .outcomes.by_key[$k].ratio = (if .outcomes.by_key[$k].total > 0 then .outcomes.by_key[$k].ok / .outcomes.by_key[$k].total else 0 end) |
    .last_ts = $ts
  '
}

# Failure counter: failures+1, total+1, ratio=failures/total, by_key.<v>.{fail,total,ratio}.
# Usage: hook_update_failure <key_var> <key_value> [extra jq args...]
hook_update_failure() {
  local _key_var="$1" key_val="$2"; shift 2
  hook_jq_state_update --argjson ts "$TS" --arg k "$key_val" "$@" '
    .outcomes.failures = ((.outcomes.failures // 0) + 1) |
    .outcomes.total = ((.outcomes.total // 0) + 1) |
    .outcomes.ratio = (if .outcomes.total > 0 then .outcomes.failures / .outcomes.total else 0 end) |
    .outcomes.by_key[$k].fail = ((.outcomes.by_key[$k].fail // 0) + 1) |
    .outcomes.by_key[$k].total = ((.outcomes.by_key[$k].total // 0) + 1) |
    .outcomes.by_key[$k].ratio = (if .outcomes.by_key[$k].total > 0 then .outcomes.by_key[$k].fail / .outcomes.by_key[$k].total else 0 end) |
    .last_ts = $ts
  '
}

# Run a command string under the slug's flock in the CURRENT shell (variables and
# functions remain visible; no subshell isolation). Prefer hook_jq_state_update /
# hook_jq_log_append for ordinary writes — only use this for custom multi-step
# logic that must be one atomic transaction. Usage: hook_with_lock '<cmd>'
hook_with_lock() {
  local __cmd="$1"
  { flock 9; eval "$__cmd"; } 9>"$LOCK_FILE"
}

# Prune large associative arrays in state to prevent unbounded growth.
# Limits by_tool, by_key, and files objects to STATE_RETENTION_LIMIT entries
# (default 100), keeping the entries with the most recent last_ts. If an entry
# lacks last_ts, it is treated as 0 (oldest). Call after state updates.
# Usage: hook_prune_state [limit]
hook_prune_state() {
  local limit="${1:-${STATE_RETENTION_LIMIT:-100}}"
  if [ -z "$limit" ] || ! printf '%s' "$limit" | grep -qE '^[0-9]+$'; then
    limit=100
  fi
  local tmp; tmp=$(mktemp "$CACHE_DIR/$HOOK_SCOPE/.${HOOK_SLUG}.prune.XXXXXX")
  {
    flock 9
    if ( cat "$STATE_FILE" 2>/dev/null || printf '{}' ) | jq --argjson lim "$limit" '
      .by_tool |= (if type == "object" then
        to_entries | sort_by(.value.last_ts // 0) | reverse | .[:$lim] | from_entries
      else . end) |
      .by_key |= (if type == "object" then
        to_entries | sort_by(.value.last_ts // 0) | reverse | .[:$lim] | from_entries
      else . end) |
      .files |= (if type == "object" then
        to_entries | sort_by(.value.last_ts // 0) | reverse | .[:$lim] | from_entries
      else . end)
    ' > "$tmp"; then
      mv "$tmp" "$STATE_FILE"
    else
      rm -f "$tmp"
      return 1
    fi
  } 9>"$LOCK_FILE"
}

# Slurp the hook's stdin JSON into $INPUT.
# Usage: hook_read_input
hook_read_input() {
  INPUT=$(cat)
}

# Extract a field from $INPUT. <path> is a jq filter (trusted, literal); the
# default is passed safely via --arg (no interpolation). Returns the default on
# null/missing. Usage: hook_get_field '.tool_name' 'unknown'
hook_get_field() {
  local path="$1" default="${2:-}"
  printf '%s' "$INPUT" | jq -r --arg d "$default" "($path) // \$d"
}
