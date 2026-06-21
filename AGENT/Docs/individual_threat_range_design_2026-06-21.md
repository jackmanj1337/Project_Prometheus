# Individual Unit Threat Range — Design — 2026-06-21

Status: Target design
Last verified: 2026-06-21

Designs the per-enemy threat-range overlay. Small, self-contained — and a **prerequisite**
for the gamepad contextual R3 danger-zone (`gamepad_layer_implementation_plan_2026-06-20.md`
§4: "R3 over an enemy → that enemy's threat range — does not exist yet").

Coupled work:
- `AGENT/Docs/gamepad_layer_implementation_plan_2026-06-20.md` §4 — the contextual R3 arm
  that consumes this; its per-enemy branch is gated on this design.

> **Tracking home:** GDD_10 → *Open Items Register* §A (UI/UX) + Appendix C. Docs-only until
> the open decisions (§7) resolve.

## 1. What exists today (verified 2026-06-21)

The per-unit threat computation **already exists, embedded** inside the faction-wide
function — `GridManager.get_enemy_danger_tiles(viewer_faction)` loops every hostile,
attack-capable enemy and, per enemy, does exactly the per-unit calc we need:

```gdscript
var move_tiles := get_movement_range(u)
if not move_tiles.has(u.tile_position):
    move_tiles.append(u.tile_position)
for t in get_all_attack_tiles(u, move_tiles):
    seen[t] = true
```

So the threat area of *one* unit = reachable tiles (incl. staying put) ∪ attack reach from
all of them. Other relevant facts:
- **Render** — `_paint_overlay(tiles, OVERLAY_DARK_RED)` via `show_enemy_danger_zone`; four
  overlay tile sources exist (`0 blue / 1 red / 2 heal / 3 dark_red`). Faction danger uses
  source 3.
