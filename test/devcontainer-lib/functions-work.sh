#!/bin/bash
set -e

source dev-container-features-test-lib

# Source the library
source /usr/local/share/devcontainer-lib/devcontainer-lib.sh

check "dc_detect_arch returns amd64 or arm64" bash -c "dc_detect_arch | grep -qE 'amd64|arm64'"
check "dc_get_remote_user returns a user" bash -c "[ -n \"$(dc_get_remote_user)\" ]"
check "dc_get_remote_home returns a path" bash -c "[ -d \"$(dc_get_remote_home)\" ]"
check "dc_retry succeeds on first try" bash -c "dc_retry 'true'"
check "dc_wait_for succeeds immediately" bash -c "dc_wait_for 'true'"
check "dc_log_info outputs correctly" bash -c "dc_log_info 'test' | grep -q 'INFO'"

reportResults
