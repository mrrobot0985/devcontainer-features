#!/bin/bash
set -e

source dev-container-features-test-lib

check "grok command exists" command -v grok
check "agent command exists" command -v agent
check "grok version works" grok --version
check "grok home directory exists" test -d /home/vscode/.grok
check "grok bin in path" test -x /home/vscode/.grok/bin/grok
check "profile.d script exists" test -f /etc/profile.d/grok-build.sh

reportResults