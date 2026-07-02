# Markdown Formatting — STRICT

**Never run plain `mdformat` without plugins. It destroys YAML frontmatter.**

## Required Command

```bash
uvx --with mdformat-frontmatter --with mdformat-gfm mdformat <files>
```

## Why Plugins Are Mandatory

Without `mdformat-frontmatter`, mdformat interprets `---` YAML frontmatter delimiters as markdown thematic breaks. This corrupts agent, rules, and skills files.

The `mdformat-gfm` plugin provides GitHub Flavored Markdown support (tables, task lists, strikethrough).

## What to Format

- Agent files (`agents/*.md`)
- Rules (`rules/**/*.md`)
- Skills (`skills/**/SKILL.md`)
- Docs (`docs/**/*.md`)
- README, CONTRIBUTING, etc.

## CI Enforcement

CI runs `mdformat --check .` with both plugins installed. Any file not formatted with both plugins will fail.

## Recovery from Corruption

1. Restore from last known-good commit: `git checkout <good-commit> -- agents/ rules/ skills/`
2. Re-format with plugins: `uvx --with mdformat-frontmatter --with mdformat-gfm mdformat agents/ rules/ skills/`
3. Verify: `uvx --with mdformat-frontmatter --with mdformat-gfm mdformat --check agents/ rules/ skills/`

## Anti-patterns

- Never run plain `uvx mdformat` or `mdformat` without plugins
- Never install mdformat without `mdformat-frontmatter` and `mdformat-gfm`
- Never skip `mdformat --check` in CI
- Never manually edit frontmatter delimiters
