# mise

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs [mise](https://mise.jdx.dev) (modern dev tool manager, replaces asdf) and configures shell integration for managing language runtimes and dev tools.

## Features

- **Official installer** — Uses the official <https://mise.run> installation script
- **Multi-shell support** — Configures bash, zsh, and/or fish
- **Auto-activation** — Adds `mise activate` to shell rc files so tools are available on shell start
- **Workspace trust** — Automatically trusts `.mise.toml` in the workspace directory

## Usage

Add the feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/mise:0": {}
  }
}
```

With a `.mise.toml` in your project root, mise will automatically install the specified tools when you open a new shell:

```toml
[tools]
node = "22"
python = "3.12"
rust = "1.85"
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `miseVersion` | string | `"latest"` | mise version to install (e.g. `2025.6.0` or `latest`) |
| `shells` | string | `"bash,zsh"` | Comma-separated list of shells to configure |
| `autoActivate` | boolean | `true` | Automatically activate mise when shell starts |
| `trustWorkspaceConfig` | boolean | `true` | Automatically trust `.mise.toml` in workspace |

## Notes

- mise replaces `asdf`, `nvm`, `pyenv`, `rbenv`, and similar per-language version managers with a single unified tool.
- After installation, run `mise install` in a project with `.mise.toml` to install all configured tools.
