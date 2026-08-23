---
Role: dated
---

# Code Review — 2026-06-10

## 1. Executive Summary

**Overall code quality rating:** 7.5/10

The codebase is in noticeably better shape than even a day ago: the five
2026-06-09 review items all landed cleanly (paired-support filter,
per-faction camera memory, typed DataManager LoadResult, UnitData type
guard in the roster loader, and the Unit.gd direct-access cleanup), and
the result is fewer accidental gotchas in the autoload surface. The big
themes for this in-depth pass are (a) inconsistencies between
*availability* gates and *action* gates that will start firing once
multi-faction hotseat content lands, (b) a real CI coverage gap where
five committed test files never run in `run_tests.sh`, (c) a handful of
defensive paths that disagree with their production counterparts, and
(d) a few content-validation gaps that will manifest as confusing
runtime symptoms rather than authored failures.

Scope: every script under `scripts/` (~7100 lines of core/runtime code,
~10300 lines of tests), `project.godot` autoload + input wiring,
`run_tests.sh`, the pre-commit hook, and `Dockerfile`. Reviewed: combat
and targeting, AI / skill / item dispatch, MapCursor and its three
RefCounted slices, GridManager, autoloads, resource scripts, settings,
shared utils, and test design.

## 2. Issues Found

### 2.1 — Action availability gates disagree across surfaces

**[SEVERITY: Medium]**
- **File & Line:** `scripts/ui/ActionMenu.gd:173`,
  `scripts/core/MapCursorTargeting.gd:234`
- **Problem:** The ActionMenu's Pair Up *visibility* gate
  (`_has_adjacent_unpaired_ally`) and MapCursorTargeting's Pair Up
  *target* gate (`_get_adjacent_unpaired_allies`) duplicate the same
  adjacency walk but disagree on the team check:

  ```gdscript
  # ActionMenu.gd:173 — strict team string compare
  if not ("team" in neighbor) or neighbor.team != unit.team:
      continue
  # MapCursorTargeting.gd:234 — alliance-group hostility
  if _is_target_hostile(neighbor):
      continue
  ```

  Today (blue + red only, no green) the two collapse to the same result.
  Once stage-3 hotseat content lands a green ally adjacent to a blue
  lead, the menu refuses to show Pair Up (strict team) while
  MapCursorTargeting *would* accept the same green ally as a target.
  Either Pair Up will appear unavailable when it should work, or
  (depending on which side gets fixed first) the menu will offer a
  pairing the target gate rejects.
- **Root Cause:** The ActionMenu helper was written under the binary
  blue/red model and was never updated when MapCursorTargeting moved to
  `_is_target_hostile`. The shared duplicated walk is the underlying
  smell — two places must remain in sync.
- **Recommended Fix:** Promote `_get_adjacent_unpaired_allies` to a
  small shared helper (either on `TileActions` next to Seize/Escape, or
  a new `PairUpAvailability.gd` static class) and have both call sites
  use it. As a near-term spot fix, route the ActionMenu helper through
  GameState's `are_hostile`:

  ```gdscript
  # ActionMenu.gd
  var gs := get_node_or_null("/root/GameState")
  ...
  if gs != null and gs.has_method("are_hostile") \
          and gs.are_hostile(unit.team, neighbor.team):
      continue
  # falls back to strict compare only when GameState is absent
  ```

  Add a test that pairs a blue lead with a green ally (mocked
  GameState.are_hostile returning false) and asserts both the menu
  visibility and the target list contain the green unit.
- **Tradeoffs:** Adds a soft GameState dependency to ActionMenu, but
  that dependency is already there for the `pair_up_enabled` flag at
  line 108 — making it carry the hostility lookup too is consistent.

### 2.2 — Pre-commit / CI coverage gap

**[SEVERITY: Medium]**
- **File & Line:** `run_tests.sh:4-36`,
  `scripts/tests/test_attack_preview_position.gd`,
  `scripts/tests/test_attack_preview_selector.gd`,
  `scripts/tests/test_more_info_content.gd`,
  `scripts/tests/test_stat_breakdown.gd`,
  `scripts/tests/test_tile_actions.gd`
- **Problem:** Five committed test files (41 assertions total) exist on
  disk but are NOT enumerated in `run_tests.sh`'s `TESTS=( … )` array, so
  the pre-commit hook never executes them. They all pass when run
  manually, so they aren't broken — they're just silently uncovered.
  Future regressions in AttackPreview positioning / selector cycling,
  More Info content, StatBreakdown formulas, or TileActions gating will
  not block a commit.
