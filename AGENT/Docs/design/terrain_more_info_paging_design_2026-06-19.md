# Terrain More Info Paging — Design (V021-05) — 2026-06-19

Status: Implemented (v0.2.2, 2026-06-20) — built as logical pages (visibility groupings
of the existing expanded rows) rather than new container nodes; same Hidden→Description→
Movement→Hidden contract. See GDD_07 §HUD Layout and `HUD.cycle_terrain_more_page`.
Last verified: 2026-06-20

## Problem (tester, v0.2.1)

The terrain More Info panel stacks the description, the per-movement-type move costs, and
the terrain actions in one scrolling box. It is "very hard to scroll the more info page
without moving the cursor of that tile" (the cursor keys both scroll the panel and move
the map cursor), and the tall panel eats viewable map area. Tester ask: split the content
onto **pages** flipped with the More Info key (`F`), keep one page **fully hidden** to
free map area, allow **more pages** later, and integrate cleanly with existing systems.

## Current implementation (what we build on)

- `scripts/ui/HUD.gd` owns the terrain panel under a movable `TerrainCorner`:
  - Compact readout: `TerrainInfoPanel/VBox/{TerrainName, TerrainCoord, TerrainDef,
    TerrainDodge, TerrainHint}` — the always-on at-a-glance view.
  - Expanded readout: `TerrainMoreInfoPanel/Scroll/VBox/{TerrainDescription,
    TerrainMoveCosts, TerrainActions}` (RichTextLabels), shown when `_terrain_expanded`.
- `_terrain_expanded` is toggled by the `more_info` action (`F`) when no higher-priority
  More Info panel is open. Priority cycle (from HUD header): combat forecast → character
  sheet → terrain HUD.
- The expanded panel renders *above* the compact panel inside the same movable corner;
  `_terrain_expanded_offset()` positions it. This offset is the reflow that V020-06 /
  V021-02 keep getting wrong on HUD-layout reset.
- Move costs come from `GridManager.get_move_costs_for_groups(terrain)` →
  `{foot, mounted, armoured, light}` (gains a `flying` column under V021-11).

## Design

### Page model

Replace the single expanded scroll body with an ordered list of **pages**, each a
container under the existing `TerrainMoreInfoPanel`. Initial pages:

- **Page 0 — Description**: `TerrainDescription` (terrain blurb) + `TerrainActions`
  (seize/heal/etc. notes). Prose lives here.
- **Page 1 — Movement**: `TerrainMoveCosts` table, one row per movement type
  (Foot/Infantry, Mounted, Armoured, Light, Flying), defence/dodge restated for context.

`F` behavior becomes a 3-state cycle on the terrain surface (when terrain is the active
More Info owner): **Hidden → Page 0 → Page 1 → Hidden → …**. "Hidden" is a real state
(not just collapsed height): the whole `TerrainMoreInfoPanel` is `visible = false`, so the
map area behind it is fully reclaimed — this is the tester's "one page completely invisible
to increase viewable map area." The compact `TerrainInfoPanel` stays visible throughout.

State is a small enum/int on HUD, e.g. `_terrain_more_page: int` where `-1` = hidden,
`0..N-1` = page index. Replaces the boolean `_terrain_expanded` (which becomes
`_terrain_more_page >= 0`). Extensibility: adding a page = appending a page container and
its builder; the cycle length derives from the page count, so "more pages can be added."

### Pages array + builder

```gdscript
# Ordered page containers under TerrainMoreInfoPanel; index = page number.
@onready var _terrain_pages: Array[Control] = [
    $TerrainCorner/TerrainMoreInfoPanel/DescriptionPage,
    $TerrainCorner/TerrainMoreInfoPanel/MovementPage,
]
var _terrain_more_page: int = -1   # -1 hidden; else active page index

func _cycle_terrain_more() -> void:
    _terrain_more_page += 1
    if _terrain_more_page >= _terrain_pages.size():
        _terrain_more_page = -1
    _apply_terrain_more_page()

func _apply_terrain_more_page() -> void:
    var showing := _terrain_more_page >= 0
    _terrain_more_panel.visible = showing
    for i in _terrain_pages.size():
        _terrain_pages[i].visible = showing and i == _terrain_more_page
    _reflow_terrain_more()   # the V021-02 reflow, page-size aware
```

### Scroll vs. cursor-move conflict

Splitting into short, single-screen pages is the primary fix: each page is sized to fit
without scrolling, so the player flips pages with `F` instead of scrolling with the cursor
keys — which removes the "scrolling also moves the map cursor" conflict the tester hit. If
a page can still overflow (long description at large Menu Scale), keep a `ScrollContainer`
on that page only, but the default expectation is no scroll. (The directional-selector
work in **V021-15** later gives terrain its own focusable selector; once that lands, arrow
keys can move within the panel without touching the map cursor — paging and the selector
are complementary, not redundant.)

### Reflow / layout-editor interaction (couples with V021-02, V021-07)

- The page swap changes the expanded panel's height, so `_terrain_expanded_offset()` /
  `_reflow_terrain_more()` must recompute from the *active page's* size, not a fixed
  expanded height. Fixing it here also hardens the V020-06/V021-02 reset bug because the
  offset is derived, not cached.
- The "Hidden" state reclaiming map area is what lets V021-07 raise the default unit-info
  block confidently — when terrain More Info is hidden (its default), the corner footprint
  is just the compact panel.

## Integration checklist

- [ ] Convert `_terrain_expanded: bool` → `_terrain_more_page: int` (-1 hidden).
- [ ] Add page containers (`DescriptionPage`, `MovementPage`) under
      `TerrainMoreInfoPanel` in the HUD scene; move existing labels into them.
- [ ] `F`/`more_info` on the terrain surface cycles Hidden → 0 → 1 → Hidden.
- [ ] Reflow recomputes from the active page size (hardens V021-02).
- [ ] Movement page renders all movement types incl. `flying` (after V021-11).
- [ ] HUD-layout-editor sample text / bounds respect the active page (V021-03/04).
- [ ] Tests: `test_hud.gd` — page cycle visibility, hidden state hides the whole panel,
      reflow anchors to the compact panel across page swaps and layout reset.
- [ ] GDD_07 §UI/Terrain Panel updated in the same commit (DoD#1).

## Open questions

1. Default page on first `F` press: Description (page 0) — confirm.
2. Should the movement page also restate Def/Dodge, or keep those compact-only? (Lean:
   restate, so the movement page is self-contained.)
3. Mouse-only mode (V021-17) adds a page button / click-to-switch — designed there;
   keep the page API (`_cycle_terrain_more`) public so that mode can call it.
