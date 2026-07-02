# Conventional Commits — STRICT

**All commit messages must follow the Conventional Commits specification.**

## Format

```
<type>[(scope)]: <description>

[optional body]
```

## Required Types

| Type | When |
| ---- | ---- |
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only changes |
| `style` | Formatting, linting, whitespace (no code change) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Maintenance, dependency updates, config changes |
| `ci` | CI/CD pipeline changes |
| `build` | Build system or external dependency changes |
| `perf` | Performance improvement |

## Rules

1. Type and description are mandatory
2. Scope is optional but encouraged for cross-cutting changes
3. Description must be lowercase, no trailing period
4. Body is optional; use for breaking changes or non-obvious context
5. Breaking changes must include `!` after type/scope or `BREAKING CHANGE:` footer

## Examples

```
feat: add session-start hook for capability detection
fix: handle empty stdin in standards-guard hook
chore(deps): bump actions/checkout from 4 to 6
style: format markdown files with mdformat
refactor: extract shared config to _config module
```

## Enforcement

- CI runs commitlint on every push and PR
- Any non-conventional commit message fails the CI gate
- Force-push of new root history is a known edge case — commitlint may need bypass
- Amend commits to fix messages; never skip CI with `--no-verify`

## Anti-patterns

- Never use `--no-verify` to bypass the commit message check
- Never use "Initial commit" or "WIP" — use `chore: initial commit`
- Never include AI attribution in commit messages
