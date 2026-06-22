# Map-Readability Cluster (§4) — Draft Plan + Open Questions Register

**Started:** 2026-06-21d
**Status:** **RESOLVED 2026-06-22g** — all open questions decided ([MRD-3] was already withdrawn);
build-ready. All four owner decisions took the recs: **[MRD-1] C** (range∩threat blend, hover/arrows
opaque on top) · **[MRD-2] B** (hold-to-peek) · **[MRD-5] A** (terrain-only dim slider) · **[MRD-6] A**
(threat-range first). **[MRD-4] B** ratified as the technical consequence of [MRD-2] B (compute once
on press). The threat-range piece (`individual_threat_range_design_2026-06-21.md`, [TUR-1..4]) folds in.
**Source:** `planning_backlog_2026-06-20.md` §4; session note 2026-06-21c Tier 1 #2.
**Companion:** `individual_threat_range_design_2026-06-21.md` ([TUR-1..4] resolved; the
threat-range piece is DESIGNED and folds in here).
**Scope:** the §4 bullets that "pair naturally" into ONE plan — **range-on-hover overlay**
- **movement path arrows** + the **already-designed individual threat range** +
**grid-visibility slider**. Camera settings, attack-by-target, richer combat prediction,
and minimap are *separate* §4 bullets, explicitly OUT of this cluster.
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

- **Overlay infra exists.** `GridManager` owns an `_overlay: TileMapLayer` with four
  paint sources: `OVERLAY_BLUE` (move), `OVERLAY_RED` (attack), `OVERLAY_HEAL` (orange),
  `OVERLAY_DARK_RED` (source 3 — the **faction danger zone**). `_paint_overlay(tiles,
  source_id)` is the single paint primitive.
- **⚠️ CORRECTION (audit 2026-06-21d): the aggregate "all-enemies danger zone" ALREADY
  EXISTS.** `GridManager.get_enemy_danger_tiles(viewer_faction)` (unions every hostile's
  threat) + `show_enemy_danger_zone()` paint it on `OVERLAY_DARK_RED`, toggled by MMB /
  `MapCursor.show_danger_zone`. The individual threat-range design then **integrates** it
  as the `_danger_mode = full` state and **adds a 5th source** (`OVERLAY_DARKER_RED`,
  source 4) for the per-unit watch layer, with a defined paint order (faction src 3 first,
  watch src 4 on top). So aggregate danger + its relationship to individual threat are
  **already designed/built — NOT this cluster's work** (see [MRD-3]).
- **Range math exists and is reusable.** `get_movement_range`, `get_attack_range_from_tiles`,
  `get_staff_range_from_tiles`, `get_all_attack_tiles`, `dijkstra_costs`,
  `get_movement_path`. The hover overlay and path arrows are *new consumers* of these,
  not new algorithms.
- **Threat range is designed, not built.** `individual_threat_range_design_2026-06-21.md`
  specifies a persistent `_watch_set`, a `_danger_mode` cycle, the darker-red layer + "D"
  markers, contextual MMB, auto-promote/demote, and save serialization (slice 4 = a
  forward dep on §2). Slice 1 (extraction) is build-ready.
- **Path arrows do NOT exist.** Today a selected unit shows the blue move overlay; no
  directional arrow sprites trace the chosen path. `get_movement_path` returns the tile
  list; the arrow renderer is missing.
- **Hover overlay does NOT exist.** Range is shown on *selection*, not on *cursor hover*
  over an idle (unselected) unit — the classic FE "hold/hover to peek a unit's reach."
- **No grid-visibility slider.** The terrain tilemap renders at full opacity; there is no
  setting to dim the map to make overlays/units pop. `SettingsManager` is the home (it
  already owns `movement_speed`, display settings).

## 2. Draft plan (classic FE convention)

Classic FE readability affordances this cluster delivers:
1. **Hover-to-peek range** (GBA/Awakening: cursor over any unit shows its move+attack
   range without selecting). Re-uses selection-time overlay math, painted from the
   cursor's hovered unit instead of the selected one.
2. **Movement path arrows** (every modern FE: an arrow from the unit to the cursor tile
   along the cheapest path). Renders `get_movement_path` as a chain of directional arrow
   tiles on a dedicated overlay/Node2D above the blue range.
