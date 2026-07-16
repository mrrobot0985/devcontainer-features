# MongoDB Development Tools

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs MongoDB shell and utilities for document database development in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | MongoDB major version (e.g., 7.0, 6.0) or 'latest' |
| `installTools` | boolean | `true` | Install mongodump, mongorestore, mongoimport, mongoexport |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/mongodb-dev:1": {
        "version": "7.0",
        "installTools": true
    }
}
```

## CLI

```bash
# Connect to MongoDB
mongosh mongodb://user:pass@host:27017/db

# Dump a database
mongodump --uri="mongodb://host/db" --out=backup/

# Restore a database
mongorestore --uri="mongodb://host/db" backup/

# Import JSON
cat data.json | mongoimport --uri="mongodb://host/db" --collection=items

# Export collection
mongoexport --uri="mongodb://host/db" --collection=items --out=items.json

# Check feature status
devcontainer-mongodb status
```

## Tools Installed

- `mongosh` — modern MongoDB shell (JavaScript/TypeScript support)
- `mongodump` — database backup
- `mongorestore` — restore from backup
- `mongoimport` — import JSON/CSV/TSV
- `mongoexport` — export to JSON/CSV

## Notes

- Requires a supported package manager (apt-get, dnf, yum, apk)
- On Debian/Ubuntu, the MongoDB official repository is added for latest versions
- Connects to MongoDB servers running elsewhere (does not install MongoDB server)
- For local MongoDB server, use `docker-compose-helper` with a mongo service
