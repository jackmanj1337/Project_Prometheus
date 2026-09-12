---
Role: dated
---

# Pillar 3 - Scenes, Data & Assets Review (2026-07-05)

> **Pillar:** 3 - Scenes, Data & Assets
> **Procedure:** `AGENT/Review Procedures/03_Scenes_Data_Assets_Pillar.md`
> **Snapshot:** branch `v0.3.0-features`, commit `914dd025ea8fbd898e5dbbc7c8ed7a6441cbf4dc`
> **Previous review:** `AGENT/Code Reviews/data_assets_review_2026-06-14.md`

**Score:** 9/10

## Executive Summary

The content tree is in good shape. UID/import drift from the prior audit is gone,
scene integrity passes, resource manifests match their directories, and no broken
scene/resource paths were found. The only data-side issue found is a stale registry
description for Map 950's test roster.

## Spot-Check / Sample

- Ran `python3 scripts/ci/check_scene_integrity.py`: 17 scene-attached scripts checked.
- Checked all tracked `.gd.uid` sidecars: 114 tracked, no missing/orphan sidecars.
- Checked image imports under `assets/` and archived evidence: no missing or orphan
  `.import` files.
- Scanned `.tscn` / `.tres` `res://` paths: no missing referenced files.
- Checked every `data/**/resource_manifest.json` against sibling `.tres` files:
  no missing or extra entries.

## Issues

### Low - Map 950 registry description still says the fixed roster has 10 units

Location: `data/maps/map_registry.json:38`,
`data/roster/test/map_950_promotion_validation/resource_manifest.json:1`

The Map 950 registry description says "10 units", but the fixed roster manifest has
12 entries, including `unit_11_lvl19_mercenary.tres` and
`unit_12_hero_skill_cap.tres`. This is player/tester-facing metadata in the map
selector, so it can mislead manual validation even though runtime loading is fine.

Recommended fix: update the registry description to say 12 units or avoid a hardcoded
count.

## Positive Observations

- The 2026-06-14 `.uid` tracking issue is fully fixed.
- The new darker-red overlay asset is committed with its import file and referenced
  by `assets/overlay_tileset.tres`.
- Resource manifests now provide a clear load-order surface and match their folders.

## Delta Vs Previous Review

Fixed: untracked UID sidecars, scene-integrity gate, analyzer gate, and the empty-dir
scope issue. New: one low data-description drift. No broken resources found.

## Prioritized Action Plan

1. Fix Map 950's stale description.
2. Keep `check_scene_integrity.py` and manifest checks in CI; they are paying off.
