# GDD_07 — UI & UX

**Status:** Active cross-cutting UI/UX contract; input/cursor and screen/panel detail
are split into the companion GDD_07 contracts linked below.
**Last verified:** 2026-08-06
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
Last verified: 2026-08-04

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
  the identity diagonal so existing players see no change. **A mobile browser defaults
  differently, and deliberately:** the identity diagonal is derived from the screen and
  calibrated for a desktop monitor at desk distance, which on a phone canvas selects the
  smallest factor available. There the default is instead the largest 0.5 step that still
  fits the 1280×720 design floor inside the actual canvas, snapped **down** so rounding
  can never push the viewport below the floor and clip authored layouts. The player
  adjusts it through the
  **Viewport Scale** slider in Settings › Display (a lower factor reveals more map tiles). Menu
  scale is now reconciled with —
  not stacked on — the global factor, and menu/HUD centring is anchor-based (the imperative
  `MenuScale._recenter()` path is retired).
  **Stale against the new floor (noted 2026-08-06):** the 1280×720 here is the *retired*
  floor, hard-coded as `1280.0 / 720.0` in `fit_content_scale_factor_for_size`. On a
  1179×2556 phone it snaps to **0.5**, giving a 2358×5112 logical viewport and body type
  at 2.7 CSS px — the measured portrait defect. Against the ratified 360×640 floor the same
  phone resolves to **3.0** and 393×852, which is Compact at 16 CSS px. It is deliberately
  **not** flipped yet: doing so before the screen conversions would make portrait large and
  broken instead of small and unclipped. Sequenced in `responsive_ui_programme_2026-08-06.md`.
- Centered temporary windows use safe-centered frames capped at 90% of the usable
  viewport. The cap is a ceiling, never a target: a window occupies its authored size
  when that fits, and only the excess is trimmed. A scene may state that size either as
  a `custom_minimum_size` or as an anchor span plus offsets — both are read as the
  preference, and a window with neither sizes to its content. Bounded scroll owners keep
  content reachable when menu scale, viewport scale, or padding leaves less room.
  Legacy top-left-authored frames are normalized to the same center-anchor contract.
- HUD custom layouts persist as versioned panel-to-safe-viewport attachment pairs.
  Both endpoints use the eight corners/edge midpoints, retain a logical-pixel offset
  and independent scale, reflow after viewport/content changes, and clamp the full
  scaled panel inside the safe rectangle. The editor exposes both attachments and an
  explicit nearest-pair action; dragging changes only the offset.
- **Display/scaling design floor:** **Superseded 2026-08-06** by the responsive redesign
  (owner decision). The floor was **1280×720** (desktop/web) with the mobile-portrait case
  deferred; it is now **360×640**, and mobile is no longer deferred. The obligation is
  unchanged in kind — every screen, panel, and beat must be playable at the fewest tiles the
  floor shows, and a bigger display revealing more is a comfort bonus that can never break a
  mechanic — but it now binds at the smaller size. Prior rationale and measured tile counts:
  [`viewport_expand_more_tiles_scoping_2026-07-11.md`](../Docs/design/viewport_expand_more_tiles_scoping_2026-07-11.md)
  §0.1. Replacement:
  [`responsive_ui_redesign_2026-08-06.md`](../Docs/design/responsive_ui_redesign_2026-08-06.md).
- **Size class:** **Implemented 2026-08-06, Pending native validation.** Screens respond to a
  class derived from the logical viewport — `backing size ÷ content_scale_factor`, which the
  player owns — rather than being authored at one size and centred in whatever they are given.
  **Compact** below 600 logical px, **Medium** 600–1023, **Expanded** 1024 and above; today's
  1280×720 layouts survive as the largest class. `ResponsiveLayout` (autoload) publishes
  `size_class_changed` and carries the two density token sets that Menu Mode selects between —
  touch and controller are different densities because density follows the input device, not a
  look-and-feel preference — plus the information-density token (Full / Standard / Minimal).
  **The class is live, not read once at startup:** the player can drag the window to an
  arbitrary size and can change Viewport Scale from the Settings screen while looking at it, so
  a screen can change class while open. Recomputation is debounced so a live window drag
  republishes once when it settles rather than once per frame, boundaries carry a 24 logical-px
  hysteresis so a window parked on one cannot oscillate, and the signal is emitted only on a
  real change — a screen that receives nothing cannot lose the player's selection, scroll
  position, or open More Info target. Unit Details now stacks its two panes below Expanded,
  replacing the hard-coded 900 px threshold that was the ad-hoc size class this generalises;
  that moves the 900–1023 band from side-by-side to stacked, which is the direction that cannot
  overflow the panel. Screens convert one per branch afterwards.
- HUD edge clamping reads the shared safe-area provider. Desktop resolves zero
  in-canvas insets. **A mobile browser now feeds real ones**: the PWA shell publishes
  `env(safe-area-inset-*)` in CSS pixels together with the canvas rectangle, and the
  provider converts both to viewport units before any panel sees them — window pixels
  per CSS pixel is measured from that rectangle rather than taken from
  `devicePixelRatio`, and the result is divided by `content_scale_factor` because
  consumers subtract insets from the post-scale viewport. Degenerate readings (a
  pre-layout canvas, a zero window, a non-numeric inset) resolve to zero rather than a
  guess. No panel call site changed, as this seam promised.
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
- `OPEN-11`'s delivered expand policy and remaining native validation are owned by
  `GDD_00 §Platform Targets`. The hidden
  `combat_animations` setting remains planned until a combat-animation system consumes
  it.

Code anchors: `scripts/autoloads/SettingsManager.gd`,
`scripts/autoloads/InputModeManager.gd`, `scripts/core/MapCursor.gd`, and
`scripts/core/HotseatController.gd`. Validation anchors:
`scripts/tests/test_settings_manager.gd`, `test_settings_screen.gd`,
`test_input_mode_manager.gd`, and the relevant UI scene tests.

---
