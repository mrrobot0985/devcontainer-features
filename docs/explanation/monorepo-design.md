# Monorepo Design

This repository holds multiple independent dev container features in a single codebase. This document explains why that design was chosen and how versioning, tags, and packaging avoid the collisions that monorepos can introduce.

## Why one repository for many features

Features extend Claude Code and container tooling in related ways. Keeping them together gives several practical advantages:

- **Shared CI and scripts.** One set of workflows runs shellcheck, schema validation, README generation, and publish-on-tag for every feature.
- **Shared patterns.** Helper scripts like `merge-settings.sh` and the `.githooks/pre-commit` hook live in one place and are reused across features.
- **Atomic cross-cutting changes.** A change that affects how several features write to `~/.claude/settings.json` can be made and reviewed in a single pull request.
- **Simpler maintenance.** There is one local CI gate, one set of issue templates, and one contribution guide.

The trade-off is that git tags, GitHub releases, and container packages must be scoped per feature. This repository solves that with prefixed tags.

## What we own vs what we compose

This monorepo invests in **differentiators**: Claude Code policy suite, network firewall with service tags, agent sandbox / host isolation audits, and related agent workflows. Pure “install CLI X” features are not a good fit when a mature official or community feature already exists.

**Policy example — Grok Build:** do not reintroduce bare install-only `xai-cli`. Prefer community `ghcr.io/sliekens/devcontainer-features/grok-build:1`; use a template bootstrap script only as a fallback. See the [agent security floor guide](../how-to-guides/combine-features.md#grok-build-install-policy-no-bare-xai-cli) and [#83](https://github.com/mrrobot0985/devcontainer-features/issues/83).

## Prefixed tags prevent collisions

A plain SemVer tag like `v0.1.0` would be ambiguous: which feature does it release? Instead, every release tag carries the feature id as a prefix:

```
claude-code-backend-v0.1.1
container-firewall-v0.2.0
container-firewall-v0.1.1
```

Developers create and push these tags after bumping `version` in `devcontainer-feature.json`. `.github/workflows/release.yaml` triggers only on `*-v*` tags (or manual dispatch for backfill) and publishes to GHCR. Actions does not mint tags.

A consumer still references a feature by its major version, not the git tag:

```jsonc
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:1": {}
}
```

The `:1` suffix resolves the latest published release whose **major** version is `1`. Prefer the current major line used by templates (`:1` as of 2026-07). Historical `:0` tags may still exist on GHCR for older consumers. The prefixed git tag is an internal release handle.

## Namespace design

Every feature is published to a dedicated package under the same GitHub Container Registry namespace:

```
ghcr.io/mrrobot0985/devcontainer-features/<feature-id>:<version>
```

For example:

```
ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:1.0.0
ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1.1.0
```

This layout is consistent with the official dev container features convention. Each feature gets its own package page and version history, while the monorepo groups them under one organization namespace.

## Repository layout

```
.
├── src/<feature>/              # One directory per feature
│   ├── devcontainer-feature.json
│   ├── install.sh
│   ├── uninstall.sh (optional)
│   └── README.md (auto-generated)
├── test/<feature>/             # Scenario tests
├── test/_global/               # Cross-feature integration scenarios
├── scripts/                    # Shared local helpers
├── .githooks/                  # Pre-commit hook
└── .github/workflows/          # Shared CI/CD definitions
```

Each `src/<feature>/` directory is an independent package. The shared tooling at the repository root is what makes the monorepo maintainable.

## Automation relies on the monorepo structure

- `test.yaml` discovers features by scanning `src/*/`.
- `validate.yml` validates every `devcontainer-feature.json` under `src/`.
- `release.yaml` publishes the collection under `./src` when a developer pushes a prefixed tag.
- `generate-feature-readmes.py` discovers features by scanning `src/`.

This would be harder to coordinate across separate repositories.

## Trade-offs

- **Tighter coupling.** A change to shared scripts or workflows affects all features, so updates must be safe for every feature.
- **Explicit release ritual.** Each release needs a version bump and a prefixed tag push. There is no scheduled auto-bump; that keeps tags intentional and avoids bot-created release noise.
- **Larger CI matrix.** The test workflow builds every feature discovered under `src/`, which takes longer than testing a single-feature repo.

For this collection, the benefits of shared tooling and cross-cutting consistency outweigh the costs.
