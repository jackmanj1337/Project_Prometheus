---
Type: register
Status: RESOLVED 2026-06-27
Last verified: 2026-06-27
Register: HEX-1..9
Resolved-in: 2026-06-27 — full design-walk (session 2026-06-27). All HEX-1..9 settled; the **build is PARKED** for the project re-evaluation/triage phase (HEX-3). Shape: topology = authored content, **campaign-default + per-map override** (HEX-1/HEX-5, mirrors `[DSP-17]`); **offset `Vector2i` stays the stored tile identity, axial/cube only inside the `GridManager` seam** (HEX-2); two-phase build (Phase 1 = centralize `tile_distance`/neighbour accessor; Phase 2 = `HexTopology`) both deferred (HEX-3); range stays `tile_distance ≤ N` + own balance pass (HEX-4); pointer-primary input, 6-key → `[ICD]` (HEX-6); separate hex tileset, art+orientation deferred (HEX-7); maps authored fresh, no auto-convert (HEX-8). **Only action taken now:** the HEX-9 forward-ward (seam comment at `GridManager.DIRS` + `[DSP]` forward-note).
---

# Grid Topology — Optional Hex-Grid Rule — Open Questions

**Started:** 2026-06-27 (thought-experiment research). **Design-walked + all questions RESOLVED
2026-06-27; BUILD PARKED** for the project re-evaluation/triage phase (HEX-3). This register
captures the design space and the settled answers so the work can start cold without
re-deriving the blast radius. The keystone seam is `GridManager.DIRS` + a future
`tile_distance()` (see "Why it is cheap to reach" below).

## One-line shape
> Make the map's geometry (square ↔ hex) a **swappable topology** behind a single seam in
> `GridManager`, selectable as an optional campaign rule, *without* the rest of the engine
> knowing which shape it is running on.

## Why it is cheap to reach and where it bites (research, 2026-06-27)
The spatial layer is unusually well-centralized, which is the whole reason this is feasible:

- **Neighbors are single-sourced.** `GridManager.DIRS` (`scripts/core/GridManager.gd:255`)
  is a 4-entry cardinal list, and **every** reachability/path/AI-distance calc flows through
  **one** function, `dijkstra_costs()` (`GridManager.gd:272`), which just iterates `DIRS`.
  Swap the neighbor set → movement range, pathfinding, and AI distance-flood all follow.
- **Move cost is already topology-agnostic.** Costs are keyed per **terrain string**
  (`_DEFAULT_MOVE_COSTS`, `get_move_cost`), not per geometry. No change needed.
- **Distance is the messy part — NOT centralized.** Manhattan (`absi(dx)+absi(dy)`) is
  inlined in ~8 sites: `GridManager._tiles_in_range` + the three range checks
  (`GridManager.gd:455,475,499`), `CombatResolver.gd:383`, `EnemyAI` (`_find_nearest_manhattan`
  + two adjacency scores ~`EnemyAI.gd:231,243,303`), `MapCursor._manhattan`
  (`MapCursor.gd:392`), `SkillHandler._manhattan` (`SkillHandler.gd:455`). These must
  consolidate behind one `tile_distance()` before any hex work.
- **Pixel conversion assumes square.** `world_to_tile` / `tile_to_world`
  (`GridManager.gd:136-142`) and `Unit.gd:63` do `tile * TILE_SIZE`. Hex needs real
  hex→pixel math (only at these few edges).
- **Rendering is mostly free.** The `.tres` tilesets have no `tile_shape`, so they default to
  square; **Godot 4 `TileMapLayer` supports `tile_shape = hexagon` natively**.
- **Input is 4-directional.** The cursor moves on 4 cardinal keys (`MapCursor`); hex has 6
  neighbors — a UX question, not a pathfinding one.
- **Storage already survives the switch.** `MapData.grid: Array[String]` (row-major terrain)
  + `Vector2i` placements are *offset coordinates*; they stay valid under hex — only the
  *adjacency/distance interpretation* of those same ints changes.

## Recommended path (two phases; phase 1 has standalone value)
1. **Phase 1 — centralize geometry (do first, low-risk, reversible probe).** Replace the ~8
   inlined distance sites with one `GridManager.tile_distance(a, b)`; route neighbor access
   through one accessor instead of bare `DIRS`. This is a pure refactor with full test
   coverage and tells us the real blast radius before committing to hex. Valuable even if
   hex never ships.
