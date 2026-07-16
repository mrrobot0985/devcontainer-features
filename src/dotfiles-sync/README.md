# Dotfiles Sync

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Clones a dotfiles repository and applies it to the container user, supporting install scripts, symlinks, and direct copying.

## Problem Solved

Developers maintain personalized shell configs, aliases, and tool settings in a dotfiles repository. Without automation, each devcontainer requires manual setup to bring these configurations in.

## Usage

Add the feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/dotfiles-sync:0": {
      "repository": "https://github.com/yourusername/dotfiles.git"
    }
  }
}
```

With a custom install command:

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/dotfiles-sync:0": {
      "repository": "https://github.com/yourusername/dotfiles.git",
      "installCommand": "./setup.sh --minimal",
      "syncMethod": "none"
    }
  }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `repository` | string | `""` | Git repository URL containing dotfiles |
| `installCommand` | string | `""` | Command to run after cloning. Auto-detected if empty. |
| `syncMethod` | string | `"auto"` | How to apply dotfiles: auto, symlink, copy, or none |

## Auto-Detection

If no `installCommand` is specified, the feature looks for (in order):

1. `./install`
2. `./install.sh`
3. `./setup`
4. `./setup.sh`
5. `make install` (if Makefile exists with install target)

If none are found, it falls back to symlinking common dotfiles (`.bashrc`, `.zshrc`, `.vimrc`, etc.) from the cloned repo.
