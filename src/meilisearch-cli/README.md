# Meilisearch CLI

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Meilisearch CLI for search index and document management in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of meilisearch to install |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/meilisearch-cli:1": {
        "version": "latest"
    }
}
```

## CLI

```bash
# Start Meilisearch server
meilisearch --master-key my-master-key

# Check health
curl http://localhost:7700/health

# Create an index
curl -X POST http://localhost:7700/indexes \
  -H 'Content-Type: application/json' \
  -d '{"uid":"books","primaryKey":"id"}'

# Add documents
curl -X POST http://localhost:7700/indexes/books/documents \
  -H 'Content-Type: application/json' \
  -d '[{"id":1,"title":"Dune"}]'

# Search
curl "http://localhost:7700/indexes/books/search?q=dune"

# Check feature status
devcontainer-meilisearch status
```

## Requirements

- No additional requirements — Meilisearch is a single binary

## Notes

- Meilisearch server runs on port 7700 — forward this port in devcontainer.json
- Data is stored in `meilisearch.ms` file by default
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/docker-compose-helper` for multi-service setups
- Use `ghcr.io/mrrobot0985/devcontainer-features/postgres-dev` for persisting indexes in PostgreSQL
