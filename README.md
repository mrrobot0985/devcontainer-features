# Dev Container Features

![CI](https://github.com/mrrobot0985/devcontainer-features/actions/workflows/test.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

Custom dev container features for Claude Code / Ollama environments.

## Namespace

```text
ghcr.io/mrrobot0985/devcontainer-features/<id>:<version>
```

## Features (9)

| Feature | Description | README |
| ------- | ----------- | ------ |
| `claude-code-backend` | Configure Claude Code to use a custom API backend such as Ollama. | [README](src/claude-code-backend/README.md) |
| `claude-code-privacy` | Disable telemetry, error reporting, feedback, and automatic updates for Claude Code. | [README](src/claude-code-privacy/README.md) |
| `claude-code-hooks` | Install lifecycle hooks for Claude Code telemetry, state tracking, and policy enforcement. | [README](src/claude-code-hooks/README.md) |
| `claude-code-rules` | Install a curated set of Claude Code behavior rules into `~/.claude/rules/`. | [README](src/claude-code-rules/README.md) |
| `claude-code-skills` | Clone skills into `~/.claude/skills/` with selectable categories. | [README](src/claude-code-skills/README.md) |
| `claude-code-plugins` | Install Claude Code plugins from marketplaces at build time. | [README](src/claude-code-plugins/README.md) |
| `claude-code-mcp-servers` | Install and configure MCP servers so external tools are available out of the box. | [README](src/claude-code-mcp-servers/README.md) |
| `container-firewall` | Configure an iptables/ipset whitelist firewall with selectable service presets. | [README](src/container-firewall/README.md) |
| `nvidia-container-toolkit` | Install and configure the NVIDIA Container Toolkit for Docker-in-Docker GPU support. | [README](src/nvidia-container-toolkit/README.md) |

## Documentation

- [Tutorials](docs/tutorials/)
- [How-to guides](docs/how-to-guides/)
- [Reference](docs/reference/)
- [Explanation](docs/explanation/)
