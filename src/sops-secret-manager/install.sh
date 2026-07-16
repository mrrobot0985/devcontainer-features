#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
GENERATE_AGE_KEY="${GENERATEAGEKEY:-true}"
CLOUD_KMS="${CLOUDKMS:-}"
CONFIGURE_GIT_FILTER="${CONFIGUREGITFILTER:-true}"

# Detect username
if [ "$USERNAME" = "auto" ] || [ "$USERNAME" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 '{ if ($3 >= val) exit; print $1 }' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "$CURRENT_USER" > /dev/null 2>&1; then
            USERNAME="$CURRENT_USER"
            break
        fi
    done
    if [ -z "$USERNAME" ]; then
        USERNAME="root"
    fi
fi

USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

# Install age (required for SOPS)
if ! command -v age >/dev/null 2>&1; then
    echo "Installing age..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y age 2>/dev/null || {
            echo "age not in apt; installing from GitHub releases..."
            ARCH="amd64"
            case "$(uname -m)" in
                aarch64|arm64) ARCH="arm64" ;;
                x86_64) ARCH="amd64" ;;
            esac
            AGE_VERSION="1.2.1"
            curl -fsSL "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${ARCH}.tar.gz" -o /tmp/age.tar.gz
            tar -xzf /tmp/age.tar.gz -C /usr/local/bin/ age age-keygen
            rm -f /tmp/age.tar.gz
        }
    else
        ARCH="amd64"
        case "$(uname -m)" in
            aarch64|arm64) ARCH="arm64" ;;
            x86_64) ARCH="amd64" ;;
        esac
        AGE_VERSION="1.2.1"
        curl -fsSL "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-${ARCH}.tar.gz" -o /tmp/age.tar.gz
        tar -xzf /tmp/age.tar.gz -C /usr/local/bin/ age age-keygen
        rm -f /tmp/age.tar.gz
    fi
else
    echo "age already installed."
fi

# Install SOPS
if ! command -v sops >/dev/null 2>&1; then
    echo "Installing SOPS..."
    ARCH="amd64"
    case "$(uname -m)" in
        aarch64|arm64) ARCH="arm64" ;;
        x86_64) ARCH="amd64" ;;
    esac
    SOPS_VERSION="3.10.2"
    curl -fsSL "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${ARCH}" -o /usr/local/bin/sops
    chmod +x /usr/local/bin/sops
    echo "SOPS installed."
else
    echo "SOPS already installed."
fi

# Generate age key if requested
AGE_DIR="${USER_HOME}/.config/sops/age"
if [ "$GENERATE_AGE_KEY" = "true" ]; then
    mkdir -p "$AGE_DIR"
    if [ ! -f "$AGE_DIR/keys.txt" ]; then
        echo "Generating age key pair..."
        age-keygen -o "$AGE_DIR/keys.txt"
        if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
            chown -R "${USERNAME}:" "$AGE_DIR"
        fi
        echo "Age key generated at $AGE_DIR/keys.txt"
    else
        echo "Age key already exists at $AGE_DIR/keys.txt"
    fi
fi

# Install cloud KMS provider tools if requested
if [ -n "$CLOUD_KMS" ]; then
    case "$CLOUD_KMS" in
        aws)
            echo "AWS KMS selected. Ensure AWS CLI is configured with credentials."
            ;;
        gcp)
            echo "GCP KMS selected. Ensure gcloud CLI is configured with credentials."
            ;;
        azure)
            echo "Azure Key Vault selected. Ensure Azure CLI is configured with credentials."
            ;;
        *)
            echo "WARNING: Unknown cloud KMS provider '$CLOUD_KMS'. Supported: aws, gcp, azure."
            ;;
    esac
fi

# Configure git filters for transparent SOPS encryption/decryption
if [ "$CONFIGURE_GIT_FILTER" = "true" ]; then
    GIT_CONFIG="${USER_HOME}/.gitconfig"
    if [ -f "$GIT_CONFIG" ]; then
        if ! grep -q "\[filter \"sops\"\]" "$GIT_CONFIG" 2>/dev/null; then
            cat >> "$GIT_CONFIG" << 'GITCONFIG_EOF'

[filter "sops"]
    clean = sops encrypt --in-place /dev/stdin
    smudge = sops decrypt --in-place /dev/stdin
    required = true
GITCONFIG_EOF
            echo "Git SOPS filter configured in $GIT_CONFIG"
        else
            echo "Git SOPS filter already configured."
        fi
    else
        cat > "$GIT_CONFIG" << 'GITCONFIG_EOF'
[filter "sops"]
    clean = sops encrypt --in-place /dev/stdin
    smudge = sops decrypt --in-place /dev/stdin
    required = true
GITCONFIG_EOF
        echo "Git SOPS filter configured in $GIT_CONFIG"
    fi

    if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
        chown "${USERNAME}:" "$GIT_CONFIG" 2>/dev/null || true
    fi
fi

# Write a convenience CLI wrapper
CLI_SCRIPT="/usr/local/bin/devcontainer-sops-status"
cat > "$CLI_SCRIPT" << 'CLI_EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "SOPS Secret Manager Status"
echo "=========================="
echo "SOPS:     $(command -v sops && sops --version | head -1 || echo 'not found')"
echo "age:      $(command -v age && age --version | head -1 || echo 'not found')"
echo "age-keygen: $(command -v age-keygen && echo 'installed' || echo 'not found')"
echo ""
echo "Age keys:"
if [ -f "${HOME}/.config/sops/age/keys.txt" ]; then
    echo "  Public key: $(grep 'public key' "${HOME}/.config/sops/age/keys.txt" | cut -d: -f2 | tr -d ' ')"
else
    echo "  No age keys found."
fi
echo ""
echo "Usage:"
echo "  sops encrypt --in-place secrets.yaml"
echo "  sops decrypt --in-place secrets.yaml"
echo "  sops --edit secrets.yaml"
CLI_EOF

chmod +x "$CLI_SCRIPT"

# Write a .sops.yaml template if it doesn't exist
SOPS_CONFIG="${USER_HOME}/.sops.yaml"
if [ ! -f "$SOPS_CONFIG" ]; then
    cat > "$SOPS_CONFIG" << 'SOPS_EOF'
# SOPS configuration template
# Uncomment and configure for your needs:

# Age key-based encryption
# creation_rules:
#   - path_regex: .*/secrets\.yaml$
#     age: <your-age-public-key>
#
# AWS KMS
# creation_rules:
#   - kms: arn:aws:kms:us-east-1:123456789:key/your-key-id
#
# GCP KMS
# creation_rules:
#   - gcp_kms: projects/my-project/locations/global/keyRings/my-keyring/cryptoKeys/my-key
#
# Azure Key Vault
# creation_rules:
#   - azure_keyvault: https://myvault.vault.azure.net/keys/mykey/
SOPS_EOF

    if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
        chown "${USERNAME}:" "$SOPS_CONFIG" 2>/dev/null || true
    fi
    echo "SOPS config template written to $SOPS_CONFIG"
fi

echo "SOPS Secret Manager installed."
echo "  CLI: devcontainer-sops-status"
echo "  Config template: $SOPS_CONFIG"
