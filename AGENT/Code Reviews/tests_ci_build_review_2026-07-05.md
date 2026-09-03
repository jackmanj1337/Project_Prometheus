---
Role: dated
---

# Pillar 4 - Tests, CI & Build Review (2026-07-05)

> **Pillar:** 4 - Tests, CI & Build
> **Procedure:** `AGENT/Review Procedures/04_Tests_CI_Build_Pillar.md`
> **Snapshot:** branch `v0.3.0-features`, commit `914dd025ea8fbd898e5dbbc7c8ed7a6441cbf4dc`
> **Previous review:** `AGENT/Code Reviews/tests_ci_build_review_2026-06-14.md`

**Score:** 7/10

## Executive Summary

The safety net is materially stronger than the 2026-06-14 audit: docs, RNG, analyzer,
scene-integrity, and the full Godot suite all pass, and CI now gates the analyzer and
scene wiring checks. The main risk is not a red gate; it is a green test preserving
an obsolete spawn-seam contract that now contradicts `DataManager` validation.

## Baseline Results

- `python3 AGENT/Docs/check_docs.py`: PASS, 22/22 checks.
- `bash scripts/ci/check_rng_usage.sh`: PASS.
- `python3 tools/godot-analyzer-mcp/tests/test_tools.py`: PASS, 12 tests in 29.390s.
- `python3 scripts/ci/check_scene_integrity.py`: PASS, 17 scene-attached scripts checked.
- `bash run_tests.sh`: PASS, 51 suites, 0 failed.
- Tool probe: Godot `4.6.stable.official.89cea1439`; Python `3.10.12`; `pytest`,
  `gdlint`, `gdformat`, and `gh` unavailable.

## Issues

### High - `test_spawn_seam` asserts the old ambiguous-placement contract

Location: `scripts/tests/test_spawn_seam.gd:62`, `scripts/autoloads/DataManager.gd:416`,
`scripts/core/GameMap.gd:224`

`DataManager` now rejects enemy placements that provide both `unit_data_path` and
inline `unit_data` with "exactly one" validation. The runtime helper still accepts
the same ambiguous dictionary by giving inline `unit_data` precedence, and
`test_spawn_seam.gd` explicitly asserts that behavior. That means the suite is green
while protecting a contract the validator now says is invalid.

Recommended fix: change `_resolve_placement_unit_data()` to reject both-sourced
placements, update `test_spawn_seam.gd`, and keep the `test_data_manager.gd` mixed-
source error coverage.

### Medium - Ratified GDScript lint/format gate is still not installed

Location: `AGENT/Review Procedures/00_Master_Review_Procedure.md:250`,
`.github/workflows/tests-pr.yml:20`, `scripts/hooks/pre-commit:11`

The master procedure still lists `gdlint`/`gdformat` as an enforcement candidate,
and this environment still lacks both tools. CI and hooks run docs, RNG, analyzer,
scene-integrity, and tests, but no style/lint gate. This was already called out in
the 2026-06-14 follow-up as blocked on a pip-capable machine.

Recommended fix: install `gdtoolkit`, run one whole-repo format pass, then add
`gdformat --check` and `gdlint` to both CI workflows and the hook.

### Low - Windows export excludes `scripts/tools/**`, not root `tools/**`

Location: `export_presets.cfg:6`

The export preset excludes `AGENT/**`, `scripts/tests/**`, and `scripts/tools/**`,
but the Python analyzer/tooling tree lives under root `tools/**`. With
`export_filter="all_resources"`, those files are eligible for export packaging even
though they are development tooling.

Recommended fix: add `tools/**` to `exclude_filter`.

## Coverage Gap Table

| System | Meaningful tests? | Notes |
|---|---:|---|
| Combat / forecast / skills | Yes | `test_combat`, `test_attack_preview_*`, `test_skill_item_handler`. |
| Turn flow / victory sequencing | Yes | `test_turn_manager`, `test_game_over_sequencing`. |
| Map cursor / MRD overlays | Yes | `test_map_cursor*`, with real overlay assertions after the 2026-07-05 fix pass. |
| Data loading / validation | Yes | `test_data_layer`, `test_data_manager`, `test_spawn_seam`; one stale assertion noted above. |
| Scenes / onready wiring | Yes | `check_scene_integrity.py` now in CI. |
| Tooling analyzer | Yes | Stdlib test suite now green and gated. |
| GDScript style | No | No `gdformat`/`gdlint` gate yet. |

## Delta Vs Previous Review

Fixed since 2026-06-14: analyzer tests are green and gated; scene-integrity is gated;
UID tracking is enforced; pre-commit has class-cache parity with CI; version-tag and
rollup-score checks exist. New/regressed: the spawn-seam test contradiction was
introduced by the 2026-07-05 inline-placement validation fix.

## Positive Observations

- `run_tests.sh` remains fast and hermetic with per-suite HOME isolation and hard
  timeouts.
- CI and hooks now cover docs, RNG, analyzer tooling, scene integrity, and Godot tests.
- `check_docs.py` has grown into a real enforcement layer rather than a passive doc
  checker.
