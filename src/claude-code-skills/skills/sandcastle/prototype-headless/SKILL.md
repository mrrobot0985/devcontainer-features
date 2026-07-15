---
name: prototype-headless
description: Build a throwaway prototype to answer a design question. Degraded AFK mode — produces code without waiting for 'does this feel right' confirmation. For sandcastle automation only.
disable-model-invocation: true
---

# Prototype (Headless)

Build a throwaway prototype near the module or page it targets. AFK mode — produces code without human confirmation.

## When to use

AFK sandcastle mode when a `Type: prototype` ticket exists and sandcastle is configured to run degraded HITL skills.

## Process

1. **Read question** — Read the ticket file. Determine if it's logic or UI:
   - "Does this logic / state model feel right?" → LOGIC.md prototype
   - "What should this look like?" → UI.md prototype

2. **Build prototype** — Create throwaway code next to the target module:
   - Name it clearly as prototype (`*.prototype.*`, `prototype-*`, etc.)
   - One command to run (`pnpm <name>`, `python <path>`, etc.)
   - No persistence (state in memory)
   - No tests, no error handling beyond runnable
   - Surface full state after every action

3. **Capture** — Commit to a throwaway branch (not main). Leave context pointer on implementation issue.

4. **Resolve ticket** — Set `Status: resolved`, append prototype branch name and location.

## Rules

- This is a degraded HITL skill. The prototype is produced but not validated by human.
- Mark all prototype files clearly so they aren't mistaken for production code.
- If sandcastle is not in degraded-HITL mode, skip this skill and report "human required."
