# Claude Code Plugins

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Claude Code plugins from marketplaces at build time

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `enableRalphLoop` | Install Ralph Loop plugin from the official marketplace | boolean | false |
| `enableObraSuperpowers` | Install Obra Superpowers plugin from the official marketplace | boolean | false |
| `enableWorkflows` | Install claude-code-workflows plugin | boolean | false |
| `enableEverythingClaudeCode` | Install everything-claude-code plugin | boolean | false |
| `customPlugins` | Comma-separated list of additional plugins to install as plugin@marketplace | string | "" |
| `customMarketplaces` | Comma-separated list of additional marketplaces to add as owner/repo or owner/repo#ref | string | "" |
| `skipOnFailure` | Skip plugin installation if a plugin or marketplace fails instead of failing the build | boolean | false |
| `verifyArtifacts` | After installation, verify that all requested plugins appear in enabledPlugins and fail the build if any are missing | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-plugins:1": {}
}
```

## `skipOnFailure` defaults

| Context | Recommended `skipOnFailure` | Why |
| ------- | --------------------------- | --- |
| **Feature default** (JSON schema) | **`false`** | Fail closed online: marketplace / plugin install errors fail the build. |
| **Offline / flaky CI** | **`true`** | Plugin marketplaces require network; CI scenarios set `skipOnFailure: true`. |
| **Studio / template dogfood** (`ollama-claude-cli-studio`) | **`true`** (explicit) | Same as skills: Ralph Loop / marketplace installs must not block studio create. |

Default in `devcontainer-feature.json` is **`false`**. Pair with `verifyArtifacts: true`
only when you need post-install proof that enabled plugins landed (still fail closed on
missing artifacts even if install steps were skipped carefully — see feature tests).

## Alternatives

Community Claude Code features typically **install the CLI only**. This suite **configures policy** (hooks, rules, skills, privacy, backend, plugins, MCP, audit-log) on top of an existing Claude Code install.
