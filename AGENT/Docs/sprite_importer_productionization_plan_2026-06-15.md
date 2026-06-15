# Map-Sprite Importer Productionization — Implementation Plan

**Status:** Planned (approved 2026-06-15; implementation deferred)
**Last verified:** 2026-06-15
**Authority:** GDD_10 §Phase 3 Systems (sprite importer); GDD_03 §Units
**Supersedes (on implementation):** `fe_map_sprite_importer_guide.md` (the from-scratch tutorial)

## Context

`fe_map_sprite_importer_guide.md` is a generic "build a new Godot project" tutorial
for an FE map-sprite importer. The roadmap flagged **four decisions needed before
implementation**; this plan resolves them and adapts the importer **into this repo**
(existing `Unit.tscn`, `data/` conventions, `DataManager`) rather than following the
guide's scaffolding. It unblocks the art pipeline and is independent of the campaign
cluster.

### Decisions taken (2026-06-15)
1. **Frame size & row order = exported settings**, default **32×32** and
   `["down","left","right","up"]`, **decoupled from `TILE_SIZE`**. The logical tile
   stays **64** (`GameConstants.TILE_SIZE`, GDD-authoritative — explicitly confirmed
   2026-06-15); art frame size is its own pipeline setting.
2. **Generate the `SpriteFrames .tres` only — never a scene.** Switch `Unit.tscn`'s
   `Sprite2D` → `AnimatedSprite2D`; assign frames per unit at spawn.
3. **Folders:** raw sheets → `assets/sprites/raw/<unit>/`; generated `.tres` →
   `data/sprite_frames/` (sibling of `classes/`, `weapons/`, …). Drop `assets/generated/`.
4. **Testability:** all pure logic in a `RefCounted` core covered by headless tests;
   the `EditorPlugin` is a thin button.

## Key findings from exploration

- **Units render via `scenes/units/Unit.tscn`** = `Node2D` + a static **`Sprite2D`**
  (`assets/sprites/units/unit_player.png`, `64×64`, `centered=false`) + `HPBar`,
  instantiated by `GameMap._spawn_unit`. Faction color = `Sprite2D.modulate` in
  `Unit._apply_faction_visual`. The guide's standalone `Node2D+AnimatedSprite2D`
  scene has none of this and `_spawn_unit` cannot consume it → **one pipeline only**.
- **`TILE_SIZE = 64`** (`scripts/shared/GameConstants.gd:10`), used at ~33 non-test
  sites; GDD_01 §Rendering marks 64 authoritative (32 was a rejected earlier draft).
  Art frame size is independent of this.
