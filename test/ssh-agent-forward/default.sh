#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-ssh-agent-forward
check "setup script exists" test -x /usr/local/share/ssh-agent-forward/setup-ssh-agent.sh

reportResults