2. **Phase 2 — add a `HexTopology` behind the seam.** Axial/cube coords internally
   (Red-Blob-Games standard), converted to/from offset `Vector2i` only at the storage and
   render edges. The optional rule selects square vs hex at map load.

## Cross-refs
- **`[DSP]`** Displacement & Carry (`registers/displacement_carry_open_questions_2026-06-25.md`)
  — shove/swap/pivot are **direction-based**; its direction set must stay topology-sourced or
  it hard-codes 4-way and blocks hex later. See **HEX-9**.
- **`[FOW]`** Fog of War / Line-of-Sight — LOS is geometry-sensitive; a hex switch reshapes it.
- **`CampaignRules`** (`scripts/resources/CampaignRules.gd`, "Target design fields") — the
  toggle's home. See **HEX-5**.
- Authority for the seam: `GridManager` (map-geometry authority, per its class doc).

---

## HEX-1 — What does "optional" mean: per-campaign, per-map, or live-flip?  `[RESOLVED 2026-06-27]`
Can a single existing square map be re-rendered as hex at runtime, or is topology chosen
when content is authored?
**RESOLVED (owner 2026-06-27): topology is authored content — campaign-default + per-map
override** (mirrors the resolved `[DSP-17]` campaign-default+override pattern). A campaign sets
a default topology; an individual `MapData` may override it. **NOT** a live runtime re-flip of
the same map data — a square map's hand-painted terrain/placements do not transform 1:1 onto
hex, so "any map, either shape" would mean dual-authoring every map. A future player-facing
"Hex Mode" is allowed only as *selecting a separately-authored hex campaign variant*, never as
re-interpreting fixed map data. → fixes the storage home in **HEX-5** (default on
`CampaignRules`, override on `MapData`).

## HEX-2 — Internal coordinate system: axial/cube vs offset  `[RESOLVED 2026-06-27]`
**RESOLVED (owner 2026-06-27): offset `Vector2i` stays the stored tile identity; axial/cube
lives ONLY inside the `GridManager` seam.** Tile identity (`Unit.tile_position`, `MapData`
placements, every tile-keyed dictionary, saves) remains offset `Vector2i` and is untouched —
square is offset-with-no-shift, so the square path needs zero change. Inside the neighbor
accessor and `tile_distance()`, convert offset→axial/cube, compute, convert back. The chosen
offset layout (even-q/odd-q/even-r/odd-r) is baked into the `HexTopology` conversion. Rejected:
axial-as-native-identity (ripples into storage/saves/every `Vector2i` site) and pure-offset
parity-branch math (bug-prone).

## HEX-3 — Commit to the topology abstraction now, or ship Phase 1 only and defer?  `[RESOLVED 2026-06-27]`
**RESOLVED (owner 2026-06-27): park BOTH phases; apply only the HEX-9 forward-ward now.**
Neither Phase 1 (geometry centralization) nor Phase 2 (`HexTopology`) is built now. Both go
into the parked-features backlog to be sorted/prioritized during the **planned project
re-evaluation / triage phase**, alongside the other recently-walked-but-unscheduled systems —
this register is not special-cased ahead of that triage. The *only* action taken immediately is
the cheap **HEX-9** ward (keep new direction-based code topology-agnostic so the option stays
alive). **Phase 1 is the designated first build step IF/WHEN the triage greenlights hex** — do
not build it speculatively before then. (Revises the initial "Phase 1 now" recommendation: a
speculative refactor amid heavy in-flight work adds churn for no near-term payoff and is
equally cheap later.)

## HEX-4 — Combat/weapon-range semantics & balance under hex  `[RESOLVED 2026-06-27]`
Range is currently a Manhattan ring (`_tiles_in_range`). Under hex it becomes a hex-distance
ring — and the **tile counts differ**: a Manhattan disk of radius R covers `2R(R+1)+1` tiles
(R1=4-neighbour melee→5 incl. self, R2→13), a hex disk covers `3R(R+1)+1` (R1→7, R2→19). So
melee threatens **6** neighbours vs 4 (~50% more), a 2-range bow covers **18** hexes vs 12.
**RESOLVED (owner 2026-06-27): range stays `tile_distance ≤ N`; hex is its own balance pass.**
No per-topology range tables (rejected — doubles authoring/reasoning on every ranged weapon).
The coverage shift is accepted as inherent (a hex *has* 6 neighbours; it cannot be made to feel
like 4) and handled by a **dedicated hex weapon-balance pass IF/WHEN hex is built** — a known,
bounded task, not a blocker. Threat/danger-zone + AI-scoring effects ride the same
`tile_distance` change for free.

