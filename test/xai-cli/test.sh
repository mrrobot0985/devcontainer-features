#!/bin/bash
set -e

source dev-container-features-test-lib

check "grok is installed" command -v grok
check "grok --version runs" bash -c "grok --version"

reportResults
