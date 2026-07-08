---
Type: plan
Status: Active - implementation plan
Last verified: 2026-07-03
---

# Band 6 Map Readability Implementation Plan

**Started:** 2026-07-03.

**Track IDs:** `B6-MRD`.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 6 rows. Drafted from the settled **Q10** walkthrough decision (2026-07-01),
the RESOLVED register `[MRD-1..6]`, and the companion design `[TUR-1..4]`.

## Purpose

Build the map-readability cluster: individual + aggregate threat range, a
precedence-ordered overlay registry, hover-to-peek range, movement path arrows,
and a grid-dim slider. Q10 sequences the work by **save-dependency**: no-save view
slices first (pure view state recomputed per frame from board state), with the
threat **watch-set** persistence as the only save-touching slice, trailing until
suspend state is real.

The overlay layers are a **precedence-ordered registry**, not a hardcoded z-order
`match` — new overlays (danger tiles, healing zones, objective markers) register
with a precedence value rather than editing render order ([EXT], Q10 watchout).

This is a build plan only. It does not authorize starting before the gates land.

## Scope

1. **Threat-range extraction (`[TUR-1..4]` slices 1-2).** Extract the per-unit
   threat calc into a reusable helper, then the `_watch_set` + `_danger_mode`
   cycle (`full|selected|combined|none`), auto-promote/demote, prune-on-death, the
   darker-red watch layer, and the "D" marker.
2. **Precedence-ordered overlay registry (`[MRD-1]` C).** Range (move/attack/heal)
   and threat layers **blend** where they overlap; hover-peek + path-arrows are
   exclusive opaque **top** layers that replace, not blend.
3. **Hover-to-peek range (`[MRD-2]`/`[MRD-4]` B).** Hold-a-button peeks a hovered
   unit's move+attack range; **computed once on press** and cached for the hovered
   unit (no per-cursor-tick range flood).
4. **Movement path arrows.** A new arrow-tile renderer over `get_movement_path` to
   the current cursor tile.
5. **Grid-dim slider (`[MRD-5]` A).** One `SettingsManager` float `grid_dim`
   (0.0-0.5, default 0.0) modulating the terrain `TileMapLayer` only.
6. **Watch-set save (`[TUR-4]` slice 4).** Serialize `_watch_set` + `_danger_mode`
   into the suspend snapshot — the **only** save-touching slice, trailing suspend.

## Non-Goals

- No per-cursor-tick range recompute — `[MRD-4]` B: hover computes once on press;
  path-arrows only recompute the (cheap) path to the current cursor tile.
- No second "overlay opacity" slider (`[MRD-5]` B) — one `grid_dim` float only.
- The aggregate "all-enemies danger zone" is **already built**
  (`get_enemy_danger_tiles` / `show_enemy_danger_zone`, MMB) — this plan
  **integrates** it as `_danger_mode = full`, it does not rebuild it (`[MRD-3]`
  withdrawn).
- Camera settings, attack-by-target, richer combat prediction, and minimap are
  **separate §4 bullets, explicitly OUT** of this cluster.
- The gamepad R3 arm of the danger-zone lands with `gamepad_layer_implementation_
  plan` §4, **not here** (`[TUR-1]`/slice 3 there).
- Do not cache derived view state that quietly grows a save dependency — view
  state recomputes per frame; only the watch-set persists (Q10 watchout).

## Source Docs

- [`band5_plus_preimplementation_questions_review_2026-06-30.md`](../../Code%20Reviews/band5_plus_preimplementation_questions_review_2026-06-30.md)
  → "Walkthrough Decisions (2026-07-01)" **Q10**.
- [`map_readability_open_questions_2026-06-21.md`](../registers/map_readability_open_questions_2026-06-21.md)
  (`[MRD-1..6]` RESOLVED — precedence C, hover B, dim A, threat-first A).
- [`individual_threat_range_design_2026-06-21.md`](../design/individual_threat_range_design_2026-06-21.md)
  (`[TUR-1..4]` — the watch-set / `_danger_mode` / render / persistence design +
  its slices 1-4 this plan implements).
- [`gamepad_layer_implementation_plan_2026-06-20.md`](gamepad_layer_implementation_plan_2026-06-20.md)
  §4 (the R3 consumer of the threat-range resolver — a downstream sibling).

## Decisions Not To Reopen

- Build order (`[MRD-6]` A): threat-range slices 1-3 → layer-precedence model →
  hover-peek → path-arrows → grid-dim slider. (Slice 4 save trails suspend.)
