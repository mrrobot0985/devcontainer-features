#!/bin/bash
set -e

source dev-container-features-test-lib

RULES_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/rules"

ENFORCE_SAFETY="${ENFORCESAFETY:-true}"
STANDARDIZE_WORKFLOW="${STANDARDIZEWORKFLOW:-true}"
PROTECT_GIT="${PROTECTGIT:-true}"
PREFER_PYTHON_TOOLING="${PREFERPYTHONTOOLING:-false}"

# Verify directory exists
check "rules directory exists" test -d "$RULES_DIR"

# Safety rules — verify presence when enabled
if [ "$ENFORCE_SAFETY" = "true" ]; then
    check "00-human-sovereignty.md exists" test -f "$RULES_DIR/00-human-sovereignty.md"
    check "00-no-attribution.md exists" test -f "$RULES_DIR/00-no-attribution.md"
    check "00-no-secrets.md exists" test -f "$RULES_DIR/00-no-secrets.md"
    check "human sovereignty header present" bash -c "grep -q 'Human Sovereignty' '$RULES_DIR/00-human-sovereignty.md'"
    check "no secrets header present" bash -c "grep -q 'No Secrets' '$RULES_DIR/00-no-secrets.md'"
fi

# Workflow rules — verify presence when enabled
if [ "$STANDARDIZE_WORKFLOW" = "true" ]; then
    check "00-mcp-tools-first.md exists" test -f "$RULES_DIR/00-mcp-tools-first.md"
    check "00-skill-discovery.md exists" test -f "$RULES_DIR/00-skill-discovery.md"
    check "04-anti-overengineering.md exists" test -f "$RULES_DIR/04-anti-overengineering.md"
    check "01-conventional-commits.md exists" test -f "$RULES_DIR/01-conventional-commits.md"
    check "03-branch-strategy.md exists" test -f "$RULES_DIR/03-branch-strategy.md"
fi

# Git protection rules — verify presence when enabled
if [ "$PROTECT_GIT" = "true" ]; then
    check "00-no-git-config-override.md exists" test -f "$RULES_DIR/00-no-git-config-override.md"
fi

# Python tooling rules — verify presence when enabled
if [ "$PREFER_PYTHON_TOOLING" = "true" ]; then
    check "00-prefer-uv.md exists" test -f "$RULES_DIR/00-prefer-uv.md"
    check "01-markdown-formatting.md exists" test -f "$RULES_DIR/01-markdown-formatting.md"
fi

# When all options are disabled, the directory should exist but be empty
if [ "$ENFORCE_SAFETY" != "true" ] && [ "$STANDARDIZE_WORKFLOW" != "true" ] && [ "$PROTECT_GIT" != "true" ] && [ "$PREFER_PYTHON_TOOLING" != "true" ]; then
    check "rules directory is empty" bash -c "[ -z \"\$(find \"$RULES_DIR\" -maxdepth 1 -type f -name '*.md' -print 2>/dev/null)\" ]"
fi

reportResults
