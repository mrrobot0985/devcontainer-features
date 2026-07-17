# Prebuild Lifecycle Helper

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Analyzes devcontainer.json lifecycle commands, detects dependency installations in non-prebuild hooks, and optionally rewrites configuration to leverage Codespaces prebuild caching

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `failOnWarning` | Fail the build if dependency installations are detected in non-prebuild hooks | boolean | false |
| `fixMode` | Automatically rewrite devcontainer.json to move dependency installations to updateContentCommand | boolean | false |
| `detectLanguages` | Comma-separated list of languages to scan for (auto, node, python, rust, ruby, go, php, java, dotnet). 'auto' scans all known lockfiles. | string | auto |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/prebuild-lifecycle-helper:1": {}
}
```