- `[MRD-1]` C: range/threat blend; hover-peek + path-arrows opaque on top.
- `[MRD-2]`/`[MRD-4]` B: hold-to-peek, computed once on press, cached.
- `[MRD-5]` A: single `grid_dim` float, terrain layer only.
- `[TUR-1]` contextual MMB only (same resolver backs gamepad R3); `[TUR-2]`
  distinct darker-red watch layer + "D" markers; `[TUR-3]` persistent `_watch_set`
  + `_danger_mode` cycle; `[TUR-4]` auto-promote/demote, prune-on-death, survives
  phases + mid-map save/load.
- Overlay precedence is a **registry** (precedence value per layer), not a
  hardcoded z-order `match`.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates:

- **None for slices 1-5** — they are pure view state recomputed from board state,
  independent of `B1-SUSPEND` (Q10: no-save slices first). Slice 1 is fully
  headless and buildable as soon as `GridManager` is present (it is, today).
- **`B1-SUSPEND` for slice 6 only** — the watch-set/`_danger_mode` serialization
  rides the between-action suspend snapshot (`[CST-8]` already lists
  `_watch_set`/`_danger_mode`). Until suspend is real, the set is runtime-only
  (survives phases/menus, not a save).
- **Editor step:** author the source-4 darker-red overlay tile before slice 2 can
  be live-verified (the "D" marker is text — no asset).

## Existing Code Touchpoints

Verified 2026-07-03 against `scripts/**/GridManager.gd`:

- `get_movement_range` (l.314), `get_movement_path` (l.328), `get_all_attack_tiles`
  (l.430) — the reusable range math; hover-peek + path-arrows are **new consumers**
  of these, not new algorithms.
- `_paint_overlay(tiles, source_id)` (l.519) — the single paint primitive;
  `OVERLAY_DARK_RED := 3` (l.516) is the faction danger source. Slice 2 adds
  source 4 (`OVERLAY_DARKER_RED`).
- `get_enemy_danger_tiles(viewer_faction)` (l.546) + `show_enemy_danger_zone`
  (l.580) — the aggregate danger **already exists**; slice 1 extracts the embedded
  per-unit calc into `get_unit_threat_tiles` and refactors this to call it (no
  faction-overlay behavior change).
- `MapCursor` — owns the `show_danger_zone` action (MMB), `_toggle_danger_zone`,
  `get_unit_at`, `_controlling_faction`; slice 2 replaces the binary toggle with
  the `_danger_mode`/`_watch_set` resolver.
- `SettingsManager` — home of `movement_speed`/display floats; slice 5 adds
  `grid_dim` alongside them.
- `EventBus.cursor_moved` — the existing per-tile hook hover-peek + path-arrows
  ride.
- Tests to extend/create: `test_grid_manager` (threat extraction + faction
  regression), `test_map_cursor` (watch-set/mode interaction), `test_settings_
  manager` (`grid_dim` round-trip), new `test_path_arrows.gd`.

## Slice 1 - Threat Extraction + Faction Regression

**Goal:** the reusable per-unit threat primitive, with the aggregate danger proven
unchanged. Fully headless, no dependencies (`[TUR]` slice 1).

Files to touch:

- `scripts/**/GridManager.gd`
- `scripts/tests/test_grid_manager.gd`

Implementation steps:

1. Add `get_unit_threat_tiles(unit) -> Array[Vector2i]`: reachable tiles (incl.
   staying put) ∪ attack reach from all of them; `[]` for a dead/null/can't-attack
   unit (the exact calc currently embedded in `get_enemy_danger_tiles`).
2. Refactor `get_enemy_danger_tiles` to union `get_unit_threat_tiles(u)` over each
   hostile attack-capable enemy — identical deduped output.

Tests:

- `get_unit_threat_tiles` returns reach ∪ attack-from-reach for an armed enemy;
  `[]` for a healer/dead/null unit.
- `get_enemy_danger_tiles` output is **unchanged** after the refactor (regression:
  same tile set for a ≥2-enemy fixture — proves behavior preservation).

F1 obligations: none (pure derived view logic; `no_save_guard`).

DoD#1 obligations: update `GDD_06`/`GDD_07` when slice 2's feature lands (this
slice is an internal refactor).

## Slice 2 - Watch Set + Mode Cycle + Render + Precedence Registry

