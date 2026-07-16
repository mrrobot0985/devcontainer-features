# OpenTelemetry Collector Dev

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs OpenTelemetry Collector and Jaeger for local tracing and metrics in devcontainers.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/otel-collector-dev:0": {
        "exporter": "jaeger",
        "receivers": "otlp,zipkin"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `exporter` | string | `jaeger` | Telemetry exporter: jaeger, zipkin, prometheus, or none |
| `receivers` | string | `otlp` | Comma-separated receivers: otlp, zipkin, prometheus, jaeger |
| `autoInstrumentation` | boolean | `false` | Install auto-instrumentation for Node.js and Python |

## Why?

Local observability parity with production prevents "works on my machine" issues with tracing. This feature bundles the OpenTelemetry Collector with Jaeger so every developer gets the same telemetry stack.

## CLI

```bash
# Start OTel Collector and Jaeger
devcontainer-otel-start
```

## Endpoints

| Service | Endpoint | Description |
|---------|----------|-------------|
| OTLP gRPC | `localhost:4317` | Trace/metric ingest |
| OTLP HTTP | `localhost:4318` | Trace/metric ingest |
| Jaeger UI | `http://localhost:16686` | Trace visualization |

## Notes

- The Collector config is written to `/etc/otelcol-contrib/config.yaml`
- Jaeger all-in-one is installed only when `exporter` is set to `jaeger`
- Auto-instrumentation requires Node.js or Python to be available
