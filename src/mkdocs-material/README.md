# MkDocs Material

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs MkDocs with Material theme and popular plugins for documentation sites in devcontainers.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/mkdocs-material:0": {
        "plugins": "search,minify,git-revision-date",
        "servePort": "8000"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `plugins` | string | `search,minify,git-revision-date,redirects` | Comma-separated list of plugins to install |
| `generateConfig` | boolean | `true` | Generate a default `mkdocs.yml` if none exists |
| `servePort` | string | `8000` | Default port for `mkdocs serve` |

## Supported Plugins

| Plugin | Package | Description |
|--------|---------|-------------|
| `search` | built-in | Full-text search |
| `minify` | mkdocs-minify-plugin | Minify HTML/CSS/JS |
| `git-revision-date` | mkdocs-git-revision-date-localized-plugin | Show last edit date |
| `redirects` | mkdocs-redirects | Page redirects |
| `mermaid` | mkdocs-mermaid2-plugin | Mermaid.js diagrams |

## CLI

```bash
# Start MkDocs dev server
devcontainer-mkdocs-serve

# Start on custom port
devcontainer-mkdocs-serve 8080 mkdocs.yml
```

## Why MkDocs Material?

- **Beautiful by default:** Material theme provides responsive design, dark/light mode, and search
- **Plugin ecosystem:** Extensible with 100+ plugins
- **Git-friendly:** Markdown source files live in version control
- **Fast:** Static site generation with instant reload

## Notes

- Requires Python/pip (install via `ghcr.io/devcontainers/features/python` if needed)
- Default config is generated at `~/mkdocs.yml` if none exists in the workspace
- Forward port 8000 (or configured `servePort`) in `devcontainer.json` for access
