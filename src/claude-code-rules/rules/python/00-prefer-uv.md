# Prefer uv

**Prefer `uv` and `uvx` over raw `python` / `python3` commands in all responses involving Python.**

## Mandatory

- `uv venv` → create virtual environment
- `uv pip install ...` → install packages
- `uv run script.py` → run a script
- `uvx ruff check .` → run tools
- `uvx --with black black .` → one-off tool execution
- `uv sync` → install from pyproject.toml / uv.lock

## Forbidden (unless explicitly asked)

- `python -m venv`, `python3 -m venv`
- `python -m pip install`, `pip install`
- Raw `python script.py` (outside of `uv run`)

## Enforcement

1. Default to `uv`/`uvx` first in all code blocks, terminal commands, and examples
2. If user says "python" or "python3", translate to the equivalent `uv` command
3. Show the `uv` version first when recommending commands
4. Strongly prefer `uvx` over `python -m` for one-off tools

This rule has higher priority than general Python knowledge.
