# Locust Load Testing

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs Locust for Python-based load and performance testing in devcontainers.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version of locust to install |
| `installPlugins` | boolean | `false` | Install locust-plugins for additional metrics |

## Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/locust-testing:1": {
        "version": "latest",
        "installPlugins": false
    }
}
```

## CLI

```bash
# Run with web UI
locust -f locustfile.py --host https://api.example.com

# Run headless
locust -f locustfile.py --headless -u 100 -r 10 --run-time 60s --host https://api.example.com

# Start web UI on all interfaces (for port forwarding)
locust -f locustfile.py --web-host 0.0.0.0

# Check feature status
devcontainer-locust status
```

## Example locustfile.py

```python
from locust import HttpUser, task

class ApiUser(HttpUser):
    @task
    def get_users(self):
        self.client.get("/api/users")
```

## Requirements

- Python 3 must be available (install via `ghcr.io/devcontainers/features/python`)
- pip is used for package installation

## Notes

- Locust uses Python coroutines (asyncio) for high concurrency
- Web UI runs on port 8089 by default — forward this port in devcontainer.json
- Complements `ghcr.io/grafana/devcontainer-features/k6` for Python-based load testing
- Combine with `ghcr.io/mrrobot0985/devcontainer-features/bruno-api-testing` for API test authoring
