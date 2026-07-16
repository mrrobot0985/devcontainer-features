#!/bin/bash
set -e

source dev-container-features-test-lib

check "cli exists" command -v devcontainer-otel-start
check "config dir exists" test -d /etc/otelcol-contrib

reportResults
