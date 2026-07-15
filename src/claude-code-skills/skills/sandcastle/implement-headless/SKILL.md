---
name: implement-headless
description: Implement AFK-capable tickets from .scratch/<feature-slug>/issues/. Runs TDD, commits to branch, no human interaction. For sandcastle automation only.
disable-model-invocation: true
---

# Implement (Headless)

Implement AFK-capable tickets from `.scratch/<feature-slug>/issues/`.

## When to use

AFK sandcastle mode when open, unblocked, unclaimed tickets exist.

## Process

1. **Find frontier** — Scan `.scratch/<feature-slug>/issues/` for files with:
   - `Status: open`
   - No unresolved `Blocked by:` entries
   - Not `Status: claimed`

2. **Claim ticket** — Set `Status: claimed` in the ticket file.

3. **Read spec** — Read the relevant `spec.md` and any ADRs.

4. **Implement** — Write code, tests, and types:
   - Use TDD where seams are pre-agreed
   - Run typechecking regularly
   - Run single test files regularly
   - Run full test suite once at the end

5. **Commit** — Commit to current branch with conventional commit message:

   ```
   feat(<scope>): <ticket title>
   
   Closes .scratch/<feature-slug>/issues/NN-<slug>.md
   ```

6. **Resolve ticket** — Append answer under `## Answer`, set `Status: resolved`. Update map.md Decisions-so-far if this was a wayfinder ticket.

## Rules

- Only implement `Type: task` tickets in AFK mode.
- Skip `Type: research`, `prototype`, `grilling` — those need human input.
- If no frontier tickets exist, exit cleanly with message.
- Never force-push. Use regular commits.
