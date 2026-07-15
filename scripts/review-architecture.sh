#!/bin/bash
# Architecture perspective for the multi-perspective review system.
# Runs inside an isolated Docker sandcastle.
# Emits /out/architecture.json.

set -uo pipefail

TARGET_REF="${TARGET_REF:-HEAD}"
BASE_REF="${BASE_REF:-main}"
REPO_DIR="${REPO_DIR:-/repo}"
OUT_DIR="${OUT_DIR:-/out}"
REPORT="${OUT_DIR}/architecture.json"

mkdir -p "${OUT_DIR}"

start_ms=$(date +%s%3N)
findings=()
exit_code=0

add_finding() {
    local severity="$1"
    local rule="$2"
    local file="$3"
    local line="$4"
    local message="$5"
    local suggestion="${6:-}"
    findings+=("$(jq -n \
        --arg perspective "architecture" \
        --arg severity "${severity}" \
        --arg rule "${rule}" \
        --arg file "${file}" \
        --argjson line "${line}" \
        --arg message "${message}" \
        --arg suggestion "${suggestion}" \
        '{perspective: $perspective, severity: $severity, rule: $rule, file: $file, line: $line, message: $message, suggestion: ($suggestion | select(. != ""))}')")
    if [ "${severity}" = "critical" ]; then
        exit_code=1
    fi
}

cd "${REPO_DIR}"

# 1. Compare changed file paths against expected layout.
if [ -f "CONTRIBUTING.md" ] || [ -f "CODING_STANDARDS.md" ]; then
    # Heuristic: shell scripts should live under src/ or scripts/ or test/.
    mapfile -t changed_files < <(git diff --name-only "${BASE_REF}...${TARGET_REF}" 2>/dev/null | grep '\.sh$' || true)
    for file in "${changed_files[@]}"; do
        case "${file}" in
            src/*|scripts/*|test/*|.githooks/*)
                ;;
            *)
                add_finding "warning" "unexpected-shell-location" "${file}" "1" "shell script outside expected directories (src/, scripts/, test/, .githooks/)" "move script to an expected location or document the exception"
                ;;
        esac
    done
fi

# 2. Detect repeated code blocks across changed shell scripts (simple 3-line hash heuristic).
mapfile -t changed_shell_scripts < <(git diff --name-only "${BASE_REF}...${TARGET_REF}" 2>/dev/null | grep '\.sh$' || true)
declare -A block_counts
declare -A block_locations
for script in "${changed_shell_scripts[@]}"; do
    if [ -f "${script}" ]; then
        # Strip comments and empty lines, then hash sliding 3-line windows.
        awk '!/^\s*#/ && NF' "${script}" | while IFS= read -r line; do
            echo "${line}"
        done | \
        awk 'NR>=3 {print (NR-2)":"(NR-1)":"NR; for(i=NR-2;i<=NR;i++) print a[i]} {a[NR]=$0}' \
        > /tmp/blocks.txt 2>/dev/null || true
    fi
done

# 3. Speculative generality check: flags for common over-engineering patterns.
mapfile -t all_changed < <(git diff --name-only "${BASE_REF}...${TARGET_REF}" 2>/dev/null || true)
for file in "${all_changed[@]}"; do
    if [ -f "${file}" ]; then
        if grep -nE '\bTODO\s*:\s*future\b|\bfuture\s+(agents?|use|need)|\bpluggable\s+architecture\b|\bplugin\s+system\b' "${file}" >/dev/null 2>&1; then
            add_finding "warning" "speculative-generality" "${file}" "1" "change contains speculative-future language or plugin-system wording" "remove speculative hooks; add only what the current spec needs"
        fi
    fi
done

# 4. Check for middle-man functions: functions that are only a single call to another function.
for script in "${changed_shell_scripts[@]}"; do
    if [ -f "${script}" ]; then
        awk '
            /^[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{/ { name=$1; body=0; next }
            name && /^\s*\}/ {
                if (body == 1) print name " may be a middle-man";
                name=""; body=0;
            }
            name { body++ }
        ' "${script}" | while IFS= read -r msg; do
            add_finding "warning" "middle-man" "${script}" "1" "${msg}" "inline the single call or justify the wrapper"
        done
    fi
done

# 5. Dependency cycle detection for Python projects.
if [ -f "pyproject.toml" ] && command -v pydeps >/dev/null 2>&1; then
    if ! pydeps --max-bacon 4 --show-deps . >/tmp/pydeps.json 2>&1; then
        add_finding "info" "pydeps-unavailable" "" "null" "pydeps could not analyse Python imports" "verify pydeps configuration"
    else
        if jq -e '.. | objects | select(.cycles? | length > 0)' /tmp/pydeps.json >/dev/null 2>&1; then
            add_finding "critical" "python-import-cycle" "" "null" "Python import cycle detected" "break the cycle by inverting a dependency or introducing an interface"
        fi
    fi
fi

duration_ms=$(( $(date +%s%3N) - start_ms ))

status="pass"
if [ "${exit_code}" -ne 0 ]; then
    status="fail"
fi

jq -n \
    --arg name "architecture" \
    --arg status "${status}" \
    --argjson exit_code "${exit_code}" \
    --argjson duration_ms "${duration_ms}" \
    --argjson findings "$(printf '%s\n' "${findings[@]}" | jq -s '.')" \
    '{name: $name, status: $status, exit_code: $exit_code, duration_ms: $duration_ms, findings: $findings}' \
    > "${REPORT}"

exit "${exit_code}"
