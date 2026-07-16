#!/usr/bin/env bash
set -euo pipefail

USERNAME="${_REMOTE_USER:-automatic}"
EXPORTER="${EXPORTER:-jaeger}"
RECEIVERS="${RECEIVERS:-otlp}"
AUTO_INSTRUMENTATION="${AUTOINSTRUMENTATION:-false}"

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

# Install OpenTelemetry Collector
if ! command -v otelcol >/dev/null 2>&1 && ! command -v otelcol-contrib >/dev/null 2>&1; then
    echo "Installing OpenTelemetry Collector..."
    ARCH="amd64"
    case "$(uname -m)" in
        aarch64|arm64) ARCH="arm64" ;;
        x86_64) ARCH="amd64" ;;
    esac

    # Download and install the contrib distribution (more receivers/exporters)
    OTEL_VERSION="0.120.0"
    DOWNLOAD_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_VERSION}/otelcol-contrib_${OTEL_VERSION}_linux_${ARCH}.tar.gz"

    curl -fsSL "$DOWNLOAD_URL" -o /tmp/otelcol.tar.gz
    tar -xzf /tmp/otelcol.tar.gz -C /usr/local/bin/ otelcol-contrib
    ln -sf /usr/local/bin/otelcol-contrib /usr/local/bin/otelcol
    rm -f /tmp/otelcol.tar.gz
    echo "OpenTelemetry Collector installed."
else
    echo "OpenTelemetry Collector already installed."
fi

# Install Jaeger (all-in-one) if requested as exporter
if [ "$EXPORTER" = "jaeger" ] || [ "$EXPORTER" = "all" ]; then
    if ! command -v jaeger-all-in-one >/dev/null 2>&1; then
        echo "Installing Jaeger all-in-one..."
        ARCH="amd64"
        case "$(uname -m)" in
            aarch64|arm64) ARCH="arm64" ;;
            x86_64) ARCH="amd64" ;;
        esac
        JAEGER_VERSION="1.67.0"
        curl -fsSL "https://github.com/jaegertracing/jaeger/releases/download/v${JAEGER_VERSION}/jaeger-${JAEGER_VERSION}-linux-${ARCH}.tar.gz" -o /tmp/jaeger.tar.gz
        tar -xzf /tmp/jaeger.tar.gz -C /usr/local/bin/ --wildcards '*/jaeger-all-in-one' --strip-components=1 2>/dev/null || \
            tar -xzf /tmp/jaeger.tar.gz -C /usr/local/bin/ jaeger-all-in-one 2>/dev/null || echo "WARNING: Jaeger extraction may require manual install"
        rm -f /tmp/jaeger.tar.gz
        chmod +x /usr/local/bin/jaeger-all-in-one 2>/dev/null || true
        echo "Jaeger installed."
    else
        echo "Jaeger already installed."
    fi
fi

# Build receiver configuration
IFS=',' read -ra RECV_LIST <<< "$RECEIVERS"
RECV_CONFIG=""
for RECV in "${RECV_LIST[@]}"; do
    RECV="$(echo "$RECV" | tr -d '[:space:]')"
    if [ -z "$RECV" ]; then
        continue
    fi
    case "$RECV" in
        otlp)
            RECV_CONFIG="${RECV_CONFIG}    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
        http:
          endpoint: 0.0.0.0:4318
"
            ;;
        zipkin)
            RECV_CONFIG="${RECV_CONFIG}    zipkin:
      endpoint: 0.0.0.0:9411
"
            ;;
        prometheus)
            RECV_CONFIG="${RECV_CONFIG}    prometheus:
      config:
        scrape_configs:
          - job_name: 'otel-collector'
            scrape_interval: 10s
            static_configs:
              - targets: ['0.0.0.0:8888']