- **Root Cause:** Test discovery is manual: the TESTS array is the
  source of truth, and adding a new test file does not automatically
  add it to the runner. A grep-or-glob loop would have caught this at
  author time.
- **Recommended Fix:** Replace the hand-maintained list with a glob
  that picks up every test file:

  ```bash
  TESTS=()
  while IFS= read -r f; do
      TESTS+=("$(basename "$f" .gd)")
  done < <(find scripts/tests -name 'test_*.gd' -type f | sort)
  ```

  Or, more conservatively, add a one-shot sanity step at the top of
  `run_tests.sh` that diffs the array against the on-disk file set and
  errors loud if they disagree. A glob is one-time work; the sanity
  step preserves the explicit-list discipline but forces it to stay
  current.
- **Tradeoffs:** A pure glob loses the explicit ordering the array
  encodes (test_data_layer must run before tests that assume parsed
  fixtures, etc.). The sanity-step alternative keeps the ordering and
  fails the hook when authors forget to add a row.

### 2.3 — PairUpBonusResolver test seam diverges from production

**[SEVERITY: Medium]**
- **File & Line:** `scripts/autoloads/PairUpBonusResolver.gd:82-99`
  (`_compute_bonuses_from_stats`) vs `:59-77` (`_compute_bonuses`)
- **Problem:** The test seam silently differs from the production path
  on the scaling layer:

  ```gdscript
  # production — missing stat reads 0 via _read_support_stat
  for stat in scaling_stats:
      var live_value: int = _read_support_stat(support_unit, stat_key)  # default 0
      var scale: int = live_value / divisor
      ...

  # test seam — missing stat *skips* the bonus
  for stat in scaling_stats:
      if not support_stats.has(stat_key):
          continue
      var scale: int = int(support_stats[stat_key]) / divisor
      ...
  ```

  A test that omits a scaling stat passes; the same configuration in
  production would still apply the flat bonus + a 0-scaled increment
  (which is no-op for stat=0, but the *paths through the function
  differ*). Worse, if a future flat block ever needs the scaling-stat
  dict to gate it, the test would not see that gate.
- **Root Cause:** The test seam was written defensively to avoid
  divide-by-zero on missing keys, but the production path already
  handles that by returning 0 from `_read_support_stat`.
- **Recommended Fix:** Make the seam route through the same body. Read
  via a unified `_read_support_stat`-shaped helper:

  ```gdscript
  func _compute_bonuses_common(class_id: String,
          read_stat: Callable) -> Dictionary:
      var flat: Dictionary = _table.call("get_class_bonus", class_id)
      var divisor: int = int(_table.get("scaling_divisor"))
      var scaling_stats: PackedStringArray = _table.get("scaling_stats")
      var out: Dictionary = {}
      for stat in flat.keys():
          out[String(stat)] = int(flat[String(stat)])
      if divisor > 0:
          for stat in scaling_stats:
              var s: String = String(stat)
              var scale: int = int(read_stat.call(s)) / divisor
              if scale != 0:
                  out[s] = int(out.get(s, 0)) + scale
      return out

  func _compute_bonuses(class_id: String, unit: Node) -> Dictionary:
      return _compute_bonuses_common(class_id,
          func(s): return _read_support_stat(unit, s))

  func _compute_bonuses_from_stats(class_id: String,
          stats: Dictionary) -> Dictionary:
      return _compute_bonuses_common(class_id,
          func(s): return int(stats.get(s, 0)))
  ```

- **Tradeoffs:** A Callable closure is slightly slower than direct
  field access, but bonus resolution is called twice per combat — not
  hot enough to matter.

### 2.4 — Danger zone is locked to blue's perspective

**[SEVERITY: Medium]**
- **File & Line:** `scripts/core/GridManager.gd:506-540`
  (`get_enemy_danger_tiles`)
- **Problem:** The danger-zone overlay always reads from blue's POV
  (`gs.are_hostile("blue", u.team)` and the headless fallback
  `u.team == "red"`). For a hotseat green player, the F-keyed threat
  overlay would show *blue's* threats, not green's — which is
  misleading: tiles "dangerous" to blue may be safe to green if green
  and blue share an alliance group.
