# Domain Docs

Single-context layout — one `CONTEXT.md` + `docs/adr/` at the repo root.

## Consumer rules

When an agent needs domain context for this repo:

1. Read `CONTEXT.md` at repo root first
2. Read relevant ADRs from `docs/adr/` when touching the area they govern
3. Respect ADR decisions; don't re-argue settled architecture

## Directory layout

```
/
├── CONTEXT.md          # High-level repo context
├── docs/
│   └── adr/              # Architecture Decision Records
│       ├── 001-*.md
│       └── ...
```

## No monorepo

This repo is a single-context project. There is no `packages/`, `pnpm-workspace.yaml`, or multi-package structure. All code lives under one root.
