# Claude Code Rules

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs a curated, condensed set of Claude Code behavior rules into ~/.claude/rules/

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `enforceSafety` | Enforce safety invariants: human sovereignty, no-attribution, no-secrets | boolean | true |
| `standardizeWorkflow` | Standardize agent workflow: skill discovery, MCP tools first, anti-overengineering, conventional commits, no-orphans, branch strategy | boolean | true |
| `protectGit` | Protect git configuration: never override git config inline | boolean | true |
| `preferPythonTooling` | Prefer Python toolchain rules: uv/uvx for Python, mdformat with frontmatter/gfm plugins | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-rules:1": {}
}
```
