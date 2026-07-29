# GDD_07 — UI & UX

**Status:** Active cross-cutting UI/UX contract; input/cursor and screen/panel detail
are split into the companion GDD_07 contracts linked below.
**Last verified:** 2026-07-15
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This entry chapter owns UI principles, navigation/state relationships, feedback,
accessibility, and parity obligations. Input/cursor mechanics and individual surface
contracts live in the companions below. Platform and renderer targets remain in
`GDD_00 §Platform Targets` (`OPEN-8`, `OPEN-11`); settings persistence schema is code-owned by
`SettingsManager` and cross-system save ownership lives in `GDD_01`.

---

## Companion Contracts

- [Input And Cursor](GDD_07_Input_Cursor.md) — action bindings, active input mode,
  mouse/touch/gamepad behavior, repeat policy, tactical cursor, and threat display.
- [Screens And Panels](GDD_07_Screens_Panels.md) — menu, HUD, modal, settings, and
  result-surface contracts.

---

## Design Reference

Status: **Reference** (design principles)
Last verified: 2026-06-13

The UI is inspired by **Fire Emblem: The Blazing Blade (GBA)**. Key principles:

- Clean, minimal overlays that do not block map visibility unnecessarily
- All important numbers are always visible before the player commits to an action
- Panels appear and disappear quickly; no slow animations on menus
- Keyboard-primary input with full mouse support

---

## UI State Machine

Status: **Implemented**
Last verified: 2026-06-13

The HUD operates as a state machine. Only one primary panel is active at a time.
`MapCursor` manages state and shows/hides panels by calling methods on `HUD`.

```
HUD States:
  FREE          — UnitInfoPanel + TerrainInfoPanel + ObjectivePanel visible
  UNIT_SELECTED — same as FREE (movement overlay active)
  ACTION_MENU   — contextual ActionMenu visible
  TARGETING     — target cycling active; AttackPreview may be visible
  STAFF_TARGET  — target cycling active for healing staff use
  ITEM_MENU     — ItemMenu visible
  WEAPON_MENU   — WeaponMenu visible
  MAP_MENU      — MapMenu visible (pauses cursor)
  DETAILS       — UnitDetailsScreen visible
  LEVEL_UP      — LevelUpScreen visible (cursor locked)
  PROMOTION     — PromotionScreen visible
  RECLASS       — ReclassScreen visible
  RESULTS       — MapResultsScreen for victory; GameOverScreen for defeat
  LOCKED        — cursor input suspended during animation or controller handoff
```

---

## Visual Feedback Summary

Status: **Split** — state/HP/level-up feedback **Implemented**; combat hit/miss/crit/death FX **Planned** (with the combat-animation system)
Last verified: 2026-06-13

| Event | Visual Feedback |
|---|---|
| Unit selected | Blue movement tiles appear; a dedicated selection ring is planned |
| Unit moved | Blue/red tiles update for new position |
| Unit acted (DONE) | Unit sprite darkened/greyed |
| New player phase | All unit sprites return to normal color |
| Attack hits | [PLACEHOLDER] brief flash on target sprite |
| Attack misses | [PLACEHOLDER] "Miss" text above target |
| Critical hit | [PLACEHOLDER] brighter flash; different sound |
| Unit dies | [PLACEHOLDER] death animation; unit fades out |
| Unit healed | [PLACEHOLDER] green flash; HP bar updates |
| Level up | Gold flash on unit sprite; LevelUpScreen shown |
| Weapon breaks | [PLACEHOLDER] weapon removed from inventory notification |

---

## Accessibility & Input Parity

Status: **Split** — input parity, rebinds, pacing, menu scaling, HUD layout, display
controls, and safe-area seams are **Implemented**; combat-animation feedback remains
**Planned**
Last verified: 2026-07-13

The UI must expose the same gameplay capabilities across keyboard/mouse, gamepad,
touch-facing interaction, and non-blue hotseat controllers. Device-specific mechanics
and the fixed mode vocabularies are binding in
[GDD_07 — Input And Cursor](GDD_07_Input_Cursor.md); individual settings and
inspection surfaces are binding in
[GDD_07 — Screens And Panels](GDD_07_Screens_Panels.md).

Cross-cutting obligations:

- All information needed to commit combat is visible through forecast, unit details,
  terrain information, and More Info; no input method gets exclusive gameplay data.
- Movement speed, phase-banner pacing, level-up presentation, menu scale, HUD layout,
  terrain dim (`MRD-5`), display mode/resolution, and map zoom remain independently
  configurable where their owning surface says they are implemented.
- Menu/modal scaling renders fonts and layout metrics at the selected size and clamps
  content to the usable viewport. Persistent HUD panels retain their authored
  per-panel layout/scale model until the structural `UI-VIEWPORT-ASPECT` migration.
- HUD edge clamping reads the shared safe-area provider. Desktop and browser currently
  resolve zero in-canvas insets; a future mobile feed attaches without changing panel
  call sites.
- Display configuration follows `GDD_00` and the display/settings guide. Tactical
  camera zoom follows `GDD_06 §Tactical Camera`; this chapter owns only the settings
  and prompt surfaces.
- Documentation vocabulary guards (`DOC-011`) read the two companion contracts:
  input modes/bindings from Input And Cursor and character-sheet duration labels from
  Screens And Panels.
- `OPEN-11` remains owned by `GDD_00 §Platform Targets`. The hidden
  `combat_animations` setting remains planned until a combat-animation system consumes
  it.

Code anchors: `scripts/autoloads/SettingsManager.gd`,
`scripts/autoloads/InputModeManager.gd`, `scripts/core/MapCursor.gd`, and
`scripts/core/HotseatController.gd`. Validation anchors:
`scripts/tests/test_settings_manager.gd`, `test_settings_screen.gd`,
`test_input_mode_manager.gd`, and the relevant UI scene tests.

---
