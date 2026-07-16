#!/bin/bash
set -e

# corporate-cert-injector install script
# Injects corporate TLS/SSL certificates into system and language trust stores

CERT_PATH="${CERTPATH:-/usr/local/share/ca-certificates/corporate}"
INJECT_JAVA="${INJECTJAVA:-true}"
INJECT_NODE="${INJECTNODE:-true}"
INJECT_PYTHON="${INJECTPYTHON:-true}"
INJECT_GIT="${INJECTGIT:-true}"
INJECT_GO="${INJECTGO:-true}"

REMOTE_USER="${_REMOTE_USER:-vscode}"
REMOTE_HOME=$(getent passwd "$REMOTE_USER" | cut -d: -f6 2>/dev/null || true)
if [ -z "$REMOTE_HOME" ]; then
    if [ "$REMOTE_USER" = "root" ]; then
        REMOTE_HOME="/root"
    else
        REMOTE_HOME="/home/$REMOTE_USER"
    fi
fi

BUNDLE_FILE="/usr/local/share/ca-certificates/corporate-bundle.crt"

echo "Corporate certificate injector"
echo "  Certificate path: $CERT_PATH"
echo "  Java injection:   $INJECT_JAVA"
echo "  Node injection:   $INJECT_NODE"
echo "  Python injection: $INJECT_PYTHON"
echo "  Git injection:    $INJECT_GIT"
echo "  Go injection:     $INJECT_GO"

