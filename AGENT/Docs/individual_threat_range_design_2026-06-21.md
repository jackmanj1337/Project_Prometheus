---
Type: design
Status: Target design
Last verified: 2026-06-23
---

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

> **Auto-promote / demote ([TUR-4] resolved → auto).** The watch layer turns on when the
> set goes empty→non-empty and off when it goes non-empty→empty, **without clobbering the
> faction layer** the player may have had on:
> - **First enemy added:** `none → selected`; `full → combined`. (`selected`/`combined`
>   unchanged.)
> - **Last enemy removed:** `selected → none`; `combined → full`. (`none`/`full` unchanged.)
>
> The manual MMB-over-empty cycle (`full→selected→combined→none→…`) still works on top of
> this; auto only fires on the empty↔non-empty transition.

## 4. Render ([TUR-2] resolved → distinct darker red + watched markers)

Three render pieces:

1. **Faction layer — dark red (source 3, existing).** The `full`/`combined` faction cloud.
2. **Watch layer — a distinct *darker* red (new source 4, `OVERLAY_DARKER_RED`).** The
   `selected`/`combined` watch-set threat. Adding source 4 to the overlay `TileMapLayer` is
   an **editor step** (author/assign the tile) on top of the code constant.
3. **Watched-enemy markers ([TUR-4] resolved → small "D").** Each watched enemy gets a small
   **"D"** glyph in the **bottom-right corner of its tile**, rendered whenever it is in
   `_watch_set` (independent of `_danger_mode`, so the set is always legible). A text glyph
   needs **no new tile asset** — a small `Label`/drawn glyph anchored to the tile's
   bottom-right is enough. **Placeholder:** flagged for the UI polish pass to review and
   likely swap for a small eye (or similar) icon. (The darker-red overlay tile in piece 2
   still needs authoring; the marker does not.)

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
- **`_watch_set`** = the picked enemies, stored as **stable unit ids** (not raw refs) so a
  defeated enemy can be pruned and a save can round-trip them. Persistent across cursor
  moves, menus, phases, and save/load (see persistence).

**The set does not follow the cursor** (the rejected live-follow model) — it changes only on
an explicit MMB-over-enemy edit, which runs the auto-promote/demote rule (§3).

**Persistence ([TUR-4] resolved → survives phases + mid-map save/load):**
- **`_watch_set` and `_danger_mode` persist across phase changes, menus, and unit selection
  within a map.** They are **not** reset by the teardown anymore.
- **What teardown clears is only the *paint*, never the state.** Entering a non-FREE /
  input-suppressed state (enemy phase, map menu) or selecting a unit (whose movement range
  owns the overlay) calls `clear_overlays()` for the visual but **retains** `_watch_set` +
  `_danger_mode`. Returning to FREE calls `repaint()`, which **recomputes from current unit
  positions** — so a post-enemy-phase repaint is fresh, never stale (the original reason the
  old toggle reset). FREE-state-only interaction is unchanged.
- **Map load / new map:** `_watch_set` clears and `_danger_mode → none` (different enemies).
- **Mid-map suspend save:** `_watch_set` (+ `_danger_mode`) are **serialized into the
  suspend snapshot and restored on load**, then `repaint()`. This adds a small field to the
  battle-state serializer — a **forward dependency on the campaign/save cluster** (§2
  "mid-battle suspend save"); recorded there. Until that serializer exists, the set lives at
  runtime only (still survives phases/menus, just not a save).

**Defeated enemies:** on a watched enemy's death, prune its id from `_watch_set`; if that
empties the set, the auto-demote rule (§3) fires (`selected→none` / `combined→full`).

A `repaint()` helper centralises the §3 mode table + §4 paint order + markers; every
edit / cycle / auto-promote-demote / return-to-FREE / load calls it (or `clear_overlays()`
for the `none` paint).

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
- **Auto-promote / demote** — adding the first enemy: `none→selected`, `full→combined`;
  removing the last: `selected→none`, `combined→full`; `selected`/`combined` (resp.
  `none`/`full`) unchanged on add (resp. remove).