**Goal:** the player-visible threat feature and the overlay precedence model
(`[MRD-1]` C + the full `[TUR]` slice 2).

Files to touch:

- `scripts/**/MapCursor.gd` (the `show_danger_zone` resolver)
- `scripts/**/GridManager.gd` (`OVERLAY_DARKER_RED` source 4, `repaint()` helper,
  precedence registry)
- `scripts/tests/test_map_cursor.gd`
- **Editor:** author the source-4 darker-red overlay tile.

Implementation steps:

1. Replace `_toggle_danger_zone` with the `[TUR]` §3 resolver: MMB over a hostile
   attack-capable enemy toggles its `_watch_set` membership; MMB over empty/terrain
   cycles `_danger_mode` (`full→selected→combined→none`). `_watch_set` stores
   **stable unit ids** (prune-on-death safe, save round-trippable).
2. `repaint()` implements the §3 mode table + §4 paint order (faction src 3 first,
   watch src 4 on top) + the "D" markers; auto-promote/demote on the empty↔non-empty
   transition; prune-on-death.
3. Persistence-without-save: teardown (enemy phase, menu, unit selection) clears
   the **paint** only, retains `_watch_set` + `_danger_mode`; return-to-FREE
   `repaint()` recomputes from current positions (fresh, never stale). Map load
   clears the set.
4. **Overlay precedence registry (`[MRD-1]` C):** layers register a
   `{layer_id, precedence}` entry; the paint resolver reads it so range
   (move/attack/heal) sits below threat and hover-peek + path-arrows (slices 3-4)
   register as opaque top layers. Any distinct overlap/blend look belongs to the
   authored overlay tile sources, not registry metadata. Adding a layer (danger
   tiles, healing zones, objective markers) is a registration, not a `repaint()`
   edit.

Tests:

- Press routing: MMB over a hostile attack-capable enemy edits `_watch_set`; over
  empty/ally/healer-enemy cycles `_danger_mode`.
- Watch-set: toggling two enemies builds a 2-member set; `selected` paints their
  union; `combined` paints faction ∪ watch with watch winning shared cells (assert
  source 4 on an overlapping tile).
- Auto-promote/demote: first add `none→selected`, `full→combined`; last remove
  `selected→none`, `combined→full`; others unchanged.
- Persistence: selection/phase-change clears paint but retains state; return-to-FREE
  `repaint()` recomputes fresh after an enemy moves; map load clears the set.
- Prune-on-death: a watched enemy dying is removed (no stale paint); last-member
  removal auto-demotes.
- Precedence: a tile in both move-range and threat blends; adding a fixture overlay
  layer paints at its registered precedence with no `repaint()` edit.

F1 obligations: none this slice — `_watch_set`/`_danger_mode` persistence is
slice 6 (survives phases at runtime here).

DoD#1 obligations: update `GDD_07` (threat-range / danger-zone UI: watch-set +
mode cycle) + flip the `GDD_10` Open Items Register row + the gamepad §4 dependency
edge in the same commit (`[TUR]` §9).

