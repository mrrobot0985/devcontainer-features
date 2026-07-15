#!/bin/bash
# Safety perspective for the multi-perspective review system.
# Runs inside an isolated Docker sandcastle.
# Emits /out/safety.json.

set -uo pipefail

TARGET_REF="${TARGET_REF:-HEAD}"
BASE_REF="${BASE_REF:-main}"
REPO_DIR="${REPO_DIR:-/repo}"
OUT_DIR="${OUT_DIR:-/out}"
REPORT="${OUT_DIR}/safety.json"

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
        --arg perspective "safety" \
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

# 1. Secret scanning with gitleaks if available.
if command -v gitleaks >/dev/null 2>&1; then
    if ! gitleaks detect --source . --log-opts "${BASE_REF}...${TARGET_REF}" --no-git -v >/tmp/gitleaks.log 2>&1; then
        while IFS= read -r line; do
            file=$(echo "${line}" | grep -oE 'File:\s*\S+' | awk '{print $2}')
            lineno=$(echo "${line}" | grep -oE 'Line:\s*[0-9]+' | awk '{print $2}')
            finding=$(echo "${line}" | grep -oE 'Finding:\s*.+' | sed 's/Finding: //')
            add_finding "critical" "no-secrets" "${file:-.}" "${lineno:-1}" "gitleaks: ${finding:-possible secret}" "revoke the credential, purge from history, and add a false-positive justification if needed"
        done < <(grep -E 'Finding:' /tmp/gitleaks.log || true)
    fi
else
    add_finding "info" "gitleaks-missing" "" "null" "gitleaks not installed; install gitleaks in the safety sandcastle image" ""
fi

# 2. Conventional commit check on commits since base.
if command -v commitlint >/dev/null 2>&1; then
    if ! git log "${BASE_REF}..${TARGET_REF}" --format=%s | commitlint >/tmp/commitlint.log 2>&1; then
        while IFS= read -r line; do
            add_finding "critical" "conventional-commits" "" "null" "commitlint: ${line}" "rewrite the commit message to follow Conventional Commits"
        done < <(cat /tmp/commitlint.log || true)
    fi
else
    add_finding "info" "commitlint-missing" "" "null" "commitlint not installed; install @commitlint/cli in the safety sandcastle image" ""
fi

# 3. No AI attribution in commits.
mapfile -t bad_commits < <(git log "${BASE_REF}..${TARGET_REF}" --format='%H %s' 2>/dev/null | grep -iE 'generated (by|with)|assisted by|created with|Co-Authored-By:|Co-authored-by|model|LLM|assistant|AI[- ]generated' || true)
for commit_line in "${bad_commits[@]}"; do
    hash=$(echo "${commit_line}" | cut -d' ' -f1)
    subject=$(echo "${commit_line}" | cut -d' ' -f2-)
    add_finding "critical" "no-attribution" "" "null" "commit ${hash} contains attribution wording: ${subject}" "rewrite the commit message to remove attribution markers"
done

# 4. No AI attribution in changed files.
mapfile -t changed_files < <(git diff --name-only "${BASE_REF}...${TARGET_REF}" 2>/dev/null || true)
ATTRIBUTION_RE='generated (by|with)|assisted by|created with|Co-Authored-By|\bmodel\b|LLM|assistant|\bAI[- ]generated\b'
for file in "${changed_files[@]}"; do
    if [ -f "${file}" ]; then
        if grep -niE "${ATTRIBUTION_RE}" "${file}" >/dev/null 2>&1; then
            lineno=$(grep -niE "${ATTRIBUTION_RE}" "${file}" | head -1 | cut -d: -f1)
            add_finding "critical" "no-attribution" "${file}" "${lineno:-1}" "file contains AI attribution marker" "remove the attribution marker"
        fi
    fi
done

# 5. No git config overrides in changed code.
for file in "${changed_files[@]}"; do
    if [ -f "${file}" ]; then
        if grep -niE 'git -c (user\.email|user\.name|commit\.gpgsign|tag\.gpgsign|user\.signingkey|gpg\.format|gpg\.ssh\.program)|GIT_AUTHOR_EMAIL|GIT_AUTHOR_NAME|GIT_COMMITTER_EMAIL|GIT_COMMITTER_NAME' "${file}" >/dev/null 2>&1; then
            lineno=$(grep -niE 'git -c (user\.email|user\.name|commit\.gpgsign|tag\.gpgsign|user\.signingkey|gpg\.format|gpg\.ssh\.program)|GIT_AUTHOR_EMAIL|GIT_AUTHOR_NAME|GIT_COMMITTER_EMAIL|GIT_COMMITTER_NAME' "${file}" | head -1 | cut -d: -f1)
            add_finding "critical" "no-git-config-override" "${file}" "${lineno:-1}" "inline git config override detected" "remove the override; rely on global/repo git configuration"
        fi
    fi
done

# 6. Human sovereignty: destructive operations must carry an approval marker.
# Common package-manager/build cleanups are excluded from the warning.
is_known_cleanup() {
    local line="$1"
    case "${line}" in
        *'/var/lib/apt/lists/'*|*'/var/cache/apk/'*|*'/var/cache/yum/'*|*'/var/cache/dnf/'*|*'/tmp/'*)
            return 0
            ;;
    esac
    return 1
}

for file in "${changed_files[@]}"; do
    if [ -f "${file}" ]; then
        if grep -niE '\b(rm -rf|docker rm -f|git reset --hard|git push --force|git filter-branch|git rebase -i|terraform destroy|kubectl delete)\b' "${file}" >/dev/null 2>&1; then
            if ! grep -qiE '#\s*(HUMAN|MANUAL|EXPLICIT)[- ]?APPROVED|#\s*requires?[- ]?(human|manual)[- ]?approval' "${file}" >/dev/null 2>&1; then
                first_match=$(grep -niE '\b(rm -rf|docker rm -f|git reset --hard|git push --force|git filter-branch|git rebase -i|terraform destroy|kubectl delete)\b' "${file}" | head -1)
                lineno=$(echo "${first_match}" | cut -d: -f1)
                content=$(echo "${first_match}" | cut -d: -f2-)
                if ! is_known_cleanup "${content}"; then
                    add_finding "warning" "human-sovereignty" "${file}" "${lineno:-1}" "destructive operation lacks explicit human-approval marker" "add a comment like '# HUMAN-APPROVED' or gate the operation behind out-of-band approval"
                fi
            fi
        fi
    fi
done

# 7. No private key or credential files committed.
for file in "${changed_files[@]}"; do
    case "${file}" in
        *.pem|*.key|*.p12|*.pfx|*.env|*/secrets/*|*/credentials/*|~/.ssh/*|~/.config/gh/hosts.yml)
            add_finding "critical" "no-secrets" "${file}" "1" "sensitive file path committed" "remove the file, purge from history, and use environment variables or a secret store"
            ;;
    esac
done

duration_ms=$(( $(date +%s%3N) - start_ms ))

status="pass"
if [ "${exit_code}" -ne 0 ]; then
    status="fail"
fi

jq -n \
    --arg name "safety" \
    --arg status "${status}" \
    --argjson exit_code "${exit_code}" \
    --argjson duration_ms "${duration_ms}" \
    --argjson findings "$(printf '%s\n' "${findings[@]}" | jq -s '.')" \
    '{name: $name, status: $status, exit_code: $exit_code, duration_ms: $duration_ms, findings: $findings}' \
    > "${REPORT}"

exit "${exit_code}"
