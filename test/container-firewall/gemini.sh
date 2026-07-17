#!/bin/bash
set -e

source dev-container-features-test-lib

check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init
check "google includes generativelanguage" bash -c "jq -e '.google.domains | index(\"generativelanguage.googleapis.com\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "google includes cloudcode-pa for Gemini CLI" bash -c "jq -e '.google.domains | index(\"cloudcode-pa.googleapis.com\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "google includes cloudaicompanion" bash -c "jq -e '.google.domains | index(\"cloudaicompanion.googleapis.com\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "google includes oauth2" bash -c "jq -e '.google.domains | index(\"oauth2.googleapis.com\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "gemini extends google" bash -c "jq -e '.gemini.extends | index(\"google\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "gemini extends github" bash -c "jq -e '.gemini.extends | index(\"github\")' /usr/local/share/container-firewall/services.json >/dev/null"
check "gemini extends npm" bash -c "jq -e '.gemini.extends | index(\"npm\")' /usr/local/share/container-firewall/services.json >/dev/null"

set +e
sudo bash -c '/usr/local/bin/container-firewall-init >/tmp/gemini-dryrun.log 2>&1'
_init_status=$?
set -e

check "gemini dry run exits 0" test "$_init_status" -eq 0
check "no unknown service tags" bash -c "! grep -q 'Unknown service tag' /tmp/gemini-dryrun.log"
check "dry run resolves allowed domains" grep -qE "ipset add allowed-domains [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" /tmp/gemini-dryrun.log
check "dry run did not create ipsets" bash -c "! sudo ipset list allowed-domains >/dev/null 2>&1"

reportResults
