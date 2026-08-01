---
Type: plan
Status: Active - implementation plan
Last verified: 2026-08-01
---

# Band 6 Fog of War / Line-of-Sight Implementation Plan

**Started:** 2026-07-03.

**Track IDs:** `B6-FOW`.

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md)
Band 6 rows. Drafted from the RESOLVED register `[FOW-1..7]`
([`fog_of_war_los_open_questions_2026-06-21.md`](../registers/fog_of_war_los_open_questions_2026-06-21.md)),
confirmed **in v1** by the owner (2026-07-03d).

## Purpose

Build classic GBA-FE **radius fog**: the map is dark except tiles inside any
living player unit's `line_of_sight` disc, enemies hide until spotted, and
walking forward reveals tiles mid-move with an **ambush interrupt**. Plus the two
authored reveal tools the owner pulled into v1 — **event-revealed rooms** (reuse
MET `reveal_tiles`) and **lightable braziers** (`map_objects` vision sources).
The AI **cheats** in v1 (full knowledge); symmetric fog is a reserved future rule.

Every design lever is captured through one seam so the reserved expansions
(true LoS occlusion, terrain/torch vision modifiers, `ai_respects_fog`, weather
fog) slot in later **without touching callers** (`[FOW-1]`/`[FOW-3]` seam
constraints, [EXT]).

This is a build plan only. It does not authorize starting before the gates land.

## Scope

1. **Vision seam + per-faction visible set (`[FOW-1]` A, `[FOW-2]` A).** A single
   `compute_visible_tiles(faction)` computing the radius union of each living
   unit's resolved `line_of_sight`; gated by an encounter-layer `MapData.fog_enabled`
   (default `false` ⇒ existing maps load unchanged).
2. **Render (`[FOW-5]`).** A fog-mask overlay dimming/hiding unseen tiles for the
   active viewer only, and hiding enemy unit nodes on unseen tiles. Registers in
   the MRD precedence-overlay registry as a **base** layer beneath range/threat.
3. **Reveal-on-move + ambush interrupt (`[FOW-4]` A-full).** Recompute the mover's
   visible set **per step**; when a step brings a previously-hidden enemy into
   view, **halt the move on that tile** and fire "enemy spotted" feedback.
4. **AI cheats, one seam (`[FOW-3]` A).** Zero `EnemyAI` change; verify hostile
   acquisition stays funnelled through `_living_hostiles_for_faction` so a future
   `ai_respects_fog` rule wraps one function.
5. **`discovered_units` save (`[FOW-5]` A).** The **only** new save field — the set
   of enemy ids ever spotted; the visible mask is recomputed from positions on load.
6. **Authored reveal tools (`§2a`, in v1).** Event-revealed rooms via MET
   `reveal_tiles` writing fog's persistent revealed set (re-reveal from
   `map_events_fired`); lightable braziers (`[FOW-7]`) as `map_objects` vision
   sources lit by a unit action **or** a new MET `light` action (lit state persists
   in `map_objects_state`).

**v1 visible-set formula:**
`visible = ⋃(living player-unit LoS discs) ∪ ⋃(lit-brazier discs) ∪ (event-revealed regions)`.

## Non-Goals

- **No true LoS occlusion** (`[FOW-1]` B) — flat radius only; walls/forest don't
  block sight. The `compute_visible_tiles()` seam lets a shadowcast replace the
  disc later with no caller change.
- **No symmetric fog AI** (`[FOW-3]` B) — AI cheats. Reserved as a run-wide
  `CampaignRules.ai_respects_fog` in the §2 consolidation, wrapping
  `_living_hostiles_for_faction`.
- **No vision modifiers** (`[FOW-6]` B/C) — flat `line_of_sight`, no terrain bonus,
  no torch/lantern items, no forest concealment. All designed fast-follows.
- **No timed/weather fog** (`[FOW-2]`) — a future MET `set_fog` action on a
  `turn_reached` trigger; not v1.
