# Kafka Development Tools

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Kafka CLI tools for event streaming development in devcontainers

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `installKcat` | Install kcat (kafkacat) — generic command-line Kafka producer/consumer | boolean | true |
| `installConfluentCli` | Install Confluent CLI for Confluent Cloud and Platform management | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/kafka-dev:1": {}
}
```