# Collect all .pem/.crt files into a single bundle
collect_certs() {
    if [ ! -d "$CERT_PATH" ]; then
        echo "INFO: Certificate directory $CERT_PATH does not exist."
        echo "      Mount corporate certificates into this path in devcontainer.json:"
        echo '        "mounts": ["source=${localEnv:HOME}/.corporate-certs,target=/usr/local/share/ca-certificates/corporate,type=bind,consistency=cached"]'
        return 1
    fi

    certs_found=$(find "$CERT_PATH" -maxdepth 1 -type f \( -name "*.pem" -o -name "*.crt" -o -name "*.cer" \) 2>/dev/null | wc -l)
    if [ "$certs_found" -eq 0 ]; then
        echo "INFO: No certificates found in $CERT_PATH"
        return 1
    fi

    echo "Collecting $certs_found certificate(s) from $CERT_PATH..."
    cat "$CERT_PATH"/*.pem "$CERT_PATH"/*.crt "$CERT_PATH"/*.cer 2>/dev/null | grep -v '^$' > "$BUNDLE_FILE" || true
    chmod 644 "$BUNDLE_FILE"
    echo "  Bundle written to $BUNDLE_FILE"
    return 0
}

# Inject into system CA store
inject_system() {
    echo "Injecting into system CA store..."
    if command -v update-ca-certificates >/dev/null 2>&1; then
        update-ca-certificates 2>/dev/null || true
        echo "  System CA store updated (Debian/Ubuntu)"
    elif command -v update-ca-trust >/dev/null 2>&1; then
        cp "$BUNDLE_FILE" /etc/pki/ca-trust/source/anchors/ 2>/dev/null || true
        update-ca-trust extract 2>/dev/null || true
        echo "  System CA store updated (RHEL/Fedora)"
    else
        echo "  WARNING: Could not find update-ca-certificates or update-ca-trust"
    fi
}

# Inject into Java keystore
inject_java() {
    if [ "$INJECT_JAVA" != "true" ]; then
        return 0
    fi

    echo "Injecting into Java keystores..."
    java_homes=$(find /usr/lib/jvm -name cacerts 2>/dev/null; find /opt -name cacerts 2>/dev/null)
    if [ -z "$java_homes" ]; then
        echo "  No Java installations found."
        return 0
    fi

    for keystore in $java_homes; do
        if [ -f "$keystore" ]; then
            echo "  Processing keystore: $keystore"
            # Use default password 'changeit'
            keytool -import -alias corporate-ca -file "$BUNDLE_FILE" -keystore "$keystore" -storepass changeit -noprompt 2>/dev/null || \
            echo "    WARNING: Could not inject into $keystore (may require manual import)"
        fi
    done
}

# Inject for Node.js
inject_node() {
    if [ "$INJECT_NODE" != "true" ]; then
        return 0
    fi

    echo "Configuring Node.js CA certificates..."

    # Add to shell profiles for the remote user
    for rc_file in "$REMOTE_HOME/.bashrc" "$REMOTE_HOME/.zshrc"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q "NODE_EXTRA_CA_CERTS" "$rc_file" 2>/dev/null; then
                echo "export NODE_EXTRA_CA_CERTS=\"$BUNDLE_FILE\"" >> "$rc_file"
                echo "  Added NODE_EXTRA_CA_CERTS to $(basename "$rc_file")"
            fi
        fi
    done

    # Also add to /etc/profile.d for system-wide effect
    cat > /etc/profile.d/corporate-certs-node.sh <<EOF
export NODE_EXTRA_CA_CERTS="$BUNDLE_FILE"
EOF
    chmod 644 /etc/profile.d/corporate-certs-node.sh
}

# Inject into Python certifi
inject_python() {
    if [ "$INJECT_PYTHON" != "true" ]; then
        return 0
    fi

    echo "Injecting into Python certificate bundles..."

    # Find certifi bundles
    certifi_bundles=$(python3 -c "import certifi; print(certifi.where())" 2>/dev/null || true)
    if [ -n "$certifi_bundles" ] && [ -f "$certifi_bundles" ]; then
        echo "  Found certifi bundle: $certifi_bundles"
        if ! grep -q "CORPORATE CERTS" "$certifi_bundles" 2>/dev/null; then
            echo "# CORPORATE CERTS BEGIN" >> "$certifi_bundles"
            cat "$BUNDLE_FILE" >> "$certifi_bundles"
            echo "# CORPORATE CERTS END" >> "$certifi_bundles"
            echo "  Certificates appended to certifi bundle"
        fi
    fi

    # Also set environment variable for requests library
    cat > /etc/profile.d/corporate-certs-python.sh <<EOF
export REQUESTS_CA_BUNDLE="$BUNDLE_FILE"
export SSL_CERT_FILE="$BUNDLE_FILE"
EOF
    chmod 644 /etc/profile.d/corporate-certs-python.sh
}

# Inject for Git
inject_git() {
    if [ "$INJECT_GIT" != "true" ]; then
        return 0
    fi

    echo "Configuring Git to use corporate CA bundle..."
    su - "$REMOTE_USER" -c "git config --global http.sslCAInfo '$BUNDLE_FILE'" 2>/dev/null || true
    echo "  Git http.sslCAInfo set to $BUNDLE_FILE"
}

# Inject for Go
inject_go() {
    if [ "$INJECT_GO" != "true" ]; then
        return 0
    fi

    echo "Configuring Go TLS certificates..."
    cat > /etc/profile.d/corporate-certs-go.sh <<EOF
export SSL_CERT_FILE="$BUNDLE_FILE"
export SSL_CERT_DIR="/usr/local/share/ca-certificates"
EOF
    chmod 644 /etc/profile.d/corporate-certs-go.sh
}

# Always create profile scripts so environment variables are set even before certs are mounted
inject_node
inject_python
inject_go

# Main: only inject actual certs when they exist
if collect_certs; then
    inject_system
    inject_java
    inject_git
    echo ""
    echo "Corporate certificates injected successfully."
    echo "  Bundle location: $BUNDLE_FILE"
else
    echo ""
    echo "INFO: No corporate certificates found to inject."
    echo "      If you have corporate certs, mount them into $CERT_PATH"
    echo "      Environment variables are pre-configured; certs will be picked up on next shell start."
fi

# Install helper script
cat > /usr/local/bin/corporate-cert-status <<'EOF'
#!/bin/bash
# corporate-cert-status — show corporate certificate injection status

CERT_PATH="/usr/local/share/ca-certificates/corporate"
BUNDLE_FILE="/usr/local/share/ca-certificates/corporate-bundle.crt"

echo "Corporate Certificate Injector Status"
echo "======================================="

if [ -d "$CERT_PATH" ]; then
    count=$(find "$CERT_PATH" -maxdepth 1 -type f \( -name "*.pem" -o -name "*.crt" -o -name "*.cer" \) 2>/dev/null | wc -l)
    echo "Certificates in $CERT_PATH: $count"
else
    echo "Certificate directory not mounted: $CERT_PATH"
fi

if [ -f "$BUNDLE_FILE" ]; then
    echo "Bundle file exists: $BUNDLE_FILE"
    echo "Bundle size: $(wc -c < "$BUNDLE_FILE") bytes"
else
    echo "Bundle file not found: $BUNDLE_FILE"
fi

echo ""
echo "Environment variables:"
env | grep -E "NODE_EXTRA_CA_CERTS|REQUESTS_CA_BUNDLE|SSL_CERT_FILE|SSL_CERT_DIR" || echo "  None set"

echo ""
echo "Git config:"
git config --global http.sslCAInfo 2>/dev/null || echo "  http.sslCAInfo not set"
EOF

chmod +x /usr/local/bin/corporate-cert-status

echo "Run 'corporate-cert-status' to check injection status."
