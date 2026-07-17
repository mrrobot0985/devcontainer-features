# Releasing a Feature

This repository is a monorepo: many features share one git repository and one CI setup. To avoid tag collisions, each feature is released with a prefixed git tag of the form `<feature-name>-v<semver>`.

Version bumps and tags are part of normal development git work. GitHub Actions only publishes to the registry when a real tag is pushed. There is no auto-release bot and no workflow that creates tags. The release workflow uses `permissions.contents: read`, so Actions cannot mint `*-v*` (or any) tags; developer-pushed tags remain the source of truth.

## Release path

1. **Update the version** in `src/<feature>/devcontainer-feature.json`. Follow SemVer:

   - Bump the major version for breaking changes.
   - Bump the minor version for new functionality.
   - Bump the patch version for fixes.

1. **Keep the feature README in sync** (pre-commit hook or):

   ```bash
   uv run python scripts/generate-feature-readmes.py
   ```

1. **Land the change on `main`** through a PR. CI must pass (`test.yaml`, `validate.yml`, `lint-workflows.yml`, conventional commits).

1. **Create and push a signed tag** from the release commit:

   ```bash
   git tag -s my-feature-v1.2.3 -m "release my-feature v1.2.3"
   git push origin my-feature-v1.2.3
   ```

   Pushing the tag starts `.github/workflows/release.yaml`, which publishes features under `./src` to GitHub Container Registry. Versions already present on GHCR are skipped by the publisher.

## Prefixed tags

The tag prefix is always the feature `id` exactly as it appears in `devcontainer-feature.json`:

```
claude-code-backend-v0.1.1
container-firewall-v0.2.0
container-firewall-v0.1.1
```

Plain SemVer tags like `v0.1.0` are not used, because they would collide across features.

## Manual publish (backfill only)

If you need to republish without a new tag (recovery or bulk backfill), run **Release dev container features** via `workflow_dispatch` from the Actions tab or:

```bash
gh workflow run release.yaml --ref main -f reason=backfill
```

This does not create tags. Prefer a normal tagged release when shipping a new version.

## Package visibility

Features are published to:

```
ghcr.io/mrrobot0985/devcontainer-features/<feature-id>:<version>
```

Packages are private by default. Open each package's GHCR settings page and set it to **public** so consumers can pull it without authentication. Public packages also stay within the GitHub free tier.

## Verify a release

After the release workflow finishes, pull the published image:

```bash
docker pull ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:0
```

Or reference it from a `devcontainer.json` and rebuild a container to confirm it resolves and installs.

## See also

- [CI Workflows](../reference/ci-workflows.md)
- [Monorepo Design](../explanation/monorepo-design.md)
