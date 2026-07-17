# MongoDB Development Tools

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs MongoDB shell and utilities for document database development in devcontainers

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `version` | MongoDB major version to install (e.g., 7.0, 6.0) or 'latest' | string | latest |
| `installTools` | Install mongodump, mongorestore, mongoimport, mongoexport | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/mongodb-dev:1": {}
}
```
