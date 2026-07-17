# OpenTelemetry Collector Dev

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs OpenTelemetry Collector and Jaeger for local tracing and metrics in devcontainers

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `exporter` | Telemetry exporter to configure: jaeger, zipkin, prometheus, or none | string | jaeger |
| `receivers` | Comma-separated list of receivers to enable (otlp, zipkin, prometheus, jaeger) | string | otlp |
| `autoInstrumentation` | Enable OpenTelemetry auto-instrumentation for supported languages (Node.js, Python, Java) | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/otel-collector-dev:1": {}
}
```
