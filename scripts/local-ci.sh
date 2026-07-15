#!/bin/bash
# Local CI gate — run this before pushing to catch failures early.
#
# This script is a convenience helper for local pre-push validation. It is NOT
# invoked by GitHub Actions; CI runs the workflows below independently.
#
# Checks performed:
#   1. shellcheck on every install.sh, uninstall.sh, test script, and helper script
#      (mirrors the shellcheck job in .github/workflows/validate.yml).
#   2. README sync check with scripts/generate-feature-readmes.py --check
#      (mirrors the readme-sync job in .github/workflows/validate.yml).
#   3. Workflow validation via act -j validate
#      (runs the validate job from .github/workflows/validate.yml).
#   4. Dry-run release via act -j deploy --dryrun
#      (exercises .github/workflows/release.yaml without publishing).
#   5. Feature smoke tests with npx @devcontainers/cli
#      (runs --skip-scenarios --skip-duplicated for every feature).
#
# Prerequisites:
#   - Docker running
#   - act installed (https://github.com/nektos/act#installation)
#   - gh CLI authenticated (for GITHUB_TOKEN injection)
#   - uv installed (https://docs.astral.sh/uv/)
#
# Limitations:
#   - Full matrix tests via act hit Docker-in-Docker edge cases; use npx directly for those.

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

# --- Shellcheck all install.sh and uninstall.sh ---
echo ""
echo "--- Running shellcheck on install.sh and uninstall.sh files ---"
for script in src/*/install.sh src/*/uninstall.sh; do
    if [ -f "$script" ]; then
        if shellcheck "$script"; then
            pass "shellcheck $(basename "$script")"
        else
            fail "shellcheck $(basename "$script")"
        fi
    fi
done

# --- Sync per-feature READMEs with devcontainer-feature.json ---
echo ""
echo "--- Running README generator check ---"
if ! command -v uv >/dev/null 2>&1; then
    fail "uv is not installed. Install from https://docs.astral.sh/uv/getting-started/installation/"
    exit 1
fi
if uv run python scripts/generate-feature-readmes.py --check; then
    pass "README generator check"
else
    fail "README generator check"
fi

# --- Markdown formatting check ---
echo ""
echo "--- Checking markdown formatting ---"
if command -v uv >/dev/null 2>&1; then
    if uvx --with mdformat-gfm mdformat --check docs/ .github/CONTRIBUTING.md .github/CODE_OF_CONDUCT.md .github/SECURITY.md; then
        pass "mdformat check"
    else
        fail "mdformat check"
    fi
else
    warn "uv not installed; skipping markdown format check"
fi

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
# These are quick default-install tests for every feature, run directly with
# npx to avoid Docker-in-Docker issues that act sometimes hits. Scenario and
# global integration tests are left for the full CI matrix in test.yaml.
echo ""
echo "--- Running npx devcontainer features test (dynamic discovery) ---"

BASE_IMAGE="mcr.microsoft.com/devcontainers/base:ubuntu"
# Reserved for features that cannot be exercised without an authenticated
# GitHub token (currently none). Add feature IDs here if that changes.
TOKEN_REQUIRED_FEATURES=()

# Discover all feature IDs from src/*/ directories that contain JSON metadata.
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
