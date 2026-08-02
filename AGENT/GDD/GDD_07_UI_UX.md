# GDD_07 — UI & UX

**Status:** Active cross-cutting UI/UX contract; input/cursor and screen/panel detail
are split into the companion GDD_07 contracts linked below.
**Last verified:** 2026-08-02
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
controls, safe-area seams, and the viewport **expand** model + `content_scale_factor`
UI-scale setting are **Implemented** (the expand/anchoring migration is Pending owner visual
validation — see the display/scaling obligation below); combat-animation feedback remains
**Planned**
Last verified: 2026-08-01

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
  content to the usable viewport. The structural `UI-VIEWPORT-ASPECT` migration has landed
  (`IMPL-VIEWPORT-ANCHORING`, Implemented 2026-08-01, Pending owner visual validation): the
  renderer runs the **expand** model (`content_scale_aspect=EXPAND`, `content_scale_size=(0,0)`)
  with a persisted `content_scale_factor` UI-scale setting whose first-launch default lands on
  the identity diagonal so existing players see no change. The player adjusts it through the
  **Viewport Scale** slider in Settings › Display (a lower factor reveals more map tiles). Menu
  scale is now reconciled with —
  not stacked on — the global factor, and menu/HUD centring is anchor-based (the imperative
  `MenuScale._recenter()` path is retired).
- Centered temporary windows use safe-centered frames capped at 90% of the usable
  viewport. Existing preferred sizes remain preferences; bounded scroll owners keep
  content reachable when menu scale, viewport scale, or padding leaves less room.
  Legacy top-left-authored frames are normalized to the same center-anchor contract.
- HUD custom layouts persist as versioned panel-to-safe-viewport attachment pairs.
  Both endpoints use the eight corners/edge midpoints, retain a logical-pixel offset
  and independent scale, reflow after viewport/content changes, and clamp the full
  scaled panel inside the safe rectangle. The editor exposes both attachments and an
  explicit nearest-pair action; dragging changes only the offset.
- **Display/scaling design floor:** the minimum supported reference viewport is **1280×720**
  (desktop/web). Every screen, panel, and beat must be playable at the fewest tiles this
  reference shows; a bigger display revealing more tiles is a comfort bonus that can never
  break a mechanic. The worst-case mobile-portrait floor stays deferred until mobile is a live
  platform. Rationale and the measured tile counts:
  [`viewport_expand_more_tiles_scoping_2026-07-11.md`](../Docs/design/viewport_expand_more_tiles_scoping_2026-07-11.md)
  §0.1.
- HUD edge clamping reads the shared safe-area provider. Desktop and browser currently
  resolve zero in-canvas insets; a future mobile feed attaches without changing panel
  call sites.
- At the accessibility stress case (1280×800, 2× content scale, 2× menu scale), New
  Game owns an outer vertical scroll region, Unit Details stacks its content and
  information regions, and Results collapses its report/actions flow vertically. The
  containing frame remains centered and inside 90% of the safe viewport; content
  scrolls before the selected type scale is reduced.
- Local Web UI inspection uses the production Web export plus an explicitly opted-in,
  read-only state bridge (`test_bridge=1`). Playwright still sends real pointer and
  keyboard input through the canvas; the bridge only reports the active screen, focus,
  post-transform control rectangles, scale settings, and text-entry state. Ordinary Web
  URLs expose no bridge. This is deterministic layout evidence, not a substitute for the
  native Windows/GPU visual pass.
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
