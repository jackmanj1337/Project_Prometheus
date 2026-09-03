---
Role: dated
---

# Pillar 4 - Tests, CI & Build Review (2026-07-15)

> **Pillar:** 4 - Tests, CI & Build
> **Procedure:** `AGENT/Review Procedures/04_Tests_CI_Build_Pillar.md`
> **Snapshot:** branch `agent/codex/2026-07-15/prep-save-followup`, commit `08b3b5c2aa5dfb1e773a87d07890b9c7629ef1b3`
> **Previous review:** `AGENT/Code Reviews/tests_ci_build_review_2026-07-05.md`

**Score:** 8/10

## Executive Summary

The safety net is stronger than the July 5 audit and directly exercises the new
campaign package, save, rewind, Prep, results, mutable-rule, and carry-forward
systems. All automated gates and a fresh Windows debug export passed. The main
remaining weakness is local/CI gate drift: the versioned pre-commit hook does not
run the analyzer or scene-integrity checks that both GitHub workflows run. The
ratified GDScript lint/format gate also remains unavailable.

## Baseline Results

- `python3 AGENT/Docs/check_docs.py`: PASS, 35/35 checks, exit 0.
- `bash run_tests.sh`: PASS, 98/98 suites, 0 failed, approximately 4.4 seconds
  after the import warm-up.
- `bash scripts/ci/check_rng_usage.sh`: PASS.
- `python3 -m pytest tools/godot-analyzer-mcp/tests/`: PASS, 12/12 in 0.05s.
- `python3 scripts/ci/check_scene_integrity.py`: PASS, 22 scene-attached scripts.
- Windows debug export using preset `Project Prometheus v0.4.0`: PASS, exit 0,
  102,031,680-byte artifact. Godot reported the known container-only inability to
  write `/home/vscode/.cache/godot`; packing and artifact creation succeeded.
- Toolchain: Godot 4.6.3, Python 3.12.13, pytest 9.1.1, gh 2.96.0 available;
  `gdlint` and `gdformat` unavailable.

## Issues

### Medium - Pre-commit omits two CI gates

Location: `scripts/hooks/pre-commit:10-20`,
`.github/workflows/tests-pr.yml:25-33`, and matching push workflow steps.

The hook runs documentation checks, the RNG guard, and the Godot suite, but it
does not run the analyzer-tool tests or `check_scene_integrity.py`. Both GitHub
workflows run those checks before the Godot suite. A local commit can therefore
pass the advertised hook and fail CI for analyzer or scene-path breakage.

Recommended fix: add the fast stdlib analyzer test and scene-integrity commands
to the versioned hook before its staged-file early exit. They complete in well
under a second in this environment.

### Medium - Ratified GDScript lint/format gate remains absent

Location: `AGENT/Review Procedures/00_Master_Review_Procedure.md` section 10,
`.github/workflows/tests-pr.yml`, `.github/workflows/tests-push.yml`, and
`scripts/hooks/pre-commit`.

Neither `gdlint` nor `gdformat` is installed, and no workflow or hook enforces
them. This is a recurring audit finding, not a regression introduced by this
branch.

Recommended fix: install pinned gdtoolkit on a dedicated formatting branch, run
the one-time formatter, then gate `gdformat --check` and `gdlint` in CI and the
hook.

### Low [CROSS] - Campaign UI remains live-validation qualified

Location: `AGENT/Docs/playtests/playtest_checklist_v0.4.0_campaign_test.md` and
`AGENT/Session Notes/2026-07-15ab.md`.

Headless coverage is broad, but keyboard/gamepad focus, long-roster scrolling,
text fit, and the complete five-map flow still require the prepared Windows
playtest. This is correctly documented as validation rather than missing
implementation, but it remains the release-facing evidence gap.

Recommended action: execute and archive the focused campaign checklist before a
release/merge claim that includes live UI acceptance.

## Coverage Gap Table

| System | Meaningful tests? | Evidence / remaining qualifier |
|---|---:|---|
| Campaign graph/progression | Yes | `test_campaign_data`, `test_campaign_manager` |
| Save/load/integrity/policy | Yes | `test_save_*`, 30 SaveManager assertions |
| Suspend/Retry/Rewind/RNG | Yes | suspend, ledger, rewind, RNG suites |
| Prep/results/defeat UI | Yes | Prep, game-over sequencing, menu-scale suites; live focus/text pending |
| Package preflight/install/export/discovery | Yes | Dedicated hostile and transaction suites |
| Tier-2 activation/save identity | Yes | Adapter, package identity, New Game pack selection |
| Mutable rules/status carry-forward | Yes | Dedicated mutable-state and status-record suites |
| Scene paths/autoload cache | Yes | Scene-integrity CI plus full headless suite |
| Analyzer tooling | Yes | 12 tests, gated in both GitHub workflows |
| GDScript style | No | gdtoolkit gate remains absent |

## CI And Hook Findings

- Pull-request and push workflows run documentation, RNG, analyzer, scene
  integrity, and the headless Godot suite without `continue-on-error`.
- The runner has per-suite timeouts and parallel isolated HOME directories.
- The versioned hook's Godot/class-cache behavior is sound, but its analyzer and
  scene-integrity omissions create the Medium parity finding above.

## DoD#2 Enforcement Gaps

- GDScript lint/format remains the primary ratified but unenforced rule.
- The master procedure's lower-priority procedure-folder and pillar-score checks
  remain backlog items; no new violation was found in this pillar.

## Build And Export Findings

- `export_presets.cfg` consistently names/product-versions v0.4.0 and excludes
  `AGENT/**`, tests, script tools, and root `tools/**`.
- A clean debug export completed successfully. The editor-cache errors are an
  environment limitation already recorded by the branch and did not prevent the
  artifact.
- Docker files were inspected but not rebuilt; no Docker configuration changed
  in the campaign/save delta.

## Positive Observations

- The suite grew from 51 to 98 suites while remaining fast and fully green.
- High-risk archive input, transactional install, protected save integrity, and
  deterministic rewind all have focused negative-path tests.
- The prior export-exclusion finding is fixed: root `tools/**` is now excluded.
- The prior spawn-seam contradiction was fixed and remains covered.

## Prioritized Action Plan

1. Add analyzer and scene-integrity checks to the versioned pre-commit hook.
2. Run the focused Windows campaign checklist and retain its log/screenshots.
3. Land the gdtoolkit format/lint gate on a dedicated mechanical-change branch.
4. Keep the export smoke test in release-cut verification.

## Delta Vs Previous Review

- Score improves from 7/10 to 8/10.
- Fixed: ambiguous spawn-seam behavior/test contradiction.
- Fixed: root `tools/**` is excluded from Windows export.
- Improved: 47 additional suites cover the campaign/save/package implementation.
- Newly surfaced: the hook/CI analyzer and scene-integrity parity gap.

## Procedure Friction

The procedure asks for a precise assertion total, but `run_tests.sh` summarizes
per-suite assertions without a final aggregate. Suite counts and failure counts
are reliable; deriving the assertion total would require parsing heterogeneous
test output. The build step also emits hundreds of progress lines, so future
audits would benefit from a quiet export-smoke wrapper that preserves exit code
and final artifact metadata.
