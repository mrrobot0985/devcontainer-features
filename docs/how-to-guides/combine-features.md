# How to Combine Features

This guide explains how to use multiple devcontainer features together without conflicts.

## Agent security floor

Templates for Claude, Grok, Codex, Pi, Hermes, Gemini, OpenCode, and multi-ai should share the same **agent-agnostic security floor**. Agent CLIs and product-specific suites sit *on top* of this floor; they do not replace it.

| Layer                       | Role                                                                                                                                                                                                                             |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `non-root-enforcer`         | Audit: refuse or warn when `remoteUser` is root                                                                                                                                                                                  |
| `ai-agent-sandbox`          | Audit: tiered runtime posture check (`moderate` recommended) — see [ai-agent-sandbox](../../src/ai-agent-sandbox/README.md) and [#82](https://github.com/mrrobot0985/devcontainer-features/issues/82)                            |
| `container-firewall`        | Enforce: iptables/ipset whitelist via service tags — multi-agent tags in [#77](https://github.com/mrrobot0985/devcontainer-features/issues/77), publish in [#79](https://github.com/mrrobot0985/devcontainer-features/issues/79) |
| Named volume for agent home | Persist auth/settings across rebuilds (path depends on the agent)                                                                                                                                                                |

Studio templates add Docker-in-Docker isolation, host-isolation audit, and optional resource/MCP layers.

### agent-minimal

Use for single-agent CLI templates (and as the base of multi-ai). Keep the floor agent-agnostic; swap only the agent installer and the firewall service tag.

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "remoteUser": "vscode",
    "features": {
        "ghcr.io/devcontainers/features/common-utils:2": {},
        "ghcr.io/devcontainers/features/node:1": {
            "version": "20"
        },
        "ghcr.io/devcontainers/features/github-cli:1": {},

        "ghcr.io/mrrobot0985/devcontainer-features/non-root-enforcer:1": {},
        "ghcr.io/mrrobot0985/devcontainer-features/ai-agent-sandbox:1": {
            "preset": "moderate"
        },
        "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
            // Pick the tag for the primary agent (see table below).
            // Multi-agent tags land in #77 / publish in #79.
            "services": "claude-code"
        }

        // Plus the agent CLI itself (Anthropic claude-code, community grok-build, …)
    },
    "mounts": [
        // Persist agent home; rename volume/path per agent.
        "source=agent-home-${devcontainerId},target=/home/vscode/.claude,type=volume"
    ]
}
```

**Firewall service tags (agent-specific):**

| Primary agent             | `services` value | Notes                                                                                                        |
| ------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------ |
| Claude Code               | `claude-code`    | Composite: github, npm, anthropic, vscode                                                                    |
| Grok Build                | `grok-build`     | Requires multi-agent tags ([#77](https://github.com/mrrobot0985/devcontainer-features/issues/77))            |
| OpenAI Codex              | `codex`          | Requires multi-agent tags ([#77](https://github.com/mrrobot0985/devcontainer-features/issues/77))            |
| Gemini CLI                | `gemini`         | Requires multi-agent tags ([#77](https://github.com/mrrobot0985/devcontainer-features/issues/77))            |
| Multi-AI / several agents | `multi-ai`       | Union of first-class agent endpoints ([#77](https://github.com/mrrobot0985/devcontainer-features/issues/77)) |

Until multi-agent tags are published ([#79](https://github.com/mrrobot0985/devcontainer-features/issues/79)), pin published tags only and extend with `extraDomains` if you must unblock a provider early.

**Agent home volumes (examples):**

| Agent       | Typical mount target   |
| ----------- | ---------------------- |
| Claude Code | `/home/vscode/.claude` |
| Grok Build  | `/home/vscode/.grok`   |
| Codex       | `/home/vscode/.codex`  |
| Gemini      | `/home/vscode/.gemini` |

Add Node and `github-cli` only when the agent or MCP layer needs them.

### agent-studio

Studio builds on agent-minimal for environments that need inner Docker and stronger host-side audit:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "remoteUser": "vscode",
    "features": {
        "ghcr.io/devcontainers/features/common-utils:2": {},
        "ghcr.io/devcontainers/features/node:1": {
            "version": "20"
        },
        "ghcr.io/devcontainers/features/github-cli:1": {},
        "ghcr.io/devcontainers/features/docker-in-docker:2": {},

        "ghcr.io/mrrobot0985/devcontainer-features/non-root-enforcer:1": {},
        "ghcr.io/mrrobot0985/devcontainer-features/ai-agent-sandbox:1": {
            "preset": "moderate"
        },
        "ghcr.io/mrrobot0985/devcontainer-features/host-isolation:1": {},
        "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
            // Always include docker when DinD is present so the inner
            // dockerd can reach registries.
            "services": "claude-code,docker"
        },

        // Optional studio layers:
        "ghcr.io/mrrobot0985/devcontainer-features/container-resource-limits:1": {
            "cpuLimit": "2",
            "memoryLimit": "4g"
        },
        // Prefer agent-agnostic MCP for non-Claude / multi-ai studios (#80).
        "ghcr.io/mrrobot0985/devcontainer-features/mcp-server-manager:1": {
            "servers": "github"
        }
    },
    "mounts": [
        "source=agent-home-${devcontainerId},target=/home/vscode/.claude,type=volume"
    ]
}
```

