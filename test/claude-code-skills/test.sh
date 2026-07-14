#!/bin/bash
set -e

source dev-container-features-test-lib

SKILLS_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/skills"
SCENARIO_NAME="${SCENARIO_NAME:-default}"

case "$SCENARIO_NAME" in
    default)
        check "default: skills directory exists" test -d "$SKILLS_DIR"
        check "default: engineering skill installed (to-spec)" test -d "$SKILLS_DIR/to-spec"
        check "default: engineering skill installed (code-review)" test -d "$SKILLS_DIR/code-review"
        check "default: productivity skill installed (grill-me)" test -d "$SKILLS_DIR/grill-me"
        check "default: productivity skill installed (teach)" test -d "$SKILLS_DIR/teach"
        check "default: misc skill not installed (git-guardrails-claude-code)" test ! -e "$SKILLS_DIR/git-guardrails-claude-code"
        check "default: personal skill not installed (edit-article)" test ! -e "$SKILLS_DIR/edit-article"
        ;;
    engineering_only)
        check "engineering_only: skills directory exists" test -d "$SKILLS_DIR"
        check "engineering_only: engineering skill installed (to-spec)" test -d "$SKILLS_DIR/to-spec"
        check "engineering_only: engineering skill installed (code-review)" test -d "$SKILLS_DIR/code-review"
        check "engineering_only: productivity skill not installed (grill-me)" test ! -e "$SKILLS_DIR/grill-me"
        check "engineering_only: misc skill not installed (git-guardrails-claude-code)" test ! -e "$SKILLS_DIR/git-guardrails-claude-code"
        check "engineering_only: personal skill not installed (edit-article)" test ! -e "$SKILLS_DIR/edit-article"
        ;;
    all_categories)
        check "all_categories: skills directory exists" test -d "$SKILLS_DIR"
        check "all_categories: engineering skill installed (to-spec)" test -d "$SKILLS_DIR/to-spec"
        check "all_categories: engineering skill installed (code-review)" test -d "$SKILLS_DIR/code-review"
        check "all_categories: productivity skill installed (grill-me)" test -d "$SKILLS_DIR/grill-me"
        check "all_categories: productivity skill installed (teach)" test -d "$SKILLS_DIR/teach"
        check "all_categories: misc skill installed (git-guardrails-claude-code)" test -d "$SKILLS_DIR/git-guardrails-claude-code"
        check "all_categories: misc skill installed (setup-pre-commit)" test -d "$SKILLS_DIR/setup-pre-commit"
        check "all_categories: personal skill installed (edit-article)" test -d "$SKILLS_DIR/edit-article"
        check "all_categories: personal skill installed (obsidian-vault)" test -d "$SKILLS_DIR/obsidian-vault"
        ;;
    none)
        check "none: skills directory exists" test -d "$SKILLS_DIR"
        check "none: skills directory is empty" test -z "$(ls -A "$SKILLS_DIR" 2>/dev/null)"
        ;;
    disabled_matt_pocock)
        check "disabled_matt_pocock: skills directory exists" test -d "$SKILLS_DIR"
        check "disabled_matt_pocock: skills directory is empty" test -z "$(ls -A "$SKILLS_DIR" 2>/dev/null)"
        ;;
    *)
        echo "ERROR: Unknown scenario '$SCENARIO_NAME'" >&2
        exit 1
        ;;
esac

reportResults
