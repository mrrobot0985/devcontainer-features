# Scripts and Automation

This repository includes a small set of local helpers that keep the monorepo consistent and catch problems before CI.

| Script / Hook                         | Purpose                                                                                                                                                                                                |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `scripts/local-ci.sh`                 | Local pre-push gate. Runs shellcheck, README sync checks, workflow validation via `act`, dry-run release, and feature smoke tests. Not invoked by CI; it is a convenience helper.                      |
| `scripts/check-ghcr-majors.sh`        | Fail-closed GHCR lag gate: resolves major tags (`:1`) for critical / template-consumed feature IDs via docker/crane/oras/gh. Used by release CI and `ghcr-lag-gate.yml`. Does not publish.             |
| `scripts/generate-feature-readmes.py` | Generates or updates `src/<feature>/README.md` files from `devcontainer-feature.json` metadata. Run manually, or let the pre-commit hook run it.                                                       |
| `.githooks/pre-commit`                | Git hook installed with `git config core.hooksPath .githooks`. Auto-generates missing feature READMEs and blocks commits where `devcontainer-feature.json` is staged without its matching `README.md`. |

## `scripts/local-ci.sh`

Full reference: see the script source at `scripts/local-ci.sh`.

Run the local gate before every push:

```bash
./scripts/local-ci.sh
```

### Checks performed

1. **Prerequisites** — verifies `act`, `docker`, and a running Docker daemon.
1. **shellcheck** — runs on `src/*/install.sh`, `src/*/uninstall.sh`, helper scripts, and test scripts.
1. **README sync** — runs `uv run python scripts/generate-feature-readmes.py --check`.
1. **Validate workflow** — runs `act -j validate` to execute the `validate` job from `.github/workflows/validate.yml`.
1. **Dry-run release** — runs `act -j deploy --dryrun` to exercise `.github/workflows/release.yaml` without publishing.
1. **Feature smoke tests** — runs default-install tests for every feature with `npx -y @devcontainers/cli features test --skip-scenarios --skip-duplicated`.

### Limitations

- Full matrix tests via `act` can hit Docker-in-Docker edge cases. Use the Dev Container CLI directly for broad matrix validation.
- The script needs an authenticated `gh` CLI to inject `GITHUB_TOKEN` into the dry-run release job.

## `scripts/check-ghcr-majors.sh`

Fail-closed check that consumer majors are pullable/resolvable on GHCR.

```bash
./scripts/check-ghcr-majors.sh
./scripts/check-ghcr-majors.sh container-firewall non-root-enforcer
FEATURE_IDS=ai-agent-sandbox,host-isolation ./scripts/check-ghcr-majors.sh
```

ID sources (union):

1. Positional args / `FEATURE_IDS`
1. Hardcoded critical set (template-known: `non-root-enforcer`, `ai-agent-sandbox`, `container-firewall`, Claude suite IDs, `host-isolation`, `mcp-server-manager`, …)
1. Grep of `TEMPLATES_SRC` or sibling `../templates/src` when the umbrella `collections/` checkout is present

Resolution: `docker manifest inspect`, else `crane`, `oras`, or `gh` packages API.

## `scripts/generate-feature-readmes.py`

Generates or updates each `src/<feature>/README.md` from the corresponding `devcontainer-feature.json`.

### Usage

```bash
# Regenerate missing READMEs and update options tables in existing READMEs
uv run python scripts/generate-feature-readmes.py

# Validate that READMEs are in sync (used in CI)
uv run python scripts/generate-feature-readmes.py --check

# Regenerate every README completely, overwriting non-options content
uv run python scripts/generate-feature-readmes.py --force
```

### Behavior

- Creates a missing README from a template.
- For existing READMEs, replaces only the options table between `## Options` and `## Example Usage`, preserving surrounding content.
- `--check` exits with a non-zero status when a README is missing or its options table does not match the JSON. This is used by the `readme-sync` CI job.
- `--force` regenerates every README completely.

## `.githooks/pre-commit`

Keeps feature READMEs in sync with their JSON metadata.

### Install the hook

```bash
git config core.hooksPath .githooks
```

### What it does

1. Runs `uv run python scripts/generate-feature-readmes.py` to create any missing READMEs.
1. If new READMEs were generated, lists them and aborts the commit so you can review and stage them.
1. If a `devcontainer-feature.json` is staged but its matching `README.md` is not, aborts the commit.

The same checks run in CI via the `readme-sync` job in `.github/workflows/validate.yml`, so drift that passes the hook will also pass CI.

## See also

- [Testing a Feature Locally](../how-to-guides/test-a-feature-locally.md)
- [CI Workflows](ci-workflows.md)
