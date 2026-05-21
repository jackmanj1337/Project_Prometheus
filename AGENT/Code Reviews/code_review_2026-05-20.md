# Code Review — 2026-05-20 (M16 Objective System)

**Scope:** the M16 Objective System changeset, commits `316e509..a104a96` on `main`
(stages 1-5; 20 files, +1,450 / −63 lines). Working tree is clean; no PRs open.

**Files reviewed (production):**

- `scripts/resources/ObjectiveCondition.gd` (new)
- `scripts/resources/MapData.gd`
- `scripts/core/TurnManager.gd` (the bulk of the change)
- `scripts/core/EnemyAI.gd`
- `scripts/core/MapCursor.gd`
- `scripts/ui/ActionMenu.gd`, `scripts/ui/GameOverScreen.gd`, `scripts/ui/HUD.gd`
- `scripts/autoloads/EventBus.gd`
- `data/maps/map_001_rout/map_001_data.tres`

Tests, session notes, and the class cache were skimmed but not graded.

---

## 1. Executive Summary

**Overall rating: 8 / 10.**

A clean milestone. The legacy three-field objective model has been replaced
with a typed, per-alliance-group condition system that scales to N factions and
seven condition types, while keeping the existing blue-perspective signals
intact for the GameOverScreen. The five-stage commit cadence, the up-front
legacy-translation bridge, and the +27-test growth make this one of the
lower-risk large refactors in the repo. The header comments on
`ObjectiveCondition`, `MapData.victory_conditions`, and
`TurnManager.check_victory_conditions` are unusually good — they read like a
spec, not a diary.

Biggest concerns are (a) a real player-visible bug in the auto-escape flow
when an escape fires mid-move under the MapCursor controller, and (b) some
tight coupling to `GameState._units_by_faction` (a leading-underscore private)
that the evaluator now reaches into from five places.

---

## 2. Issues Found

### **[HIGH] Auto-escape leaves the MapCursor flow showing an ActionMenu for a unit that has been `queue_free()`'d**

- **File & Line:** `scripts/core/TurnManager.gd:828-843` (`record_escape`) and
  `scripts/core/MapCursor.gd:487-496` (`_try_move_selected_to_cursor`).
- **Problem:** The chain is:
  1. `MapCursor._try_move_selected_to_cursor` does
     `await _selection.selected_unit.move_along_path(path)`.
  2. `Unit.move_along_path` emits `bus.unit_moved` after the tween finishes
     (`scripts/units/Unit.gd:468`).
  3. `TurnManager._on_unit_moved` runs synchronously, matches an escape
     condition, calls `record_escape(unit)`, which calls
     `gs.unregister_unit(unit)` and `unit.queue_free()`.
  4. The signal returns, `move_along_path` returns, the `await` resumes — and
     MapCursor unconditionally enters `State.UNIT_MOVED` and calls
     `_show_action_menu()` on the escaped (queue-freed) unit.
  `queue_free()` is deferred to the next idle frame, so this won't necessarily
  crash, but the player will see the Attack/Wait menu for a unit that just
  walked off the map; if they pick anything, `_finish_action()` re-inserts the
  freed unit into `TurnManager._unit_states` via `set_unit_state(DONE)`. The
  M16 test only exercises `record_escape` directly, not through the
  cursor-driven path, so this slipped through.
- **Root Cause:** `record_escape` is now a path that frees the unit and
  modifies game state from inside an `await`-bracketed cursor flow, but the
  cursor flow doesn't re-validate `_selection.selected_unit` after its move
  await — historically there was no way for the unit to disappear during its
  own move.
