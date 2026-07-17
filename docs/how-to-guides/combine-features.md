# How to Combine Features

This guide explains how to use multiple devcontainer features together without conflicts.

## Common Combinations

### Claude Code + Firewall + Docker-in-Docker

When using `container-firewall` with `docker-in-docker`, ensure the firewall whitelists Docker Hub so the inner dockerd can pull images:

```json
"features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0": {
        "services": "claude-code,docker"
    }
}
```

The `docker` service tag adds `registry-1.docker.io` and `production.cloudflare.docker.com` to the whitelist.

### Claude Code + Hooks + Plugins

Install hooks before plugins so that plugin installation events are captured by the hooks:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-plugins:0": {
        "enableRalphLoop": true,
        "verifyArtifacts": true
    }
}
```

### GPU Environment (NVIDIA + Docker-in-Docker)

For GPU-accelerated inner containers, combine `docker-in-docker` with `container-firewall`. The toolkit configures the inner dockerd to use the NVIDIA runtime:

```json
"features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0": {
        "defaultRuntime": false,
        "restartDockerd": true
    }
}
```

The devcontainer must also be launched with `--gpus=all`.

### Full Agentic Stack

For a complete agentic development environment, combine:

```json
"features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:1": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:0": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-privacy:0": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0": {
        "blockDangerousCommands": true
    },
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-rules:0": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-mcp-servers:0": {
        "enableGithub": true
    },
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0": {}
}
```

## Ordering Rules

1. **claude-code first** — The official Anthropic feature must install before backend, plugins, hooks, or MCP servers because these features depend on the `claude` CLI.

1. **common-utils before everything** — Most custom features depend on `common-utils` for user setup and basic tools.

1. **node before plugins and MCP servers** — Both plugins and MCP servers use `npx`, which requires Node.js.

1. **docker-in-docker before container-firewall** — The toolkit reloads dockerd, which must exist first.

## Troubleshooting Interactions

### Firewall blocks plugin downloads

If plugins fail to install behind the firewall, ensure the `npm` and `github` service tags are included:

```json
"services": "claude-code,npm,github"
```

### Hooks logs grow too large

If hook state files grow unbounded, set `stateRetentionLimit` on the hooks feature:

```json
"claude-code-hooks": {
    "stateRetentionLimit": 50
}
```

### MCP servers fail without GitHub token

The GitHub MCP server requires a `GITHUB_TOKEN` environment variable. Provide it via `containerEnv`:

```json
"containerEnv": {
    "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}"
}
```

### NVIDIA toolkit fails on non-apt systems

The container firewall feature supports apt, yum, and dnf. On Alpine Linux, it skips gracefully with a warning. Ensure your base image uses a supported package manager.
