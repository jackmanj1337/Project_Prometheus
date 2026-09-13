---
Role: topic
---

# Documentation Review - 2026-07-05

> **Status:** Active - documentation review report
> **Last verified:** 2026-07-05
> **Pillar:** 2 - Documentation
> **Procedure:** `AGENT/Review Procedures/02_Documentation_Pillar.md`
> **Snapshot:** branch `v0.3.0-features`, commit `914dd025ea8fbd898e5dbbc7c8ed7a6441cbf4dc`
> **Previous review:** `AGENT/Docs/archive/consolidation/documentation_review_2026-06-14.md`

**Score:** 7/10

## Executive Summary

`check_docs.py` is green, the generated indexes are intact, and most recent planning
work is well cross-linked. The main documentation failure is a DoD#1 miss: the
inline enemy-placement spawn seam is implemented and tracked in the control plane,
but the live GDD specs still document only `unit_data_path`.

## `check_docs.py` Status

PASS, 22/22 checks.

## Spot-Check Sample

Reviewed `GDD_01`, `GDD_06`, `GDD_07`, `GDD_08`, `GDD_10`, the feature index,
the project control plane, active guides, and the latest playtest/build docs touched
by v0.2.7/v0.3.0 work.

## Issues

### High - GDD map-data specs omit the implemented inline `unit_data` spawn seam

Location: `AGENT/GDD/GDD_06_Maps_Objectives.md:239`,
`AGENT/GDD/GDD_01_Architecture.md:1440`,
`AGENT/Docs/plans/project_control_plane_2026-06-29.md:102`,
`scripts/resources/MapData.gd:14`, `scripts/core/GameMap.gd:224`

The control plane says `B4-ENCOUNTER-MODEL` Slice 1 is implemented and that
`_spawn_units` accepts in-memory `unit_data`. The code and `MapData.gd` comment agree.
The live GDD map-data specs still describe enemy placements as only
`{unit_data_path, tile, ai_profile, is_boss, faction}`.

Root cause: behavior changed in the 2026-07-05 spawn-seam slice without updating the
GDD owner chapters in the same commit. That violates DoD#1.

Recommended fix: update `GDD_01` and `GDD_06` to document the exactly-one source rule:
`unit_data_path` XOR `unit_data: UnitData`, with optional placement-level `ai_profile`
override. Also update `Last verified` if the section header requires it.

### Medium - Active manual test playbook has stale Map 950 skill-cap setup

Location: `AGENT/Docs/guides/manual_test_playbook.md:330`,
`data/roster/test/map_950_promotion_validation/unit_12_hero_skill_cap.tres:47`

The playbook says `unit_12_hero_skill_cap` starts with four equipped skills and earns
Disarm at level 15. The live data now starts it with five equipped skills, matching
the v0.2.6 build manifest's "now at the skill cap" note. A tester following the
guide will expect the wrong setup.

Recommended fix: update the playbook to say the unit starts at the five-skill cap,
and keep overflow testing as a separate fixture requirement.

## Governance & Lifecycle Compliance

- Status/Last verified structural checks: PASS via `check_docs.py`.
- Prohibited status words: PASS via `check_docs.py`.
- Generated `INDEX.md` / `REGISTERS.md`: PASS before this report was added.
- Authority hygiene: no live doc was found linking a Historical/Superseded doc as
  current authority in the sampled areas.

## Coverage & Automation Gaps

- DoD#1 is still mostly human-reviewed. The spawn-seam miss shows that updating the
  control plane is not enough; behavior-changing commits can still skip the GDD owner
  chapters. A practical check would be hard, but a commit-template/hook warning for
  `scripts/resources/MapData.gd` or `scripts/core/GameMap.gd` changes without
  `AGENT/GDD/GDD_01_Architecture.md` / `GDD_06_Maps_Objectives.md` might catch this
  class.
- The manual test playbook has no data-backed drift guard. If it names specific
  fixtures and counts, those claims can rot.

## Positive Observations

- The control plane accurately recorded the implemented spawn seam even though the
  GDD owner chapters lagged.
- The display/logging guide has already corrected the `._sc_` exported-build mistake
  and points testers at `%APPDATA%`.
- Generated docs manifests remain green and make retrieval straightforward.

## Delta Vs Previous Review

Fixed from 2026-06-14: fort-heal drift, UID tracking, analyzer gating, and catalog
template exceptions. New: spawn-seam GDD drift and stale manual playbook fixture text.

## Prioritized Action Plan

1. Update `GDD_01` and `GDD_06` for inline enemy-placement data.
2. Update `manual_test_playbook.md` for Map 950's five-skill fixture.
3. Consider a lightweight DoD#1 warning for resource-schema/runtime-map changes.
