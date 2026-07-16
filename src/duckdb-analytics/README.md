# DuckDB Analytics

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs DuckDB CLI for analytical queries and data processing in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of DuckDB to install |
| `installExtensions` | boolean | `false` | Install httpfs, json, and parquet extensions |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/duckdb-analytics:1": {
        "version": "latest",
        "installExtensions": true
    }
}
```

## CLI

```bash
# Interactive shell
duckdb

# Query a CSV file
duckdb -c "SELECT * FROM 'data.csv'"

# Query a Parquet file
duckdb -c "SELECT * FROM read_parquet('file.parquet')"

# Export to JSON
duckdb -c ".mode json" -c "SELECT * FROM 'data.csv'"

# Check feature status
devcontainer-duckdb status
```

## Extensions

When `installExtensions: true`, the following are pre-installed:

- `httpfs` — Read remote files via HTTP/S3
- `json` — JSON parsing and generation
- `parquet` — Parquet file reading and writing

## Requirements

- No additional requirements — DuckDB is a single binary

## Notes

- DuckDB is an embedded analytical database (SQLite for analytics)
- Supports querying CSV, Parquet, JSON directly without loading
- Complements `ghcr.io/mrrobot0985/devcontainer-features/postgres-dev` and `mongodb-dev`
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/jupyter-ml-dev` for data science pipelines
