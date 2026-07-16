# SonarScanner CLI

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs SonarScanner CLI for code quality analysis in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of sonar-scanner-cli to install |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/sonar-scanner:1": {
        "version": "latest"
    }
}
```

## CLI

```bash
# Run code analysis
sonar-scanner \
  -Dsonar.projectKey=my-project \
  -Dsonar.sources=. \
  -Dsonar.host.url=https://sonarqube.example.com \
  -Dsonar.token=$SONAR_TOKEN

# Run with debug output
sonar-scanner-debug -X

# Check feature status
devcontainer-sonar status
```

## Requirements

- `SONAR_TOKEN` environment variable for authentication
- `SONAR_HOST_URL` environment variable pointing to SonarQube server
- Java runtime is bundled with the scanner

## Notes

- Complements `ghcr.io/mrrobot0985/devcontainer-features/container-security-scan` (Trivy) for security + quality coverage
- Works with SonarQube Server, SonarCloud, and SonarQube Community Edition
- Requires network access to the SonarQube server during analysis
