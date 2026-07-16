# Astro Static Site

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Astro CLI for building fast content sites and documentation in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of astro to install |
| `installTypeScript` | boolean | `true` | Install TypeScript support |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/astro-docs:1": {
        "version": "latest",
        "installTypeScript": true
    }
}
```

## CLI

```bash
# Start development server
npx astro dev

# Build site
npx astro build

# Preview built site
npx astro preview

# Type check
npx astro check

# Check feature status
devcontainer-astro status
```

## Requirements

- Node.js and npm must be available (install via `ghcr.io/devcontainers/features/node`)
- Astro is installed globally via npm

## Notes

- Astro is framework-agnostic — use React, Vue, Svelte, or vanilla JS
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/docusaurus-docs` or `vitepress-docs` for multi-format documentation
- Forward port 4321 in devcontainer.json for live preview
