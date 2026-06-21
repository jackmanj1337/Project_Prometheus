# Map-Readability Cluster (§4) — Draft Plan + Open Questions Register

**Started:** 2026-06-21d
**Status:** Planning draft — register OPEN.
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
  `OVERLAY_DARK_RED` (threat — added for the threat-range design). `_paint_overlay(tiles,
  source_id)` is the single paint primitive.
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
player see?
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
- **Resolution:** _[OPEN]_

### [MRD-2] Hover-peek: trigger model  **[OPEN]**
- **A — Auto on cursor-rest over any unit** (no button; range appears when the cursor
  sits on a unit). Closest to GBA-FE; zero input cost.
- **B — Hold-a-button to peek** (press to show, release to hide). Avoids flicker while
  scrubbing the cursor fast; maps cleanly to a gamepad face/shoulder button.
- **C — Toggle key** cycles peek on/off globally.
- **Rec: B** — auto-peek (A) repaints the overlay on every cursor tick (perf + visual
  noise, see [MRD-4]); a hold is intentional, gamepad-friendly, and composes with the
  input-mode work (§1). Offer A as a setting later if requested.
- **Resolution:** _[OPEN]_

### [MRD-3] Aggregate threat ("all enemies danger zone") vs individual — relationship  **[OPEN]**
The individual design (`_watch_set`) tracks hand-picked units. The classic "danger zone"
shows *all* enemies at once.
- **A — Aggregate is just "watch every hostile"** — one toggle adds all hostiles to the
  existing `_watch_set`; no new system, reuses the designed machinery + dark-red layer.
- **B — Separate aggregate path** with its own union-of-ranges cache, distinct from the
  individual watch set.
- **Rec: A** — the design already supports a set of watched units; "all" is a population
  of that set. One code path, one render layer, one save field. Cheaper now (per the
  mobile-web "bias to cheap-now" memory).
- **Resolution:** _[OPEN]_

### [MRD-4] Live recompute performance for hover + arrows  **[OPEN]**
Hover-peek and path-arrows recompute as the cursor moves. On a large map with many units,
recomputing ranges per cursor tick could stutter (esp. web/mobile target).
- **A — Recompute every cursor move** (simplest; rely on the fact ranges are small floods).
- **B — Debounce/cache:** recompute only after the cursor rests N ms on a new unit; cache
  the last hovered unit's range until the hovered unit changes.
- **Rec: B** — pairs with [MRD-2]'s hold-to-peek (compute once on press), and path-arrows
  only need the path to the *current* cursor tile (one `get_movement_path` call, already
  cheap). Caps worst-case repaint cost for the web/mobile target.
- **Resolution:** _[OPEN]_

### [MRD-5] Grid-visibility slider: what it dims, and persistence  **[OPEN]**
- **A — Dims terrain layer only** (`modulate.a` on the terrain `TileMapLayer`); units +
  overlays stay full opacity. Pure readability knob.
- **B — Separate "overlay opacity" too** (two sliders: terrain dim + overlay strength).
- **Rec: A** — one slider, one setting, solves the stated need (make overlays/units pop).
  `SettingsManager` float `grid_dim` (0.0–0.5), default 0.0; DoD#2 guard for the value
  range in `check_docs.py` only if it becomes a string-keyed setting (a float needs no
  vocab guard). Add B later only if a playtester asks.
- **Resolution:** _[OPEN]_

### [MRD-6] Build order within the cluster  **[OPEN]**
- **A — Threat-range slices first** (it's already designed, slice 1 build-ready), then
  hover-peek, then path-arrows, then slider.
- **B — Slider + path-arrows first** (smallest, no design dependency), then hover, then
  threat.
- **Rec: A** — the threat-range design is the most-specified and unblocks the gamepad R3
  danger-zone; doing it first banks the hardest piece and establishes the layer-precedence
  decision ([MRD-1]) that the others depend on. Slider is a 1-commit add any time.
- **Resolution:** _[OPEN]_

## 4. Slice sketch (provisional, pending register)
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
