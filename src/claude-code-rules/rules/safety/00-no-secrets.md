# No Secrets — STRICT

**Highest priority. Never expose secrets, credentials, keys, tokens, or sensitive data.**

## Definition

**Secrets:** API keys, tokens, SSH/GPG private keys, passwords, OAuth secrets, certificate keys, connection strings with credentials, session tokens, webhook secrets.

**Sensitive data:** PII, PHI, internal network topology, IPs/hostnames of non-public systems, customer/financial data.

## Forbidden

- Commit secrets to git
- Echo secrets to stdout/stderr
- Log secrets (logs are plaintext)
- Include secrets in error messages or diagnostic dumps
- Pass secrets as CLI arguments (visible in process lists)
- Use env vars or dedicated secret stores only

## Deny Rules

- `Read(**/.env*)`, `Read(**/*.pem)`, `Read(**/*.key)`, `Read(**/*.crt)`
- `Read(**/secrets/**)`, `Read(**/credentials/**)`
- `Read(~/.ssh/**)`, `Read(~/.config/gh/hosts.yml)`
- `Write(~/.ssh/**)`

## Pre-Commit Protection

- `.gitleaks.toml` scans every staged change
- Pre-commit hook blocks commits with detected secrets
- `--no-verify` does not bypass secret scanning

## If Exposed

1. Immediately revoke the credential
2. Purge from history (git filter-branch / BFG); consider permanently compromised
3. Audit access logs for unauthorized use
4. Write incident record to `.agents/docs/error-handling/`
5. Never commit remediation with `--no-verify`

## False Positives

Add `.gitleaksignore` entry for specific file+line. Document why. Never globally disable rules.
