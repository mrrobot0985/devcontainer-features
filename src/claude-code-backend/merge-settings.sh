#!/bin/sh
# merge-settings.sh — shared helper for merging JSON into Claude Code settings.json.
#
# Usage:
#   source /path/to/merge-settings.sh
#   merge_settings_json <settings_file> <json_snippet_or_file> [<jq_path>]
#
# Arguments:
#   settings_file         Path to settings.json (created if missing)
#   json_snippet_or_file  Either a JSON string or a path to a JSON file
#   jq_path               Optional jq path to merge under, e.g. "env" (default: root)
#
# Behavior:
#   - Validates existing settings.json before merging
#   - Validates source JSON snippet/file before merging
#   - New values take precedence (recursive merge via jq '*')
#   - Writes atomically via a .tmp file in the same directory
#   - Idempotent: repeated merges with the same input produce the same output
#   - Drops "$schema" metadata from source config files before merging

merge_settings_json() {
    _settings_file="$1"
    _json_source="$2"
    _target_path="${3:-}"

    if ! command -v jq >/dev/null 2>&1; then
        echo "ERROR: jq is required by merge_settings_json() but is not installed"
        return 1
    fi

    # Resolve source JSON: file path or inline snippet.
    if [ -f "$_json_source" ]; then
        if ! jq -e . "$_json_source" >/dev/null 2>&1; then
            echo "ERROR: $_json_source is not valid JSON"
            return 1
        fi
        # Drop schema metadata from source config files before merging.
        _json=$(jq 'del(.["$schema"])' "$_json_source")
    else
        if ! printf '%s' "$_json_source" | jq -e . >/dev/null 2>&1; then
            echo "ERROR: provided JSON snippet is not valid JSON"
            return 1
        fi
        _json="$_json_source"
    fi

    # Load existing settings or start fresh.
    if [ -f "$_settings_file" ]; then
        if ! jq -e . "$_settings_file" >/dev/null 2>&1; then
            echo "ERROR: existing $_settings_file is not valid JSON"
            return 1
        fi
        _settings=$(jq '.' "$_settings_file")
    else
        _settings='{}'
    fi

    # Build path components for optional nested merge target.
    if [ -z "$_target_path" ]; then
        _path_components='[]'
    else
        _path_components=$(printf '%s' "$_target_path" | jq -R 'split(".") | map(select(length > 0))')
    fi

    # Merge: new values take precedence. Recursive merge via jq '*'.
    _merged=$(jq -n \
        --argjson settings "$_settings" \
        --argjson snippet "$_json" \
        --argjson path "$_path_components" '
        ($path | length) as $depth |
        if $depth == 0 then
            $settings * $snippet
        else
            $settings | setpath($path; (getpath($path) // {}) * $snippet)
        end
    ')

    # Write atomically via a sibling .tmp file.
    mkdir -p "$(dirname "$_settings_file")"
    printf '%s\n' "$_merged" | jq . > "${_settings_file}.tmp" && mv "${_settings_file}.tmp" "$_settings_file"
}
