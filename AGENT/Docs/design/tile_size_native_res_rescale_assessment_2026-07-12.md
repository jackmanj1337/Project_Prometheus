---
Role: dated
Type: design
Status: Deferred (post-v1)
Last verified: 2026-07-12
---

# `GameConstants.TILE_SIZE` Rescale — Cost Assessment & Single-Source-of-Truth Plan

Status: **Deferred** (post-v1) — parked under `B8-TILE-RESCALE` in the
[Project Control Plane](../plans/project_control_plane_2026-06-29.md); no work scheduled.
Last verified: 2026-07-12

## Question this answers

If the placeholder art (`GDD_06` "Tile Setup in Godot", Implemented (placeholder
art)) is ever replaced with real pixel art authored at a smaller native
resolution (e.g. 16px), what would it actually cost to change
`GameConstants.TILE_SIZE` itself (currently `64`, `scripts/shared/GameConstants.gd:10`)
end-to-end, and how would the codebase need to change so every consumer
genuinely derives from that one constant instead of quietly assuming a fixed
pixel size?

Note: this is a distinct question from "can we author 16px-looking art at all"
— that's already possible today without touching `TILE_SIZE` (see the earlier
CameraController zoom-shimmer discussion). This document is specifically about
the cost of changing the constant's *value*.

## Summary

The GDScript layer already does this well: every runtime system that needs a
pixel size reads `GameConstants.TILE_SIZE` symbolically, and no `.gd` file
outside `GameConstants.gd` hardcodes a literal `64`. Changing the constant
requires zero GDScript edits in that layer.

The real cost lives outside GDScript: serialized `.tres` resources, source art
files, one scene file, and a few design decisions (viewport size, default
zoom feel) that were tuned by eye against 64px and won't auto-correct. None of
this is hard, but it is real production work, not a one-line diff — and one
part of it (TileSet atlas regions) has a silent-corruption failure mode worth
naming explicitly.

## What already correctly keys off the constant (cost: $0 code changes)

| File | Role |
|---|---|
| `scripts/core/GridManager.gd` | `tile_to_world` / `world_to_tile` |
| `scripts/core/GameMap.gd` | Camera pan limits |
| `scripts/core/MapCursor.gd` | Cursor/menu placement (the `EDGE_GAP_PX = 4.0` constant is intentionally *independent* of tile size — see below) |
| `scripts/core/CameraController.gd` | Zoom math (`ZOOM_LEVELS`) |
| `scripts/ui/AttackPreview.gd` | `tile_px = TILE_SIZE * zoom`, panel placement |
| `scripts/ui/CombatHUD.gd` | World-to-screen offset for damage popups |
| `scripts/units/Unit.gd` | Tile-snap position, move-path targets, `PairUpBadge` offset (explicitly computed from `TILE_SIZE`, see line 105-106 comment) |
| `scripts/tools/generate_tilesets.gd`, `generate_placeholder_assets.gd` | Tool scripts that build tileset/placeholder assets |
| `test_grid_manager.gd`, `test_camera_controller.gd`, `test_attack_preview_position.gd`, `test_map_cursor.gd`, `test_unit_stats.gd` | Assert against `GameConstants.TILE_SIZE` symbolically, not a literal |

Flipping the constant alone does not break any of this. It's the reason the
change *looks* cheap at first glance.

## What does NOT automatically follow (the real cost)

1. **Serialized TileSet resources** — `assets/terrain_tileset.tres` and
   `assets/overlay_tileset.tres` bake `Vector2i(64, 64)` literally into
   `tile_size` and ~48 `texture_region_size` fields (one per atlas source).
   These are build artifacts of `generate_tilesets.gd`
   (`godot --headless --path . --script res://scripts/tools/generate_tilesets.gd`
   — scriptable, no editor UI required) so regenerating them is mechanical
   *once the inputs are right*. It is not mechanical on its own: `texture_region_size`
   **crops** a fixed-size rectangle out of the source PNG — it does not scale
   the PNG to fit. If the constant changes to 16 but
   `assets/sprites/terrain/*.png` are still 64×64 files, the regenerated
   tileset will silently sample only the top-left 16×16 corner of each
   texture. No error, no warning — just wrong-looking tiles. Source art must
   be resized/re-authored *first*.

2. **Every terrain/overlay/cursor source PNG** — `assets/sprites/terrain/*.png`
   (7 files), `assets/sprites/ui/overlay_*.png` (~48 incl. perimeter masks),
   `assets/sprites/cursor/cursor.png`. This is genuine art production work and
   is the dominant cost of the whole exercise, independent of any code change.

3. **Unit sprites are plain, unscaled `Sprite2D`s** — `Unit.gd` computes the
   sprite's *position* from `TILE_SIZE` (`position = tile * TILE_SIZE`) but
   never sets `Sprite2D.scale`. `unit_player.png` / `unit_enemy.png` must
   independently match the new pixel size or they will visually overflow (or
   float inside) the tile footprint — there is no runtime normalization today
   that derives a render scale from `texture.get_size() / GameConstants.TILE_SIZE`.