DoD#2 obligations: `_danger_mode` is a fixed value-set (`none|full|selected|
combined`) — add a `check_docs` guard mirroring the mouse-cursor value-set check
(parse the `const`, assert GDD lists each).

## Slice 3 - Hover-To-Peek Range

**Goal:** hold-a-button peeks a hovered unit's reach, computed once on press
(`[MRD-2]`/`[MRD-4]` B).

Files to touch:

- `scripts/**/MapCursor.gd` (peek action + press/release)
- `scripts/**/GridManager.gd` (paint the peek as an opaque top layer)
- `scripts/tests/test_map_cursor.gd`

Implementation steps:

1. On peek-button **press** (FREE state), read the hovered unit under the cursor,
   compute its move+attack range **once**, cache it, and paint it as an **exclusive
   opaque top layer** (registered in slice 2's precedence registry, `replace`).
2. On **release**, clear the peek paint. While held, moving the cursor to a
   **different** unit recomputes; staying on the same unit reuses the cache (no
   per-tick flood, `[MRD-4]` B).
3. Rides `EventBus.cursor_moved`; does not disturb `_watch_set`/`_danger_mode`.

Tests:

- Peek press over a unit paints its move+attack range; release clears it.
- Moving to a new unit while held recomputes; staying on the same unit does not
  recompute (cache hit — assert compute count).
- Peek paints on top of / replaces range+threat (opaque top layer, not blended).

F1 obligations: none (transient view state; `no_save_guard`).

DoD#1 obligations: update `GDD_07` (hover-peek) + flip `GDD_10_Roadmap`.

## Slice 4 - Movement Path Arrows

**Goal:** a directional arrow chain from the selected unit to the cursor tile.

Files to create or touch:

- `scripts/**/` a path-arrow renderer (arrow-tile chain or Node2D above the blue
  range)
- `scripts/tests/test_path_arrows.gd`

Implementation steps:

1. On a selected unit, render `get_movement_path(unit, cursor_tile)` as a chain of
   directional arrow tiles along the cheapest path, as an **exclusive opaque top
   layer** (registered in the precedence registry).
2. Recompute **only** the path to the current cursor tile on `cursor_moved` (one
   cheap `get_movement_path` call, `[MRD-4]` B) — no range recompute.

Tests:

- The arrow-tile sequence equals `get_movement_path` direction deltas.
- The path updates as the cursor moves; arrows sit above the blue move range.

F1 obligations: none (transient view state; `no_save_guard`).

DoD#1 obligations: update `GDD_07` (path arrows) + flip `GDD_10_Roadmap`.

## Slice 5 - Grid-Dim Slider

**Goal:** one readability knob dimming the terrain layer (`[MRD-5]` A).

Files to touch:

- `scripts/**/SettingsManager.gd` (`grid_dim` float)
- the terrain `TileMapLayer` modulate site
- `scripts/tests/test_settings_manager.gd`

Implementation steps:

1. Add `grid_dim: float` (0.0-0.5, default 0.0) to `SettingsManager`, persisted via
   the existing `movement_speed`-style load/save plumbing.
2. Modulate `.a` on the **terrain** `TileMapLayer` only; units + overlays stay
   full opacity.
3. A Settings slider control (reuse the existing float-slider pattern).

Tests:

- `grid_dim` round-trips through `SettingsManager` (extend `test_settings_manager`).
- The terrain layer modulate reflects `grid_dim`; overlays/units unaffected.

F1 obligations: none (a settings float, not campaign save). No `check_docs` guard
(float, not string-keyed, `[MRD-5]`).

DoD#1 obligations: update `GDD_07` (grid-dim accessibility knob) + flip
`GDD_10_Roadmap`.

## Slice 6 - Watch-Set Save Serialization (Trails Suspend)

**Goal:** the one save-touching slice — persist `_watch_set` + `_danger_mode`
into the suspend snapshot (`[TUR]` slice 4). **Gated on `B1-SUSPEND`.**

Files to touch:

- the between-action suspend serializer (Band 1, `[CST-8]`)
- `scripts/**/MapCursor.gd` (snapshot/restore hooks)
- `scripts/tests/test_map_cursor.gd` (or the suspend serializer suite)

Implementation steps:

1. Add `_watch_set` (stable ids) + `_danger_mode` to the between-action suspend
   snapshot (`[CST-8]` already lists them as part of the snapshot scope).
2. On resume, restore both, prune ids for enemies no longer present, then
   `repaint()`.

Tests:

- `_watch_set` + `_danger_mode` survive a suspend/resume round-trip.
- Ids for absent enemies are pruned on restore (no stale watch entries).

F1 obligations: `_watch_set` + `_danger_mode` are part of the suspend snapshot —
confirm the Band 1 suspend serializer includes them (flag in that plan).

DoD#1 obligations: update `GDD_07` + flip `GDD_10_Roadmap`.

## Implementation Commit Order

1. Slice 1 threat extraction + faction regression (headless, no gates).
2. Slice 2 watch-set + mode cycle + render + precedence registry (editor step).
3. Slice 3 hover-to-peek range.
4. Slice 4 movement path arrows.
5. Slice 5 grid-dim slider.
6. Slice 6 watch-set save serialization — **trails `B1-SUSPEND`**.

Slices 1-5 are pure view state with **no save dependency** (Q10: no-save slices
first) and can land before suspend exists. Slice 6 is the only save-touching slice
and waits for suspend. The gamepad R3 arm is a downstream sibling in
`gamepad_layer_implementation_plan` §4, not this plan.

## Verification Checklist

Same as the Band 2/3/4/5 plans. Run after each implementation slice:

```bash
python3 AGENT/Docs/check_docs.py
git diff --check
./run_tests.sh
```

Docs-only edits to this plan require:

```bash
python3 AGENT/Docs/gen_docs_index.py
python3 AGENT/Docs/check_docs.py
```
