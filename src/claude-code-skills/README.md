# Claude Code Skills

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Installs skills into ~/.claude/skills/ with configurable sources

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `enableMattPocockSkills` | Clone and install Matt Pocock's skills from github.com/mattpocock/skills | boolean | true |
| `mattPocockSkillsVersion` | Version/tag of mattpocock/skills to clone | string | v1.1.0 |
| `installEngineering` | Install engineering skills (requires enableMattPocockSkills) | boolean | true |
| `installProductivity` | Install productivity skills (requires enableMattPocockSkills) | boolean | true |
| `installMisc` | Install miscellaneous skills (requires enableMattPocockSkills) | boolean | false |
| `installPersonal` | Install personal skills (requires enableMattPocockSkills) | boolean | false |
| `skipOnFailure` | Skip skill installation if clone fails instead of failing the build | boolean | false |

## Example Usage

```json
"features": {
    "ghcr.io/mrrobot0985/devcontainer-features/claude-code-skills:1": {}
}
```