- **Trigger** — `MapCursor._toggle_danger_zone()` flips a binary overlay on/off, **FREE
  state only** (a selected unit's movement range owns the overlay otherwise). Bound to
  `show_danger_zone` (Q) and middle-mouse (MMB).
- **Cursor → unit** — `_grid.get_unit_at(current_tile)` returns the unit under the cursor
  (or `null`). `_controlling_faction` is the perspective ("danger to whom").
- **Hostility** — routed through `GameState.are_hostile(viewer_faction, team)` with a
  headless fallback (different team = hostile).

## 2. The extraction (core change)

Pull the embedded per-unit calc into a reusable, pure helper and have the faction function
call it — no behaviour change to the faction overlay, new capability unlocked:

```gdscript
# The threat area of a single unit: every tile it could reach (incl. staying put)
# and the attack reach from all of them. Empty if the unit can't attack.
func get_unit_threat_tiles(unit: Node) -> Array[Vector2i]:
    if unit == null or unit.data == null or unit.data.hp <= 0:
        return []
    if not _equipped_can_attack(unit):
        return []
    var move_tiles := get_movement_range(unit)
    if not move_tiles.has(unit.tile_position):
        move_tiles.append(unit.tile_position)
    return get_all_attack_tiles(unit, move_tiles)
```

`get_enemy_danger_tiles` then becomes: for each hostile attack-capable enemy, union
`get_unit_threat_tiles(u)` into `seen`. Identical output, deduped as today. This is a pure
refactor of existing logic + one new public entry point — the cheapest possible base.

## 3. Contextual resolver (shared by mouse + gamepad)

One resolver decides per-unit vs faction-wide from the cursor's hovered tile, so the
**same** code path serves MMB and the gamepad R3 (the gamepad plan's "parity" goal):

```
resolve_danger_target(cursor_tile, viewer_faction):
    u := grid.get_unit_at(cursor_tile)
    if u != null and is_hostile(u, viewer_faction) and u can attack:
        return per-unit   → get_unit_threat_tiles(u)
    else:
        return faction    → get_enemy_danger_tiles(viewer_faction)
```

This lives where MapCursor can call it on toggle. `_toggle_danger_zone()` changes from
"always faction-wide" to "resolve from `current_tile`": toggling on while the cursor is
over a hostile, attack-capable enemy paints that enemy's threat; otherwise the faction
overlay, exactly as today. Off-toggle and the FREE-state / input-suppressed guards are
unchanged.

> **Binding note:** the backlog phrase "parity with the mouse right-click" predates the
> current bindings — `show_danger_zone` is **MMB** today (RMB is `cancel`). This design
> makes the **existing MMB toggle** contextual (not RMB), matching the gamepad R3. Whether
> to also add a separate hover/RMB affordance is **[TUR-1]**.

## 4. Render

Per-unit threat reuses **`OVERLAY_DARK_RED`** (source 3) — no new tile source, no editor
change. The context (you toggled while over a specific enemy) communicates whose threat it
is. A **distinct colour for individual threat** and/or highlighting the source enemy is
polish, gated as **[TUR-2]** (would add a 5th overlay source in the editor).

## 5. Interaction / state semantics

The danger zone is a binary toggle that paints once and does not track cursor movement.
With a contextual target this raises a question: after toggling on over enemy A, moving
the cursor to enemy B does **not** repaint under today's model. Two options, **[TUR-3]**:

- **Static (matches today, recommended first cut):** paint on toggle from the then-current
  tile; to retarget, toggle off and on again. Zero new wiring.
- **Live-follow (nicer UX, more cost):** while danger mode is on, repaint as the cursor
  moves over different enemies / off all enemies. Needs a hook into cursor movement +
  repaint-throttling.

Everything else (FREE-state-only, drop on input-suppress / selection / phase change) is
inherited unchanged from the existing toggle.

## 6. Headless test plan

Extend `test_grid_manager` (the faction-danger suite):
- `get_unit_threat_tiles(unit)` returns reach ∪ attack-from-reach for an armed enemy;
  `[]` for a healer / dead / null unit.
- `get_enemy_danger_tiles` output is **unchanged** after the refactor (regression — same
  tile set for a fixture with ≥2 enemies; proves the extraction is behaviour-preserving).
- The contextual resolver: cursor over a hostile attack-capable enemy → that enemy's tiles;
  over an ally / empty / healer-enemy tile → faction set.

**Live-verify only:** the overlay paint, the toggle feel, and (if [TUR-3]=live) the
follow-repaint.

## 7. Open decisions

Small enough to keep inline (recommendations given; resolve before coding):

- **[TUR-1] Affordance** — make only the existing MMB/`show_danger_zone` toggle contextual
  (Recommended — matches the gamepad R3, zero new bindings), **or** also add a separate
  hover/RMB preview for individual threat. *Rec: contextual toggle only for v1; revisit a
  hover preview with the "map readability" UI/UX bundle.*
- **[TUR-2] Render distinction** — reuse `OVERLAY_DARK_RED` (Recommended — no editor change)
  **or** add a 5th overlay source for a distinct individual-threat colour + source-enemy
  highlight (polish). *Rec: reuse dark-red now; distinct colour is later polish.*
- **[TUR-3] Retarget semantics** — static paint-on-toggle (Recommended — matches today's
  model, no new wiring) **or** live-follow repaint as the cursor moves. *Rec: static first
  cut; live-follow as an enhancement.*

## 8. Build slices

1. **Extraction + faction regression** — §2: `get_unit_threat_tiles` + refactor
   `get_enemy_danger_tiles` to use it; headless regression proves no faction-overlay change.
   Pure logic, fully independent, lands the reusable primitive.
2. **Contextual resolver + MMB wiring** — §3: resolver + `_toggle_danger_zone` retarget
   (static, [TUR-3]=static). After this the mouse shows individual threat.
3. **Gamepad R3 arm** — hand off to `gamepad_layer_implementation_plan_2026-06-20.md` §4:
   bind R3 through the same resolver. (Lands with the gamepad layer, not here.)

Slice 1 is the immediate win and unblocks nothing-else-needed testing. Slice 2 delivers the
player-visible feature. Slice 3 is the gamepad consumer.

## 9. Definition of done

- DoD#1: update GDD_07 (threat-range / danger-zone UI section gains the per-enemy mode) +
  flip the GDD_10 Open Items Register row (UI/UX individual threat range) and the gamepad
  §4 dependency edge in the same commit.
- DoD#2: no new fixed-value vocabulary, so no new `check_docs` guard required.
- Tests: §6 headless coverage green; full suite + `check_docs` green per commit.
