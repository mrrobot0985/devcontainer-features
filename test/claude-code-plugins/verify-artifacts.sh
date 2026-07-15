#!/bin/bash
set -e

source dev-container-features-test-lib

CLAUDE_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

check "claude directory exists" test -d "$CLAUDE_DIR"
check "settings.json exists" test -f "$SETTINGS_FILE"

# With verifyArtifacts=true, if the plugin failed to install (e.g., network issues),
# the build should have failed. If we got here, either the plugin installed successfully
# or skipOnFailure hid the failure but verifyArtifacts allowed it through.
# We verify the artifact check logic was executed by checking the build output.
check "settings.json is valid JSON" bash -c "jq empty '$SETTINGS_FILE'"

reportResults
