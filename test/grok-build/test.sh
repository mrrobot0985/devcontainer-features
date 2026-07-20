#!/bin/bash
set -e

source dev-container-features-test-lib

# Check grok installation using file existence (not test -x)
check "grok symlink exists" test -L /usr/local/bin/grok
check "grok target exists" test -e /root/.grok/bin/grok
check "grok home directory exists" test -d /root/.grok
check "grok downloads exist" test -f /root/.grok/downloads/grok-linux-x86_64
check "profile.d script exists" test -f /etc/profile.d/grok-build.sh

reportResults