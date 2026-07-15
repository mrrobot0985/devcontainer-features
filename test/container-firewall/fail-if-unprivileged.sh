#!/bin/bash
set -e

source dev-container-features-test-lib

check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init

# Clear any rules/ipsets applied by the postCreateCommand during container build
# to ensure a clean state for the unprivileged test scenario.
sudo iptables -F 2>/dev/null || true
sudo iptables -X 2>/dev/null || true
sudo iptables -t nat -F 2>/dev/null || true
sudo iptables -t nat -X 2>/dev/null || true
sudo iptables -t mangle -F 2>/dev/null || true
sudo iptables -t mangle -X 2>/dev/null || true
sudo ipset destroy allowed-domains 2>/dev/null || true
sudo ipset destroy blocked-domains 2>/dev/null || true
sudo ipset destroy allowed-domains-v6 2>/dev/null || true
sudo ipset destroy blocked-domains-v6 2>/dev/null || true

# Simulate an environment where iptables is not functional.
mkdir -p /tmp/fakebin
cat > /tmp/fakebin/iptables <<'EOF'
#!/bin/sh
echo "iptables: Permission denied (you must be root)" >&2
exit 3
EOF
chmod +x /tmp/fakebin/iptables

set +e
sudo bash -c "PATH=/tmp/fakebin:$PATH /usr/local/bin/container-firewall-init >/tmp/init-fail.log 2>&1"
_init_status=$?
set -e

check "fails when unprivileged and failIfUnprivileged=true" test "$_init_status" -eq 1
check "error message mentions missing iptables" grep -q "iptables is not functional" /tmp/init-fail.log
check "error message mentions failIfUnprivileged" grep -q "failIfUnprivileged is enabled" /tmp/init-fail.log
check "no allowed-domains ipset left behind" bash -c "! sudo ipset list allowed-domains >/dev/null 2>&1"
check "no blocked-domains ipset left behind" bash -c "! sudo ipset list blocked-domains >/dev/null 2>&1"
check "no iptables rules remain" bash -c "test -z \"\$(sudo iptables -L 2>/dev/null | grep -v '^Chain\\|^target\\|^[[:space:]]*\$')\""

rm -rf /tmp/fakebin

reportResults
