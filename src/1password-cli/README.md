# 1Password CLI

Installs the 1Password CLI (`op`) and provides a `get-secret` helper for
retrieving secrets from 1Password vaults in devcontainer workflows.

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/1password-cli:0": {
        "version": "latest"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | 1Password CLI version to install |

## Commands

- `op` — the 1Password CLI
- `get-secret <vault> <item> <field>` — read a secret value

## Example

```bash
# In postCreateCommand or a script
export API_KEY=$(get-secret my-vault api-key credential)
```

## Notes

- Requires 1Password account and `op` sign-in before use.
- Consider using 1Password Service Accounts in CI/CD environments.
- The `get-secret` helper is a thin wrapper around `op read`.
