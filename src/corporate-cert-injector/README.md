# Corporate Certificate Injector

Injects corporate TLS/SSL certificates into system and language-specific trust stores, enabling devcontainers to work behind TLS-inspecting proxies (Zscaler, Palo Alto, Blue Coat, etc.).

## Problem Solved

Corporate proxies intercept TLS connections using self-signed certificates. Without these certificates in the container's trust store:

- Package managers (npm, pip, cargo) fail with certificate errors
- Git clones from HTTPS remotes fail
- API calls from application code fail
- CI pipelines break in corporate environments

## Usage

Add the feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/mrrobot0985/devcontainer-features/corporate-cert-injector:0": {}
  },
  "mounts": [
    "source=${localEnv:HOME}/.corporate-certs,target=/usr/local/share/ca-certificates/corporate,type=bind,consistency=cached"
  ]
}
```

Place your corporate `.pem` or `.crt` files in `~/.corporate-certs` on the host.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `certPath` | string | `"/usr/local/share/ca-certificates/corporate"` | Directory where corporate certificates are mounted |
| `injectJava` | boolean | `true` | Inject certificates into the Java keystore |
| `injectNode` | boolean | `true` | Set `NODE_EXTRA_CA_CERTS` environment variable |
| `injectPython` | boolean | `true` | Inject certificates into Python certifi bundle |
| `injectGit` | boolean | `true` | Configure Git to use the corporate CA bundle |
| `injectGo` | boolean | `true` | Set `SSL_CERT_FILE` and `SSL_CERT_DIR` for Go |

## What Gets Configured

- **System CA store**: Runs `update-ca-certificates` or `update-ca-trust`
- **Java**: Adds certs to all detected `cacerts` keystores
- **Node.js**: Sets `NODE_EXTRA_CA_CERTS` in shell profiles and `/etc/profile.d`
- **Python**: Appends certs to certifi bundle; sets `REQUESTS_CA_BUNDLE` and `SSL_CERT_FILE`
- **Git**: Sets `http.sslCAInfo` globally
- **Go**: Sets `SSL_CERT_FILE` and `SSL_CERT_DIR`

## Helper Command

```bash
corporate-cert-status  # Show injection status and environment variables
```
