# PostgreSQL Development Tools

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs PostgreSQL client tools for database development in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | PostgreSQL major version (e.g., 16, 15) or 'latest' |
| `installPgFormatter` | boolean | `true` | Install pgFormatter for SQL formatting |
| `installPgTop` | boolean | `false` | Install pgtop for real-time PostgreSQL monitoring |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/postgres-dev:1": {
        "version": "16",
        "installPgFormatter": true
    }
}
```

## CLI

```bash
# Connect to a database
psql postgresql://user:pass@host/db

# Dump a database
pg_dump -h host -U user db > backup.sql

# Restore a database
pg_restore -h host -U user -d db backup.dump

# Check server status
pg_isready -h host

# Format SQL
pg_format file.sql

# Check feature status
devcontainer-postgres status
```

## Tools Installed

- `psql` — interactive terminal
- `pg_dump` — database backup
- `pg_restore` — restore from backup
- `pg_isready` — server connectivity check
- `pg_basebackup` — replication base backup
- `pg_format` (optional) — SQL formatter
- `pgtop` (optional) — real-time monitoring

## Notes

- Requires a supported package manager (apt-get, dnf, yum, apk)
- Connects to PostgreSQL servers running elsewhere (does not install PostgreSQL server)
- For local PostgreSQL server, use `docker-compose-helper` with a postgres service
