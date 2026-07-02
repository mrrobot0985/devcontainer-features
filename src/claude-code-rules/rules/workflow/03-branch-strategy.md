# Branch Strategy and CI Gate — STRICT

**All changes must go through a CI-passing branch before merging to main.**

## Branch Strategy

### Main Branch

- `main` is the source of truth
- Direct push to `main` requires all CI checks to pass
- Force push to `main` only for exceptional cases (history rewrite, removing secrets). Never routine.

### Feature Branches

- Naming: `<type>/<description>` using kebab-case
- Types: `feat/`, `fix/`, `chore/`, `docs/`, `refactor/`, `test/`, `ci/`
- Example: `feat/session-start-hook`, `fix/mypy-strict-errors`

### Commit Strategy

- Prefer small, focused commits on feature branches
- Squash merge to `main` keeps history linear
- Each commit must pass CI independently

## CI Gate

### Must Pass Before Merge

1. **Lint** — ruff check (or equivalent)
2. **Format** — ruff format --check (or equivalent), mdformat --check with plugins
3. **Type check** — mypy --strict (or equivalent)
4. **Tests** — pytest (or equivalent)
5. **Commit message** — commitlint (conventional commits)

### CI Configuration

- CI workflow runs on every push and PR
- Use shared workflows (BrainXio/cicd) for consistency
- Do not disable CI checks without documented justification
- If a check fails, fix it — never skip with `--no-verify`

### Force Push Mitigations

- Force push of new root history breaks commitlint (no common ancestor)
- In this specific case, commitlint may need skip or manual verification
- After the first post-force-push commit, commitlint returns to normal
- Do not leave repos in a state where CI can never pass

## Anti-patterns

- Never merge with failing CI
- Never disable branch protection to bypass CI
- Never force push to `main` without explicit justification
- Never use generic branch names like `fix`, `test`, or `update`
- Never push directly to `main` for non-trivial changes — use a branch
