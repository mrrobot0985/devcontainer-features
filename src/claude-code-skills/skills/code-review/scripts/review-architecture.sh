#!/bin/sh
set -e

# review-architecture.sh — Check patterns, deps, abstractions.
# Usage: review-architecture.sh <branch> <workspace>

BRANCH="${1:-}"
WORKSPACE="${2:-.}"
cd "$WORKSPACE"

ok=true

# Check for circular imports (Python simple heuristic)
for py in $(git diff --name-only origin/main.."$BRANCH" 2>/dev/null | grep '\.py$' || true); do
    [ -f "$py" ] || continue
    if grep -qE 'from \. import' "$py" 2>/dev/null; then
        echo "WARN: possible circular import in $py"
    fi
done

# Check branch naming convention
if ! echo "$BRANCH" | grep -qE '^(feat|fix|docs|chore|ci|refactor|test)/'; then
    echo "WARN: branch '$BRANCH' does not follow conventional naming"
    ok=false
fi

# Check for large files
for f in $(git diff --name-only origin/main.."$BRANCH" 2>/dev/null || true); do
    [ -f "$f" ] || continue
    size="$(stat -c%s "$f" 2>/dev/null || echo 0)"
    if [ "$size" -gt 1048576 ]; then
        echo "WARN: $f is larger than 1MB ($size bytes)"
    fi
done

if [ "$ok" = true ]; then
    echo "PASS: architecture"
    exit 0
else
    echo "FAIL: architecture"
    exit 1
fi