- **No `MapData` terrain/encounter decomposition** (`[FOW-2]` forward reservation)
  — `fog_enabled` ships on `MapData` next to `enemy_placements`; it migrates
  automatically when the split lands.
- **No brazier extinguish/toggle** (`[FOW-7]`) — one-way `light` latch in v1.

## Source Docs

- [`fog_of_war_los_open_questions_2026-06-21.md`](../registers/fog_of_war_los_open_questions_2026-06-21.md)
  (`[FOW-1..7]` RESOLVED — radius A, encounter-layer A, AI-cheats A, per-step
  ambush A-full, `discovered_units` A, flat-vision A, braziers A) + §2a authored
  reveal tools + §4 slice sketch + §6 forward reservations.
- MET register (`map_events_triggers_open_questions_2026-06-21.md`) — the
  `reveal_tiles` action (event rooms) and the new `light` action (`[FOW-7]`,
  `[MET-3]`); `map_events_fired` re-reveal on load.
- DCH register (doors/chests) — the `map_objects` model + `map_objects_state`
  snapshot braziers ride (same substrate as `B6-DTR`).

## Decisions Not To Reopen

- `[FOW-1]` A: flat-radius vision behind the `compute_visible_tiles()` seam
  (occlusion = later expansion, no caller change).
- `[FOW-2]` A: `fog_enabled` is **encounter/scenario data** (ships on `MapData`
  beside `enemy_placements`), default `false`; NOT a terrain-grid property, NOT a
  run-wide mode.
- `[FOW-3]` A: AI cheats; keep acquisition funnelled through the single
  `_living_hostiles_for_faction` seam.
- `[FOW-4]` A-full: per-step mid-tween recompute **with ambush interrupt** (halt on
  the revealing step) — the one piece of real v1 complexity.
- `[FOW-5]` A: `discovered_units` is the only new save field; rooms/braziers add
  zero fields (derive from `map_events_fired` / `map_objects_state`).
- `[FOW-6]` A: flat per-unit `line_of_sight`, no modifiers in v1.
- `[FOW-7]` A: braziers are `map_objects` vision sources; lit by unit action AND
  MET `light`; one-way latch.

## Dependency Note

Plan now; implement after gates. Minimum upstream gates:

- **`B1-F1` / `B1-SUSPEND`** — for the `discovered_units` save field. Until suspend
  is real, `discovered_units` is runtime-only (fog still works within a session).
- **`B4-MAP-OBJECTS` (DCH)** — braziers (slice 6) are `map_objects` + ride
  `map_objects_state`. The core radius fog (slices 1-4) does **not** need DCH.
- **`B3-MET`** — event-revealed rooms reuse `reveal_tiles`; the brazier MET `light`
  action folds into MET's vocabulary. Unit-lit braziers can land before MET; the
  MET `light` arm trails MET.
- Core radius fog + ambush (slices 1-4) is buildable against the live tree once
  `MapData` carries `fog_enabled` — the vision math + render + move-interrupt need
  no unbuilt system. Save + authored reveals trail their gates.

## Existing Code Touchpoints

Verified 2026-07-03 against the live tree:

- **`UnitData.line_of_sight` (l.33, default 4)** + `ClassData.base_line_of_sight`
  (l.24), resolved through `Unit.gd:1059` (reclass deltas) — the vision-radius
  input. **Nothing reads it today**; `MoreInfoContent.gd:34` already documents it as
  "used for fog-of-war vision once that system is active." No new stat.
- **`GameMap._spawn_units` (l.168)** — full-knowledge spawn today (`GameState.gd:6`
  notes enemies are re-spawned fresh); fog adds the per-faction render filter, not a
  spawn change.
- **`EnemyAI._living_hostiles_for_faction` (l.319)** — the single acquisition seam;
  v1 leaves it untouched (proves `[FOW-3]` A), a future `ai_respects_fog` wraps it.