- **Recommended Fix:** Re-validate after the move await before showing the
  ActionMenu:

  ```gdscript
  func _try_move_selected_to_cursor() -> void:
      var path := _selection.plan_path_to(current_tile)
      if path.is_empty():
          return
      _state = State.LOCKED
      await _selection.selected_unit.move_along_path(path)
      # An auto-escape (or any future "remove on move") could have freed the
      # unit during the move await. Drop back to FREE if so.
      var u := _selection.selected_unit
      if u == null or not is_instance_valid(u) or u.data == null or u.data.hp <= 0:
          _selection.clear()
          _state = State.FREE
          return
      _state = State.UNIT_MOVED
      _show_action_menu()
  ```

  Also add a cursor-driven regression test in `test_turn_manager.gd` or a
  cursor test that drives `move_along_path` and asserts the cursor returns to
  `FREE` with no ActionMenu shown.
- **Tradeoffs:** None substantive — the new guard is cheap. Alternative
  designs (have `record_escape` defer the free until end-of-frame, or have
  MapCursor own escape) are larger and not warranted here.

### **[MEDIUM] `check_victory_conditions` reaches into `GameState._units_by_faction` directly from five places**

- **File & Line:** `scripts/core/TurnManager.gd:564, 638, 640, 646, 745, 763`.
- **Problem:** The evaluator iterates `gs._units_by_faction.keys()` to list
  every registered faction. By Godot convention the leading underscore marks
  this dict as private to GameState; the evaluator reaching in encodes
  GameState's storage layout into TurnManager. Already five sites use it, and
  the upcoming M14 stage 4 work (faction-agnostic AI) is likely to add more.
- **Root Cause:** No public "list every registered faction id" accessor on
  GameState yet — pre-M16 the only thing that cared was the blue/red
  bookkeeping.
