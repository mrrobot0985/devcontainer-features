# Contributing

## Development Setup

```bash
git clone --recurse-submodules https://github.com/mrrobot0985/devcontainer-workspace.git
cd devcontainer-workspace/modules/<repo-name>
git config core.hooksPath .githooks
```

## Commit Messages

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[(scope)]: <description>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`.

## Pre-Commit Hooks

This repo uses a pre-commit hook to generate missing READMEs from JSON metadata. Install it once:

```bash
git config core.hooksPath .githooks
```

## CI Gate

Before pushing, run the local CI gate:

```bash
./scripts/local-ci.sh
```

## Branch Strategy

- `main` is protected — all changes go through PR
- Branch naming: `<type>/<description>` in kebab-case
- Squash merge to `main`

## Releasing

This is a monorepo containing multiple dev container features. To prevent git tag collisions, each feature gets its own prefixed tag.

### Tag Format

Use `<feature-name>-v<semver>` for every release. For example:

- `claude-code-hooks-v0.2.0`
- `claude-code-rules-v0.3.1`
- `claude-code-skills-v0.4.0`

### Why Prefixed Tags?

A single git tag namespace is shared across all features. Without a prefix, `v0.2.0` is ambiguous — it could apply to any feature. Prefixed tags keep release histories independent and readable.

### Release Steps

1. Update the `version` field in `src/<feature>/devcontainer-feature.json`
2. Commit the change with a conventional commit message:  
   `feat(<feature>): bump version to X.Y.Z`
3. Create and push a signed tag:  
   `git tag -s <feature-name>-vX.Y.Z -m "release <feature> vX.Y.Z"`
4. Push the tag to trigger the release workflow:  
   `git push origin <feature-name>-vX.Y.Z`

The release workflow triggers on any `*-v*` tag and publishes the feature whose JSON version changed.
