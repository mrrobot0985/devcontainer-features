# Dev Container Features

![CI](https://github.com/mrrobot0985/devcontainer-features/actions/workflows/test.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

Custom dev container features for Claude Code / Ollama environments.

## Namespace

```text
ghcr.io/mrrobot0985/devcontainer-features/<id>:<version>
```

## Features (45)

| Feature | Description | Version | README |
| ------- | ----------- | ------- | ------ |
| `1password-cli` | Installs the 1Password CLI and provides a get-secret helper for retrieving secrets from 1Password... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/1password-cli/README.md) |
| `act-runner` | Installs nektos/act for running GitHub Actions workflows locally inside devcontainers | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/act-runner/README.md) |
| `ai-agent-sandbox` | Tiered security isolation presets for AI coding agent devcontainers. Audits container runtime pos... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/ai-agent-sandbox/README.md) |
| `bruno-api-testing` | Installs Bruno CLI for local-first, Git-friendly API testing and collection management in devcont... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/bruno-api-testing/README.md) |
| `claude-code-audit-log` | Installs a simple audit-log script that appends structured JSON events to a workspace file for co... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/claude-code-audit-log/README.md) |
| `claude-code-backend` | Configures Claude Code to use a custom API backend | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/claude-code-backend/README.md) |
| `claude-code-hooks` | Installs bash hooks for Claude Code lifecycle telemetry, state tracking, and policy enforcement (... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/claude-code-hooks/README.md) |
| `claude-code-mcp-orchestrator` | Installs and manages MCP server lifecycle from .mcp.json configuration. Starts servers on contain... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/claude-code-mcp-orchestrator/README.md) |
| `claude-code-mcp-servers` | Installs and configures Model Context Protocol (MCP) servers for Claude Code so external tools ar... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/claude-code-mcp-servers/README.md) |
| `claude-code-plugins` | Installs Claude Code plugins from marketplaces at build time | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/claude-code-plugins/README.md) |
| `claude-code-privacy` | Privacy-hardened defaults for Claude Code | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/claude-code-privacy/README.md) |
| `claude-code-rules` | Installs a curated, condensed set of Claude Code behavior rules into ~/.claude/rules/ | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/claude-code-rules/README.md) |
| `claude-code-skills` | Installs skills into ~/.claude/skills/ with configurable sources | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/claude-code-skills/README.md) |
| `cloud-cli-persistence` | Persists cloud CLI authentication state across container rebuilds by validating host credential m... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/cloud-cli-persistence/README.md) |
| `container-firewall` | Configures an iptables/ipset whitelist firewall for the container with selectable service tags an... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/container-firewall/README.md) |
| `container-security-scan` | Installs Trivy and runs a vulnerability scan on the container image during postCreateCommand, wit... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/container-security-scan/README.md) |
| `corporate-cert-injector` | Injects corporate TLS/SSL certificates into system and language-specific trust stores, enabling d... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/corporate-cert-injector/README.md) |
| `cosign-verify` | Installs Cosign (Sigstore) and provides helpers for verifying container image signatures and atte... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/cosign-verify/README.md) |
| `dependency-cache-manager` | Auto-detects project types and configures package manager cache directories to use a named volume... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/dependency-cache-manager/README.md) |
| `devcontainer-ci-tools` | Installs the devcontainer CLI, docker-buildx, and act (local GitHub Actions runner) for self-test... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/devcontainer-ci-tools/README.md) |
| `devcontainer-lib` | Installs a shared shell utility library for use in devcontainer lifecycle scripts and custom auto... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/devcontainer-lib/README.md) |
| `devcontainer-lock-audit` | CI gate that enforces .devcontainer-lock.json presence and validates that pinned feature versions... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/devcontainer-lock-audit/README.md) |
| `direnv-integration` | Installs direnv via apt-get and hooks it into shell startup for automatic .envrc loading when cha... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/direnv-integration/README.md) |
| `docker-compose-helper` | Validates docker-compose.yml files and optionally injects health checks and dependency ordering f... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/docker-compose-helper/README.md) |
| `dotfiles-sync` | Clones a dotfiles repository and applies it to the container user, supporting install scripts, sy... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/dotfiles-sync/README.md) |
| `git-config-manager` | Standardizes git configuration for devcontainer users from feature options or host environment va... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/git-config-manager/README.md) |
| `git-hooks-manager` | Installs and configures pre-commit hooks for linting, formatting, and conventional commits in dev... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/git-hooks-manager/README.md) |
| `host-isolation` | Audits devcontainer.json for unsafe runArgs, mounts, and capabilities. Warns when privileged mode... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/host-isolation/README.md) |
| `mcp-server-manager` | Installs and configures Model Context Protocol (MCP) servers for AI-assisted development inside d... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/mcp-server-manager/README.md) |
| `mise` | Installs mise (modern dev tool manager, replaces asdf) and configures shell integration for manag... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/mise/README.md) |
| `mkdocs-material` | Installs MkDocs with Material theme and popular plugins for documentation sites in devcontainers | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/mkdocs-material/README.md) |
| `multi-arch-tuning` | Detects container architecture and sets environment variables for Ollama, PyTorch, and uv to avoi... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/multi-arch-tuning/README.md) |
| `nix-package-manager` | Installs the Nix package manager with flakes support and optional home-manager integration for re... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/nix-package-manager/README.md) |
| `non-root-enforcer` | Audits devcontainer.json for root remoteUser and warns or fails when the container is configured ... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/non-root-enforcer/README.md) |
| `nvidia-container-toolkit` | Installs and configures the NVIDIA Container Toolkit so GPU-accelerated containers can run from a... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/nvidia-container-toolkit/README.md) |
| `otel-collector-dev` | Installs OpenTelemetry Collector and Jaeger for local tracing and metrics in devcontainers | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/otel-collector-dev/README.md) |
| `podman-checkpoint-helper` | Installs Podman with checkpoint/restore support (CRIU) for ephemeral AI agent container workflows... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/podman-checkpoint-helper/README.md) |
| `prebuild-lifecycle-helper` | Analyzes devcontainer.json lifecycle commands, detects dependency installations in non-prebuild h... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/prebuild-lifecycle-helper/README.md) |
| `registry-mirror-config` | Configures Docker daemon registry mirrors to accelerate image pulls in corporate, air-gapped, or ... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/registry-mirror-config/README.md) |
| `sops-secret-manager` | Installs Mozilla SOPS with age key generation for encrypting secrets in devcontainer projects | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/sops-secret-manager/README.md) |
| `ssh-agent-forward` | Forwards the host SSH agent into the devcontainer for Git operations without copying private keys... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/ssh-agent-forward/README.md) |
| `starship-prompt` | Installs the Starship cross-shell prompt and configures it for bash, zsh, and fish | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/starship-prompt/README.md) |
| `sudo-audit` | Audits the container image for passwordless sudo configuration and warns or fails when NOPASSWD d... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/sudo-audit/README.md) |
| `syft-sbom` | Installs Syft and provides helpers for generating SBOMs (CycloneDX/SPDX) from the container files... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/syft-sbom/README.md) |
| `taskfile-dev` | Installs the Task (go-task) command runner with shell completions and optional alias. Auto-detect... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/taskfile-dev/README.md) |
## Documentation

- [Tutorials](docs/tutorials/)
- [How-to guides](docs/how-to-guides/)
- [Reference](docs/reference/)
- [Explanation](docs/explanation/)
