# Feature Catalog

Auto-generated from `devcontainer-feature.json` definitions.

## Features

| Feature | Version | Description | Options |
| ------- | ------- | ----------- | ------- |

| `claude-code-backend` | 0.1.1 | Configures Claude Code to use a custom API backend | `baseUrl` (string, default: "")<br>`authToken` (string, default: ollama)<br>`models` (string, default: "")<br>`logLevel` (string, default: error) |
| `claude-code-hooks` | 0.2.0 | Installs bash hooks for Claude Code lifecycle telemetry, state tracking, and policy enforcement (self-contained, pinned to v0) | `installSessionHooks` (boolean, default: true)<br>`installAgentHooks` (boolean, default: true)<br>`installTurnHooks` (boolean, default: true)<br>`installStatusLine` (boolean, default: true)<br>`blockDangerousCommands` (boolean, default: false)<br>`dangerousCommandDenylist` (string, default: "")<br>`stateRetentionLimit` (number, default: 100) |
| `claude-code-mcp-servers` | 0.1.0 | Installs and configures Model Context Protocol (MCP) servers for Claude Code so external tools are available out of the box | `enableGithub` (boolean, default: true)<br>`enableFilesystem` (boolean, default: false)<br>`githubTokenEnvVar` (string, default: GITHUB_TOKEN) |
| `claude-code-plugins` | 0.1.0 | Installs Claude Code plugins from marketplaces at build time | `enableRalphLoop` (boolean, default: false)<br>`enableObraSuperpowers` (boolean, default: false)<br>`enableWorkflows` (boolean, default: false)<br>`enableEverythingClaudeCode` (boolean, default: false)<br>`customPlugins` (string, default: "")<br>`customMarketplaces` (string, default: "")<br>`skipOnFailure` (boolean, default: false)<br>`verifyArtifacts` (boolean, default: false) |
| `claude-code-privacy` | 0.1.0 | Privacy-hardened defaults for Claude Code | `disableTelemetry` (boolean, default: true)<br>`disableErrorReporting` (boolean, default: true)<br>`disableFeedback` (boolean, default: true)<br>`disableUpdates` (boolean, default: true) |
| `claude-code-rules` | 0.1.2 | Installs a curated, condensed set of Claude Code behavior rules into ~/.claude/rules/ | `enforceSafety` (boolean, default: true)<br>`standardizeWorkflow` (boolean, default: true)<br>`protectGit` (boolean, default: true)<br>`preferPythonTooling` (boolean, default: false) |
| `claude-code-skills` | 0.1.0 | Installs skills into ~/.claude/skills/ with configurable sources | `enableMattPocockSkills` (boolean, default: true)<br>`mattPocockSkillsVersion` (string, default: v1.1.0)<br>`installEngineering` (boolean, default: true)<br>`installProductivity` (boolean, default: true)<br>`installMisc` (boolean, default: false)<br>`installPersonal` (boolean, default: false)<br>`skipOnFailure` (boolean, default: false) |
| `container-firewall` | 0.4.0 | Configures an iptables/ipset whitelist firewall for the container with selectable service tags and optional telemetry blocking | `services` (string, default: claude-code)<br>`extraDomains` (string, default: "")<br>`blockTelemetry` (boolean, default: false)<br>`policy` (string, default: whitelist)<br>`enableIPv6` (boolean, default: true)<br>`failIfUnprivileged` (boolean, default: true)<br>`dryRun` (boolean, default: false) |
| `nvidia-container-toolkit` | 0.2.0 | Installs and configures the NVIDIA Container Toolkit so GPU-accelerated containers can run from an inner Docker daemon (Docker-in-Docker) | `enable` (boolean, default: true)<br>`defaultRuntime` (boolean, default: false)<br>`restartDockerd` (boolean, default: true) |

## Namespace

```text
ghcr.io/mrrobot0985/devcontainer-features/<id>:<version>
```