"
            ;;
        jaeger)
            RECV_CONFIG="${RECV_CONFIG}    jaeger:
      protocols:
        grpc:
          endpoint: 0.0.0.0:14250
        thrift_http:
          endpoint: 0.0.0.0:14268
        thrift_compact:
          endpoint: 0.0.0.0:6831
"
            ;;
    esac
done

# Build exporter configuration
EXPORT_CONFIG=""
case "$EXPORTER" in
    jaeger)
        EXPORT_CONFIG="    jaeger:
      endpoint: jaeger-collector:14250
      tls:
        insecure: true"
        ;;
    zipkin)
        EXPORT_CONFIG="    zipkin:
      endpoint: http://zipkin:9411/api/v2/spans"
        ;;
    prometheus)
        EXPORT_CONFIG="    prometheusremotewrite:
      endpoint: http://prometheus:9090/api/v1/write"
        ;;
    *)
        EXPORT_CONFIG="    logging:
      verbosity: detailed"
        ;;
esac

# Write OTel Collector config
mkdir -p /etc/otelcol-contrib
cat > /etc/otelcol-contrib/config.yaml << EOF
receivers:
${RECV_CONFIG}

processors:
  batch:

exporters:
${EXPORT_CONFIG}

service:
  pipelines:
    traces:
      receivers: [$(echo "$RECEIVERS" | tr ',' '\n' | tr -d '[:space:]' | tr '\n' ',')]
      processors: [batch]
      exporters: [$EXPORTER]
    metrics:
      receivers: [$(echo "$RECEIVERS" | tr ',' '\n' | tr -d '[:space:]' | tr '\n' ',')]
      processors: [batch]
      exporters: [$EXPORTER]
EOF

# Install auto-instrumentation if requested
if [ "$AUTO_INSTRUMENTATION" = "true" ]; then
    echo "Installing OpenTelemetry auto-instrumentation..."

    # Node.js
    if command -v npm >/dev/null 2>&1; then
        npm install -g @opentelemetry/auto-instrumentations-node 2>/dev/null || echo "WARNING: Node.js auto-instrumentation install failed"
    fi

    # Python
    if command -v pip >/dev/null 2>&1; then
        pip install opentelemetry-distro opentelemetry-instrumentation 2>/dev/null || echo "WARNING: Python auto-instrumentation install failed"
    fi

    echo "Auto-instrumentation packages installed."
fi

# Write a convenience startup script
STARTUP_SCRIPT="/usr/local/bin/devcontainer-otel-start"
cat > "$STARTUP_SCRIPT" << 'STARTUP_EOF'
#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${1:-/etc/otelcol-contrib/config.yaml}"

echo "Starting OpenTelemetry Collector with config: $CONFIG_FILE"

if [ -f "$CONFIG_FILE" ]; then
    otelcol --config "$CONFIG_FILE" &
    OTEL_PID=$!
    echo "OpenTelemetry Collector started (PID: $OTEL_PID)"
else
    echo "WARNING: Config file not found at $CONFIG_FILE"
fi

if command -v jaeger-all-in-one >/dev/null 2>&1; then
    jaeger-all-in-one &
    JAEGER_PID=$!
    echo "Jaeger started (PID: $JAEGER_PID)"
fi

echo "Telemetry services started."
echo "  OTLP gRPC: 4317"
echo "  OTLP HTTP: 4318"
echo "  Jaeger UI:  http://localhost:16686"
echo ""
echo "Press Ctrl+C to stop."
wait
STARTUP_EOF

chmod +x "$STARTUP_SCRIPT"

# Set ownership for user
if [ "$(id -u)" = "0" ] && [ -n "$USERNAME" ]; then
    chown -R "${USERNAME}:" /etc/otelcol-contrib 2>/dev/null || true
fi

echo "OpenTelemetry Collector Dev installed."
echo "  Config: /etc/otelcol-contrib/config.yaml"
echo "  Start:  devcontainer-otel-start"
echo "  OTLP:   grpc://localhost:4317, http://localhost:4318"
