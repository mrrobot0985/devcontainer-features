#!/bin/bash
set -e

source dev-container-features-test-lib

SKILLS_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/skills"

check "skills directory exists" test -d "$SKILLS_DIR"
check "skills directory is not empty" test -n "$(ls -A "$SKILLS_DIR" 2>/dev/null)"

reportResults
