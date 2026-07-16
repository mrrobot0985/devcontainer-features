# Redis Development Tools

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Redis CLI tools for cache and session development in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `installRedisBenchmark` | boolean | `true` | Install redis-benchmark for performance testing |
| `installRedisCheckers` | boolean | `true` | Install redis-check-aof and redis-check-rdb |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/redis-dev:1": {
        "installRedisBenchmark": true,
        "installRedisCheckers": true
    }
}
```

## CLI

```bash
# Connect to Redis server
redis-cli -h host -p 6379

# Ping server
redis-cli ping

# Run benchmark
redis-benchmark -n 10000

# Check data files
redis-check-aof appendonly.aof
redis-check-rdb dump.rdb

# Check feature status
devcontainer-redis status
```

## Tools Installed

- `redis-cli` — command-line interface
- `redis-benchmark` — performance testing (optional)
- `redis-check-aof` — AOF file integrity check (optional)
- `redis-check-rdb` — RDB file integrity check (optional)

## Notes

- Requires a supported package manager (apt-get, dnf, yum, apk)
- Connects to Redis servers running elsewhere (does not install Redis server)
- For local Redis server, use `docker-compose-helper` with a redis service
