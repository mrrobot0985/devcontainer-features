# Docusaurus Documentation Site

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Docusaurus for building documentation websites in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of @docusaurus/core to install |
| `initTemplate` | string | `classic` | Template for new sites: classic, classic-typescript, fast |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/docusaurus-docs:1": {
        "version": "latest",
        "initTemplate": "classic-typescript"
    }
}
```

## CLI

```bash
# Initialize a new site
npx create-docusaurus@latest my-docs classic

# Start development server
npx docusaurus start

# Build site
npx docusaurus build

# Serve built site
npx docusaurus serve

# Check feature status
devcontainer-docusaurus status
```

## Requirements

- Node.js and npm must be available (install via `ghcr.io/devcontainers/features/node`)
- Docusaurus is installed globally via npm

## Notes

- Use `classic-typescript` template for TypeScript-based documentation
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/mkdocs-material` for multi-format documentation
- Forward port 3000 in devcontainer.json for live preview
