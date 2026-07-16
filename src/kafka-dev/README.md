# Kafka Development Tools

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Kafka CLI tools for event streaming development in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `installKcat` | boolean | `true` | Install kcat (kafkacat) — generic command-line Kafka producer/consumer |
| `installConfluentCli` | boolean | `false` | Install Confluent CLI for Confluent Cloud management |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/kafka-dev:1": {
        "installKcat": true,
        "installConfluentCli": false
    }
}
```

## CLI

```bash
# Produce messages to a topic
echo "hello" | kcat -b localhost:9092 -t my-topic -P

# Consume messages from a topic
kcat -b localhost:9092 -t my-topic -C

# List topics and brokers
kcat -b localhost:9092 -L

# Check feature status
devcontainer-kafka status
```

## Tools Installed

- `kcat` / `kafkacat` — generic CLI producer/consumer for Kafka and other message queues
- `confluent` (optional) — Confluent Cloud and Platform management CLI

## Notes

- kcat is installed via system package manager when available
- For Kafka servers, use `docker-compose-helper` with a Kafka service
- KRaft mode (no ZooKeeper) is recommended for local development
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/docker-compose-helper` for multi-service setups
