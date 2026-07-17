# dbt Data Transformation

![Version](https://img.shields.io/badge/version-1.0.1-blue?style=flat-square)

Installs dbt-core for data transformation pipelines in devcontainers

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `version` | Version of dbt-core to install, or 'latest' | string | latest |
| `installDuckdbAdapter` | Install dbt-duckdb adapter for DuckDB analytics | boolean | true |
| `installPostgresAdapter` | Install dbt-postgres adapter for PostgreSQL databases | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/dbt-transform:1": {}
}
```
