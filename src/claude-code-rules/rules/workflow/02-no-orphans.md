# No Orphans — STRICT

**Every created resource must have an owner and a deletion plan. Orphans are technical debt before they are problems.**

## Definition

An **orphan** is any artifact, resource, or stateful object created during automation that is left unmanaged after its immediate purpose is complete.

**Examples:** merged-but-not-deleted branches, untagged container images, stale workflow runs, temporary directories never cleaned up, dangling DNS records, abandoned preview environments.

## Rules

### 1. Create With a Cleanup Plan

Before creating any resource that persists beyond the current operation, define how and when it will be removed.

**Required:** Branch deletion on merge. Container image lifecycle policy. Preview environment TTL. Temporary directory cleanup in a `trap` or `finally` block.

**Forbidden:** "We'll clean it up later." Resources created without a corresponding deletion mechanism.

### 2. Merged Branches Die Immediately

A branch that has been squash-merged or fast-forwarded to `main` has no further purpose. It is an orphan.

**Required:** Delete the branch locally and remotely as part of the merge operation (`--delete-branch` with `gh pr merge`, manual cleanup immediately after).

**Forbidden:** Keeping merged feature branches "just in case." Git history on `main` is the source of truth; branches are ephemeral pointers.

### 3. Untagged Images Are Garbage

A container image pushed to a registry without a durable tag (or with only a mutable tag like `latest`) is an orphan waiting to consume storage and confuse deployment.

**Required:** Every publish gets a semantic version tag (`vX.Y.Z`). Untagged manifests are deleted. Old patch versions are purged on minor/major bumps.

**Forbidden:** Pushing images with only `latest` or build-id tags. Leaving untagged manifests in GHCR after tag deletion.

### 4. Workflow Runs Are Not Archives

CI/CD workflow runs produce artifacts, logs, and caches. Left alone they accumulate indefinitely.

**Required:** Artifact retention policies. Automatic deletion of run logs after N days. No artifact uploads without a downstream consumer.

**Forbidden:** Using GitHub Actions artifacts as permanent storage. Retaining logs "just in case" beyond operational need.

### 5. Temporary Means Temporary

Any file, directory, or process created with `mktemp`, `mktemp -d`, or an ephemeral environment must be removed before exit.

**Required:** `trap 'rm -rf "$TEMP_DIR"' EXIT` in shell scripts. Explicit cleanup in code. Ephemeral environments torn down after validation.

**Forbidden:** Script exit without cleanup block. Reliance on `/tmp` scavenging as a deletion strategy.

### 6. Orphan Detection Is Continuous

Orphans accumulate silently. Periodic audit is not optional.

**Required:** Regular review of branches, registry contents, open PRs, and cloud resources. Automated alerts for resources past TTL.

**Forbidden:** "I'll check next quarter." Waiting for cost overruns or namespace pollution before acting.

## Enforcement

- If you create it, you delete it. Ownership does not transfer to "ops" or "the platform."
- If deletion is blocked by policy (retention requirements), document the justification and expiration date explicitly.
- When in doubt, prefer ephemeral over persistent. Prefer deletion over retention.
