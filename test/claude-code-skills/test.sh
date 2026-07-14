#!/bin/bash
set -e

source dev-container-features-test-lib

SKILLS_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/skills"

check "skills directory exists" test -d "$SKILLS_DIR"

reportResults
