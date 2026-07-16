# Cosign Verify

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs [Cosign](https://github.com/sigstore/cosign) (Sigstore) and provides helpers for verifying container image signatures and attestations via keyless OIDC.

## Features

- **Signature verification** — Verify container image signatures using Cosign
- **Attestation extraction** — Extract SBOM and provenance attestations from signed images
- **Keyless OIDC support** — Works with GitHub Actions, Google Cloud, and other OIDC providers
- **Helper utility** — `cosign-verify-image` command for quick verification

## Usage

Add the feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/cosign-verify:0": {}
  }
}
```

Verify an image signature:

```bash
cosign-verify-image ghcr.io/owner/image:tag
```

Extract an SBOM attestation:

```bash
cosign-verify-image ghcr.io/owner/image:tag --sbom
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cosignVersion` | string | `"latest"` | Cosign version to install |
| `verifyOnInstall` | boolean | `false` | Run a verification test on install |

## Notes

- Cosign requires network access to Sigstore infrastructure (`rekor.sigstore.dev`, `fulcio.sigstore.dev`)
- In air-gapped environments, you will need to configure a private Sigstore instance
