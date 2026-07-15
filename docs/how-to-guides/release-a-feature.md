# Releasing a Feature

This repository is a monorepo: many features share one git repository and one CI setup. To avoid tag collisions, each feature is released with a prefixed git tag of the form `<feature-name>-v<semver>`.

## Automated release path (preferred)

The normal release flow is fully automated:

1. **Detect changes** — `.github/workflows/auto-release.yml` runs weekly and on demand. It compares every feature source directory against its latest prefixed tag. If the directory changed, it bumps the patch version in `src/<feature>/devcontainer-feature.json`.
2. **Open a pull request** — the workflow creates a PR titled `chore: bump feature versions`.
3. **Merge the PR** — once CI passes and the PR merges to `main`, `.github/workflows/tag-release.yml` reads each feature's current version and creates the prefixed tag if it does not already exist.
4. **Publish** — pushing the tag triggers `.github/workflows/release.yaml`, which publishes the feature to GitHub Container Registry using the devcontainers publish action.

You do not need to edit versions or create tags manually unless you are following the emergency path.

## Manual release (emergency only)

Use this path when you must ship a specific feature immediately and cannot wait for the weekly automation.

1. **Update the version** in `src/<feature>/devcontainer-feature.json`. Follow SemVer:

   - Bump the major version for breaking changes.
   - Bump the minor version for new functionality.
   - Bump the patch version for fixes.

2. **Commit with a conventional commit message**:

   ```bash
   git add src/my-feature/devcontainer-feature.json
   git commit -m "feat(my-feature): bump version to 1.2.3"
   ```

3. **Create and push a signed tag**:

   ```bash
   git tag -s my-feature-v1.2.3 -m "release my-feature v1.2.3"
   git push origin my-feature-v1.2.3
   ```

   Pushing the tag starts `.github/workflows/release.yaml`.

## Prefixed tags

The tag prefix is always the feature `id` exactly as it appears in `devcontainer-feature.json`:

```
claude-code-backend-v0.1.1
container-firewall-v0.2.0
nvidia-container-toolkit-v0.1.1
```

Plain SemVer tags like `v0.1.0` are not used, because they would collide across features.

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
