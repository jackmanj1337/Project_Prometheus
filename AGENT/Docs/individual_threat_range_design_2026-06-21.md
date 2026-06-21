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

## 3. Interaction model — watch set + display-mode cycle ([TUR-3] resolved)

Two orthogonal pieces of state, both driven by the **single `show_danger_zone` action**
(MMB / gamepad R3), branching on whether the cursor is over a hostile enemy:

- **`_watch_set`** — a persistent set of hostile enemies the player has hand-picked.
  **MMB over a hostile, attack-capable enemy toggles that enemy's membership** (add if
  absent, remove if present). Persistent: it does **not** follow the cursor; it stays until
  the player removes members or a drop event fires (§5).
- **`_danger_mode`** — the overlay display mode, one of **`full | selected | combined |
  none`**. **MMB over empty / non-enemy terrain cycles** it `full -> selected -> combined ->
  none -> full ...`. Starts at `none` (overlay off, matching today's "off" default).

A single resolver routes the press, so the **same** path serves MMB and the gamepad R3
(the gamepad plan's "parity" goal):

```
on show_danger_zone press, FREE state only:
    u := grid.get_unit_at(cursor_tile)
    if u != null and is_hostile(u, viewer_faction) and _equipped_can_attack(u):
        toggle u in _watch_set          # edit the watch set
    else:
        _danger_mode = next in [full, selected, combined, none]   # cycle display
    repaint()                            # see section 4
```

What each mode paints (`repaint()`):

| `_danger_mode` | Faction layer (dark red, src 3) | Watch layer (darker red, src 4) |
|---|---|---|
| `full` | all hostile enemies' threat | — |
| `selected` | — | union of `_watch_set` threat |
| `combined` | all hostile enemies' threat | watch set, **painted on top** |
| `none` | — | — |

**Watched-enemy markers** render whenever `_watch_set` is non-empty — independent of the
mode — so the player always sees *which* enemies are selected even in `none`/`full` (a
membership edit always gives feedback). See section 4.

> **Binding note:** the backlog phrase "parity with the mouse right-click" predates the
> current bindings — `show_danger_zone` is **MMB** today (RMB is `cancel`). This design uses
> the **existing MMB / R3 action** for both the set edit and the mode cycle ([TUR-1]:
> contextual MMB only, no separate hover/RMB affordance).

> **[TUR-4] (minor, open):** when the player adds the first enemy to the watch set while
> `_danger_mode` is `none` or `full`, do we auto-promote the mode to show it (`combined`),
> or keep the controls orthogonal (membership edit only; marker shows, threat tiles don't
> until they cycle)? *Rec: keep orthogonal — markers give feedback; auto-promote is a
> surprise jump. Cheap to revisit live.*

## 4. Render ([TUR-2] resolved → distinct darker red + watched markers)

Three render pieces:

1. **Faction layer — dark red (source 3, existing).** The `full`/`combined` faction cloud.
2. **Watch layer — a distinct *darker* red (new source 4, `OVERLAY_DARKER_RED`).** The
   `selected`/`combined` watch-set threat. Adding source 4 to the overlay `TileMapLayer` is
   an **editor step** (author/assign the tile) on top of the code constant.
3. **Watched-enemy markers (new).** A per-unit marker so the player sees *which* enemies are
   in `_watch_set` (not just their threat tiles). Rendered on each watched enemy's tile/unit
   whenever the set is non-empty. The exact visual (a badge tile, a sprite outline, or a
   modulate tint) is an implementation/asset detail — **needs a small asset** if a badge
   tile is chosen. Recommend a lightweight unit-modulate or a dedicated marker tile so it
   reads on top of any terrain.

**Paint order (matters for `combined`):** `repaint()` clears the overlay, paints the faction
layer first (source 3), then the watch layer on top (source 4) so a watched enemy's tiles
show darker-red *within* the broader faction cloud. The overlay is a single `TileMapLayer`,
so a later `set_cell` wins per tile — faction-then-watch ordering is the whole mechanism.
Watched markers paint last (they sit on unit tiles, not threat tiles).

Performance: cache the faction tile set when entering `full`/`combined` (it loops every
enemy — the expensive call); recompute only the cheap per-unit watch union on a membership
edit. A `_watch_set` edit while in `full` doesn't recompute faction at all.

## 5. State semantics

Two members replace the old single `_danger_zone_shown` bool on `MapCursor`:

- **`_danger_mode: String`** = `none | full | selected | combined` (default `none`).
- **`_watch_set`** = the picked enemies (store unit refs, or stable unit ids if refs can go
  stale on death — see drop rules). Persistent across cursor moves.

**The set does not follow the cursor** (that was the rejected live-follow model) — it only
changes on an explicit MMB-over-enemy edit. The cursor moving never repaints.

**Drop / clear rules (extend today's danger-zone teardown):**
- **FREE state only** — both controls are inert outside FREE (the overlay layer is owned by
  a selected unit's movement range otherwise), exactly as the current toggle.
- **On input-suppress / unit selection / phase change** — clear the overlay paint *and*
  reset `_danger_mode = none`. **Open sub-point:** does `_watch_set` *membership* also clear,
  or persist across these so the player's hand-picked set survives a phase? *Rec: clear the
  paint + mode every time (matches today's "no stale overlay" guarantee), but **persist the
  membership** within a map so the set isn't lost on every menu open; clear membership on
  map load / objective change. Confirm live — folded into [TUR-4]'s family of polish calls.*
- **Dead / removed watched enemy** — prune it from `_watch_set` on death so a stale ref
  never paints (storing a unit id + validating on repaint is the safe form).

A `repaint()` helper centralises the §3 table + §4 paint order; every edit/cycle/drop calls
it (or `clear_overlays()` for `none`).

## 6. Headless test plan

Extend `test_grid_manager` (the faction-danger suite):
- `get_unit_threat_tiles(unit)` returns reach ∪ attack-from-reach for an armed enemy;
  `[]` for a healer / dead / null unit.
- `get_enemy_danger_tiles` output is **unchanged** after the refactor (regression — same
  tile set for a fixture with ≥2 enemies; proves the extraction is behaviour-preserving).

Extend `test_map_cursor` (the interaction state):
- **Press routing** — MMB over a hostile attack-capable enemy edits `_watch_set` (adds, then
  removes on a second press); over empty / ally / healer-enemy cycles `_danger_mode`
  `none→full→selected→combined→none`.
- **Watch-set membership** — toggling two enemies builds a 2-member set; `selected` paints
  exactly their union; `combined` paints faction ∪ watch with watch tiles winning the shared
  cells (assert source 4 on an overlapping tile).
- **Drop rules** — selection / input-suppress / phase change resets `_danger_mode=none` and
  clears the paint; membership persistence follows the §5 rec.
- **Prune on death** — a watched enemy dying is removed from `_watch_set` (no stale paint).

**Live-verify only:** the actual overlay colours, the darker-red distinction, the watched-
enemy marker visual, and the feel of the cycle.

## 7. Open decisions

Small enough to keep inline (recommendations given; resolve before coding):

- **[TUR-1] Affordance — ✅ RESOLVED 2026-06-21 → contextual MMB toggle only.** The existing
  `show_danger_zone` / MMB toggle becomes contextual (over enemy = per-unit, else faction);
  the same resolver backs the gamepad R3. No separate hover/RMB preview.
- **[TUR-2] Render distinction — ✅ RESOLVED 2026-06-21 → distinct *darker* red** (new 5th
  overlay source `OVERLAY_DARKER_RED`; editor step required). See §4.
- **[TUR-3] Interaction model — ✅ RESOLVED 2026-06-21 → persistent watch set + display-mode
  cycle** (not static-vs-live-follow). MMB over an enemy adds/removes it from a persistent
  `_watch_set`; MMB over empty terrain cycles `_danger_mode` through `full | selected |
  combined | none`; watched enemies get a marker; faction + watch layer both shown in
  `combined`, layered (§3, §4, §5).
- **[TUR-4] Polish details — OPEN (minor, recommendations given, tune live):** (a) auto-
  promote the mode when the first enemy is added vs. keep controls orthogonal (rec:
  orthogonal); (b) `_watch_set` membership lifetime across menu/phase (rec: persist within a
  map, clear on map load); (c) the exact watched-enemy marker visual + whether it needs a new
  asset (rec: lightweight modulate/marker tile). All cheap to settle during slice 2 live-verify.

## 8. Build slices

1. **Extraction + faction regression** — §2: `get_unit_threat_tiles` + refactor
   `get_enemy_danger_tiles` to use it; headless regression proves no faction-overlay change.
   Pure logic, fully independent, lands the reusable primitive.
2. **Watch set + mode cycle + render** — §3 resolver replacing `_toggle_danger_zone`, the
   `_danger_mode`/`_watch_set` state (§5), the `repaint()` helper + paint order (§4), the new
   `OVERLAY_DARKER_RED` source, and the watched-enemy marker. **Editor/asset steps:** author
   the source-4 darker-red tile and the marker visual. After this the mouse drives the full
   feature. (Settle [TUR-4]'s polish details during this slice's live-verify.)
3. **Gamepad R3 arm** — hand off to `gamepad_layer_implementation_plan_2026-06-20.md` §4:
   bind R3 through the same resolver (R3-over-enemy edits the set, R3-over-empty cycles the
   mode). (Lands with the gamepad layer, not here.)

Slice 1 is the immediate, fully-headless win (the reusable primitive + regression). Slice 2
delivers the player-visible feature (some live-verify for colours/marker). Slice 3 is the
gamepad consumer.

## 9. Definition of done

- DoD#1: update GDD_07 (threat-range / danger-zone UI section gains the watch-set + mode
  cycle) + flip the GDD_10 Open Items Register row (UI/UX individual threat range) and the
  gamepad §4 dependency edge in the same commit.
- DoD#2: `_danger_mode` is a small fixed value-set (`none|full|selected|combined`) — if it is
  documented in GDD_07 as canonical, add a `check_docs` guard mirroring the mouse-cursor
  value-set check (parse a `const` array, assert GDD lists each). Confirm at implementation.
- Editor/asset: the source-4 darker-red overlay tile and the watched-enemy marker are
  authored before slice 2 can be live-verified.
- Tests: §6 headless coverage green; full suite + `check_docs` green per commit.
