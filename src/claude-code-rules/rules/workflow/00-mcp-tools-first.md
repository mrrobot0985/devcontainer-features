# MCP Tools First

**Prefer MCP tool interfaces over raw file reads for well-known services.**

## Applies

- Documentation servers → prefer `get_document` over `cat`
- Knowledge bases → prefer `query` over `grep`
- Coordination/state → prefer the service's MCP interface over raw file reads

## Raw Reads OK

- Files that are the direct subject of the current task
- Services with no MCP server configured
- Debugging MCP server issues themselves

## Enforcement

- Prefer `Read` for task-relevant files, MCP tools for service queries
- Never write directly to files managed by an MCP server