## HEX-5 — Where the toggle lives  `[RESOLVED 2026-06-27 — by HEX-1]`
**RESOLVED (owner 2026-06-27, determined by HEX-1's campaign-default+override):**
- `CampaignRules.grid_topology: String = "square"` — campaign default, added under the
  existing **"Target design fields (not yet wired)"** section; mirrored onto `GameState` only
  when Phase 2 wires it. Matches `permadeath_enabled`/`pair_up_enabled` — save-specific
  gameplay state, **not** a `SettingsManager` app setting.
- `MapData.grid_topology: String = ""` — optional per-map override; **`""` = inherit the
  campaign default** (empty-string sentinel, not a magic `"inherit"` literal — matches other
  optional `MapData` fields that default empty).
Value vocabulary: `"square"` | `"hex"` (extensible if a third topology ever appears).

## HEX-6 — Cursor input for 6 neighbors  `[RESOLVED 2026-06-27]`
The cursor is 4-directional; hex has 6 adjacencies.
**RESOLVED (owner 2026-06-27): pointer-primary now; native 6-key cursoring deferred to the
`[ICD]` input/controls register as a Phase-2 detail.** Mouse/touch tile selection is already
topology-agnostic and reaches every hex with zero change, so hex is **not** input-blocked.
Keyboard cursoring keeps 4-way (up/down/left/right) across offset rows in the interim;
specifying the two off-axis hex-neighbour keys is ICD's job, not this register's, and only if
hex is greenlit. Not a Phase-1 concern.

## HEX-7 — Rendering & art under hex  `[RESOLVED 2026-06-27]`
Existing 64px **square** sprites do not fill a hex cell; Godot's hex `TileMapLayer`
(`tile_shape = hexagon`) needs hex-shaped tile art.
**RESOLVED (owner 2026-06-27): separate hex-shaped tileset; art deferred to the build's art
pass.** Current map art is placeholder-only (art-pipeline direction), so deferring wastes
nothing. **Pointy-top vs flat-top orientation is also deferred** to that art pass — it's an
aesthetic call coupled to the sprites (and to HEX-2's baked offset layout: pointy-top →
even-r/odd-r horizontal rows, flat-top → even-q/odd-q vertical columns). Noted leaning:
**pointy-top** is the likely default for a top-down tactics grid, but it is **not pinned** here.

## HEX-8 — Maps: re-author vs auto-convert  `[RESOLVED 2026-06-27 — by HEX-1]`
**RESOLVED (owner 2026-06-27, direct consequence of HEX-1's no-live-flip):** hex maps are
**authored fresh** as a distinct set; **no auto-conversion** of square maps is required or
assumed. A square→hex converter is a possible later authoring nicety, **never a prerequisite**
for the feature.

## HEX-9 — Forward-ward on in-flight spatial systems  `[RESOLVED 2026-06-27 — applied]`
Even while hex is parked, other spatial work can quietly hard-code 4-way and make hex
expensive later. **The single most valuable output of parking this register**, and the only
action taken now (per HEX-3).
**RESOLVED + APPLIED (owner 2026-06-27): doc forward-note in `[DSP]` + a seam comment at
`GridManager.DIRS`.** Concretely landed:
1. **`GridManager.gd` `DIRS` (≈line 255)** carries a comment marking it the single geometry
   seam and instructing direction-based features to read neighbours through it, not copy a
   4-way literal (cites `[HEX-9]`). Not a refactor — a durable in-code ward seen at the literal.
2. **`[DSP]` register** (`registers/displacement_carry_open_questions_2026-06-25.md`, Notes)
   gains a `[HEX-9]` forward-ward: shove/swap/pivot/carry directions must source from the
   geometry seam, not a hard-coded 4-way `Vector2i` literal.
Catalog check: `[DSP]` is the only live direction-based design today, so no broader sweep was
needed. Principle for future direction-based registers: **source direction sets from the
`GridManager` seam.**
