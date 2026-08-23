---
Role: dated
---

# Playtester Build Manifest - v0.2.4

> **Status:** exported 2026-07-01. Windows debug `.exe` built with Godot `4.6.stable`;
> the release metadata (`export_presets.cfg`, Main Menu `VersionLabel`,
> `environment_setup.md`) is at `v0.2.4`.

## Artifact

- Path: `builds/Project_Prometheus_v0.2.4_debug.exe`
- Source commit: `3741999`
- Exported: `2026-07-01`
- Godot: `4.6.stable.official.89cea1439`
- Size: `101268928` bytes
- SHA-256: `45ed14f1526497e0e10106b5a2a67ab74031e87139d631337fd80506b376a156`

The artifact is intentionally ignored by Git. v0.2.4 ships as **two files**: the
executable and the single self-contained handbook
`AGENT/Docs/playtests/playtest_checklist_v0.2.4.md`.

## Why v0.2.4

v0.2.4 is the **display-gate rerun build**. The v0.2.3 playtest returned with Part I
(display & crisp scaling) failing or unclear on several surfaces. Those were triaged in
`playtest_v0.2.3_results_triage_plan_2026-07-01.md` as `V023-01..11`, and the immediate
repair set (`V023-01..06`, `V023-08a`, `V023-09a`) was implemented in commit `fd0f5f4`.
This build exists to **re-validate those repaired surfaces on a real screen** so
`VAL-V023-DISPLAY` can flip. It carries no new features over v0.2.3 — same v0.2.2 +
v0.2.3 content, plus the repairs.

## What changed since v0.2.3 (the repair pass, commit `fd0f5f4`)

- **`V023-01`** Settings Menu Scale: added a **`0.5x`** level, locked the Settings slider
  column so it no longer drifts during a live scale change, and added a
  `menu_scale_schema_version` migration so previously-saved `1.0x` settings stay `1.0x`.
- **`V023-02a`** Character sheet: converted to a fixed centered **scroll frame**; Menu
  Scale re-applies after the sheet is populated and after paired-unit swaps.
- **`V023-03`** Contextual menus (Action / Item / Weapon): now remember their tile anchor
  and **re-anchor after map zoom** and Settings Map Zoom changes.
- **`V023-04`** AttackPreview: weapon rows included in the measured row-height pass, panel
  grown (`170→230` high, info column `260→300`), neutral weapon-triangle / effectiveness
  now render a visible gray **`■ Neutral`** marker instead of a blank cycle-only row, and
  the More Info description area has a larger bounded region.
- **`V023-05`** Level-Up: wheel/zoom and other non-dismissal input is **consumed** while
  the popup is visible; only confirm/cancel/left/right-click advance it (fixes the
  scroll-wheel-dismiss bug — Godot wheel events are mouse buttons).
- **`V023-06`** Windowed resolutions clamp to a 16:9 client area inside the usable display
  rect so the OS title bar stays reachable; Borderless and Fullscreen remain distinct
  `DisplayServer` modes.
- **`V023-08a`** Archer class copy: bow range is now described as weapon-driven.
- **`V023-09a`** Terrain More Info click paging: clicks anywhere inside the compact or
  expanded panel cycle pages, including the Movement page.

## Known limitations carried into this build

- **This build IS the validation vehicle.** `VAL-V023-DISPLAY` is still
  **Pending validation** — every repair above is inherently visual and was only
  headless-tested. It flips `[x]` / Verified only after the handbook's Part I passes on a
  real Windows screen (ideally including a 1440p/4K monitor).
- **`V023-04` weapon-row root cause was worked around, not confirmed.** The original
  report (weapon names missing despite a matching source/build hash) was treated as a
  panel-sizing/row-clipping problem and fixed by growing the panel and including weapon
  rows in the height pass. If names are *still* missing in this build, that points at a
  different cause (export scene cache, render/colour) — flag it explicitly, this is the
  highest-risk check.
- **Deferred v0.2.3 items are NOT in this build:** character-sheet page layout
  (`V023-02b`), HUD editor expanded-terrain frame (`V023-07`), full unit-trait aggregation
  (`V023-08b`), full tile action/requirement descriptors (`V023-09b`), and Map Menu
  right-click/touch-modal semantics (`V023-10`). Do not report these as v0.2.4 regressions.
- **`V023-11` validation gap:** the v0.2.3 return omitted `godot.log` and a regression
  pass. Both are requested again in the v0.2.4 handbook.

## Verification

- Full source suite: PASS (48 suites green; pre-commit hook gates it).
- check_docs: PASS (21/21).
- Release-metadata test (`test_release_metadata.gd`): PASS — preset name/path/product
  version, Main Menu label, checklist presence, and setup guide all agree at `v0.2.4`.
- Export: PASS — Windows debug `.exe` built headless, SHA-256 recorded above.
- All visual/input checks remain in `playtest_checklist_v0.2.4.md` and need a human pass
  on real Windows (Part I is the v0.2.3 closeout gate).
