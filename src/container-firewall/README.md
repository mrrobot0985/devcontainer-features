# Container Firewall

![Version](https://img.shields.io/badge/version-0.4.0-blue?style=flat-square)

Configures an iptables/ipset whitelist firewall for the container with selectable service tags and optional telemetry blocking.

## Breaking changes in 0.4.0

- The lifecycle hook moved from `postStartCommand` to `postCreateCommand`. A nonzero exit from the firewall init script now aborts container creation.
- `failIfUnprivileged` defaults to `true`. If `iptables` is not functional (for example, when `NET_ADMIN` is missing), the devcontainer build fails by default.
- To restore the previous warn-and-continue behavior, set `failIfUnprivileged: false`.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `services` | Comma-separated service tags to whitelist. Use 'minimal' for an empty baseline. Composite tags like 'claude-code' expand to multiple services. | string | claude-code |
| `extraDomains` | Additional comma-separated domains to whitelist beyond the selected services. | string | "" |
| `blockTelemetry` | Block known telemetry and tracking endpoints at the network level | boolean | false |
| `policy` | whitelist drops non-matching traffic; monitor logs but does not block | string | whitelist |
| `enableIPv6` | Also apply whitelist rules to IPv6 (ip6tables) | boolean | true |
| `failIfUnprivileged` | Fail container creation when iptables cannot be used (missing CAP_NET_ADMIN). When false, emit a warning and continue as a no-op. | boolean | true |
| `dryRun` | Resolve all configured domains and print the IPs/CIDRs and policy that would be applied without modifying iptables or ipset rules. | boolean | false |

## Example Usage

Default configuration:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0": {}
}
```

Composing multiple services:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0": {
        "services": "claude-code,pypi,docker"
    }
}
```

Dry-run a configuration before applying it:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0": {
        "services": "github",
        "dryRun": true
    }
}
```

By default, the feature now fails container creation when `iptables` is not functional. To keep the previous warn-and-no-op behavior on unprivileged containers, set:

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0": {
        "failIfUnprivileged": false
    }
}
```
