# No Git Config Override — STRICT

**Never pass `-c <key>=<value>` or any inline override to git for config already set globally or per-repo.**

## Forbidden

- `git -c user.email=...`, `git -c user.name=...`
- `git -c commit.gpgsign=false`, `git -c tag.gpgsign=false`
- `git -c user.signingkey=...`, `git -c gpg.format=...`, `git -c gpg.ssh.program=...`
- `GIT_AUTHOR_EMAIL` / `GIT_AUTHOR_NAME` / `GIT_COMMITTER_*` env-var overrides
- `git config user.email ...` (writing config mid-session)
- Any `-c` flag that re-sets identity, signing, or commit behavior

## Why

Git is properly configured already. The default `user.email` is ID-prefixed to prevent `Co-authored-by` on squash merge. `commit.gpgsign=true` and `tag.gpgsign=true` are on by default.

Passing `-c` overrides silently fights this setup and has caused repeated bugs:

- Switching to the non-prefixed email reintroduces `Co-authored-by`.
- Disabling `gpgsign` produces unverified commits violating `required_signatures`.
- Inline overrides are invisible in shell history.

**You do not need to touch git config. Run plain `git commit -S -m "..."`, `git tag -s ...`, etc. The defaults are correct.**

## Legitimate Override

Only for documented, user-requested setup changes (e.g. "rotate signing key"). Change the **config file**, not via per-command `-c` flags, and only after explicit out-of-band human approval.

## Anti-patterns

- `git -c user.email="..." commit -S ...` — already the default.
- `git -c commit.gpgsign=false commit ...` — unverified, violates branch protection.
- `GIT_AUTHOR_EMAIL=... git commit ...` — same problem via env var.
- Editing `~/.gitconfig` or `.git/config` mid-session — ask the human; do not reconfigure.