- **Root Cause:** Known stage-3 gap (the comment at GridManager.gd:507
  flags it). The cursor's `_controlling_faction` isn't threaded through
  to the danger zone yet, even though the camera save/restore now is
  (after 2026-06-09's per-faction fix).
- **Recommended Fix:** Take the controlling faction as a parameter:

  ```gdscript
  # GridManager.gd
  func get_enemy_danger_tiles(viewer_faction: String = "blue") -> Array[Vector2i]:
      var seen: Dictionary = {}
      var gs := get_node_or_null("/root/GameState") if is_inside_tree() else null
      for u in _get_units():
          if not ("team" in u):
              continue
          var hostile: bool
          if gs != null and gs.has_method("are_hostile"):
              hostile = gs.are_hostile(viewer_faction, u.team)
          else:
              hostile = u.team != viewer_faction  # binary fallback
          ...

  # MapCursor.gd: _toggle_danger_zone
  _grid.show_enemy_danger_zone(_controlling_faction)
  ```

  Same change to `show_enemy_danger_zone`. The default arg keeps every
  existing test caller working.
- **Tradeoffs:** None. The cursor already tracks `_controlling_faction`
  for the camera fix, and the GridManager helpers are routed through it
  for selection/targeting already.

### 2.5 — Combat mock unit diverges from real Unit on modifier reads

**[SEVERITY: Medium]**
- **File & Line:** `scripts/tests/test_combat.gd:47-60` (`MockUnit`)
- **Problem:** `MockUnit.battle_speed`, `accuracy`, and `dodge` read
  raw `data.get("speed")` / `data.get("skill")`, NOT
  `get_effective_stat(...)` like the real `Unit.gd` does. The mock has
  no `active_modifiers` array, no `get_effective_stat` method at all.
  Every combat test that involves a "combat"-duration modifier
  (Resolve, Wrath, Pair Up bonuses, stat_bonus skill) exercises a
  *different* code path than what runs in production. Tests can pass
  while a real bug in modifier flow ships.
- **Root Cause:** The mock predates the modifier system. It is fit for
  pure stat math but not for the full damage formula now that the
  formula reads through `get_effective_stat`.
- **Recommended Fix:** Either (a) give `MockUnit` an `active_modifiers`
  field and a `get_effective_stat` that sums it, mirroring `Unit.gd`'s
  one-stat implementation; or (b) for the modifier-relevant tests,
  instantiate a real `Unit.gd` Node via `unit_scene.instantiate()` and
  call `initialize(data, tile, team)`. (b) is more honest but heavier
  per-test; (a) is closer to the existing mock model and only needs
  ~15 lines.

  ```gdscript
  # MockUnit additions
  var active_modifiers: Array[Dictionary] = []

  func get_effective_stat(stat_name: String) -> int:
      var base: int = int(data.get(stat_name))
      for m in active_modifiers:
          if m["stat"] == stat_name:
              base += int(m["delta"])
      return maxi(0, base)

  # And have battle_speed/accuracy/dodge use it
  ```

  Add at least one test that stamps a `combat`-duration modifier on the
  mock, runs combat, and asserts the modifier flows through hit /
  damage like it would in production.
- **Tradeoffs:** The mock grows in size and mirrors more of Unit's API
  — but if the divergence keeps growing, the next regression in
  modifier handling will land silently.

### 2.6 — SkillHandler use-counters key by `effect_id`, not `skill.id`

**[SEVERITY: Low]**
- **File & Line:** `scripts/skills/SkillHandler.gd:172-198`
- **Problem:** Per-map and per-combat skill use counters use
  `skill.effect_id` as the key. Today no two skill `.tres` files share
  an `effect_id` (Vantage / Renewal / Miracle are unique), but
  `stat_bonus` is generic (one effect, many configurations) and the
  pattern will repeat as new "+N" skills land. Two `stat_bonus` skills
  on the same unit would share a single use counter.
- **Root Cause:** Counter key chosen for dispatch convenience, not
  identity isolation.
- **Recommended Fix:** Key by `skill.id`:

  ```gdscript
  if skill.max_uses_per_map != -1:
      var used: int = unit.data.skill_use_counters.get(skill.id, 0)
      ...
      unit.data.skill_use_counters[skill.id] = used + 1
  ```

  Same change to `_combat_skill_uses`. Snapshot/restore (`UnitData.skill_use_counters`)
  is opaque, so the change is on-write only.
- **Tradeoffs:** The dispatch table is still keyed by `effect_id` (one
  handler per behaviour); only the *counter* key changes. No data
  migration needed because no shipping skill currently uses
  `max_uses_per_map` with a duplicated `effect_id`.

### 2.7 — UnitData has no hp/max_hp/level consistency validation

**[SEVERITY: Low]**
- **File & Line:** `scripts/autoloads/DataManager.gd:578-619`
  (`collect_unit_validation_errors`)
- **Problem:** The unit validator checks class_id, internal_level,
  class_line_id, reclass_options, weapon_wexp tracks, and ai_profile —
  but never `hp <= max_hp`, `max_hp > 0`, or `level >= 1`. An authored
  `.tres` with `hp=50` and `max_hp=10` loads fine; the HP bar then
  initialises with `max_value = 10` and `value = 50` (clamped to 10),
  and combat math runs with absurd HP. The unit looks broken in-game
  but no error fires at load.
- **Root Cause:** The validator focuses on references (does this id
  resolve?) and skipped invariants (does this number make sense?).
- **Recommended Fix:** Extend the validator:

  ```gdscript
  if unit.max_hp < 1:
      errors.append("DataManager: unit '%s' max_hp must be >= 1" % unit.unit_id)
  if unit.hp < 0 or unit.hp > unit.max_hp:
      errors.append("DataManager: unit '%s' hp %d outside [0, %d]" %
          [unit.unit_id, unit.hp, unit.max_hp])
  if unit.level < 1:
      errors.append("DataManager: unit '%s' level must be >= 1" % unit.unit_id)
  ```

  Mirror the field-pattern in `GameState._validate_snapshot_unit_dict`,
  which already does these checks for snapshot restoration.
- **Tradeoffs:** Bad authored units fail loud at boot rather than
  rendering oddly in-game — strictly an improvement.

### 2.8 — `_target_has_vulnerability` fallback uses the wrong field

**[SEVERITY: Low]**
- **File & Line:** `scripts/core/CombatResolver.gd:286-289`
- **Problem:**

  ```gdscript
  func _target_has_vulnerability(target: Node, group: String) -> bool:
      if target.has_method("has_vulnerability"):
          return target.has_vulnerability(group)
      return target.has_method("has_quality") and target.has_quality(group)
  ```

  `has_vulnerability` reads `class_data.vulnerability_groups` (what
  effectiveness tags hit this unit); `has_quality` reads
  `class_data.special_qualities` (what the unit IS). These are
  conceptually different lists — a class can have `special_qualities=
  ["armoured"]` but `vulnerability_groups=[]` (no class does today, but
  it's a valid authored state). The fallback would then incorrectly
  treat the armoured unit as vulnerable to anti-armoured weapons.

  In practice every Unit node has `has_vulnerability`, so this branch
  is dead. But it's *also* incorrect dead code — when someone deletes
  the `has_vulnerability` method one day, the fallback will silently
  give the wrong answer instead of a clear "method missing" error.
- **Root Cause:** Vestigial fallback from before `has_vulnerability`
  was added to `Unit.gd`. The author conflated "the class is X" with
  "the class is vulnerable to X".
- **Recommended Fix:** Drop the fallback. It is dead today and wrong
  if it ever runs:

  ```gdscript
  func _target_has_vulnerability(target: Node, group: String) -> bool:
      if target.has_method("has_vulnerability"):
          return target.has_vulnerability(group)
      return false
  ```

  Or, if you want to surface the "missing method" case loudly, swap
  the fallback for a `push_error`.
- **Tradeoffs:** None — strictly correctness.

### 2.9 — SettingsManager `rebind_action` won't re-mirror to `ui_*`

**[SEVERITY: Low]**
- **File & Line:** `scripts/autoloads/SettingsManager.gd:139-167`,
  `:179-182`
- **Problem:** `_mirror_game_keys_to_ui` runs once at startup and
  copies the game's `cursor_up` / `confirm` / `cancel` events into
  Godot's `ui_up` / `ui_accept` / `ui_cancel` so menus work. When
  `rebind_action(action_name, event)` later changes a game action, it
  calls `_apply_keybindings()` but NOT `_mirror_game_keys_to_ui()` —
  so a player who rebinds `confirm` from Z to Y finds menus still
  triggering on Z (the original mirrored event).
- **Root Cause:** The rebind path doesn't know it has a downstream
  dependency on the mirror. The mirror is "set-once" at boot.
- **Recommended Fix:** Re-mirror after every rebind, and make the
  mirror idempotent so the call is cheap:

  ```gdscript
  func rebind_action(action_name: String, event: InputEvent) -> void:
      keybindings[action_name] = [event]
      _apply_keybindings()
      _mirror_game_keys_to_ui()  # NEW
      save()
  ```

  `_mirror_game_keys_to_ui` already guards with
  `InputMap.action_has_event(...)` so re-running is fine.

  Note: `SettingsScreen` is currently read-only (no rebind UI ships
  yet), so this bug is *latent* — the only call site for
  `rebind_action` is the test suite. Worth fixing now so the future
  rebind UI doesn't ship the regression.
- **Tradeoffs:** Adds a redundant mirror call on every rebind (a few
  hash lookups). Negligible.

### 2.10 — No global unit_id uniqueness check

**[SEVERITY: Low]**
- **File & Line:** `scripts/autoloads/DataManager.gd:194-281`
  (`collect_map_registry_validation_errors`),
  `scripts/autoloads/GameState.gd:207-213` (`find_unit_by_id`)
- **Problem:** `unit_id` is the lookup key for `find_unit_by_id`,
  PairUpRegistry (whose keys are unit_ids), and snapshot/restore. The
  validator checks duplicate `id`s on classes/weapons/items/skills, but
  not on units across roster + enemy_placements. A roster unit and an
  enemy placement sharing `unit_id="chrom"` would result in
  `find_unit_by_id` returning whichever was registered first, breaking
  Pair Up lookups in non-obvious ways.
- **Root Cause:** Unit ids weren't part of the dedup pass when the
  duplicate-id detection was added — roster/enemy splits made the join
  awkward.
- **Recommended Fix:** Add a cross-source uniqueness check during
  `collect_map_registry_validation_errors`. Gather every loaded roster
  + enemy unit's `unit_id` into a single dict and flag duplicates:

  ```gdscript
  # collect_map_registry_validation_errors
  var seen_unit_ids: Dictionary = {}  # unit_id -> source path
  # In the roster_units loop and enemy_placements loop, before each
  # unit_id-bearing append:
  if seen_unit_ids.has(uid):
      errors.append("DataManager: duplicate unit_id '%s' at '%s' (also at '%s')" %
          [uid, current_path, seen_unit_ids[uid]])
  else:
      seen_unit_ids[uid] = current_path
  ```

- **Tradeoffs:** None — surfaces a class of bug whose runtime symptoms
  ("my Pair Up partner is wrong") are particularly hard to diagnose.

## 3. Positive Observations

- **Combat resolver context dict.** The schema doc at the top of
  `CombatResolver.gd:9-55` is the kind of one-place WHY that pays off
  every time a new skill lands. The "skill-added" annotations on the
  Nihil flags make the cross-cutting nature of those keys legible.
- **The `_run_strike_series` extraction (`CombatResolver.gd:623-638`).**
  Five separate strike series (Vantage opener, attacker, counter,
  follow-up, etc.) flow through one guarded loop, so the "stop when
  either side is dead" rule cannot drift between sites. This was
  identified as a risk in earlier reviews and has now been collapsed
  cleanly.
- **PairUpRegistry as a tiny, side-effect-poor autoload
  (`scripts/autoloads/PairUpRegistry.gd`).** 180 lines, every mutation
  has a clear "what does this leave the world in" comment, the
  `_campaign_allows_pair_up()` gate is documented including which call
  sites are intentionally NOT gated. Easy to reason about.
- **The 2026-06-09 review items.** All five fixes landed with tests,
  matched the recommended approach (not a half-measure), and stayed
  small. `get_living_units_of` now correctly filters paired supports;
  per-faction camera memory works for the multi-faction case; the
  DataManager `LoadResult` enum is the right shape; the roster type
  guard is in the right place; and the Unit.gd direct-access cleanup
  routes through the right accessor. The branch is materially more
  ship-ready than it was a session ago.
- **`MapCursor` slice extraction
  (`scripts/core/MapCursor{Selection,Targeting,Input}.gd`).** The
  RefCounted slice pattern keeps each piece unit-testable without a
  SceneTree while leaving the FSM on the Node. The boundary is clean
  (the slices never `get_node_or_null` themselves — they route through
  the grid Node when they need an autoload).

## 4. Architectural Observations

- **Two-system gates for the same question.** ActionMenu visibility
  and MapCursorTargeting target collection answer "is this neighbor a
  legal Pair Up partner?" independently. Same problem appears in
  miniature for Seize / Escape — but those are already routed through
  the shared `TileActions` helper (which is the right pattern). The
  Pair Up gate should follow `TileActions` and the auras-and-Charm
  helper should follow once those skills land. The general rule
  worth lifting into project docs: **availability gates that don't
  share a source of truth will drift.**
- **MockUnit and Unit drift (issue 2.5) is one instance of a larger
  pattern.** Several tests build minimal stubs that re-implement parts
  of `Unit.gd` (combat math, modifier evaluation). Each is fine in
  isolation; together they form a shadow API. As `Unit.gd` grows
  (the file is already 1151 lines), the divergence risk grows too.
  Worth keeping an eye on: when a single bug fix has to touch two
  similar-looking helpers in different test files, that's the signal
  to extract a shared `TestUnitStub.gd` like the cursor extractions.
- **`get_enemy_danger_tiles` is one of several places still wired to
  the hardcoded "blue" perspective** (the danger zone, the HUD
  objective panel comment, a couple of comments in TurnManager). The
  pattern needs one of two cleanups: either (a) the cursor's
  `_controlling_faction` becomes a first-class input to every
  player-perspective query (recommended — already done for camera
  save/restore), or (b) the project decides hotseat shares blue's POV
  for these auxiliary surfaces. Pick one before stage-3 content lands;
  half-converted is the worst state.
- **`run_tests.sh` runs ~30 tests sequentially.** A full run is
  ~3 minutes on the dev container — that's the dominant cost of a
  pre-commit. The tests are independent (each is its own godot
  process) so a `xargs -P` parallelisation would knock 60-70% off the
  wall time. The only shared state is `user://settings.cfg`, which the
  SettingsManager and SettingsScreen tests both write — those two
  should stay serial, but the other 28 can fan out. Worth doing once
  the CI cost starts to hurt.
- **Pre-commit hook runs the full suite for every commit.** The
  `SKIP_TESTS=1` escape exists, but using it normalises bypassing
  validation. A faster default (parallel run, or "just the suites
  whose touched-file ancestors were modified") would make running
  tests the path of least resistance.

## 5. Prioritized Action Plan

1. **Fix the ActionMenu / MapCursorTargeting Pair Up gate mismatch
   (issue 2.1).** One spot fix or a shared helper extraction;
   high-leverage because it locks in the alliance-group model before
   stage-3 content trips over it.
2. **Make `run_tests.sh` discover tests from the filesystem (issue
   2.2).** Eight lines of bash; recovers ~40 silent assertions of
   coverage.
3. **Thread the controlling faction through `get_enemy_danger_tiles`
   (issue 2.4).** Tiny change, finishes the per-faction perspective
   work that the camera save/restore already started.
4. **Unify the PairUpBonusResolver test seam with the production path
   (issue 2.3).** Removes a small but real "tests don't cover what
   ships" gap.
5. **Teach `MockUnit` about modifiers (issue 2.5)** so combat tests
   exercise the real code path for stat reads. Same gap shape as 2.3.
6. **Key SkillHandler counters by `skill.id` (issue 2.6),** add the
   hp/level invariant validators (issue 2.7), drop the dead-and-wrong
   `_target_has_vulnerability` fallback (issue 2.8), re-mirror keys
   after `rebind_action` (issue 2.9), and add the cross-source
   unit_id uniqueness check (issue 2.10). These are all small, all
   defensive, all eliminate a class of confusing runtime symptom.
7. **Add tests for:**
   - Pair Up button visibility AND target collection for a green ally
     adjacent to a blue lead under the alliance-group model;
   - danger zone painted from green's perspective shows green's
     enemies, not blue's;
   - a `combat`-duration modifier stamped on a MockUnit flows through
     hit/damage/dodge in `test_combat.gd`;
   - cross-source duplicate `unit_id` (one in the roster, one in
     `enemy_placements`) fires `push_error` at boot;
   - missing scaling stat in `bonuses_for_class_and_stats` matches
     production's "read as 0" behaviour;
   - an authored UnitData with `hp > max_hp` fails validation.

## Assumptions

- I assumed stage-3 hotseat content (green/yellow factions controlled
  by a local human player) is real on the roadmap and will exercise
  the cross-faction gates (issue 2.1, 2.4) within the next milestone or
  two. If it's been deprioritised, the severity of 2.1 and 2.4 drops a
  notch.
- I assumed authored data is partially trusted: validators should
  catch authoring mistakes (bad IDs, malformed conditions, stat
  inconsistencies) but the project doesn't intend to support
  user-submitted maps. If user-mod support is in scope, several Low
  items here move up to Medium (validators become the security
  boundary, not just an authoring nicety).
- I assumed `MockUnit` is intentionally minimal — a property of the
  test, not a project goal. If the goal is "every test must run
  against the real `Unit.gd`", issue 2.5 reframes as "delete MockUnit
  and use the real Unit" rather than "extend MockUnit". The same
  outcome either way; only the path differs.