- **Resources live under `data/`** (`classes/items/maps/roster/skills/weapons`); source
  art under `assets/sprites/`. `project.godot` already sets nearest-neighbor filtering
  (the guide's "disable filter" step is moot).
- The guide's Step 1 says "Renderer: Forward+" — the project ratified **Compatibility
  (OpenGL)** (OPEN-8); ignore that step. The importer itself is renderer-agnostic.

## Design

### 1. `SpriteImporterCore` (pure, headless-testable)
`addons/fe_importer/sprite_importer_core.gd`, `extends RefCounted`, **no editor deps**:
- **Config** (an `ImporterConfig` Resource or a plain Dictionary): `frame_width=32`,
  `frame_height=32`, `directions=["down","left","right","up"]`, `walk_frames=4`,
  `walk_fps`, `raw_root="res://assets/sprites/raw/"`,
  `out_root="res://data/sprite_frames/"`. All **exported / overridable**.
- Pure functions: `list_unit_folders(raw_root)`; `frame_region(col,row,cfg) -> Rect2`;
  `build_sprite_frames(walk_tex, stand_tex, cfg) -> SpriteFrames` (animations
  `walk_<dir>` ×`walk_frames` and `idle_<dir>` ×1, via `AtlasTexture` regions);
  `import_unit(unit_id, cfg) -> SpriteFrames`; `save_frames(unit_id, frames, cfg)`
  (`ResourceSaver.save` to `data/sprite_frames/<unit_id>_frames.tres`).
- `import_all(cfg)` loops folders → import → save. **No scene generation.**

### 2. `EditorPlugin` (thin)
`addons/fe_importer/plugin.gd` + `plugin.cfg`: a toolbar button whose handler is just
`SpriteImporterCore.new().import_all(default_config)`. No logic lives here.

### 3. Unit scene switch (the real wiring — decision 2's hidden work)
- `scenes/units/Unit.tscn`: `Sprite2D` → **`AnimatedSprite2D`** (`_sprite` ref + the
  `_apply_faction_visual` `modulate` write are unchanged — `modulate` is on
  `CanvasItem`, shared by both node types).
- Add **`ClassData.sprite_frames_path: String`** (map sprite is per-class); optional
  per-unit override on `UnitData` later. At spawn, `Unit.initialize` loads the
  `SpriteFrames` (class → unit override), assigns it, and plays `idle_down`.
- **Fallback:** a default placeholder `SpriteFrames` (wrap the existing 64×64
  placeholder as a one-frame `idle_down`) so classes without imported art still render
  — keeps every current map working before any art exists.
- **On-tile placement:** 32px art on a 64px tile — set the `AnimatedSprite2D`
  offset/centering so the sprite foot-aligns within the tile (FE map sprites overhang;
  art size ≠ tile size by design). Tune in the scene; `TILE_SIZE` untouched.

## Tests (`test_sprite_importer.gd`, headless, glob-discovered)
- `frame_region` returns the correct `Rect2` grid for given frame size + row/col
  (off-by-one guard); a non-default `frame_width` shifts regions accordingly.
- direction/row mapping honors a reordered `directions` config.
- `build_sprite_frames` yields exactly `walk_<dir>`(×`walk_frames`) + `idle_<dir>`(×1)
  animations with the configured names/counts.
- folder/filename parsing extracts unit ids; a unit folder missing `-walk`/`-stand`
  is reported and skipped, not crashed.
- `save_frames` round-trips: save to a temp `user://` path, reload, assert animations
  survive (isolated HOME per the `run_tests.sh` worker model).

## Documentation (DoD#1)
- Rewrite `fe_map_sprite_importer_guide.md` to the productionized design (adapt-into-
  repo; `SpriteFrames`-only; `data/sprite_frames/` + `assets/sprites/raw/`; drop the
  new-project/Forward+ steps), or mark it superseded by this plan + a new short guide.
- GDD_03 §Units: `ClassData.sprite_frames_path`; the `AnimatedSprite2D` switch + fallback.
- GDD_10 §Phase 3 Systems: mark the four importer decisions resolved (link this plan);
  keep the item itself implementation-deferred. Bump `Last verified` on edited GDDs.
- DoD#2: add a `DataManager.validate_*` check that every `ClassData.sprite_frames_path`
  resolves to an existing resource (mirrors the existing reward-item validation) — a
  good ratified-rule candidate; land it with the wiring.

## Out of scope
- Combat animations, palette/recolor swapping, mounted-unit composites, metadata
  sidecars, recursive/nested folder schemes (the guide's Priority 2/3).
- Any change to `TILE_SIZE` (stays 64) or re-authoring tile/sprite art to 32.
- A full editor UI/preview beyond the single import button.

## Verification
- Headless `bash run_tests.sh` green incl. `test_sprite_importer`; `python3
  AGENT/Docs/check_docs.py` 12/12.
- Editor: drop a `mage/` sheet pair in `assets/sprites/raw/`, press the button →
  `data/sprite_frames/mage_frames.tres` appears with the 8 animations; point a
  `ClassData.sprite_frames_path` at it and spawn that class → the unit animates on the
  map, keeps its faction tint + HP bar, and a class with no path falls back to the
  placeholder without error.
