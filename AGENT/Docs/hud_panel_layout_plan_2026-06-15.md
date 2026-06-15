# HUD Panel Layout — Scale & Reposition (Display & Accessibility item 4) — Implementation Plan

**Status:** Planned (approved 2026-06-15; implementation deferred)
**Last verified:** 2026-06-15
**Authority:** GDD_10 §Near-Term Display & Accessibility (item 4); GDD_07 §Accessibility
**Builds on:** the shipped Display items 1–3 (`SettingsManager` `[display]` section,
`Window.content_scale_factor`) — see branch `display-accessibility-controls`.

## Context

Item 4 is the last and "broadest/least-defined" of the Display & Accessibility group:
let the player **scale and reposition individual HUD panels** (panel layout, distinct
from item 3's global UI scale). It was deferred from the items 1–3 pass on purpose.
Today the persistent HUD panels are authored at fixed offsets/anchors in
`scenes/ui/HUD.tscn` with no player control over placement or per-panel size.

### Decisions taken (2026-06-15)
- **Scope = persistent HUD readouts only:** `PhaseLabel`, `TurnLabel`, `UnitInfoPanel`,
  `ObjectivePanel`, `TerrainCorner`. The cursor-anchored contextual menus
  (Action/Item/Map/Weapon/AttackPreview) are **excluded** — they position
  dynamically and would break if freely moved.
- **Dedicated "Edit HUD Layout" mode** entered from Settings (no accidental drags in
  normal play).
- **v1 = reposition + per-panel scale** (composes on top of item 3's global
  `content_scale_factor`).

## Key findings from exploration

- The persistent panels are direct children of the **`HUD` Control** (full-rect,
  `anchors_preset 15`) in `scenes/ui/HUD.tscn`, scripted by `scripts/ui/HUD.gd`
  (`@onready` refs already exist for each panel). The HUD instance lives under
  `GameMap.tscn`'s **`HUDLayer` CanvasLayer**, alongside the transient menus.
- Panels are positioned by **offsets** (`UnitInfoPanel` bottom-left, `ObjectivePanel`
  top-left, `TerrainCorner` anchored bottom-right via `anchors_preset 3`). They are
  discrete, top-level nodes — ideal for per-panel transforms.
- **`SettingsManager` already has the `[display]` section + the stepped-control +
  reset patterns** (items 2–3) and persists a Dictionary (`keybindings`) through
  `ConfigFile`, so a `hud_layout` Dictionary (with `Vector2` offsets) persists with no
  new plumbing.
- Item 3's `content_scale_factor` scales the whole CanvasLayer; a per-panel
  `Control.scale` is local, so the two **compose multiplicatively** without conflict.

## Design

### Persistence (`SettingsManager`, `[display]` section)
- `var hud_layout: Dictionary = {}` — keyed by stable `panel_id` →
  `{ "offset": Vector2, "scale": float }`. Empty/missing entry = authored layout.
- load/save/reset entries; `reset_section_to_defaults("display")` clears `hud_layout`.
- Stable panel ids: `phase_label`, `turn_label`, `unit_info`, `objective`,
  `terrain_corner` (moving `TerrainCorner` moves its whole VBox stack — one unit).

### HUD application (`HUD.gd`)
- At `_ready`, **capture each panel's authored base position** into a dict (so offsets
  are deltas and Reset restores the base exactly).
- `apply_layout(layout: Dictionary)`: for each known panel, set
  `panel.position = base_pos[id] + layout[id].offset` and
  `panel.scale = Vector2.ONE * layout[id].scale`. Set `panel.pivot_offset` to a sensible
  corner so a scaled corner panel grows inward, not off-screen; clamp the final rect to
  the viewport so a panel can't be dragged fully off-screen.
- Called on HUD `setup()` reading `SettingsManager.hud_layout`, and live during editing.

### Edit mode (`HudLayoutEditor` overlay)
- A `HudLayoutEditor` Control (new) shown when the player opens **"Edit HUD Layout"**
  (a button on the in-map Settings screen; disabled from the main menu where no live
  HUD exists). It dims the map and draws a draggable frame around each registered
  panel plus a small per-panel scale control (+/- or a scale slider for the selected
  panel), with global **Reset** and **Done** buttons.
- Dragging a frame updates that panel's `offset` and calls `apply_layout` live;
  the scale control updates `scale` live. **Done** writes `hud_layout` to
  `SettingsManager` and saves; **Reset** restores the authored layout and clears the
  entries. Drag is handled via the frame's `_gui_input` (mouse) so it doesn't fight
  the map cursor (which is suppressed while the modal editor is open — reuse the
  `ModalScreen` / input-suppression pattern).

### Entry point
Add an **"Edit HUD Layout"** button to `SettingsScreen` (enabled only when a live HUD
is reachable, i.e. opened via Map Menu → Settings during a map). Main-menu Settings
shows it disabled with a hint, or hidden — minor wiring choice, default disabled.

## Tests (headless, glob-discovered)
- **`test_hud_layout.gd`** (new) or extend `test_hud.gd`: `apply_layout` offsets a
  panel from its base and sets its scale; an empty/partial layout leaves unlisted
  panels at base; Reset restores base position + scale exactly; an unknown `panel_id`
  is ignored; an off-screen offset is clamped back into the viewport.
- **Extend `test_settings_manager.gd`**: `hud_layout` (a `Dictionary` of `Vector2`
  offsets + float scales) round-trips through save/load; `reset_section_to_defaults
  ("display")` clears it; a malformed entry on load is tolerated (skipped, defaulted).
- The drag/scale **editor interaction** is mouse-driven and, like
  `AttackPreview` positioning, is **verified by playtest** rather than headless — the
  pure `apply_layout` + serialization are the unit-tested seams.

## Documentation (DoD#1)
- GDD_07 §Accessibility: per-panel HUD layout (item 4) — Implemented (reposition +
  scale); note it composes with item 3's global `content_scale_factor`.
- GDD_10 §Near-Term: flip item 4 from Deferred → Implemented. Bump `Last verified`.
- DoD#2: likely no new mechanical rule; note explicitly. (If desired, a check that
  every registered `panel_id` exists in `HUD.tscn` could guard against drift.)

## Out of scope
- Repositioning/scaling the contextual menus (Action/Item/Map/Weapon/AttackPreview).
- Multiple saved layout profiles / per-resolution layouts.
- Gamepad-driven editing (rides with the key-rebind/gamepad milestone).
- Snapping/grid alignment (free-drag in v1; could add later).

## Verification
- Headless `bash run_tests.sh` green incl. the layout apply/serialize tests;
  `python3 AGENT/Docs/check_docs.py` 12/12.
- Live: Map Menu → Settings → Edit HUD Layout → drag `UnitInfoPanel` and scale
  `TerrainCorner` → Done; the new placement persists across a map reload and a restart
  (inspect `user://settings.cfg` `[display] hud_layout`); Reset restores the authored
  layout; confirm per-panel scale composes correctly with a non-1 global UI scale
  (item 3); confirm a panel can't be dragged fully off-screen.
