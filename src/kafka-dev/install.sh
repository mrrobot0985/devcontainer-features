#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
INSTALL_KCAT="${INSTALLKCAT:-true}"
INSTALL_CONFLUENT="${INSTALLCONFLUENTCLI:-false}"

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

# Install kcat
if [ "$INSTALL_KCAT" = "true" ]; then
    if ! command -v kcat > /dev/null 2>&1 && ! command -v kafkacat > /dev/null 2>&1; then
        echo "Installing kcat..."

        if command -v apt-get > /dev/null 2>&1; then
            apt-get update && apt-get install -y kafkacat || apt-get install -y kcat || echo "WARNING: kcat not available in repository"
        elif command -v dnf > /dev/null 2>&1; then
            dnf install -y kafkacat || echo "WARNING: kcat not available"
        elif command -v yum > /dev/null 2>&1; then
            yum install -y kafkacat || echo "WARNING: kcat not available"
        elif command -v apk > /dev/null 2>&1; then
            apk add --no-cache kafkacat || echo "WARNING: kcat not available"
        else
            echo "WARNING: No supported package manager for kcat"
        fi
    else
        echo "kcat already installed."
    fi
fi

# Install Confluent CLI
if [ "$INSTALL_CONFLUENT" = "true" ]; then
    if ! command -v confluent > /dev/null 2>&1; then
        echo "Installing Confluent CLI..."

        ARCH="amd64"
        case "$(uname -m)" in
            aarch64|arm64) ARCH="arm64" ;;
            x86_64) ARCH="amd64" ;;
        esac

        CONFLUENT_URL="https://s3-us-west-2.amazonaws.com/confluent.cloud/confluent-cli/archives/latest/confluent_latest_linux_${ARCH}.tar.gz"
        curl -fsSL "$CONFLUENT_URL" -o /tmp/confluent.tar.gz
        tar -xzf /tmp/confluent.tar.gz -C /tmp
        if [ -d /tmp/confluent ]; then
            cp /tmp/confluent/bin/confluent /usr/local/bin/confluent
            chmod +x /usr/local/bin/confluent
        fi
        rm -rf /tmp/confluent.tar.gz /tmp/confluent

        echo "Confluent CLI installed."
    else
        echo "Confluent CLI already installed."
    fi
fi

# Verify kcat
if command -v kcat > /dev/null 2>&1; then
    echo "kcat installed: $(kcat -V 2>&1 || echo 'version unknown')"
elif command -v kafkacat > /dev/null 2>&1; then
    echo "kafkacat installed: $(kafkacat -V 2>&1 || echo 'version unknown')"
else
    echo "WARNING: kcat/kafkacat not found after installation"
fi

# Write a convenience CLI wrapper
HELPER_SCRIPT="/usr/local/bin/devcontainer-kafka"
cat > "$HELPER_SCRIPT" << 'HELPER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
    produce)
        echo "Producing to Kafka topic..."
        if command -v kcat > /dev/null 2>&1; then
            kcat -P "$@"
        elif command -v kafkacat > /dev/null 2>&1; then
            kafkacat -P "$@"
        else
            echo "ERROR: kcat not installed"
            exit 1
        fi
        ;;
    consume)
        echo "Consuming from Kafka topic..."
        if command -v kcat > /dev/null 2>&1; then
            kcat -C "$@"
        elif command -v kafkacat > /dev/null 2>&1; then
            kafkacat -C "$@"
        else
            echo "ERROR: kcat not installed"
            exit 1
        fi
        ;;
    list)
        echo "Listing Kafka topics..."
        if command -v kcat > /dev/null 2>&1; then
            kcat -L "$@"
        elif command -v kafkacat > /dev/null 2>&1; then
            kafkacat -L "$@"
        else
            echo "ERROR: kcat not installed"
            exit 1
        fi
        ;;
    status)
        echo "Kafka Development Tools status"
        if command -v kcat > /dev/null 2>&1; then
            echo "kcat: $(kcat -V 2>&1 || echo 'installed')"
        elif command -v kafkacat > /dev/null 2>&1; then
            echo "kafkacat: $(kafkacat -V 2>&1 || echo 'installed')"
        else
            echo "WARNING: kcat/kafkacat not installed"
        fi
        if command -v confluent > /dev/null 2>&1; then
            echo "Confluent CLI: $(confluent version 2>&1 || echo 'installed')"
        fi
        echo ""
        echo "Usage:"
        echo "  devcontainer-kafka produce    # Produce messages"
        echo "  devcontainer-kafka consume    # Consume messages"
        echo "  devcontainer-kafka list       # List topics/brokers"
        ;;
    *)
        if command -v kcat > /dev/null 2>&1; then
            kcat "$COMMAND" "$@"
        elif command -v kafkacat > /dev/null 2>&1; then
            kafkacat "$COMMAND" "$@"
        else
            echo "ERROR: kcat not installed"
            exit 1
        fi
        ;;
esac
HELPER_EOF

chmod +x "$HELPER_SCRIPT"

echo "Kafka Development Tools installed."
echo "  CLI: devcontainer-kafka"
echo "  kcat: $(kcat -V 2>/dev/null || kafkacat -V 2>/dev/null || echo 'installed')"
