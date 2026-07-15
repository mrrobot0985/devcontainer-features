#!/bin/sh
set -e

# review-correctness.sh — Check tests, types, syntax.
# Usage: review-correctness.sh <branch> <workspace>

BRANCH="${1:-}"
WORKSPACE="${2:-.}"
cd "$WORKSPACE"

ok=true

# Check for syntax errors in shell scripts
for sh in $(git diff --name-only origin/main.."$BRANCH" 2>/dev/null | grep '\.sh$' || true); do
    [ -f "$sh" ] || continue
    if ! sh -n "$sh" 2>/dev/null; then
        echo "FAIL: syntax error in $sh"
        ok=false
    fi
done

# Run npm test if package.json exists
if [ -f "package.json" ] && command -v npm >/dev/null 2>&1; then
    if ! npm test --if-present >/dev/null 2>&1; then
        echo "FAIL: npm test failed"
        ok=false
    fi
fi

# Run pytest if pytest.ini or pyproject.toml exists
if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
    if command -v pytest >/dev/null 2>&1; then
        if ! pytest >/dev/null 2>&1; then
            echo "FAIL: pytest failed"
            ok=false
        fi
    fi
fi

if [ "$ok" = true ]; then
    echo "PASS: correctness"
    exit 0
else
    echo "FAIL: correctness"
    exit 1
fi
