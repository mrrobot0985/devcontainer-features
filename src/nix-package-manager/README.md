# Nix Package Manager

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs the Nix package manager with flakes support and optional home-manager integration for reproducible dev environments.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/nix-package-manager:0": {
        "flakes": true,
        "homeManager": false
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `multiUser` | boolean | `true` | Install Nix in multi-user (daemon) mode |
| `flakes` | boolean | `true` | Enable Nix flakes and the new `nix` command |
| `homeManager` | boolean | `false` | Install home-manager for user-level package/dotfile management |
| `packages` | string | `""` | Space-separated Nix packages to install (e.g., `"git vim htop"`) |

## Why Nix?

- **Reproducibility:** Nix builds are deterministic and isolated
- **Flakes:** Declarative project environments with `flake.nix` and `flake.lock`
- **Complement to mise:** Use Nix for system-level reproducibility, mise for project-level tool versioning

## Post-Install

After the container starts, verify Nix:

```bash
nix --version
nix flake --help
```

Install packages:

```bash
nix-env -iA nixpkgs.git
nix shell nixpkgs#nodePackages.typescript
```

## Notes

- The official Nix installer is used; installation may take a few minutes
- Some packages in the `packages` option may need to be installed manually if nixpkgs paths differ
- home-manager requires `nix-channel --update` after container startup if installed at build time
