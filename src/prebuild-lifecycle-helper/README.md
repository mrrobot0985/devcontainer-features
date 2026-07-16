# Prebuild Lifecycle Helper

![Version](https://img.shields.io/badge/version-0.2.0-blue)

Analyzes `devcontainer.json` lifecycle commands, detects dependency installations placed in non-prebuild hooks, and optionally rewrites configuration to leverage GitHub Codespaces prebuild caching.

## Problem

Heavy operations like `npm install` or `pip install` placed in `postCreateCommand` run at every workspace connect time, preventing Codespaces from caching them in the prebuild snapshot. Proper placement in `updateContentCommand` can reduce cold start from minutes to seconds.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/prebuild-lifecycle-helper:0": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `failOnWarning` | boolean | `false` | Fail the build if dependency installations are detected in non-prebuild hooks |
| `fixMode` | boolean | `false` | Automatically rewrite `devcontainer.json` to move dependency installations to `updateContentCommand` |
| `detectLanguages` | string | `"auto"` | Comma-separated list of languages to scan (`auto`, `node`, `python`, `rust`, `ruby`, `go`, `php`, `java`, `dotnet`) |
| `commandTimeout` | string | `"60s"` | Timeout for each detected install command when running in fixMode |

## Detected Languages

The tool scans workspace lockfiles and maps them to optimal install commands:

| Lockfile | Language | Install Command |
|----------|----------|-----------------|
| `package-lock.json` | Node | `npm ci` |
| `yarn.lock` | Node | `yarn install --frozen-lockfile` |
| `pnpm-lock.yaml` | Node | `pnpm install --frozen-lockfile` |
| `bun.lockb` | Node | `bun install` |
| `Pipfile.lock` | Python | `pipenv install --deploy` |
| `poetry.lock` | Python | `poetry install --no-interaction` |
| `requirements*.txt` | Python | `pip install -r requirements.txt` |
| `Cargo.lock` | Rust | `cargo build` |
| `Gemfile.lock` | Ruby | `bundle install` |
| `go.sum` | Go | `go mod download` |
| `composer.lock` | PHP | `composer install --no-interaction --optimize-autoloader` |
| `pom.xml` | Java | `mvn dependency:resolve` |
| `build.gradle` | Java | `gradle build` |
| `packages.lock.json` | .NET | `dotnet restore` |

## Auto-Fix Mode

Enable `fixMode` to automatically rewrite `devcontainer.json`:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/prebuild-lifecycle-helper:0": {
        "fixMode": true
    }
}
```

This will:

1. Back up `devcontainer.json` to `devcontainer.json.prebuild-backup`
2. Move dependency installations from `onCreateCommand`, `postCreateCommand`, and `postStartCommand` to `updateContentCommand`
3. Preserve non-install commands in their original hooks

## Standalone CLI

Run manually at any time:

```bash
# Audit only
prebuild-audit

# Audit specific file
prebuild-audit /path/to/devcontainer.json

# Audit and auto-fix
prebuild-audit --fix

# Scan only Node and Python
prebuild-audit --lang node,python
```

## Integration

Add to `postCreateCommand` for CI validation:

```json
"postCreateCommand": "prebuild-audit"
```

## Notes

- `updateContentCommand` runs during prebuild creation and is frozen into the snapshot
- `postCreateCommand` and `postStartCommand` run at connect time
- The tool respects `.gitignore` when scanning for lockfiles
- Requires `jq` for fixMode; the feature will attempt to install it if missing
