# Tickets: Devcontainer Features v1.0.0 Polish

Remaining work to get all 66 features and CI passing cleanly before v1.0.0 release.

Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

## Fix invalid licenseURI in devcontainer-feature.json files

**What to build:** Audit all `src/*/devcontainer-feature.json` files and replace any `licenseURI` key (invalid per schema) with `documentationURL` (valid). Validate each file with `python -m json.tool` and the devcontainer-feature schema after changes.

**Blocked by:** None — can start immediately.

- [ ] All features with `licenseURI` are identified and fixed
- [ ] All `devcontainer-feature.json` files pass JSON validation
- [ ] No `licenseURI` references remain in any feature JSON

## Fix shellcheck SC2034 in install scripts

**What to build:** Run shellcheck across all `src/*/install.sh` files, fix SC2034 (unused variable) warnings by either using the variable, removing it, or adding a `shellcheck disable` comment with justification. Each fix must not change the feature's runtime behavior.

**Blocked by:** Fix invalid licenseURI in devcontainer-feature.json files.

- [ ] All install.sh scripts pass shellcheck with zero warnings
- [ ] No SC2034 warnings remain
- [ ] CI lint job passes on all features

## Backfill missing test scenarios for older features

**What to build:** Create `test/` directories with `scenarios.json` and `test.sh` for features created before the test scaffolding was standardized. Each test must verify the feature installs correctly and its helper CLI responds to `status`.

**Blocked by:** Fix shellcheck SC2034 in install scripts.

- [ ] Every feature has a `test/` directory with at least one scenario
- [ ] `scenarios.json` references a valid `devcontainer.json` and test script
- [ ] CI test job covers all 66 features

## Implement Wave 18 features from research backlog

**What to build:** Create two features that were researched but not yet implemented: `wcag-lsp-dev` (accessibility language server for WCAG compliance) and `local-ci-runner` (runs CI pipelines locally using act or similar). Each needs `devcontainer-feature.json`, `install.sh`, `README.md`, and `test/`.

**Blocked by:** Backfill missing test scenarios for older features.

- [ ] `wcag-lsp-dev` feature installs and passes its smoke test
- [ ] `local-ci-runner` feature installs and passes its smoke test
- [ ] Both features appear in `README.md` table with version badges
- [ ] Features README count updated to 68

## Validate full CI pipeline end-to-end

**What to build:** Push a branch, open a PR, and verify the complete CI workflow (lint + test) passes for all features. Fix any remaining failures discovered during this run. Merge the PR to main only when green.

**Blocked by:** Implement Wave 18 features from research backlog.

- [ ] Lint job passes (JSON validation, shellcheck, ruff, README checks)
- [ ] Test job passes for all features
- [ ] PR is merged with green CI
- [ ] No remaining CI failures on main
