# Claude Code Audit Log

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs a simple audit-log script that appends structured JSON events to a workspace file for compliance and post-incident review

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `logDir` | Directory where audit log files are written | string | /workspace/.audit-logs |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-audit-log:1": {}
}
```

## Composition (manual only)

This feature **installs** an audit-log helper script and directory layout. It does
**not** auto-wire Claude Code hooks, settings, or other suite features.

Compose it yourself in `devcontainer.json` next to the rest of the suite when you
need compliance-style JSON event files — for example the studio template includes
it explicitly alongside hooks/rules/skills. There is no mandatory auto-wire from
`claude-code-hooks` or other features into the audit log path.

## Alternatives

Community Claude Code features typically **install the CLI only**. This suite **configures policy** (hooks, rules, skills, privacy, backend, plugins, MCP, audit-log) on top of an existing Claude Code install.
