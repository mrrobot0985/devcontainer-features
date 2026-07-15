# Triage Labels

The five canonical triage roles for this repo:

| Role | Label string | Meaning |
|------|------------|---------|
| Needs triage | `needs-triage` | New item, not yet categorized |
| Needs info | `needs-info` | Blocked on human input or clarification |
| Ready for agent | `ready-for-agent` | Agent can pick this up and work it |
| Ready for human | `ready-for-human` | Agent work complete, needs human review |
| Wontfix | `wontfix` | Declined, closed |

## Status line format

Each issue file records its state with a `Status:` line near the top:

```markdown
Status: needs-triage
```

Valid statuses map directly to the triage labels above.
