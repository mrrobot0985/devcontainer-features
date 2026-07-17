# Dotfiles Sync

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Clones a dotfiles repository and applies it to the container user, supporting install scripts, symlinks, and direct copying

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `repository` | Git repository URL containing dotfiles (e.g. https://github.com/user/dotfiles.git) | string | "" |
| `installCommand` | Command to run after cloning (e.g. ./install, make install). Leave empty to auto-detect. | string | "" |
| `syncMethod` | How to apply dotfiles: auto (detect), symlink, copy, or none | string | auto |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/dotfiles-sync:1": {}
}
```

## Alternatives

- `helpers4/.../dotfiles-sync` — host config bind-sync (git/ssh/etc.)
- `rio/.../chezmoi` — chezmoi-based management

**Our model:** clone a dotfiles repo and apply it (install script, symlink, or copy). Prefer helpers4 or chezmoi when their model fits better.