4. **`scenes/units/Unit.tscn` has one genuinely hardcoded literal** —
   the `HPBar` node's `offset_right = 60.0` (`offset_left = 4.0`, a 4px margin
   against an assumed 64px sprite) is a scene-baked design-time value with
   nothing in code overriding it at runtime. By contrast, `PairUpBadge`'s
   scene-default offsets (`42.0` / `64.0`) are stale-looking but harmless,
   because `Unit.gd:110-111` already overwrites them at runtime from
   `GameConstants.TILE_SIZE` — the `HPBar` has no equivalent runtime override.

5. **`project.godot` viewport (`1280×720`)** — not a bug, but an implicit
   consequence: at zoom 1.0 today the view shows 20×11.25 tiles. Changing
   `TILE_SIZE` changes how much map is visible at the same nominal zoom.
   This needs a deliberate re-tuning decision, not just a code change.

6. **Fixed-pixel UI spacing constants** — `MapCursor.EDGE_GAP_PX = 4.0` and
   `AttackPreview.FORECAST_ROW_PADDING_Y = 4.0` are *intentionally* independent
   of `TILE_SIZE` today (see the `MapCursor.gd:1127-1136` comment — "the gap
   past the edge stays constant" was the deliberate V025-03 decision). Not a
   bug, but worth re-confirming that intent still holds if the tile shrinks a
   lot: a 4px gap is unremarkable next to a 64px tile and disproportionately
   large next to a 16px one.

7. **`CameraController.ZOOM_LEVELS` default feel** — per the earlier
   shimmer discussion, the shimmer-safe zoom stops are a function of the zoom
   value's power-of-twoness, not of `TILE_SIZE`, so the array doesn't strictly
   need new entries. But the *visual meaning* of "1.0×" changes, so the
   default zoom index and general camera feel should be re-tuned deliberately,
   not left on the assumption that it still looks right.

8. **Test literals** — the existing tests reference the symbol correctly, but
   any *new* test written during the change should be audited to make sure it
   doesn't hand-copy a literal pixel value derived from today's `64` instead
   of reading the constant.

## Making `TILE_SIZE` a genuine single source of truth

The gap isn't that `TILE_SIZE` is used inconsistently in code — it's that the
convention "every tile/sprite source texture is authored at exactly
`TILE_SIZE`×`TILE_SIZE` pixels" is implicit and unenforced. Nothing fails
loudly if an art asset drifts from that. Concrete closes, in the same spirit
as the project's existing "fail loud at startup" pattern
(`DataManager._validate_cross_references` / `VALID_EFFECT_TAGS` in
`GameConstants.gd`):

- **Add a texture-dimension assertion** (test or startup check) that loads
  every terrain/overlay/cursor/unit texture and asserts
  `width == height == GameConstants.TILE_SIZE`. This turns silent
  atlas-cropping corruption (item 1 above) into an immediate, loud failure.
- **Move `HPBar`'s offsets into `Unit.gd`**, computed from
  `GameConstants.TILE_SIZE` the same way `PairUpBadge`'s already are, removing
  the last hardcoded literal from `Unit.tscn`.
- **Add a render-scale line to `Unit.gd`** (e.g.
  `_sprite.scale = Vector2.ONE * GameConstants.TILE_SIZE / _sprite.texture.get_width()`)
  so a unit texture authored at a different native resolution than
  `TILE_SIZE` degrades to a visible scale mismatch instead of a silent
  overflow — or, if art is always meant to be pre-sized exactly to
  `TILE_SIZE`, let the assertion above be the enforcement instead and skip
  runtime scaling entirely (simpler, matches current convention).
- **Treat viewport size and default zoom as an explicit re-tuning step** in
  any change checklist for this constant, not something assumed to survive
  unchanged.
- **Document the "art must equal `TILE_SIZE`" convention** explicitly (it is
  currently tribal knowledge inferable only from reading the tool scripts).

## Recommendation

Consistent with the project's own scope framing (`GDD_00` — *"decisions
optimize for demonstrable engineering quality... commercial-release
optimization is not the primary lens"*), this is real, boundable, but
non-trivial production work with no gameplay-system payoff. Park it: keep
this document as the playbook if art direction ever moves to a native
low-resolution style, and don't schedule it against `REL-WEB-DEMO` or any
v1-core work.

## Cross-references

- `AGENT/GDD/GDD_06_Maps_Objectives.md` — "Tile Setup in Godot" (Implemented,
  placeholder art), the authoritative `TILE_SIZE = 64` citation.
- `AGENT/GDD/GDD_00_Overview.md` — Project Scope (`SET-011..014`) and
  `REL-WEB-DEMO` framing referenced in the recommendation above.
- Tracked as `B8-TILE-RESCALE` in
  [Project Control Plane](../plans/project_control_plane_2026-06-29.md) and
  `AGENT/GDD/GDD_10_Roadmap.md` ("Parked Or Post-v1 Work").
