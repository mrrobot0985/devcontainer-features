# SOPS Secret Manager

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Mozilla SOPS with age key generation for encrypting secrets in devcontainer projects.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/sops-secret-manager:0": {
        "generateAgeKey": true,
        "configureGitFilter": true
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `generateAgeKey` | boolean | `true` | Generate an age key pair for the devcontainer user |
| `cloudKms` | string | `""` | Cloud KMS provider: aws, gcp, azure, or empty for age-only |
| `configureGitFilter` | boolean | `true` | Configure git filters for transparent SOPS encryption/decryption |

## Why SOPS?

- **Git-friendly:** Encrypted values in committed files; only values are encrypted, keys remain visible
- **Team-friendly:** Multiple keys can decrypt the same file (age, AWS KMS, GCP KMS, Azure Key Vault)
- **No secret sprawl:** Secrets live in version control, encrypted, with audit history

## CLI

```bash
# Check SOPS status
devcontainer-sops-status

# Encrypt a file
sops encrypt --in-place secrets.yaml

# Decrypt a file
sops decrypt --in-place secrets.yaml

# Edit an encrypted file
sops --edit secrets.yaml
```

## Setup

1. The feature generates an age key pair in `~/.config/sops/age/keys.txt`
2. Copy the public key from `devcontainer-sops-status` output
3. Configure `.sops.yaml` in your project root with the public key
4. Use `sops --edit secrets.yaml` to create/edit encrypted files

## Git Integration

When `configureGitFilter` is enabled, files matching the SOPS pattern are automatically encrypted on `git add` and decrypted on checkout. Configure patterns in `.sops.yaml` or `.gitattributes`.

## Notes

- Requires `age` for key generation and encryption
- Cloud KMS providers require additional CLI tools and credentials
- The generated age key is ephemeral unless persisted via volume mounts
