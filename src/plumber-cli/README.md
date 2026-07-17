# Plumber Message Queue CLI

![Version](https://img.shields.io/badge/version-1.0.1-blue?style=flat-square)

Installs Plumber CLI for reading and writing messages from Kafka, RabbitMQ, NATS, Redis, and cloud message queues in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of plumber to install |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/plumber-cli:1": {
        "version": "latest"
    }
}
```

## CLI

```bash
# Read from Kafka
plumber read kafka --topics my-topic

# Write to RabbitMQ
plumber write rabbitmq --queue my-queue --input "hello world"

# Read from NATS
plumber read nats --subject test

# Relay from Kafka to RabbitMQ
plumber relay kafka --topics src -d rabbitmq --queue dst

# Check feature status
devcontainer-plumber status
```

## Supported Backends

- **Kafka** — Apache Kafka topics
- **RabbitMQ** — Queues and exchanges
- **NATS** — NATS Streaming / JetStream
- **Redis** — Redis Pub/Sub and Streams
- **GCP PubSub** — Google Cloud Pub/Sub
- **AWS SQS/SNS** — Amazon Simple Queue/Notification Service
- **Azure Service Bus** — Microsoft Azure messaging
- **MQTT** — IoT messaging
- **Apache Pulsar** — Cloud-native messaging

## Requirements

- No additional requirements — Plumber is a single binary

## Notes

- Complements `ghcr.io/mrrobot0985/devcontainer-features/kafka-dev` with multi-queue support
- Use `docker-compose-helper` to spin up message queue services for testing
- Supports protobuf, avro, thrift, and JSON decoding
