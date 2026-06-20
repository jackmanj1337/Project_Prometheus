# Mouse-Only / Touch Cursor Mode — Design (V021-17) — 2026-06-19

Status: Implemented
Last verified: 2026-06-20

## Problem (tester, v0.2.1)

Tester request: a mouse-only mode (also useful for touchscreen) where the map cursor does
**not** follow mouse hover. Instead, the cursor **jumps to the clicked tile** on a first
click, and a **second click that does not move the cursor** actually selects the tile/unit.
In this mode the terrain panel needs a **next-page button** (or the whole panel switches
when any part of it is clicked) since there is no hover-scroll.

## Original implementation seam (what this built on)

- Before V021-17, `SettingsManager.mouse_cursor` drove `"enabled"` (mouse motion moves the
  cursor) vs `"disabled"` (mouse motion ignored), with an older `mouse_targeting="snap"`
  value still migrated on load.
- V021-17 kept the same seams and expanded them to `follow|click|disabled`:
  - `scripts/autoloads/SettingsManager.gd` owns `VALID_MOUSE_CURSOR_MODES` and legacy
    normalization (`enabled→follow`, `snap→click`).
  - `scripts/core/MapCursor.gd` keeps `_handle_mouse_motion()` / `_handle_mouse_button()`
    as the only mouse cursor behavior entry points.
- So we already have the seams: a settings value, a motion handler, and a click handler.

## Design

### Setting: re-introduce a third `mouse_cursor` value

`mouse_cursor ∈ { "follow", "click", "disabled" }`:

- **`follow`** (was `"enabled"`) — current behavior: cursor tracks hover; click selects.
- **`click`** (new) — **mouse-only mode**: hover does nothing; first click moves the
  cursor to that tile (no select); a second click on the **same** tile (cursor already
  there) performs select/confirm. Touch-friendly.
- **`disabled`** — mouse never moves the cursor (keyboard/gamepad only).

Migration: keep the existing loader's legacy remap; map old `"enabled"` → `"follow"` and
the historical `"snap"` → `"click"` (snap ≈ click-to-move). The Settings dropdown
(`SettingsScreen` `mouse_cursor` option, line 86) gains the third labelled choice
(e.g. "Follow / Click / Off"). DoD#1: update GDD_07 §Input; if we ratify the value set as
a fixed vocabulary, add a `check_docs`/test assertion (DoD#2).

### MapCursor behavior in `click` mode

```
on mouse motion:               # _handle_mouse_motion
    if mode == "click": return # hover is inert

on mouse button (left, pressed):   # _handle_mouse_button
    tile = tile_under_pointer()
    if mode == "click":
        if cursor.tile != tile:
            move_cursor_to(tile)   # first click: relocate, do NOT select
        else:
            confirm_select()       # second click on same tile: select/confirm
    else:
        ... existing follow/select path ...
```

Notes:
- "A second click that does not move the cursor" is naturally expressed as "click on the
  tile the cursor already occupies." No timing/double-click needed — it is positional.
- Right-click / cancel keeps its existing meaning (back/deselect) in all modes.
- Edge-scroll on mouse moves stays skipped (the code already skips edge-scroll for
  mouse-driven moves; relevant for `click`'s relocate step).
- Keyboard/gamepad cursor movement is unaffected in every mode.

### Terrain panel interaction (couples with V021-05 paging)

In `click` mode there is no hover-scroll, so add an explicit page control to the terrain
panel, reusing the paging API from the V021-05 design (`_cycle_terrain_more()`):

- Primary: **clicking anywhere on the terrain panel calls `_cycle_terrain_more()`**
  (Hidden → Page 0 → Page 1 → Hidden), the tester's "entire panel switches when clicked."
- Optional: a small **`▸` next-page button** in the panel corner for discoverability,
  bound to the same call. Recommend shipping the click-anywhere behavior and adding the
  button only if playtest finds it undiscoverable.
- This control is only wired/visible when `mouse_cursor == "click"` (or always present but
  inert otherwise) — keep it from interfering with `follow`/keyboard play.

### Touchscreen note

`click` mode is the touch story: a tap is a click. The same first-tap-moves /
second-tap-selects flow works for touch, and the terrain page-on-tap gives a no-hover way
to read movement costs. Full touch input (`InputEventScreenTouch`) mapping is out of scope
here but `click` mode is designed to be the foundation it maps onto.

## Integration checklist

- [x] `SettingsManager.mouse_cursor` accepts `follow|click|disabled`; loader migrates
      legacy `enabled→follow`, `snap→click`.
- [x] `SettingsScreen` mouse-cursor dropdown gains the third option + label.
- [x] `MapCursor._handle_mouse_motion` inert in `click` mode.
- [x] `MapCursor._handle_mouse_button` implements relocate-then-select in `click` mode.
- [x] Terrain panel click cycles pages in `click` mode (reuses V021-05 `_cycle_terrain_more`).
- [x] Tests: `test_map_cursor.gd` — click mode relocates on first click, selects on
      second same-tile click, ignores motion; `test_settings_manager.gd` migration.
- [x] GDD_07 §Input/Accessibility updated in the same commit (DoD#1).

Implementation note (2026-06-20): terrain click paging is routed through `MapCursor` while
HUD panels keep `MOUSE_FILTER_IGNORE`, preserving the existing "HUD doesn't eat map clicks"
contract from `test_game_map_scene`.

## Open questions

1. Value names: `follow` / `click` / `disabled` vs keep `enabled` and add `click`?
   (Lean: rename to `follow` for symmetry, with back-compat load mapping.)
2. Terrain panel: ship click-anywhere only, or also the `▸` button? (Lean: click-anywhere
   first.)
3. Should `click` mode also drive the "cancel-over-unit opens sheet" request (V021-16),
   or is that mode-independent? (Lean: V021-16 is mode-independent; keep separate.)