- **`GridManager._paint_overlay` (l.519)** + `OVERLAY_BLUE..OVERLAY_DARK_RED`
  (0-3, l.513-516) — the paint primitive. **Coordination:** `B6-MRD` slice 2
  reserves **source 4** (`OVERLAY_DARKER_RED`, watch layer); fog takes
  **source 5** (`OVERLAY_FOG`) or a dedicated dark `TileMapLayer` for the unseen
  mask. Register it in the MRD precedence-overlay registry as a base layer.
- **`Unit.move_along_path` (l.548)** — the per-step tween loop (`path[i]`
  iteration, l.559-564); the ambush interrupt (slice 3) hooks the per-step point to
  recompute visibility and stop the tween mid-path.
  > **CORRECTION 2026-08-01 — this anchor's premise does not hold. Re-measure before
  > estimating slice 3.** There is no "per-step point" to hook. `move_along_path` is
  > now at l.561 (anchors drifted) and assigns `tile_position = path[-1]` **before**
  > the loop; the loop at l.575-579 only chains tween segments and commits **no
  > logical state per step**. Worse, at Instant movement speed
  > (`_get_per_tile_seconds() <= 0`) the function calls `snap_to_tile(path[-1])` and
  > returns — **the loop never executes**, so the ambush interrupt as specified would
  > silently not fire for any player using that setting. Slice 3 is therefore larger
  > than "hook the existing loop": it has to make the path a resolved, interruptible
  > sequence with parity across movement speeds and AI. See
  > `../design/terrain_authoring_decisions_2026-08-01.md` `[TER-7]` and tracker row
  > `DESIGN-MOVEMENT-PATH-PASS-THROUGH-2026-08-01`.
- **No `map_objects` / DCH model exists yet** (grep clean) — braziers (slice 6) are
  drafted against the planned DCH API, same caveat as the other Band 6 plans.
- Tests to create/extend: new `test_fog_of_war.gd` (visible-set union, AI-sees-all,
  ambush halt, discovered set), `test_snapshot_coverage` (`discovered_units`),
  `test_map_events` (`reveal_tiles` into fog / `light`), `test_enemy_ai` (regression:
  targets an unseen player).

## Slice 1 - Vision Seam + Per-Faction Visible Set

**Goal:** the headless vision primitive behind one seam, gated by `fog_enabled`.

Files to touch:

- `scripts/resources/MapData.gd` (`fog_enabled: bool = false`)
- a fog service/helper (new `scripts/core/FogService.gd` or a `GridManager` method)
- `scripts/tests/test_fog_of_war.gd` (new)

Implementation steps:

1. Add `MapData.fog_enabled: bool = false` next to `enemy_placements` (encounter-
   layer field, `[FOW-2]`). Default false ⇒ existing maps unchanged.
2. Add `compute_visible_tiles(faction) -> Dictionary` (tile-set): the union of each
   living `faction` unit's LoS disc, radius = resolved `unit.data.line_of_sight`
   (Chebyshev/Manhattan disc, `[FOW-1]` A). **All visibility flows through this one
   function** — the occlusion-swap seam.

Tests:

- Visible set for a fixed layout equals the LoS-disc union; a second unit extends
  it; a dead unit contributes nothing.
- `fog_enabled=false` short-circuits (no fog computed).

F1 obligations: none this slice (pure derived; `no_save_guard`).

DoD#1 obligations: update `GDD_06` (fog/LoS model) when slice 2's feature is
player-visible.

## Slice 2 - Render: Fog Mask + Enemy Hiding

**Goal:** the player sees fog; enemies on unseen tiles are hidden.

Files to touch:

- `scripts/core/GridManager.gd` (`OVERLAY_FOG` source 5 / dark layer + paint)
- the unit render/visibility site (hide enemy nodes on unseen tiles)
- `scripts/tests/test_fog_of_war.gd`
- **Editor:** author the fog-mask overlay tile / dark layer.

Implementation steps:

1. Paint the **complement** of the active viewer's visible set as the fog mask
   (`OVERLAY_FOG` source 5, coordinated after MRD's source 4). Register it in the
   MRD precedence-overlay registry as a **base** layer (range/threat/peek paint on
   top).
2. Hide enemy unit nodes whose tile ∉ the viewer's visible set (player view only);
   the roster + `EnemyAI` still see them (`[FOW-3]` A).
3. Recompute + repaint at **phase start** for the active faction.

Tests:

- An enemy on an unseen tile is absent from the player render list but **present**
  in `EnemyAI` target lists (proves A).
- The fog mask covers exactly the complement of the visible set.

F1 obligations: none (recomputed from positions).

DoD#1 obligations: update `GDD_06` + flip the `GDD_10` roadmap row.

## Slice 3 - Reveal-On-Move + Ambush Interrupt

> **GATED 2026-08-01 — do not build this slice before the per-step movement seam is
> settled.** Fog is not the only claimant on it. `[PER-8]` `on_cross` (a unit crossing
> a masked unit's tile springing a reactive trigger — the register's own "bait into
> traps" case) and `[TER-7]` pass-through terrain traps need the same seam. This slice
> is what would *create* that seam, and all three consumers inherit its shape.
>
> **The model is now settled** — see `../design/position_change_model_decisions_2026-08-01.md`
> `[PCM-1..7]` (owner, 2026-08-01). Build this slice **against that model**, not against
> the anchor above. The two rulings that change this slice most:
>
> * **`[PCM-3]`** — crossing detection must resolve over the **path as data**, before or
>   independently of animation, because the tween loop commits no logical state and does
>   not run at all at Instant speed. Hooking the tween is wrong. This is the largest
>   piece of work in the slice and is what the estimate above missed.
> * **`[PCM-1]`** — the resolver this slice builds is **shared**: `[TER-7]` terrain
>   pass-through triggers, `[PER-8]` `on_cross` and traversing displacement
>   (`[PCM-4]`) are all consumers. Build it as a general crossing resolver with
>   registered consumers, not as fog-specific code. The ambush reveal is then one
>   registered trigger with `interrupt: halt` (`[PCM-5]`).
>
> `[FOW-4]` A-full is unchanged and unreopened. For the avoidance of doubt, `[DSP-12]`'s
> "never interrupts" governs **in-progress combat exchanges**, not moves, and never
> conflicted with this slice. The vision math, render filter and per-faction visible set
> (slices 1-2) are unaffected and can proceed independently.

**Goal:** walking reveals tiles per step; a newly-spotted enemy halts the move.

Files to touch:

- `scripts/units/Unit.gd` (`move_along_path` per-step hook)
- the fog service (per-step recompute) + "enemy spotted" feedback
- `scripts/tests/test_fog_of_war.gd`

Implementation steps:

1. In the `move_along_path` per-step loop (l.559-564), after each committed step
   recompute the mover faction's visible set (`[FOW-4]` A-full).
2. If a step brings a previously-hidden enemy into view, **stop the tween at that
   tile**, add the enemy to `discovered_units`, and fire "enemy spotted" feedback
   (reuse the `ai_unit_acting` camera-pan/announce pattern).
3. Only under `fog_enabled` — non-fog maps keep the current straight-through move.

Tests:

- A move **halts** on the exact step that reveals a hidden enemy; the enemy enters
  `discovered_units`.
- A move with nothing to reveal completes normally (regression).

F1 obligations: touches `discovered_units` (populated here; persisted slice 5).

DoD#1 obligations: update `GDD_06`/`GDD_08` (ambush reveal) + flip `GDD_10`.

## Slice 4 - AI Cheats (Verify One Seam)

**Goal:** confirm zero `EnemyAI` change and the seam stays single.

Files to touch:

- `scripts/tests/test_enemy_ai.gd` (regression assertion)

Implementation steps:

1. No behavior change. Assert acquisition stays funnelled through
   `_living_hostiles_for_faction` (it is, l.319) so a future `ai_respects_fog` rule
   wraps one function (`[FOW-3]` build constraint).

Tests:

- Under `fog_enabled`, the AI still targets a player unit the player cannot see
  (proves cheating-AI A).

F1 obligations: none.

DoD#1 obligations: note the `ai_respects_fog` forward hook in `GDD_08`.

## Slice 5 - `discovered_units` Save (Trails Suspend)

**Goal:** persist the discovered-enemy memory — the only new save field.

Files to touch:

- the save/suspend serializer (`B1-F1`/`[CST]`)
- `scripts/tests/test_snapshot_coverage.gd`

Implementation steps:

1. Add `discovered_units` (enemy id set) to the save schema (`[FOW-5]` A). The
   visible mask is **not** saved — recomputed from positions + LoS on load.
2. On load, seed hidden/shown state from positions; a discovered enemy stays known.

Tests:

- `discovered_units` round-trips through save/load; the visible mask is recomputed
  (not stored).

F1 obligations: `discovered_units` is the whole feature's only new field — reserve
it in the `[CST]` schema (flag in the Band 1 plan).

DoD#1 obligations: update `GDD_06` + flip `GDD_10`.

## Slice 6 - Authored Reveal Tools (Rooms + Braziers)

**Goal:** event-revealed rooms + lightable braziers. **Rooms gate on MET;
braziers gate on DCH (`map_objects`).**

Files to touch:

- MET action runner (`reveal_tiles` writes fog's revealed set; new `light` action)
- the `map_objects` model (brazier subtype + `lit` + `vision_radius`)
- the fog service (union lit-brazier discs + event-revealed regions)
- `scripts/tests/test_map_events.gd`, `test_fog_of_war.gd`

Implementation steps:

1. **Event rooms:** MET `reveal_tiles` adds its tiles to fog's **persistent
   revealed set**; re-reveals on load from `map_events_fired` (zero new field,
   `[FOW-5]`).
2. **Braziers (`[FOW-7]`):** a `map_objects` entry with runtime `lit: bool` +
   `vision_radius`; while lit, its tile contributes a vision disc to the visible
   union. Lit state persists in `map_objects_state` (zero new field).
3. **Lighting:** an adjacent unit spends its action to light (reuse DCH's
   adjacent-interact seam); a MET `light` action lights/pre-lights (folds into MET's
   vocabulary next to `reveal_tiles`). One-way latch (`[FOW-7]`).

Tests:

- A `reveal_tiles` event adds tiles to the revealed set; they survive save/load via
  `map_events_fired`.
- A lit brazier contributes its `vision_radius` disc; its `lit` state survives
  round-trip via `map_objects_state`; lighting is one-way.

F1 obligations: none new — rooms/braziers derive from already-reserved
`map_events_fired` / `map_objects_state`.

DoD#1 obligations: update `GDD_06` (authored reveal tools) + the MET action list in
`GDD_08` (add `light`) + flip `GDD_10`.

DoD#2 obligations: if the MET action vocabulary has a `check_docs` guard, add
`light` to its enumerated set.

## Implementation Commit Order

1. Slice 1 vision seam + visible set (headless; needs `MapData.fog_enabled`).
2. Slice 2 render fog mask + enemy hiding (editor step; coordinate `OVERLAY_FOG`
   source 5 with MRD's source 4).
3. Slice 3 reveal-on-move + ambush interrupt (the real complexity).
4. Slice 4 AI-cheats verification (no behavior change).
5. Slice 5 `discovered_units` save — **trails `B1-SUSPEND`**.
6. Slice 6 authored reveal tools — rooms trail `B3-MET`, braziers trail
   `B4-MAP-OBJECTS`.

Slices 1-4 are buildable against the live tree once `fog_enabled` exists. Slice 5
trails suspend; slice 6 trails MET/DCH.

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
