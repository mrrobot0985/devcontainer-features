# Container Firewall

Configures an iptables/ipset whitelist firewall for the container with selectable service presets and optional telemetry blocking

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `profile` | Preset bundle of allowed outbound services | string | claude-code |
| `customDomains` | Comma-separated extra domains to allow (used only with profile=custom) | string | "" |
| `blockTelemetry` | Block known telemetry and tracking endpoints at the network level | boolean | false |
| `policy` | whitelist drops non-matching traffic; monitor logs but does not block | string | whitelist |
| `enableIPv6` | Also apply whitelist rules to IPv6 (ip6tables) | boolean | true |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0": {}
}
```
