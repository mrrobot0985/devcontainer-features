#!/bin/bash
set -e

source dev-container-features-test-lib

check "container-firewall-init exists" test -x /usr/local/bin/container-firewall-init

# Simulate an environment where iptables is not functional.
mkdir -p /tmp/fakebin
cat > /tmp/fakebin/iptables <<'EOF'
#!/bin/sh
echo "iptables: Permission denied (you must be root)" >&2
exit 3
EOF
chmod +x /tmp/fakebin/iptables

set +e
sudo bash -c "PATH=/tmp/fakebin:$PATH /usr/local/bin/container-firewall-init >/tmp/init-noop.log 2>&1"
_init_status=$?
set -e

check "warns when unprivileged and failIfUnprivileged=false" grep -q "WARNING: iptables is not functional" /tmp/init-noop.log
check "exit status is 0" test "$_init_status" -eq 0

reportResults
