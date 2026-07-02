#!/bin/bash
set -e

source dev-container-features-test-lib

RULES_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/rules"

# Verify directory exists
check "rules directory exists" test -d "$RULES_DIR"

# Safety rules
check "00-human-sovereignty.md exists" test -f "$RULES_DIR/00-human-sovereignty.md"
check "00-no-attribution.md exists" test -f "$RULES_DIR/00-no-attribution.md"
check "00-no-secrets.md exists" test -f "$RULES_DIR/00-no-secrets.md"

# Workflow rules
check "00-mcp-tools-first.md exists" test -f "$RULES_DIR/00-mcp-tools-first.md"
check "00-skill-discovery.md exists" test -f "$RULES_DIR/00-skill-discovery.md"
check "04-anti-overengineering.md exists" test -f "$RULES_DIR/04-anti-overengineering.md"
check "01-conventional-commits.md exists" test -f "$RULES_DIR/01-conventional-commits.md"
check "03-branch-strategy.md exists" test -f "$RULES_DIR/03-branch-strategy.md"

# Git protection rules
check "00-no-git-config-override.md exists" test -f "$RULES_DIR/00-no-git-config-override.md"

# Python tooling rules (should NOT exist in default scenario)
check "00-prefer-uv.md absent by default" test ! -f "$RULES_DIR/00-prefer-uv.md"
check "01-markdown-formatting.md absent by default" test ! -f "$RULES_DIR/01-markdown-formatting.md"

# Verify safety rule content
check "human sovereignty header present" bash -c "grep -q 'Human Sovereignty' '$RULES_DIR/00-human-sovereignty.md'"
check "no secrets header present" bash -c "grep -q 'No Secrets' '$RULES_DIR/00-no-secrets.md'"

reportResults
