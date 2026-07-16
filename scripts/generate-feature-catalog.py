#!/usr/bin/env python3
"""Generate the feature catalog from devcontainer-feature.json metadata.

Reads all feature definitions in src/ and writes a consolidated catalog
to docs/reference/feature-catalog.md.

Usage:
    uv run python scripts/generate-feature-catalog.py [--check]

--check exits with a non-zero status if the catalog would change.
"""

import json
import sys
from pathlib import Path

CATALOG_PATH = Path("docs/reference/feature-catalog.md")
SRC_DIR = Path("src")

CATALOG_HEADER = """# Feature Catalog

Auto-generated from `devcontainer-feature.json` definitions.

## Features

| Feature | Version | Description | Options |
| ------- | ------- | ----------- | ------- |
"""


def _format_options(options: dict) -> str:
    if not options:
        return "—"
    parts = []
    for key, meta in options.items():
        typ = meta.get("type", "string")
        default = meta.get("default", "")
        if isinstance(default, bool):
            default = str(default).lower()
        elif isinstance(default, str) and not default:
            default = '""'
        parts.append(f"`{key}` ({typ}, default: {default})")
    return "<br>".join(parts)


def _generate_catalog() -> str:
    lines = [CATALOG_HEADER]
    for feature_dir in sorted(SRC_DIR.iterdir()):
        if not feature_dir.is_dir():
            continue
        json_path = feature_dir / "devcontainer-feature.json"
        if not json_path.exists():
            continue

        data = json.loads(json_path.read_text())
        feature_id = data.get("id", feature_dir.name)
        version = data.get("version", "0.0.0")
        description = data.get("description", "")
        options = data.get("options", {})
        options_str = _format_options(options)

        lines.append(
            f"| `{feature_id}` | {version} | {description} | {options_str} |"
        )

    lines.append("")
    lines.append("## Namespace")
    lines.append("")
    lines.append("```text")
    lines.append("ghcr.io/mrrobot0985/devcontainer-features/<id>:<version>")
    lines.append("```")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    check_only = "--check" in sys.argv
    generated = _generate_catalog()

    if check_only:
        if CATALOG_PATH.exists():
            existing = CATALOG_PATH.read_text()
            if existing == generated:
                print("Feature catalog is up to date.")
                return 0
            else:
                print("ERROR: feature catalog is out of date. Run the generator.")
                return 1
        else:
            print(f"ERROR: feature catalog missing at {CATALOG_PATH}")
            return 1

    CATALOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    CATALOG_PATH.write_text(generated)
    print(f"Generated feature catalog at {CATALOG_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
