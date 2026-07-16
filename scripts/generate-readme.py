import json
import os

# Generate the features table
rows = []
for d in sorted(os.listdir("src")):
    json_path = f"src/{d}/devcontainer-feature.json"
    if not os.path.exists(json_path):
        continue

    data = json.load(open(json_path))
    desc = data.get("description", "")
    version = data.get("version", "0.0.0")

    if len(desc) > 100:
        desc = desc[:97] + "..."

    badge = f"![Version](https://img.shields.io/badge/version-{version}-blue?style=flat-square)"
    readme_link = f"[README](src/{d}/README.md)"
    desc = desc.replace("|", "\\|")

    rows.append((d, desc, badge, readme_link))

count = len(rows)

header = f"""# Dev Container Features

![CI](https://github.com/mrrobot0985/devcontainer-features/actions/workflows/test.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

Custom dev container features for Claude Code / Ollama environments.

## Namespace

```text
ghcr.io/mrrobot0985/devcontainer-features/<id>:<version>
```

## Features ({count})

| Feature | Description | Version | README |
| ------- | ----------- | ------- | ------ |
"""

body = "\n".join(
    f"| `{id}` | {desc} | {badge} | {link} |"
    for id, desc, badge, link in rows
)

footer = """
## Documentation

- [Tutorials](docs/tutorials/)
- [How-to guides](docs/how-to-guides/)
- [Reference](docs/reference/)
- [Explanation](docs/explanation/)
"""

with open("README.md", "w") as f:
    f.write(header + body + footer)

print(f"Wrote README.md with {count} features")
