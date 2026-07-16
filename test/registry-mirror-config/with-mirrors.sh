#!/bin/bash
set -e

source dev-container-features-test-lib

check "daemon json exists" test -f /etc/docker/daemon.json
check "mirrors configured" bash -c 'grep -q "mirror.example.com" /etc/docker/daemon.json'

reportResults
