#!/usr/bin/env python3
"""Generate feature README.md files from devcontainer-feature.json metadata.

Existing READMEs are preserved by default; only the options table between
``## Options`` and ``## Example Usage`` is updated when JSON options change.
Run this manually when you add a new feature, or let the pre-commit hook
run it for you.

Usage:
    uv run python scripts/generate-feature-readmes.py [--check] [--force]

--check exits with a non-zero status if any README is missing or if the
options table in an existing README does not match the current JSON.
--force regenerates every README completely.
"""

import argparse
import json
import sys
from pathlib import Path

README_TEMPLATE = """# {name}

![Version](https://img.shields.io/badge/version-{version}-blue?style=flat-square)

{description}

## Options

{options_table}

## Example Usage

```json
"features": {{
    "ghcr.io/mrrobot0985/devcontainer-features/{id}:{version_major}": {{}}
}}
```
"""

OPTIONS_HEADING = "## Options"
USAGE_HEADING = "## Example Usage"
TABLE_HEADER = "| Options Id | Description | Type | Default Value |"
TABLE_SEPARATOR = "| ----- | ----- | ----- | ----- |"


def _load_feature_data(feature_dir: Path) -> dict:
    json_path = feature_dir / "devcontainer-feature.json"
    if not json_path.exists():
        raise FileNotFoundError(f"{json_path} not found")
    return json.loads(json_path.read_text())


def _options_table_rows(options: dict) -> list[str]:
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
    return rows


def _build_options_table(options: dict) -> str:
    rows = _options_table_rows(options)
    return "\n".join([TABLE_HEADER, TABLE_SEPARATOR, *rows])


def generate_readme(feature_dir: Path) -> str:
    data = _load_feature_data(feature_dir)
    options = data.get("options", {})
    version = data.get("version", "0")
    version_major = version.split(".")[0] if version else "0"

    return README_TEMPLATE.format(
        name=data.get("name", data["id"]),
        description=data.get("description", ""),
        options_table=_build_options_table(options),
        id=data["id"],
        version=version,
        version_major=version_major,
    )


def _find_options_section(text: str) -> tuple[int, int] | None:
    """Return line indices of ``## Options`` and ``## Example Usage`` headings."""
    lines = text.splitlines()
    start = None
    end = None
    for i, line in enumerate(lines):
        stripped = line.strip()
        if start is None and stripped == OPTIONS_HEADING:
            start = i
        elif start is not None and stripped == USAGE_HEADING:
            end = i
            break
    if start is None or end is None:
        return None
    return start, end


def _parse_options_table(text: str) -> list[str] | None:
    """Return the normalised lines of a standard options table, or None."""
    bounds = _find_options_section(text)
    if bounds is None:
        return None
    start, end = bounds
    lines = [
        line.strip() for line in text.splitlines()[start + 1 : end] if line.strip()
    ]
    if len(lines) < 2:
        return None
    if lines[0] != TABLE_HEADER.strip() or lines[1] != TABLE_SEPARATOR.strip():
        return None
    return lines


def _replace_options_table(readme_path: Path, expected_table: str) -> bool:
    """Replace the options table in place while preserving surrounding content."""
    text = readme_path.read_text()
    lines = text.splitlines(keepends=True)
    bounds = _find_options_section(text)
    if bounds is None:
        return False
    start, end = bounds

    table_lines = [line + "\n" for line in expected_table.split("\n")]
    new_lines = lines[: start + 1] + ["\n"] + table_lines + ["\n"] + lines[end:]
    readme_path.write_text("".join(new_lines))
    return True


def _options_match(readme_path: Path, options: dict) -> bool | None:
    """Return True if the README options table matches the generated one.

    Returns None when the README does not contain a parseable options table in
    the expected format.
    """
    table = _parse_options_table(readme_path.read_text())
    if table is None:
        return None
    expected = [line.strip() for line in _build_options_table(options).splitlines()]
    return table == expected


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate or update feature README.md files."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Report missing READMEs or drifted options tables without writing files.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate every README completely.",
    )
    args = parser.parse_args()

    src_dir = Path(__file__).parent.parent / "src"
    changed = False

    # Iterate over every feature directory and either generate, regenerate, or
    # validate its README.md based on the CLI mode.
    for feature_dir in sorted(src_dir.iterdir()):
        if not feature_dir.is_dir():
            continue
        json_path = feature_dir / "devcontainer-feature.json"
        if not json_path.exists():
            continue

        readme_path = feature_dir / "README.md"

        if args.force:
            if args.check:
                print(f"Would regenerate {readme_path}")
                changed = True
            else:
                readme_path.write_text(generate_readme(feature_dir))
                print(f"Regenerated {readme_path}")
                changed = True
            continue

        if not readme_path.exists():
            if args.check:
                print(f"Would create {readme_path}")
                changed = True
            else:
                readme_path.write_text(generate_readme(feature_dir))
                print(f"Created {readme_path}")
                changed = True
            continue

        data = _load_feature_data(feature_dir)
        options = data.get("options", {})

        match = _options_match(readme_path, options)
        if match is None:
            if not args.check:
                print(
                    f"Skipping {readme_path}: options table not in expected format; "
                    "use --force to regenerate"
                )
            continue
        if match:
            continue

        if args.check:
            print(f"Drift detected in {readme_path}")
            changed = True
        else:
            table = _build_options_table(options)
            if _replace_options_table(readme_path, table):
                print(f"Updated options table in {readme_path}")
                changed = True
            else:
                print(
                    f"Skipping {readme_path}: could not locate options section; "
                    "use --force to regenerate"
                )

    # In --check mode a non-zero exit code signals that READMEs are missing or
    # out of sync, which is used by CI to block merge of drifted docs.
    return 1 if (args.check and changed) else 0


if __name__ == "__main__":
    sys.exit(main())