- **Recommended Fix:** Add `get_registered_faction_ids() -> Array[String]` on
  GameState that returns `_units_by_faction.keys()` typed, and route the five
  sites through it. The change is mechanical and keeps the evaluator
  decoupled from how GameState stores the buckets (a future move to a flat
  list or to per-faction Nodes wouldn't ripple).
- **Tradeoffs:** None — the accessor is a one-liner and the call sites are
  isolated.

### **[MEDIUM] `_eval_rout(faction_id=X)` silently passes when X is neither a registered faction id nor an alliance group**

- **File & Line:** `scripts/core/TurnManager.gd:635-651`.
- **Problem:** If `cond.faction_id` is a typo (`"reds"` instead of `"red"`)
  or refers to a faction that was never registered on this map, the function
  falls through both branches and returns `true` — i.e. "rout of nobody" is
  vacuously met, fires `map_victory`, and ends the map on turn 1. There is
  no warning. Most rout conditions today author `faction_id == ""` which is
  the safe path, but stage-4+ maps are expected to start naming factions
  directly.
- **Root Cause:** The fallback "treat as group name" branch silently returns
  `true` when no faction matches the group either — there's no
  "neither matched" state.
- **Recommended Fix:** In the second branch, track whether at least one
  faction matched the group; if zero matched, log a `push_warning` and return
  `false` (unmet) — that surfaces the typo without crashing.

  ```gdscript
  var matched := false
  for fid in gs._units_by_faction.keys():
      if gs.get_alliance_group(fid) == cond.faction_id:
          matched = true
          if not gs.get_living_units_of(fid).is_empty():
              return false
  if not matched:
      push_warning("ObjectiveCondition rout: faction_id '%s' matches no faction or group" % cond.faction_id)
      return false
  return true
  ```

  The eventual `DataManager` validation pass noted in
  `TurnManager._conditions_for_group:580` is the better long-term home, but
  a runtime warning costs nothing and catches it today.
- **Tradeoffs:** A map author who deliberately authors `rout("future_faction")`
  to mean "satisfied when that faction doesn't exist yet" would now have to
  reverse the condition. Not a known use case.

### **[MEDIUM] Redundant guard in the implicit "group routed" default append**

- **File & Line:** `scripts/core/TurnManager.gd:455-458`.
- **Problem:**

  ```gdscript
  if _conditions_for_group(_map_data.defeat_conditions, g).size() == 0 \
          and (defeat_by_group[g] as Array).is_empty():
      (defeat_by_group[g] as Array).append(_implicit_group_routed_condition())
  ```

  `defeat_by_group[g]` was assigned from `_conditions_for_group(...)` four
  lines above and not mutated since — the two predicates are equivalent. A
  reader has to puzzle for a moment about whether they can ever diverge; they
  can't.
- **Root Cause:** Probably belt-and-braces during stage 2's bootstrap.
- **Recommended Fix:** Keep one clause — the `defeat_by_group[g].is_empty()`
  read is the one the comment is really about ("only when the group has no
  other way out"). The `_conditions_for_group(...).size() == 0` clause can
  be dropped.
- **Tradeoffs:** None.

### **[LOW] `ObjectiveCondition.tiles` semantics for `seize` quietly assume exactly one tile in `get_display_text`**

- **File & Line:** `scripts/resources/ObjectiveCondition.gd:63-66`.
- **Problem:**

  ```gdscript
  "seize":
      if tiles.is_empty():
          return "Seize"
      return "Seize %s" % str(tiles[0])
  ```

  The evaluator allows multi-tile seize zones (`_eval_seize` walks
  `_seize_records` against `tile in cond.tiles`), but the HUD only ever
  names the first tile. A two-tile seize condition reads as if only one
  tile satisfies it.
- **Recommended Fix:** Either format the tile list (`"Seize %s" % ", ".join(...)`)
  or strip the coordinate entirely (`"Seize tile"` / `"Seize %d tiles" % tiles.size()`).
  Coordinate strings are noisy for players anyway; a named landmark would
  be nicer if `MapData` ever grows tile-name metadata.
- **Tradeoffs:** Truncating loses some info; expanding makes the line long.
  Pick whichever the in-progress UI mock prefers.

### **[LOW] `_eval_seize` allow-list grants seize credit to units outside the conditioning group**

- **File & Line:** `scripts/core/TurnManager.gd:705-721`.
- **Problem:** When `cond.allowed_unit_ids` is non-empty, the function
  returns `true` purely on unit_id match without checking the seizing unit's
  faction or alliance group:

  ```gdscript
  if not cond.allowed_unit_ids.is_empty():
      if unit_id in cond.allowed_unit_ids:
          return true
      continue
  ```

  If two factions share a `unit_id` (or a future cross-faction recruit /
  capture mechanic exists), an enemy seizing the same tile under the same
  unit_id would satisfy a victory condition authored for the player's group.
  In practice nothing today triggers `record_seize` for a non-controlling
  faction — `MapCursor._commit_seize` is the only caller — but the can_seize
  ActionMenu gate also runs through this path and could erroneously show the
  Seize button to an enemy under a hotseat / AI flow.
- **Recommended Fix:** Add the conditioning-group check as an AND, not as
  the else-branch:

  ```gdscript
  if not cond.allowed_unit_ids.is_empty() and not (unit_id in cond.allowed_unit_ids):
      continue
  if gs.get_alliance_group(faction) != for_group:
      continue
  return true
  ```

- **Tradeoffs:** Removes the "any unit anywhere with this id can seize for
  this group" authoring shortcut. If a map design wants that, it can name
  the unit's group directly in `for_group`. Worth confirming with the
  author whether that shortcut was intentional.

### **[LOW] `_unit_states` does not get a `record_escape` parallel for `_original_tiles`**

- **File & Line:** `scripts/core/TurnManager.gd:838-840`.
- **Problem:** `record_escape` correctly erases the unit from `_unit_states`
  and `_original_tiles`, but if `record_escape` runs *before* the cursor's
  move-undo flow (it can't today, but the auto-escape path runs immediately
  on the unit_moved emit), `_original_tiles` is now stale-free. Minor — this
  is bookkeeping cleanup that already happens here, but worth a single-line
  comment that the order is `unregister → erase state → erase tile → free`
  precisely so the next reader doesn't reorder them.
- **Recommended Fix:** Leave a one-line comment on the four-step block.
- **Tradeoffs:** None.

### **[LOW] `HUD._build_objective_lines` hardcodes `"allies"` as the fallback blue-group name**

- **File & Line:** `scripts/ui/HUD.gd:83`.
- **Problem:** When GameState is missing (the headless test path),
  `_build_objective_lines` defaults `blue_group = "allies"`. That happens to
  match `FactionData.alliance_group` defaults today, but it's a literal in
  HUD that drifts from the FactionData side if the default ever changes.
- **Recommended Fix:** Use `FactionData`'s default constant if one exists,
  or push the fallback into a `GameState.get_alliance_group_default("blue")`
  one-liner. Low priority — the failure mode is "no objective lines shown"
  rather than a crash.
- **Tradeoffs:** None.

### **[LOW] `_eval_survive`'s `turns` semantics don't match the `protect`-shaped use case implied by `get_display_text`**

- **File & Line:** `scripts/core/TurnManager.gd:740-751` and
  `scripts/resources/ObjectiveCondition.gd:71-74`.
- **Problem:** `_eval_survive` returns `true` once `turn_number > cond.turns`
  — i.e. survive 5 means "satisfied on turn 6, when 5 rounds have completed".
  The display text reads `"Survive %d turn(s)" % turns`. With `turns = 5`,
  the panel says "Survive 5 turn(s)" but the condition fires on the start of
  turn 6. If `turn_number` starts at 1 and ticks at end-of-player-phase,
  that's actually 5 *full* rounds — matches the display text. But if a
  future map design wants "survive 5 enemy phases" or "survive 5 unit
  activations" the same field gets reused with different semantics. Worth
  pinning the unit (rounds, not phases / activations) explicitly in the
  field doc on ObjectiveCondition.
- **Recommended Fix:** Tighten the doc on `turns:` in
  `ObjectiveCondition.gd:44-47` to "completed *rounds*" (matches `turn_number`
  ticking once per full cycle in WHOLE_PHASE) and note the survive helper
  comment's "consecutive rounds" caveat at the field too.
- **Tradeoffs:** None — pure doc tightening.

### **[LOW] `victory_conditions` / `defeat_conditions` are untyped `Dictionary` — losing the schema in the inspector and at validation time**

- **File & Line:** `scripts/resources/MapData.gd:54-55`.
- **Problem:** The dicts are typed `Dictionary` rather than
  `Dictionary[String, Array[ObjectiveCondition]]`. Godot 4.4+ supports
  typed Dictionaries; if the project's minimum is on a version that has
  them, the type would catch the wrong-shape mistakes that
  `_conditions_for_group` defensively filters out. Validation cost is
  meaningful too — DataManager already validates other catalogues; a
  cross-ref check ("every group key matches a FactionData.alliance_group,
  every Array entry is a non-null ObjectiveCondition") would catch typos at
  load instead of silently no-op'ing at runtime.
- **Recommended Fix:** Two paths, either independent: (a) bump the field
  types to `Dictionary[String, Array[ObjectiveCondition]]` if engine version
  permits; (b) extend `DataManager` validation (already done in B6 for
  weapons / skills / items per the recent log) to cover MapData's two new
  dicts in a follow-up stage. The session notes call out the latter as a
  deferred item already.
- **Tradeoffs:** Typed dictionaries can require existing `.tres` files to be
  resaved.

---

## 3. Positive Observations

- **Documentation density at file headers.** `ObjectiveCondition.gd`,
  `MapData.victory_conditions`, `TurnManager.check_victory_conditions`, and
  `_implicit_group_routed_condition` all carry the "why this shape" rationale
  inline — the implicit-default-when-no-defeats rule and the
  `_group_routed` sentinel vs. `rout(faction_id="")` distinction are exactly
  the subtleties a future reader would otherwise have to git-archaeology.
- **The legacy-translation bridge in stages 2-4 → clean delete in stage 5.**
  Carrying `objective_type` / `turn_limit` / `required_survivor_ids` through
  three commits as authored-blue conditions, then deleting them in one
  commit with every test rewritten in the same commit, is exactly the
  textbook approach. No mid-refactor dead code lingers.
- **Defensive `_conditions_for_group`.** Tolerating missing keys, empty
  Arrays (preserving "opt out of implicit routed" semantics), and non-Array
  garbage values is the right level of paranoia for a Resource that an
  inspector user can break in subtle ways. The explicit preservation of
  "authored empty array = opt out, missing key = implicit default" is
  exactly the semantic the spec wants.
- **The Decision 7 chokepoint at `EnemyAI.run_enemy_phase`.** Two `_map_over`
  bails (between units and before `start_player_phase`) close the
  "decided map keeps playing out remaining AI turns" hole cleanly without
  having to thread the check through every AI subroutine.
- **`_build_standings` separates the winner-rank-1 and draw-rank-1 cases
  with one boolean.** Easy to read; the stable sort note matters.

---

## 4. Architectural Observations

- **TurnManager is becoming a kitchen sink.** It is now: phase scheduler
  (M14), per-unit action state owner, per-group victory evaluator (M16),
  seize/escape event recorder, and Decision-7 chokepoint. 900 lines is
  manageable today but the next two milestones (M14 stage 4-5 AI dispatch,
  hotseat) will land here too. A natural seam is to peel the evaluator
  (`check_victory_conditions` + the seven `_eval_*` helpers + the two
  records arrays + the `_group_eliminated_round` dict) into a
  `MapObjectiveEvaluator` RefCounted that TurnManager composes. The
  M14-cadence split-out pattern (MapCursorTargeting / MapCursorSelection /
  MapCursorInput) is the precedent.
- **GameState's faction storage is now reached into directly from five M16
  call sites.** See Issue M-2 — every place that walks "every faction" reads
  `_units_by_faction.keys()`. The right fix is a single `get_registered_faction_ids()`
  accessor; doing it once now keeps the M14-stage-4 dispatch from doubling
  the count.
- **The `can_seize` / `_on_unit_moved` "all conditions across both dicts"
  walk is a different shape than the per-group evaluator.** That's why
  `_all_conditions_of_type` exists. Both shapes are needed (action-time vs.
  evaluation-time), but it's worth making sure future condition types that
  add action-time gates (a "claim" action, say) follow the same split
  rather than reinventing.
- **`ObjectiveCondition` as a single typed Resource was the right call.**
  The header comment names the trade-off ("only the fields relevant to
  `type` are meaningful — the others are inert defaults") and the
  inspector-UX win compounds across the seven types. The alternative class
  hierarchy would have been seven `.gd` files, seven entries in the global
  class cache, and a custom inspector to pick the subclass.

---

## 5. Prioritized Action Plan

1. **Fix the auto-escape mid-move crash window** — guard `_selection.selected_unit`
   with `is_instance_valid` after the `move_along_path` await in
   `MapCursor._try_move_selected_to_cursor`, and add a regression test that
   drives an escape through the cursor (not just `record_escape` direct).
   (Issue H-1.) Highest priority — player-reachable.
2. **Add `GameState.get_registered_faction_ids()` and re-route the five
   M16 call sites.** Drops the five `gs._units_by_faction.keys()` reaches
   into one. (Issue M-2.) Cheap, big readability win.
3. **Add a warning to `_eval_rout` for the "unknown faction id" path.**
   Surface typos at runtime now, even before DataManager learns to validate
   the dicts. (Issue M-3.) One-line `push_warning`.
4. **Drop the redundant clause in the implicit-routed append.** (Issue M-4.)
   Trivial.
5. **Add the group-membership check to `_eval_seize` allow-list path.**
   (Issue L-2.) Confirm with the author that the shortcut was unintentional
   before changing.
6. **Doc tightening on `ObjectiveCondition.turns` and `seize`'s
   multi-tile display text.** (Issues L-1, L-5.) Pure documentation.
7. **(Backlog) Extract `MapObjectiveEvaluator`.** Not load-bearing today,
   but worth queueing before M14 stages 4-5 land more in TurnManager.

---

*Review covers commits `316e509`, `badeec6`, `bd2d12e`, `8fed076`, `a104a96`
on `main`. No deferred follow-ups exist inside M16 per the session notes;
issues raised here are net-new findings, not items the author had flagged.*
