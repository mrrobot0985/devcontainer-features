# Prebuild Lifecycle Helper

Audits `devcontainer.json` lifecycle commands and warns when heavy operations
are placed in `postCreateCommand` or `postStartCommand` instead of
`updateContentCommand`. This misclassification prevents GitHub Codespaces from
optimizing the operation into the prebuild snapshot, causing slow cold starts.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/prebuild-lifecycle-helper:0": {}
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `failOnWarning` | boolean | `false` | Fail if heavy operations are in non-prebuild hooks |

## Detected Heavy Operations

- `npm install`, `yarn install`, `pnpm install`
- `pip install`, `poetry install`, `uv sync`
- `apt-get`
- `cargo build`
- `mvn install`, `gradle build`
- `git clone`
- `curl .*install`
- `bundle install`
- `go mod download`
- `conda install`

## Integration

Add to `postCreateCommand`:

```json
"postCreateCommand": "prebuild-lifecycle-helper"
```

## Notes

- `updateContentCommand` runs during prebuild creation and is frozen into the
  snapshot. `postCreateCommand` and `postStartCommand` run at connect time.
- Proper classification can reduce cold start from 8 minutes to ~30 seconds.
