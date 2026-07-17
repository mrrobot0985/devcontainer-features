# Claude Code Hooks

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs bash hooks for Claude Code lifecycle telemetry, state tracking, and policy enforcement (self-contained major `:1`)

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `installSessionHooks` | Install session lifecycle hooks (start, end, setup, compact, etc.) | boolean | true |
| `installAgentHooks` | Install agent behavior hooks (tool use, permissions, subagents, tasks) | boolean | true |
| `installTurnHooks` | Install turn-level hooks (prompt submission, stop, notifications) | boolean | true |
| `installStatusLine` | Also install the status line hook configuration | boolean | true |
| `blockDangerousCommands` | Block dangerous Bash commands at the PreToolUse hook instead of only logging them | boolean | false |
| `dangerousCommandDenylist` | Additional comma-separated regex patterns to treat as dangerous when blockDangerousCommands is enabled | string | "" |
| `stateRetentionLimit` | Maximum number of entries to retain in per-tool/per-file state objects. Older entries are pruned automatically. | string | 100 |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:1": {}
}
```

## Policy enforcement (denylist)

When `blockDangerousCommands` is `true`, the agent `PreToolUse` hook
(`hooks/agent/pretooluse.sh`) evaluates Bash commands against a built-in
dangerous-command regex and optional `dangerousCommandDenylist` patterns.
A match with blocking enabled exits **1** (Claude Code aborts the tool call).
Without blocking, matches are still logged and counted; the hook exits **0**.

Scenarios `block_dangerous` and `custom_denylist` cover the green-path
behavior for default and custom patterns.

### Known gaps (honest limits)

| Gap | Behavior | Why |
| --- | -------- | --- |
| **Non-Bash tools** | PreToolUse exits **0** immediately when `tool_name != "Bash"` | Matcher and denylist only apply to Bash. Edit, Write, Read, MCP tools, etc. are **not** blocked by this feature. |
| **Empty / missing command** | Exit **0** if `.tool_input.command` is empty | Nothing to evaluate. |
| **Custom denylist is raw regex** | `dangerousCommandDenylist` is a comma-separated list joined with `\|` and fed to `grep -E` **without** shell-escaping or re2 safety | Authors must supply valid ERE fragments. A malformed pattern can break matching or over-match. Do not paste untrusted strings. |
| **Not a full sandbox** | Hooks are policy signals inside Claude Code, not kernel isolation | Pair with `container-firewall`, `non-root-enforcer`, `ai-agent-sandbox` for defense in depth. |

## State retention (`stateRetentionLimit`)

Install writes `STATE_RETENTION_LIMIT` into `~/.claude/hooks/config/hooks.env`
from the `stateRetentionLimit` option (enum string: `10`…`1000`, default
**`100`**).

### What is pruned

`hook_prune_state` in `hooks/lib/common.sh` (called after dangerous-command
state updates in `pretooluse.sh` and available to other hooks) prunes these
**object maps** on the per-hook state JSON file:

- `.by_tool`
- `.by_key`
- `.files`

For each map that is a JSON object:

1. Convert to entries.
2. Sort by `.value.last_ts` ascending (missing `last_ts` treated as `0` = oldest).
3. Reverse (newest first).
4. Keep only the first **N** entries where **N** = `stateRetentionLimit` (or the
   optional argument to `hook_prune_state`).
5. Rebuild the object via `from_entries`.

Non-object values for those keys are left unchanged. Top-level counters such as
`.outcomes.*` are **not** pruned by this limit.

### What is not `stateRetentionLimit`

NDJSON log files (`hook_jq_log_append`) use a **separate** line cap: when a log
exceeds **500** lines it is truncated to the newest **250** lines. That is
independent of `stateRetentionLimit`.

Invalid or empty limit values fall back to **100**.

## Alternatives

Community Claude Code features typically **install the CLI only**. This suite **configures policy** (hooks, rules, skills, privacy, backend, plugins, MCP, audit-log) on top of an existing Claude Code install.
