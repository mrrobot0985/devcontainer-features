#!/bin/bash
set -e

source dev-container-features-test-lib

# Check grok installation - try direct path since PATH may not include /usr/local/bin in test
check "grok binary exists" test -x /usr/local/bin/grok
check "agent binary exists" test -x /usr/local/bin/agent
check "grok version works" /usr/local/bin/grok --version
check "grok home directory exists" test -d /root/.grok
check "grok bin exists" test -x /root/.grok/bin/grok
check "profile.d script exists" test -f /etc/profile.d/grok-build.sh

reportResults