3. **Aggregate + individual threat range** ("danger zone" / Awakening's toggle, plus
   Conquest's per-unit hover). The individual piece is the designed `_watch_set`; the
   aggregate "all enemies" toggle is its natural sibling and shares the dark-red layer.
4. **Grid-visibility slider** (a readability/accessibility knob — dim terrain so colored
   overlays and unit sprites read clearly). A `SettingsManager` float + a modulate on the
   terrain `TileMapLayer`.

**Layering precedence (the core render question — see [MRD-1]):** when move, attack,
heal, individual-threat, aggregate-threat, hover-peek, and path-arrows can all want the
same tile, a deterministic precedence is needed so the player sees one unambiguous color.

## 3. Open questions register

### [MRD-1] Overlay precedence + stacking model  **[OPEN]**
Multiple layers can claim one tile (e.g. my move range ∩ enemy threat). What does the
player see? **Note (audit):** the danger layers already have a defined internal order
(faction src 3, then watch src 4 on top — from the threat-range design); this question is
therefore only about how the move/attack/heal layers + the NEW hover-peek + path-arrows
interleave with that existing danger overlay.
- **A — Single fixed precedence, one color per tile** (e.g. selected-unit's own range
  wins on its own tiles; threat shows only on non-range tiles). Simplest; one source per
  tile via `_paint_overlay` ordering.
- **B — Separate stacked TileMapLayers with transparency** (move layer + threat layer
  blend where they overlap, giving a distinct "in-range AND dangerous" tint). Richer info,
  more layers + a blend palette to design.
- **C — Hybrid:** range and threat on separate layers (B), but hover-peek and path-arrows
  are exclusive top layers that replace, not blend.
- **Rec: C** — the move/attack vs threat overlap is exactly the info FE players want
  ("can I reach this safely?"), so blend those; but hover and arrows are transient
  cursor-driven feedback that should read instantly, so they sit on top opaque.
- **Resolution: C — RESOLVED 2026-06-22g.** Range (move/attack/heal) and threat layers blend
  where they overlap (the "reachable AND dangerous" tint); hover-peek + path-arrows are exclusive
  opaque top layers that replace, not blend. Preserves the threat-range design's internal order
  (faction src 3, watch src 4 on top); a small range∩threat blend palette is a build-time DoD#1
  GDD_06 add (no string-keyed vocab → no `check_docs` guard).

### [MRD-2] Hover-peek: trigger model  **[OPEN]**
- **A — Auto on cursor-rest over any unit** (no button; range appears when the cursor
  sits on a unit). Closest to GBA-FE; zero input cost.
- **B — Hold-a-button to peek** (press to show, release to hide). Avoids flicker while
  scrubbing the cursor fast; maps cleanly to a gamepad face/shoulder button.
- **C — Toggle key** cycles peek on/off globally.
- **Rec: B** — auto-peek (A) repaints the overlay on every cursor tick (perf + visual
  noise, see [MRD-4]); a hold is intentional, gamepad-friendly, and composes with the
  input-mode work (§1). Offer A as a setting later if requested.
- **Resolution: B — RESOLVED 2026-06-22g.** Hold-a-button to peek (press shows the hovered
  unit's move+attack range, release hides). Maps to a gamepad button; computes once on press
  ([MRD-4] B). Auto-peek (A) reserved as a later opt-in setting.

### [MRD-3] ~~Aggregate threat vs individual — relationship~~ **[RESOLVED-BY-EXISTING-DESIGN — audit 2026-06-21d]**
**This question was based on a wrong assumption and is withdrawn.** The audit found the
aggregate "all-enemies danger zone" is **already built** (`get_enemy_danger_tiles` /
`show_enemy_danger_zone`, MMB) AND its relationship to the individual watch set is
**already designed** in `individual_threat_range_design_2026-06-21.md`: `_danger_mode`
cycles `full | selected | combined | none`, where `full` = the existing faction aggregate
(source 3) and `selected` = the `_watch_set` (new source 4), `combined` layers both. The
threat-range design **explicitly keeps faction (src 3) and watch (src 4) on separate
layers** — so my draft rec ("add all hostiles to `_watch_set`") would have *contradicted*
the resolved design. **No work here.** The only residual question this cluster owns is how
the NEW hover-peek + path-arrows compose with that existing danger overlay — folded into
[MRD-1]. (Kept as a numbered entry so [MRD-4..6] don't renumber across the session note /
backlog / roadmap references.)

### [MRD-4] Live recompute performance for hover + arrows  **[OPEN]**
Hover-peek and path-arrows recompute as the cursor moves. `EventBus.cursor_moved` already
fires on every tile change (`MapCursor`) — that's the existing hook both features ride. On a
large map with many units, recomputing ranges per cursor tick could stutter (esp. web/mobile).
- **A — Recompute every cursor move** (simplest; rely on the fact ranges are small floods).
- **B — Debounce/cache:** recompute only after the cursor rests N ms on a new unit; cache
  the last hovered unit's range until the hovered unit changes.
- **Rec: B** — pairs with [MRD-2]'s hold-to-peek (compute once on press), and path-arrows
  only need the path to the *current* cursor tile (one `get_movement_path` call, already
  cheap). Caps worst-case repaint cost for the web/mobile target.
- **Resolution: B — RESOLVED 2026-06-22g (ratified as the consequence of [MRD-2] B).** Hover-peek
  computes the range once on button-press and caches it for the hovered unit; path-arrows recompute
  only `get_movement_path` to the current cursor tile (already cheap). No per-cursor-tick range
  flood. Both ride the existing `EventBus.cursor_moved` hook.

### [MRD-5] Grid-visibility slider: what it dims, and persistence  **[OPEN]**
- **A — Dims terrain layer only** (`modulate.a` on the terrain `TileMapLayer`); units +
  overlays stay full opacity. Pure readability knob.
- **B — Separate "overlay opacity" too** (two sliders: terrain dim + overlay strength).
- **Rec: A** — one slider, one setting, solves the stated need (make overlays/units pop).
  `SettingsManager` float `grid_dim` (0.0–0.5), default 0.0; DoD#2 guard for the value
  range in `check_docs.py` only if it becomes a string-keyed setting (a float needs no
  vocab guard). Add B later only if a playtester asks.
- **Resolution: A — RESOLVED 2026-06-22g.** One `SettingsManager` float `grid_dim` (0.0–0.5,
  default 0.0) modulating the terrain `TileMapLayer` only; units + overlays stay full opacity.
  Persists via the existing `movement_speed`-style load/save plumbing. No `check_docs` guard
  (float, not string-keyed). B reserved if a playtester asks.

### [MRD-6] Build order within the cluster  **[OPEN]**
- **A — Threat-range slices first** (it's already designed, slice 1 build-ready), then
  hover-peek, then path-arrows, then slider.
- **B — Slider + path-arrows first** (smallest, no design dependency), then hover, then
  threat.
- **Rec: A** — the threat-range design is the most-specified and unblocks the gamepad R3
  danger-zone; doing it first banks the hardest piece and establishes the layer-precedence
  decision ([MRD-1]) that the others depend on. Slider is a 1-commit add any time.
- **Resolution: A — RESOLVED 2026-06-22g.** Build order: threat-range slices 1–3 (per the existing
  design; slice 4 save defers to §2) → layer-precedence model ([MRD-1] C) → hover-peek ([MRD-2]/
  [MRD-4] B) → path-arrows → grid-dim slider ([MRD-5]). Matches §4 slice sketch below.

## 4. Slice sketch (RESOLVED 2026-06-22g — build order per [MRD-6] A)
1. Threat-range slice 1–3 (per the existing design; slice 4 save defers to §2).
2. Layer-precedence model ([MRD-1]) + aggregate toggle ([MRD-3]).
3. Hover-peek ([MRD-2]/[MRD-4]).
4. Path arrows (new arrow-tile renderer over `get_movement_path`).
5. Grid-visibility slider ([MRD-5]).

## 5. Test notes
- Headless: assert overlay tile-sets from `_paint_overlay` consumers (precedence, watch-set
  union for aggregate) — extends the threat-range design's test plan.
- Path arrows: assert the arrow-tile sequence equals `get_movement_path` direction deltas.
- Settings: `grid_dim` round-trips through `SettingsManager` (extend `test_settings_manager`).
