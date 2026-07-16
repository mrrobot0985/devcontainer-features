# dbt Data Transformation

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs dbt-core for data transformation pipelines in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of dbt-core to install |
| `installDuckdbAdapter` | boolean | `true` | Install dbt-duckdb adapter |
| `installPostgresAdapter` | boolean | `false` | Install dbt-postgres adapter |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/dbt-transform:1": {
        "installDuckdbAdapter": true,
        "installPostgresAdapter": true
    }
}
```

## CLI

```bash
# Build all models
dbt build

# Run models
dbt run

# Run tests
dbt test

# Test connection
dbt debug

# Check feature status
devcontainer-dbt status
```

## Adapters

| Adapter | Database |
|---------|----------|
| `dbt-duckdb` | DuckDB (embedded analytical) |
| `dbt-postgres` | PostgreSQL |

## Requirements

- Python 3 must be available (install via `ghcr.io/devcontainers/features/python`)
- pip is used for package installation

## Notes

- Combine with `ghcr.io/mrrobot0985/devcontainer-features/duckdb-analytics` for local DuckDB transformations
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/postgres-dev` for PostgreSQL transformations
- dbt profiles are configured in `~/.dbt/profiles.yml`