**Studio additions vs agent-minimal:**

| Addition                                       | Why                                                                                                                                                 |
| ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `docker-in-docker`                             | Inner containers for agent tools / builds                                                                                                           |
| `host-isolation`                               | Audit unsafe `runArgs`, docker.sock binds, excessive caps                                                                                           |
| `container-firewall` services include `docker` | Whitelist Docker Hub / registry domains for DinD pulls                                                                                              |
| optional `container-resource-limits`           | Cap CPU/memory for runaway agent workloads                                                                                                          |
| optional `mcp-server-manager`                  | Agent-agnostic MCP ([#80](https://github.com/mrrobot0985/devcontainer-features/issues/80)); do **not** use `claude-code-mcp-*` on non-Claude agents |

### Explicit do-nots

1. **Do not** put Claude-only features on non-Claude agents:

   - `claude-code-backend`
   - `claude-code-privacy`
   - `claude-code-hooks`
   - `claude-code-rules`
   - `claude-code-skills`
   - `claude-code-plugins`
   - `claude-code-mcp-servers` / `claude-code-mcp-orchestrator`
   - `claude-code-audit-log`

   These write under `~/.claude` and assume the Anthropic CLI. For multi-ai or non-Claude templates, use the security floor + agent-agnostic pieces (`mcp-server-manager`, firewall tags) instead.

1. **Do not** revive bare `xai-cli` as a monorepo feature. Prefer the community Grok Build feature; see [Grok Build install policy](#grok-build-install-policy-no-bare-xai-cli) ([#83](https://github.com/mrrobot0985/devcontainer-features/issues/83)).

1. **Do not** skip the firewall `docker` tag when Docker-in-Docker is present — image pulls will fail closed under whitelist policy.

1. **Do not** treat `ai-agent-sandbox` as a substitute for `container-firewall`. Sandbox **audits** posture; firewall **enforces** network policy. Use both.

### Grok Build install policy (no bare xai-cli)

Monorepo decision ([#83](https://github.com/mrrobot0985/devcontainer-features/issues/83)): **do not reintroduce** a bare install-only `xai-cli` feature unless it gains real policy value (settings merge, persist helpers, hooks). Owned differentiators stay firewall, sandbox, and the Claude suite — not pure CLI installers.

**Prefer (default for Grok templates):**

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/grok-build:1": {}
}
```

Community `grok-build` installs the CLI and persists `~/.grok`. Pin a current major (or exact) version appropriate for your template.

**Fallback:** a template bootstrap script that installs Grok Build only when the community feature is unavailable (air-gapped / registry pin issues). Bootstrap is not a substitute for the security floor.

**Alternatives note (Grok install):**

| Option                                                | When to use                                               |
| ----------------------------------------------------- | --------------------------------------------------------- |
| `ghcr.io/sliekens/devcontainer-features/grok-build:1` | **Default** — community installer with home persistence   |
| Template `bootstrap.sh` install                       | Fallback only if the community feature cannot be resolved |
| Bare monorepo `xai-cli` feature                       | **Do not revive** unless it adds policy beyond install    |

Compose Grok templates as: **agent-minimal or agent-studio floor** + community `grok-build` + `container-firewall` services `grok-build` (after [#77](https://github.com/mrrobot0985/devcontainer-features/issues/77) / [#79](https://github.com/mrrobot0985/devcontainer-features/issues/79)).

## Common Combinations

### Claude Code + Firewall + Docker-in-Docker

When using `container-firewall` with `docker-in-docker`, ensure the firewall whitelists Docker Hub so the inner dockerd can pull images:

```json
"features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
        "services": "claude-code,docker"
    }
}
```

The `docker` service tag adds `registry-1.docker.io` and `production.cloudflare.docker.com` to the whitelist.

### Claude Code + Hooks + Plugins

Install hooks before plugins so that plugin installation events are captured by the hooks:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:1": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-plugins:1": {
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
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
        "services": "docker"
    }
}
```

The devcontainer must also be launched with `--gpus=all`.

### Full Agentic Stack (Claude)

For a complete Claude agentic development environment, combine the security floor with the Claude suite:

```json
"features": {
    "ghcr.io/anthropics/devcontainer-features/claude-code:1": {},
    "ghcr.io/mrrobot0985/devcontainer-features/non-root-enforcer:1": {},
    "ghcr.io/mrrobot0985/devcontainer-features/ai-agent-sandbox:1": {
        "preset": "moderate"
    },
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:1": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-privacy:1": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:1": {
        "blockDangerousCommands": true
    },
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-rules:1": {},
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-mcp-servers:1": {
        "enableGithub": true
    },
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {
        "services": "claude-code"
    }
}
```

Claude-only features above apply **only** when Claude Code is present. Non-Claude agents should stop at the [agent security floor](#agent-security-floor).

## Ordering Rules

1. **claude-code first** — The official Anthropic feature must install before backend, plugins, hooks, or MCP servers because these features depend on the `claude` CLI.

1. **common-utils before everything** — Most custom features depend on `common-utils` for user setup and basic tools.

1. **node before plugins and MCP servers** — Both plugins and MCP servers use `npx`, which requires Node.js.

1. **docker-in-docker before container-firewall** — The firewall may need dockerd present when the `docker` service tag is enabled; install DinD first.

1. **Security floor before agent product suite** — Install `non-root-enforcer`, `ai-agent-sandbox`, and `container-firewall` alongside (or before) agent-specific features so audits and network policy apply regardless of which CLI is layered on top.

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

### Studio DinD trips ai-agent-sandbox

Docker-in-docker is expected in agent-studio. Keep the sandbox on `moderate` (or `permissive` if DinD posture is intentional) and rely on `host-isolation` plus the firewall `docker` tag for defense in depth. See [#82](https://github.com/mrrobot0985/devcontainer-features/issues/82).

## Related issues

| Issue                                                                 | Topic                                            |
| --------------------------------------------------------------------- | ------------------------------------------------ |
| [#77](https://github.com/mrrobot0985/devcontainer-features/issues/77) | Multi-agent `container-firewall` service tags    |
| [#78](https://github.com/mrrobot0985/devcontainer-features/issues/78) | This security floor guide                        |
| [#79](https://github.com/mrrobot0985/devcontainer-features/issues/79) | Publish firewall with multi-agent tags           |
| [#80](https://github.com/mrrobot0985/devcontainer-features/issues/80) | `mcp-server-manager` for multi-ai / studios      |
| [#82](https://github.com/mrrobot0985/devcontainer-features/issues/82) | `ai-agent-sandbox` presets for the floor         |
| [#83](https://github.com/mrrobot0985/devcontainer-features/issues/83) | No bare `xai-cli`; prefer community `grok-build` |
