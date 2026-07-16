# Starship Prompt

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Installs the [Starship](https://starship.rs) cross-shell prompt and configures it for bash, zsh, and/or fish.

## Features

- **Cross-shell support** — Works with bash, zsh, and fish
- **Built-in presets** — Apply curated prompt styles out of the box
- **Minimal latency** — Rust-based, fast shell prompt
- **Rich context** — Shows git branch, directory, language versions, and more

## Usage

Add the feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/starship-prompt:0": {}
  }
}
```

With a preset and fish shell:

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/starship-prompt:0": {
      "shells": "bash,zsh,fish",
      "preset": "nerd-font-symbols"
    }
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `starshipVersion` | string | `"latest"` | Starship version to install |
| `shells` | string | `"bash,zsh"` | Comma-separated list of shells to configure |
| `preset` | string | `""` | Built-in preset name (see list below) |

## Presets

Available presets: `nerd-font-symbols`, `pastel-powerline`, `jetpack`, `plain-text-symbols`, `no-nerd-font`, `no-random-emojis`, `bracketed-segments`, `tokyo-night`
