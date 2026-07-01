#!/usr/bin/env python3
"""Generate missing feature README.md files from devcontainer-feature.json metadata.

Existing READMEs are left untouched to preserve manual enhancements.
Run this manually when you add a new feature, or let the pre-commit hook
run it for you.

Usage:
    uv run python scripts/generate-feature-readmes.py [--check]

--check exits with a non-zero status if any README would be created.
"""

import json
import sys
from pathlib import Path

README_TEMPLATE = """# {name}

{description}

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
{options_table}

## Example Usage

```json
"features": {{
    "ghcr.io/mrrobot0985/devcontainer-features/{id}:{version_major}": {{}}
}}
```
"""


def _generate_options_table(options: dict) -> str:
    rows = []
    for key, meta in options.items():
        desc = meta.get("description", "")
        typ = meta.get("type", "string")
        default = meta.get("default", "")
        if isinstance(default, bool):
            default = str(default).lower()
        elif isinstance(default, str) and not default:
            default = '""'
        rows.append(f"| `{key}` | {desc} | {typ} | {default} |")
    return "\n".join(rows)


def generate_readme(feature_dir: Path) -> str:
    json_path = feature_dir / "devcontainer-feature.json"
    if not json_path.exists():
        raise FileNotFoundError(f"{json_path} not found")

    data = json.loads(json_path.read_text())
    options = data.get("options", {})
    version = data.get("version", "0")
    version_major = version.split(".")[0] if version else "0"

    return README_TEMPLATE.format(
        name=data.get("name", data["id"]),
        description=data.get("description", ""),
        options_table=_generate_options_table(options),
        id=data["id"],
        version_major=version_major,
    )


def main() -> int:
    check_only = "--check" in sys.argv
    src_dir = Path(__file__).parent.parent / "src"
    changed = False

    for feature_dir in sorted(src_dir.iterdir()):
        if not feature_dir.is_dir():
            continue
        json_path = feature_dir / "devcontainer-feature.json"
        if not json_path.exists():
            continue

        readme_path = feature_dir / "README.md"
        if readme_path.exists():
            continue

        generated = generate_readme(feature_dir)

        if check_only:
            print(f"Would create {readme_path}")
            changed = True
        else:
            readme_path.write_text(generated)
            print(f"Created {readme_path}")
            changed = True

    return 1 if (check_only and changed) else 0


if __name__ == "__main__":
    sys.exit(main())
