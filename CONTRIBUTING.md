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
