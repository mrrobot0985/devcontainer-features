# Container Firewall

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Configures an iptables/ipset whitelist firewall for the container with selectable service tags and optional telemetry blocking

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

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:1": {}
}
```
