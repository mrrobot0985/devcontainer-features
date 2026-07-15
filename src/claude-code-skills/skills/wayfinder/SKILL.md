# /wayfinder

Chart a wayfinder map from a SPEC.md.

## Usage

```bash
/wayfinder [project-root]
```

## Inputs

- `SPEC.md` in the project root
- Optional `wayfinder/config.yaml` for overrides

## Outputs

- `WAYFINDER.md` at the project root
- `wayfinder/map.yaml` at the project root

## Behavior

Idempotent unless `FORCE=true`. Parses SPEC.md milestones and implementation headings, creates phase/ticket nodes, derives dependencies from explicit 'Blocked by'/'Depends on' text, and writes both markdown and YAML.
