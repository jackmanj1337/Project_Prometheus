---
Role: dated
---

# Full Project Audit - Rollup (2026-07-05)

> Top-level rollup for the second complete-project audit run under
> `AGENT/Review Procedures/`. Run serially because sub-agent tooling was not
> explicitly authorized by the user.

**Overall health:** 7/10

## 1. Snapshot

| | |
|---|---|
| Branch / commit | `v0.3.0-features` @ `914dd025ea8fbd898e5dbbc7c8ed7a6441cbf4dc` |
| Working tree before audit edits | clean |
| `check_docs.py` | PASS, 22/22 |
| `check_rng_usage.sh` | PASS |
| `run_tests.sh` | PASS, 51 suites, 0 failed |
| Analyzer suite | PASS, 12/12 under stdlib `python3` |
| Scene integrity | PASS, 17 scene-attached scripts checked |
| Engine | Godot `4.6.stable.official.89cea1439` |
| Tool gaps | `pytest`, `gdlint`, `gdformat`, `gh` unavailable |

Pillar reports:

- `AGENT/Code Reviews/code_review_2026-07-05.md` (Code)
- `AGENT/Docs/governance/documentation_review_2026-07-05.md` (Documentation)
- `AGENT/Code Reviews/data_assets_review_2026-07-05.md` (Scenes, Data & Assets)
- `AGENT/Code Reviews/tests_ci_build_review_2026-07-05.md` (Tests, CI & Build)
- `AGENT/Code Reviews/process_history_review_2026-07-05.md` (Process & History)

## 2. Scorecard

| Pillar | Score | Delta vs previous |
|---|:---:|---|
| 1 - Code | 7/10 | down from 9; new spawn-seam contract bugs |
| 2 - Documentation | 7/10 | down from 8; GDD owner specs missed implemented spawn seam |
| 3 - Scenes/Data/Assets | 9/10 | up from 8; UID/import/resource integrity clean |
| 4 - Tests/CI/Build | 7/10 | up from 6; gates fixed, but stale spawn-seam test |
| 5 - Process/History | 7/10 | down from 8; audit cadence and DoD#1 miss |
| Overall health | 7/10 | weakest-pillar headline; mean 7.4 |

## 3. Executive Summary

The project is healthier operationally than it was on 2026-06-14: all baseline gates
are green, analyzer tests are fixed and gated, scene integrity is in CI, and UID drift
is gone. The main concern is contract drift around the new inline spawn seam: code,
tests, validation, and GDD do not all describe the same behavior. This is a contained
issue, but it crosses four pillars and should be fixed before building more generated
encounter work on top of it.

## 4. Cross-Pillar Findings

### CR-2026-07-05-1 - Inline spawn-seam contract drift

Owners: P1 + P4 + P2 + P5

`GameMap._spawn_units()` accepts inline `unit_data`, but it overwrites an inline unit's
existing `ai_profile` with `"basic"` when placement-level `ai_profile` is omitted.
`DataManager` now rejects both-sourced placements, while `_resolve_placement_unit_data()`
and `test_spawn_seam.gd` still accept and assert "inline wins." The control plane
records Slice 1 as implemented, but `GDD_01` and `GDD_06` still document only
`unit_data_path`.

Recommended fix in one follow-up commit: align runtime exactly-one validation, preserve
inline `ai_profile` by default, update spawn-seam tests, and update `GDD_01`/`GDD_06`.

### CR-2026-07-05-2 - Review cadence is manual

Owner: P5

The master procedure says run after about 30 commits or four weeks. This audit ran
514 commits after the last full audit, because the owner requested it. Add a reminder
or closeout check.

### CR-2026-07-05-3 - GDScript style gate remains deferred

Owner: P4

The gdtoolkit gate remains absent and the tools are unavailable in this environment.
This is lower urgency than correctness, but it is still a ratified enforcement backlog
item.

## 5. Unified Prioritized Action Plan

1. Fix the spawn-seam contract drift end-to-end: runtime, tests, GDD_01/GDD_06.
2. Add an audit-cadence reminder tied to commits since the latest full rollup.
3. Update Map 950 metadata/playbook drift (`10 units`, four-vs-five skill fixture).
4. Add `tools/**` to the Windows export exclusion.
5. Finish the gdformat/gdlint gate on a pip-capable machine.
6. Continue the planned registry migrations; avoid adding new closed-switch content
   cases unless they are temporary compatibility bridges.

## 6. Regression Watch

- 2026-06-14 CR-1 UID tracking: fixed and enforced.
- 2026-06-14 CR-2 fort-heal floor: fixed with regression test.
- 2026-06-14 CR-3 analyzer suite red/ungated: fixed and gated.
- Branch naming: improved by splitting `v0.3.0-features`.

## 7. Positive Observations

- Baseline gates are all green.
- Recent bug fixes continue to include focused regression tests.
- The control plane gives a good cross-feature view; it exposed the spawn-seam GDD
  miss by disagreeing with the owner specs.
