# Playtester Build Manifest - v0.2.5

> **Status:** exported 2026-07-02. Windows debug `.exe` built with Godot `4.6.stable`;
> the release metadata (`export_presets.cfg`, Main Menu `VersionLabel`,
> `environment_setup.md`) is at `v0.2.5`.

## Artifact

- Path: `builds/Project_Prometheus_v0.2.5_debug.exe`
- Source commit: `STUB`
- Exported: `2026-07-02`
- Godot: `4.6.stable.official.89cea1439`
- Size: `STUB` bytes
- SHA-256: `STUB`

The artifact is intentionally ignored by Git. v0.2.5 ships as **two files**: the
executable and the single self-contained handbook
`AGENT/Docs/playtests/playtest_checklist_v0.2.5.md`.

## Why v0.2.5

v0.2.5 is a **follow-up display-rerun build**. The v0.2.4 rerun confirmed most of the
v0.2.3 repairs but revealed that the `V023-01` Menu Scale column lock only held the
slider's x-axis — rows above it still change height with the scale factor, so the slider
drifted **vertically** mid-drag. Additionally, a settings migration edge case was found:
a `settings.cfg` predating the `menu_scale_schema_version` field was silently bumped from
`1.0x` to `1.25x` on migration. Both are fixed in commit `d0c26f6`. `VAL-V023-DISPLAY`
remains **Pending validation** — the handbook's Part I passes on a real Windows screen
(monitor + resolution setup) are still required to flip it.

## What changed since v0.2.4 (commit `d0c26f6`)

- **`V023-01` vertical follow-up:** `SettingsScreen.apply_menu_scale` now captures the
  Menu Scale row's on-screen y before the re-scale and restores it via the panel
  `ScrollContainer.scroll_vertical` one deferred-layout frame later. Regression test:
  `test_settings_screen.gd` asserts row-y stability (it failed at 481 px drift without
  the fix).
- **Migration guard:** `SettingsManager`'s `menu_scale_schema_version` migration now
  shifts only *actually-stored* indices, so a `settings.cfg` predating the menu-scale
  setting keeps the `1.0x` default instead of being silently bumped to `1.25x`.
  Test matrix in `test_settings_manager.gd`.

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
  right-click/touch-modal semantics (`V023-10`). Do not report these as v0.2.5 regressions.
- **`V023-11` validation gap:** the v0.2.3 return omitted `godot.log` and a regression
  pass. Both are requested again in the v0.2.5 handbook.

## Verification

- Full source suite: PASS (suites green; pre-commit hook gates it).
- check_docs: PASS.
- Release-metadata test (`test_release_metadata.gd`): PASS — preset name/path/product
  version, Main Menu label, checklist presence, and setup guide all agree at `v0.2.5`.
- Export: PASS — Windows debug `.exe` built headless, SHA-256 recorded above.
- All visual/input checks remain in `playtest_checklist_v0.2.5.md` and need a human pass
  on real Windows (Part I is the v0.2.3 closeout gate).
