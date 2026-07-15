#!/bin/bash
# Correctness perspective for the multi-perspective review system.
# Runs inside an isolated Docker sandcastle.
# Emits /out/correctness.json.

set -uo pipefail

TARGET_REF="${TARGET_REF:-HEAD}"
BASE_REF="${BASE_REF:-main}"
REPO_DIR="${REPO_DIR:-/repo}"
OUT_DIR="${OUT_DIR:-/out}"
REPORT="${OUT_DIR}/correctness.json"

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
        --arg perspective "correctness" \
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

# Determine changed shell scripts between base and target.
mapfile -t changed_shell_scripts < <(git diff --name-only "${BASE_REF}...${TARGET_REF}" 2>/dev/null | grep '\.sh$' || true)

# 1. Bash parse check.
for script in "${changed_shell_scripts[@]}"; do
    if [ -f "${script}" ]; then
        if ! bash -n "${script}" >/dev/null 2>&1; then
            add_finding "critical" "bash-parse" "${script}" "1" "bash -n failed: syntax error" "fix the syntax error and re-run bash -n"
        fi
    fi
done

# 2. shellcheck on changed shell scripts.
if command -v shellcheck >/dev/null 2>&1; then
    for script in "${changed_shell_scripts[@]}"; do
        if [ -f "${script}" ]; then
            while IFS= read -r line; do
                severity="warning"
                if echo "${line}" | grep -qE '^\s*\^-- (SC|shellcheck)'; then
                    # shellcheck severity hints are not in the compact format; skip summary lines
                    continue
                fi
                sc_id=$(echo "${line}" | grep -oE 'SC[0-9]{4}' | head -1)
                sc_line=$(echo "${line}" | awk -F: '{print $2}' | grep -oE '[0-9]+' | head -1)
                if [ -n "${sc_id}" ]; then
                    # Classify a few shellcheck codes as critical.
                    case "${sc_id}" in
                        SC2148|SC1000|SC1071|SC1072|SC1073)
                            severity="critical"
                            ;;
                    esac
                    add_finding "${severity}" "${sc_id}" "${script}" "${sc_line:-1}" "shellcheck: ${line}" "see https://www.shellcheck.net/wiki/${sc_id}"
                fi
            done < <( shellcheck --format=gcc "${script}" 2>&1 || true )
        fi
    done
else
    add_finding "info" "shellcheck-missing" "" "null" "shellcheck not installed; skipping shell script lint" "include shellcheck in the correctness sandcastle image"
fi

# 3. JSON parse check for devcontainer-feature.json files.
mapfile -t changed_json < <(git diff --name-only "${BASE_REF}...${TARGET_REF}" 2>/dev/null | grep 'devcontainer-feature\.json$' || true)
for file in "${changed_json[@]}"; do
    if [ -f "${file}" ]; then
        if ! jq empty "${file}" >/dev/null 2>&1; then
            add_finding "critical" "json-parse" "${file}" "1" "devcontainer-feature.json is not valid JSON" "fix JSON syntax"
        fi
    fi
done

# 4. Run project-level tests if a test runner is present.
if [ -f "pyproject.toml" ] && command -v pytest >/dev/null 2>&1; then
    if ! pytest -q >/tmp/pytest.log 2>&1; then
        add_finding "critical" "pytest-failed" "" "null" "pytest suite failed" "see /tmp/pytest.log inside the container"
    fi
elif [ -f "package.json" ] && command -v npm >/dev/null 2>&1; then
    if ! npm test >/tmp/npmtest.log 2>&1; then
        add_finding "critical" "npm-test-failed" "" "null" "npm test failed" "see /tmp/npmtest.log inside the container"
    fi
fi

# 5. Markdown lint if mdformat is present (project style check).
if command -v mdformat >/dev/null 2>&1; then
    mapfile -t changed_md < <(git diff --name-only "${BASE_REF}...${TARGET_REF}" 2>/dev/null | grep '\.md$' || true)
    for file in "${changed_md[@]}"; do
        if [ -f "${file}" ]; then
            if ! mdformat --check "${file}" >/dev/null 2>&1; then
                add_finding "warning" "mdformat" "${file}" "1" "markdown formatting does not match mdformat style" "run mdformat on the file"
            fi
        fi
    done
fi

duration_ms=$(( $(date +%s%3N) - start_ms ))

# Build report.
status="pass"
if [ "${exit_code}" -ne 0 ]; then
    status="fail"
fi

jq -n \
    --arg name "correctness" \
    --arg status "${status}" \
    --argjson exit_code "${exit_code}" \
    --argjson duration_ms "${duration_ms}" \
    --argjson findings "$(printf '%s\n' "${findings[@]}" | jq -s '.')" \
    '{name: $name, status: $status, exit_code: $exit_code, duration_ms: $duration_ms, findings: $findings}' \
    > "${REPORT}"

exit "${exit_code}"
