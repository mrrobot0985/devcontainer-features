Status: open
Type: research
Blocked by:

## Question

Which issue tracker backend should sandcastle use for headless AFK operation?

## Context

Matt's skills support three tracker backends: GitHub, GitLab, and local-markdown. Sandcastle needs a tracker that works without human intervention and without requiring API tokens or network access. The local-markdown tracker (`.scratch/`) fits this perfectly, but we need to confirm it's the right default for devcontainer templates.

## Options

1. **Local-markdown only** — `.scratch/` is the canonical tracker. No network, no tokens, works offline. GitHub sync is a separate Phase 4 effort.
2. **GitHub primary with local-markdown fallback** — try GitHub first, fall back to `.scratch/` if no remote or no `gh` CLI.
3. **User-configurable at template instantiate time** — ask the user which tracker they want when creating the devcontainer.

## Answer

**Local-markdown only** is the default for sandcastle headless mode.

Rationale:

- AFK automation must not depend on network or tokens
- `.scratch/` works in any devcontainer, offline, with zero config
- GitHub sync remains a Phase 4 opt-in, not a default
- The `local-markdown-tracker` skill scaffolds the conventions automatically

Sandcastle bootstrap auto-mode defaults to `.scratch/` and only attempts GitHub if explicitly configured.

## What would resolve this

A decision recorded in the map's Decisions-so-far and a note in `docs/agents/issue-tracker.md` about sandcastle's default posture.

---

Status: resolved
