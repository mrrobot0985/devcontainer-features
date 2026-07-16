# VitePress Documentation Site

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs VitePress for building Vite-powered documentation websites in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of vitepress to install |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/vitepress-docs:1": {
        "version": "latest"
    }
}
```

## CLI

```bash
# Initialize a new site
npx vitepress init

# Start development server
npx vitepress dev

# Build site
npx vitepress build

# Preview built site
npx vitepress preview

# Check feature status
devcontainer-vitepress status
```

## Requirements

- Node.js and npm must be available (install via `ghcr.io/devcontainers/features/node`)
- VitePress is installed globally via npm

## Notes

- VitePress uses Markdown and Vue-based theming
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/docusaurus-docs` for React-based docs
- Forward port 5173 in devcontainer.json for live preview