- **Persistence** — selection / input-suppress / phase change clears the *paint* but
  **retains** `_watch_set` + `_danger_mode`; a return-to-FREE `repaint()` recomputes from
  current positions (assert fresh tiles after moving an enemy). Map load clears the set.
- **Prune on death** — a watched enemy dying is removed from `_watch_set` (no stale paint);
  if it was the last member, auto-demote fires.
- **Save round-trip** (with the §2 serializer, when it lands) — `_watch_set` + `_danger_mode`
  survive a suspend/resume.

**Live-verify only:** the actual overlay colours, the darker-red distinction, the "D"
marker, and the feel of the cycle.

## 7. Decisions — all resolved (2026-06-21)

- **[TUR-1] → contextual MMB only.** The `show_danger_zone` action (MMB / R3) drives
  everything; no separate hover/RMB. Same resolver backs the gamepad R3.
- **[TUR-2] → distinct *darker* red** watch layer (new 5th overlay source
  `OVERLAY_DARKER_RED`; editor step) + watched-enemy markers. See §4.
- **[TUR-3] → persistent watch set + display-mode cycle.** MMB over an enemy adds/removes it
  from a persistent `_watch_set`; MMB over empty cycles `_danger_mode`
  `full|selected|combined|none`; faction + watch shown layered in `combined` (§3, §4, §5).
- **[TUR-4] → resolved:** (a) **auto-promote/demote** the watch layer on the empty↔non-empty
  transition (§3); (b) **defeated enemies are pruned** from the set (§5); (c) the set +
  mode **survive phases and mid-map save/load** (§5; serialization is a forward dep on §2);
  (d) marker = a **small "D" bottom-right of the tile**, a placeholder to review in the UI
  polish pass (likely an eye icon).

## 8. Build slices

1. **Extraction + faction regression** — §2: `get_unit_threat_tiles` + refactor
   `get_enemy_danger_tiles` to use it; headless regression proves no faction-overlay change.
   Pure logic, fully independent, lands the reusable primitive.
2. **Watch set + mode cycle + render** — §3 resolver replacing `_toggle_danger_zone`, the
   `_danger_mode`/`_watch_set` state + auto-promote/demote + prune-on-death + the
   paint-only/retain-state persistence across phases (§5), the `repaint()` helper + paint
   order (§4), the new `OVERLAY_DARKER_RED` source, and the "D" marker. **Editor step:**
   author the source-4 darker-red overlay tile (the "D" marker is text — no asset). After
   this the mouse drives the full feature; runtime persistence covers phases/menus.
3. **Gamepad R3 arm** — hand off to `gamepad_layer_implementation_plan_2026-06-20.md` §4:
   bind R3 through the same resolver (R3-over-enemy edits the set, R3-over-empty cycles the
   mode). (Lands with the gamepad layer, not here.)
4. **Save serialization** — add `_watch_set` + `_danger_mode` to the mid-battle suspend
   snapshot. **Belongs to the §2 campaign/save cluster** ("mid-battle suspend save"), not
   this feature; recorded as a forward dependency so it isn't forgotten. Until then the set
   is runtime-only (survives phases, not a save).

Slice 1 is the immediate, fully-headless win (the reusable primitive + regression). Slice 2
delivers the player-visible feature (some live-verify for colours/marker). Slice 3 is the
gamepad consumer; slice 4 is the save-serialization tie-in owned by §2.

## 9. Definition of done

- DoD#1: update GDD_07 (threat-range / danger-zone UI section gains the watch-set + mode
  cycle) + flip the GDD_10 Open Items Register row (UI/UX individual threat range) and the
  gamepad §4 dependency edge in the same commit.
- DoD#2: `_danger_mode` is a small fixed value-set (`none|full|selected|combined`) — if it is
  documented in GDD_07 as canonical, add a `check_docs` guard mirroring the mouse-cursor
  value-set check (parse a `const` array, assert GDD lists each). Confirm at implementation.
- Editor: the source-4 darker-red overlay tile is authored before slice 2 can be
  live-verified (the "D" marker is text — no asset).
- Forward dep: the §2 mid-battle suspend serializer must include `_watch_set` + `_danger_mode`
  (slice 4); flag it in the §2 plan when that cluster is written.
- Tests: §6 headless coverage green; full suite + `check_docs` green per commit.
