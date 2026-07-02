#!/bin/bash
set -e

source dev-container-features-test-lib

SKILLS_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude/skills"

# Verify directory exists
check "skills directory exists" test -d "$SKILLS_DIR"

# Verify at least one skill was installed (default enables engineering + productivity)
check "skills directory is not empty" bash -c "test -n \"$(ls -A '$SKILLS_DIR')\""

reportResults
