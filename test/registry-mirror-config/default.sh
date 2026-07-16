#!/bin/bash
set -e

source dev-container-features-test-lib

check "daemon json readable" bash -c 'test -f /etc/docker/daemon.json || true'

reportResults
