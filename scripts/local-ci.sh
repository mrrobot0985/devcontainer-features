#!/bin/bash
# Local CI gate — run this before pushing to catch failures early.
# Uses act (https://github.com/nektos/act) for workflow simulation and
# npx @devcontainers/cli for feature-level testing.
#
# Prerequisites:
#   - Docker running
#   - act installed (https://github.com/nektos/act#installation)
#   - gh CLI authenticated (for GITHUB_TOKEN injection)
#
# Limitations:
#   - Full matrix tests via act hit Docker-in-Docker edge cases; use npx directly for those

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() {
    echo -e "${GREEN}PASS${NC}: $1"
    ((PASS+=1))
}

fail() {
    echo -e "${RED}FAIL${NC}: $1"
    ((FAIL+=1))
}

warn() {
    echo -e "${YELLOW}WARN${NC}: $1"
}

echo "========================================"
echo "  Local CI Gate"
echo "  Repo: $(basename "$REPO_ROOT")"
echo "========================================"
echo ""

# --- Check prerequisites ---
if ! command -v act >/dev/null 2>&1; then
    fail "act is not installed. Install from https://github.com/nektos/act"
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    fail "docker is not installed"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    fail "docker daemon is not running"
    exit 1
fi

pass "prerequisites (act, docker)"

# --- Shellcheck all install.sh ---
echo ""
echo "--- Running shellcheck on install.sh files ---"
for script in src/*/install.sh; do
    if [ -f "$script" ]; then
        if shellcheck "$script"; then
            pass "shellcheck $(basename "$(dirname "$script")")"
        else
            fail "shellcheck $(basename "$(dirname "$script")")"
        fi
    fi
done

# --- Validate devcontainer-feature.json files ---
echo ""
echo "--- Running act: validate workflow ---"
if act -j validate >/dev/null 2>&1; then
    pass "act -j validate"
else
    fail "act -j validate"
fi

# --- Dry-run release workflow ---
echo ""
echo "--- Running act: release workflow (dry-run) ---"
if act -j deploy --dryrun --secret GITHUB_TOKEN="$(gh auth token 2>/dev/null || echo '')" >/dev/null 2>&1; then
    pass "act -j deploy --dryrun"
else
    fail "act -j deploy --dryrun"
fi

# --- Feature-level smoke tests ---
echo ""
echo "--- Running npx devcontainer features test (dynamic discovery) ---"

BASE_IMAGE="mcr.microsoft.com/devcontainers/base:ubuntu"
TOKEN_REQUIRED_FEATURES=()

mapfile -t features < <(for dir in src/*/; do
    if [ -f "${dir}devcontainer-feature.json" ]; then
        basename "$dir"
    fi
done)

for feature in "${features[@]}"; do
    if printf '%s\n' "${TOKEN_REQUIRED_FEATURES[@]}" | grep -qx "$feature" && [ -z "${GITHUB_TOKEN:-}" ]; then
        warn "Skipping $feature (requires GITHUB_TOKEN)"
        continue
    fi
    echo "Testing feature: $feature..."
    if npx -y @devcontainers/cli features test \
        --skip-scenarios \
        --skip-duplicated \
        --features "$feature" \
        --base-image "$BASE_IMAGE" \
        --project-folder "$REPO_ROOT" >/dev/null 2>&1; then
        pass "feature test: $feature"
    else
        fail "feature test: $feature"
    fi
done


# --- Summary ---
echo ""
echo "========================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Gate FAILED.${NC} Fix issues before pushing."
    exit 1
else
    echo -e "${GREEN}Gate PASSED.${NC} Safe to push."
    exit 0
fi
