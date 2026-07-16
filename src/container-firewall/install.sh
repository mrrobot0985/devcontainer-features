#!/bin/sh
set -e

echo "Activating feature 'container-firewall'"

SERVICES="${SERVICES:-minimal}"
EXTRADOMAINS="${EXTRADOMAINS:-}"
BLOCKTELEMETRY="${BLOCKTELEMETRY:-false}"
POLICY="${POLICY:-whitelist}"
ENABLEIPV6="${ENABLEIPV6:-true}"
FAILIFUNPRIVILEGED="${FAILIFUNPRIVILEGED:-true}"
DRYRUN="${DRYRUN:-false}"

# Install dependencies using distro-specific package managers.
install_deps() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y --no-install-recommends iptables ipset dnsutils curl jq aggregate sudo iproute2 ca-certificates
        if ! command -v ip6tables >/dev/null 2>&1; then
            apt-get install -y --no-install-recommends ip6tables || true
        fi
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache iptables ipset bind-tools curl jq aggregate sudo iproute2 ca-certificates
        if ! command -v ip6tables >/dev/null 2>&1; then
            apk add --no-cache ip6tables || true
        fi
    elif command -v yum >/dev/null 2>&1; then
        yum install -y iptables ipset bind-utils curl jq aggregate sudo iproute ca-certificates
        if ! command -v ip6tables >/dev/null 2>&1; then
            yum install -y ip6tables || true
        fi
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y iptables ipset bind-utils curl jq aggregate sudo iproute ca-certificates
        if ! command -v ip6tables >/dev/null 2>&1; then
            dnf install -y ip6tables || true
        fi
    else
        echo "ERROR: could not install firewall dependencies"
        exit 1
    fi
}

if ! command -v iptables >/dev/null 2>&1 \
    || ! command -v ipset >/dev/null 2>&1 \
    || ! command -v dig >/dev/null 2>&1 \
    || ! command -v curl >/dev/null 2>&1 \
    || ! command -v jq >/dev/null 2>&1 \
    || { [ "$ENABLEIPV6" = "true" ] && ! command -v ip6tables >/dev/null 2>&1; }; then
    echo "Installing firewall dependencies..."
    install_deps
fi

# Locate the service registry shipped with the feature and install it
# where the runtime script can read it.
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REGISTRY_SRC="$SCRIPT_DIR/services.json"
REGISTRY_DST="/usr/local/share/container-firewall/services.json"

mkdir -p "$(dirname "$REGISTRY_DST")"
cp "$REGISTRY_SRC" "$REGISTRY_DST"

RUNTIME_SRC="$SCRIPT_DIR/container-firewall-init"
SCRIPT_PATH="/usr/local/bin/container-firewall-init"
TMP_RUNTIME=$(mktemp)

trap 'rm -f "$TMP_RUNTIME"' EXIT

# Bake the build-time option values into the runtime script.
sed \
    -e "s#__SERVICES__#${SERVICES}#g" \
    -e "s#__EXTRADOMAINS__#${EXTRADOMAINS}#g" \
    -e "s#__BLOCKTELEMETRY__#${BLOCKTELEMETRY}#g" \
    -e "s#__POLICY__#${POLICY}#g" \
    -e "s#__ENABLEIPV6__#${ENABLEIPV6}#g" \
    -e "s#__FAILIFUNPRIVILEGED__#${FAILIFUNPRIVILEGED}#g" \
    -e "s#__DRYRUN__#${DRYRUN}#g" \
    "$RUNTIME_SRC" > "$TMP_RUNTIME"

cp "$TMP_RUNTIME" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

echo "Container Firewall feature installed"
echo "Firewall rules will be applied automatically at container creation via postCreateCommand"
