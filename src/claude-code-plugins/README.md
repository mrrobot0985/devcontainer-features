# Claude Code Plugins (claude-code-plugins)

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Installs Claude Code plugins from marketplaces at build time.

## Requirements

- `ghcr.io/anthropics/devcontainer-features/claude-code` must be installed first (for the `claude` CLI to be available).
- `git` is required for marketplace cloning and will be installed automatically if missing.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enableRalphLoop` | boolean | `false` | Install [Ralph Loop](https://claude.com/plugins/ralph-loop) from the official marketplace |
| `enableObraSuperpowers` | boolean | `false` | Install [Obra Superpowers](https://github.com/obra/superpowers) from the official marketplace |
| `enableWorkflows` | boolean | `false` | Install [claude-code-workflows](https://github.com/shinpr/claude-code-workflows) |
| `enableEverythingClaudeCode` | boolean | `false` | Install [everything-claude-code](https://github.com/affaan-m/everything-claude-code) |
| `customPlugins` | string | `""` | Comma-separated list of additional plugins as `plugin@marketplace` |
| `customMarketplaces` | string | `""` | Comma-separated list of additional marketplaces as `owner/repo` or `owner/repo#ref` |
| `skipOnFailure` | boolean | `false` | Skip plugin installation if a plugin or marketplace fails instead of failing the build |

## Example

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/anthropics/devcontainer-features/claude-code:0": {},
        "ghcr.io/mrrobot0985/devcontainer-features/claude-code-plugins:0": {
            "enableRalphLoop": true,
            "enableObraSuperpowers": true,
            "customPlugins": "my-plugin@my-marketplace",
            "customMarketplaces": "my-org/my-marketplace#v1.2.3"
        }
    }
}
```

## Notes

- Plugins are installed at **user scope** so they are available across all projects in the devcontainer.
- The official Anthropic marketplace (`claude-plugins-official`) is pre-registered and does not need to be added via `customMarketplaces`.
- Third-party marketplaces required by curated plugins (e.g. `shinpr/claude-code-workflows`) are registered automatically when the corresponding toggle is enabled.
- For fully offline containers, consider pre-building a plugin seed directory with `CLAUDE_CODE_PLUGIN_CACHE_DIR` and exposing it at runtime via `CLAUDE_CODE_PLUGIN_SEED_DIR`.
