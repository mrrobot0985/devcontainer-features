# /to-tickets

Convert SPEC.md sections into individual ticket markdown files.

## Usage

```bash
/to-tickets [project-root]
```

## Inputs

- `SPEC.md`
- `WAYFINDER.md` / `wayfinder/map.yaml`

## Outputs

- `wayfinder/tickets/T<NNN>-<slug>.md` files with YAML frontmatter

## Behavior

Idempotent unless FORCE=true. Scans SPEC.md for actionable sections, assigns deterministic IDs, writes one ticket per section with frontmatter id/title/status/priority/type/branch/blockedBy. Existing tickets are skipped unless FORCE=true.
