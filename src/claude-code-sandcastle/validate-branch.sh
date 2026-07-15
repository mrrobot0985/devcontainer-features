#!/usr/bin/env bash
set -euo pipefail

# Validate Branch
# Checks conventional commits, branch naming, and per-type gates.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/.ralph/logs/validate-branch.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    local msg="[$(date -Iseconds)] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
log "Validating branch: ${BRANCH_NAME}"

# Branch naming convention
BRANCH_PATTERN='^(feat|fix|chore|docs|refactor|test|ci)\/[a-z0-9-]+$'
if ! echo "$BRANCH_NAME" | grep -qE "$BRANCH_PATTERN"; then
    log "ERROR: Branch name does not match pattern: ${BRANCH_PATTERN}"
    log "Expected: <type>/<description> using kebab-case"
    exit 1
fi

log "Branch naming: PASS"

# Conventional commits
COMMIT_PATTERN='^(feat|fix|docs|style|refactor|test|chore|ci|build|perf)(\([^)]+\))?!?: .+'
BAD_COMMITS=$(git log --format='%s' main..HEAD | grep -vE "$COMMIT_PATTERN" || true)
if [ -n "$BAD_COMMITS" ]; then
    log "ERROR: Non-conventional commits found:"
    echo "$BAD_COMMITS"
    exit 1
fi

log "Conventional commits: PASS"

# Per-type gates
BRANCH_TYPE=$(echo "$BRANCH_NAME" | cut -d'/' -f1)
case "$BRANCH_TYPE" in
    feat)
        log "Type gate: feature branch — ensure tests and docs updated"
        ;;
    fix)
        log "Type gate: fix branch — ensure regression test added"
        ;;
    chore|docs|refactor|test|ci)
        log "Type gate: ${BRANCH_TYPE} branch — standard checks"
        ;;
    *)
        log "ERROR: Unknown branch type: ${BRANCH_TYPE}"
        exit 1
        ;;
esac

log "Branch validation complete"
