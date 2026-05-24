# More Info Mode Plan — 2026-05-24

## Purpose
Turn the current unit-details stat breakdown into a consistent **More Info**
inspection flow that helps playtesting and debugging on the three surfaces that
matter most during live play:

1. character sheet
2. combat preview
3. terrain HUD

This doc is now the implementation handoff for the next session. The major UX
and scope decisions below are locked unless a later playtest forces a change.

## Locked Decisions

### Surfaces
- Phase 1 covers:
  - `UnitDetailsScreen` character sheet
  - combat preview
  - terrain HUD

### Activation
- Clicking a selectable stat/item in the character sheet opens its More Info
  view.
- Clicking a selectable stat/item in the combat preview opens its More Info
  view.
- Pressing `F` follows this priority:
  1. if the combat preview More Info selector is available, open that
  2. else if the character sheet is open, open its More Info selector
  3. else on the map, expand the terrain HUD into terrain More Info mode

### Terrain More Info Content
- Show terrain combat bonuses.
- Show terrain movement penalties for common movement groups.
- Show special tile actions available on that tile, such as `Seize`, `Shop`,
  and `Activate`.

### Combat Preview Content
- The combat preview must expose:
  - crit rates
  - weapon triangle advantage markers
  - weapon effectiveness markers
- These are prerequisites for the combat-preview More Info surface. Do not ship
  a selector there until the preview can show the relevant values and markers.

### Stat Breakdown Policy
- Use a shared helper at `scripts/shared/StatBreakdown.gd`.
- Keep `Unit.get_effective_stat()` as the math authority. The helper explains
  the result; it must not replace the runtime stat math.
- Use friendly display labels first, with raw source ids as fallback when no
  friendly label exists yet.
- Group duplicate modifier entries by source where that is straightforward and
  does not hide useful debugging information.
- Show duration information now, not later.

### Terrain Data Policy
- Show movement penalties for common authored groups, not every possible niche
  movement tag.
- Query existing gameplay systems for tile actions. Do not hardcode tile-action
  strings inside the HUD.

## Implementation Shape

### Shared Breakdown Helper
Create `scripts/shared/StatBreakdown.gd` with a narrow, reusable API.

Recommended return shape:

```gdscript
{
  "stat": "strength",
  "label": "Str",
  "base": 9,
  "effective": 11,
  "total_delta": 2,
  "mods": [
    {
      "source_id": "tonic",
      "source_label": "Tonic",
      "delta": 2,
      "duration_type": "turn",
      "remaining": 1
    }
  ]
}
```

Helper responsibilities:
- collect active modifiers affecting one stat
- compute grouped modifier rows for display
- provide a stable data contract to all three UI surfaces

Helper non-responsibilities:
- final text layout for each UI
- replacing `Unit.get_effective_stat()`
- inventing modifiers that do not exist in runtime state

### Character Sheet
The character sheet is the first stable More Info surface because it already
contains the current stat breakdown.

Phase-1 character-sheet requirements:
- keep the compact colored stat summary
- make selectable stats open a More Info detail view
- reuse the shared breakdown helper instead of inline formatting
- include base, modifiers, signed deltas, duration, and final effective value

### Combat Preview
The combat preview upgrade has two parts.

Part A: complete the preview data it already needs
- verify and expose crit rates clearly
- add weapon triangle markers
- add weapon effectiveness markers

Part B: add the More Info selector
- allow click selection on available preview fields
- allow `F` to open the selector when the preview is present
- More Info should explain where the currently shown preview values come from

### Terrain HUD
Terrain More Info uses the existing HUD rather than a new modal in phase 1.

Phase-1 terrain requirements:
- `F` on the open map toggles the terrain HUD into an expanded More Info state
- expanded terrain info must include:
  - terrain name
  - combat bonuses
  - movement penalties for common groups
  - special tile actions available on that tile

This should stay an expanded panel, not a separate pop-up, unless layout forces
that later.

## Build Order
Implement in this order:

1. extract shared stat-breakdown helper
2. migrate character sheet to the helper
3. upgrade combat preview with crit / weapon triangle / effectiveness markers
4. add combat-preview More Info selector and `F` handling
5. add terrain HUD expanded More Info mode and map-level `F` handling

This order keeps the shared data contract stable before spreading the feature
across multiple UIs.

## File-Level Starting List

Expected first-pass files:
- `scripts/shared/StatBreakdown.gd`
- `scripts/ui/UnitDetailsScreen.gd`
- `scenes/ui/UnitDetailsScreen.tscn`
- `scripts/ui/AttackPreview.gd`
- `scenes/ui/AttackPreview.tscn`
- `scripts/ui/HUD.gd`
- `scenes/ui/HUD.tscn`
- input wiring in the relevant screen/controller scripts for `F`

Possible support files depending on current plumbing:
- `scripts/core/MapCursor.gd`
- `scripts/core/GameMap.gd`
- any existing tile-action or terrain helper the HUD should query

## Test Plan

Add tests in this order:

1. `StatBreakdown` unit tests
2. character-sheet rendering / selector tests
3. combat-preview tests for crit / weapon triangle / effectiveness markers
4. combat-preview More Info selector tests
5. HUD terrain expansion tests

Important assertions:
- boosted stats render green
- lowered stats render red
- unchanged stats keep the default color
- breakdown lists only modifiers that affect the selected stat
- grouped source rows preserve the correct signed total
- duration text appears when duration data exists
- `F` respects the selector priority:
  - combat preview first
  - then character sheet
  - then terrain HUD
- terrain More Info lists the expected tile actions without hardcoded false
  positives

## Explicitly Deferred
- a separate global modal for terrain More Info
- hover-to-open More Info behavior
- every possible movement group label on terrain tiles
- deep transient combat math that is not yet represented cleanly in the preview
  or runtime state

## Next Session Start
Begin implementation at step 1 of **Build Order**. Do not reopen the UX
questions unless the current UI code makes one of these locked decisions
impossible without a cleaner fallback.
