#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-otel-start
check "config exists" test -f /etc/otelcol-contrib/config.yaml

reportResults
