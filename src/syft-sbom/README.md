# Syft SBOM Generator

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs [Syft](https://github.com/anchore/syft) and provides helpers for generating SBOMs (Software Bill of Materials) from the container filesystem in CycloneDX or SPDX format.

## Features

- **SBOM generation** — Scan the container filesystem and generate SBOMs
- **Multiple formats** — CycloneDX JSON, SPDX JSON, Syft JSON, or text
- **Helper utility** — `generate-sbom` command with configurable output
- **Compliance-ready** — CycloneDX and SPDX are industry-standard formats

## Usage

Add the feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/syft-sbom:0": {}
  }
}
```

Generate an SBOM:

```bash
generate-sbom
```

Generate SPDX format SBOM from a specific directory:

```bash
generate-sbom --format spdx-json --source dir:/path/to/project
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `syftVersion` | string | `"latest"` | Syft version to install |
| `defaultFormat` | string | `"cyclonedx-json"` | Default SBOM output format |

## Notes

- Syft scans the filesystem by default. To scan a container image, use `docker:IMAGE` as the source.
- Combine with `cosign-verify` to sign and attach SBOMs as attestations.
