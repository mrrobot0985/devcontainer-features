# /to-spec

Generate a SPEC.md from project context.

## Usage

```bash
/to-spec [project-root]
```

## Inputs

- `README.md` in the project root
- Any `docs/*.md` files
- `package.json`, `pyproject.toml`, or similar manifest files

## Outputs

- `SPEC.md` at the project root

## Behavior

Idempotent unless `FORCE=true`. If `SPEC.md` already exists and `FORCE` is not set, the skill prints a warning and exits.

The generated SPEC.md must include these headings:

- Summary
- Goals
- Non-Goals
- Architecture
- Milestones
- Risks
