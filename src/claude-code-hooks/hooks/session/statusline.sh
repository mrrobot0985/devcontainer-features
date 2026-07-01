#!/usr/bin/env bash
# Claude Code statusline — model + used tokens + percentage

set -euo pipefail

input=$(cat)

# --- helpers ----------------------------------------------------------------
normalize() { # drop [..] tags, lowercase, trim
  printf '%s' "$1" | sed 's/\[[^]]*\]//g' | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}
base() { printf '%s' "$1" | cut -d: -f1; }

# --- model tier detection ---------------------------------------------------
model_raw=$(printf '%s' "$input" | jq -r '.model.id // .model.display_name // ""')
model_norm=$(normalize "$model_raw")
opus_norm=$(normalize   "${ANTHROPIC_DEFAULT_OPUS_MODEL:-}")
sonnet_norm=$(normalize "${ANTHROPIC_DEFAULT_SONNET_MODEL:-}")
haiku_norm=$(normalize  "${ANTHROPIC_DEFAULT_HAIKU_MODEL:-}")

match() {
  [ -n "$1" ] || return 1
  [ "$model_norm" = "$1" ] && return 0
  [ -n "$model_norm" ] && [ "$(base "$model_norm")" = "$(base "$1")" ] && return 0
  return 1
}

tier="Unknown"
if   match "$opus_norm";   then tier="Opus"
elif match "$sonnet_norm"; then tier="Sonnet"
elif match "$haiku_norm";  then tier="Haiku"
fi

# --- context window ---------------------------------------------------------
context_size=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // 200000')
# Guard: ensure context_size is a non-negative integer (defensive against
# non-numeric JSON values that would break the -gt comparison).
case "$context_size" in
  ''|*[!0-9]*) context_size=0 ;;
esac
used_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')

tokens_used=0
if [ -n "$used_pct" ] && [ "$context_size" -gt 0 ] 2>/dev/null; then
  tokens_used=$(awk -v u="$used_pct" -v c="$context_size" 'BEGIN{printf "%.0f", u*c/100}')
fi

# format tokens
if [ "$tokens_used" -ge 1000000 ] 2>/dev/null; then
  tokens_display="$(awk -v t="$tokens_used" 'BEGIN{printf "%.1fM", t/1000000}')"
elif [ "$tokens_used" -ge 1000 ] 2>/dev/null; then
  tokens_display="$(awk -v t="$tokens_used" 'BEGIN{printf "%.0fk", t/1000}')"
else
  tokens_display="$tokens_used"
fi

# session color — disable ANSI when stdout is not a TTY (e.g. piped/captured).
if [ -t 1 ]; then
  reset="\033[0m"
  session_color="${ANTHROPIC_SESSION_COLOR:-}"
  case "$session_color" in
    blue)   color="\033[34m" ;;
    green)  color="\033[32m" ;;
    purple) color="\033[35m" ;;
    orange) color="\033[33m" ;;
    red)    color="\033[31m" ;;
    yellow) color="\033[93m" ;;
    *)      color="\033[36m" ;;
  esac
else
  reset=""
  color=""
fi

# --- emit -------------------------------------------------------------------
printf "${color}%s${reset} | %s tokens | %.0f%%\n" "$tier" "$tokens_display" "${used_pct:-0}"
