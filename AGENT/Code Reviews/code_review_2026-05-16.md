---
Role: dated
---

# Code Review — 2026-05-16

Reviewer: Claude
Codebase: ~6,858 lines, 46 GDScript files, Godot 4 turn-based tactics RPG (Fire Emblem-like)
Scope: all `scripts/` source (autoloads, core, resources, units, items, skills, ui, shared). Test
files (`scripts/tests/`) reviewed for coverage but not line-audited. Tool scripts excluded.

---

## 1. Executive Summary

**Overall quality: 7 / 10.**

This is a well-structured, unusually well-documented first-milestone codebase. Systems are cleanly
decoupled through an EventBus, combat math is a stateless engine with a proper preview/resolve
split, and the headless-test accommodations are thoughtful. The biggest concerns are two latent
correctness bugs that current tests do not catch — the Retry snapshot does not deep-copy inventory
resources, and a unit that counter-kills its attacker receives zero EXP — plus a settings layer
that is partly inert and partly unreachable. None of these crash on the golden path, which is
exactly why they have survived this long.

---

## 2. Issues Found

### [SEVERITY: High]
- **File & Line:** `scripts/autoloads/GameState.gd:171` (`_snapshot_unit_data`) and `:203-204` (`_restore_unit_data`)
- **Problem:** The Retry snapshot stores `"inventory": data.inventory.duplicate(true)`. In Godot 4,
  `Array.duplicate(true)` deep-copies nested `Array`/`Dictionary` values but **does not duplicate
  `Object`/`Resource` elements** — the references are shared. `InventoryEntry` is a `Resource`, so
  the snapshot array holds the *same* entry objects as the live inventory. When combat decrements
  `entry.uses_remaining` (via `Unit.use_weapon_durability`) or `ItemHandler` consumes an item, the
  snapshotted entry mutates in lockstep. On Retry, `restore_map_snapshot()` restores an inventory
  whose weapons are already worn down and whose consumables are already spent.
- **Root Cause:** A reasonable but incorrect assumption that `duplicate(true)` is fully recursive.
  It is recursive for containers, not for `Object` references.
- **Recommended Fix:** Deep-copy each entry explicitly on snapshot, and again on restore so repeated
  Retries stay isolated:
  ```gdscript
  # in _snapshot_unit_data
  var inv_copy: Array[InventoryEntry] = []
  for e in data.inventory:
      inv_copy.append(e.duplicate(true))
  # ... "inventory": inv_copy

  # in _restore_unit_data
  data.inventory.clear()
  for e in snap.get("inventory", []):
      data.inventory.append(e.duplicate(true))
  ```
  `conditions`/`active_modifiers` are `Array[Dictionary]` and *are* correctly deep-copied today;
  only `inventory` is affected.
- **Tradeoffs:** Slightly more allocation per snapshot. Negligible — snapshots happen once per map.
  This also matters for the upcoming suspend-save milestone, which serializes the same snapshot.

### [SEVERITY: High]
- **File & Line:** `scripts/core/CombatResolver.gd:566`
- **Problem:**
  ```gdscript
  var def_exp: int = calculate_exp(defender, attacker, attacker_died) if (def_hit and not attacker_died) else 0
  ```
  When the defender lands a counterattack that **kills the attacker**, `attacker_died` is `true`, so
  the guard `def_hit and not attacker_died` is false and `def_exp` becomes `0`. A unit that survives
  combat and kills its attacker on the counter earns no EXP at all — not even the normal hit EXP,
  let alone the kill bonus. The attacker side (`:565`) is computed correctly without this clause.
- **Root Cause:** The `not attacker_died` term looks like an *award* guard ("don't grant EXP to a
  dead unit") that was placed on the wrong side. The dead-unit guard already exists separately and
  correctly on the award line (`:573`, `not defender_died`).
- **Recommended Fix:**
  ```gdscript
  var def_exp: int = calculate_exp(defender, attacker, attacker_died) if def_hit else 0
  ```
  `calculate_exp` already takes `killed = attacker_died`, so a counter-kill correctly yields kill
  EXP. The `not defender_died` guard on line 573 still prevents awarding EXP to a freed defender.
- **Tradeoffs:** None. This is a straight correctness fix. Add a test: defender counter-kills
  attacker → defender EXP > 0.

### [SEVERITY: Medium]
- **File & Line:** `scripts/autoloads/GameState.gd:38-46`
- **Problem:** `GameState` caches `permadeath_enabled` and `leveling_method` from `SettingsManager`
  **once**, in `_ready()`. `Unit.handle_death()` reads `gs.permadeath_enabled` and `Unit.level_up()`
  reads `gs.leveling_method`. `SettingsScreen` writes changes to `SettingsManager`, never to
  `GameState`. So changing permadeath or leveling method in-game has no effect until the process
  restarts. The comment "kept in sync with SettingsManager" describes a sync that does not exist.
- **Root Cause:** A pull-once-at-boot pattern with no change notification. There is no
  `settings_changed` signal on the bus.
- **Recommended Fix:** Either (a) drop the cache and have `Unit` read `SettingsManager` directly
  via `get_node_or_null` at the point of use, or (b) add an EventBus `settings_changed` signal that
  `SettingsManager` emits on every write and `GameState` listens for. Option (a) is simpler and
  removes a duplicated source of truth.
- **Tradeoffs:** Option (a) costs a tree lookup per death/level-up — trivial. Option (b) keeps the
  cache but adds wiring. Prefer (a).

### [SEVERITY: Medium]
- **File & Line:** `scripts/ui/PhaseBanner.gd:20-22` (and the `combat_animations` setting generally)
- **Problem:** `SettingsManager` exposes `phase_banner` (`"show"|"skip"`) and `SettingsScreen` lets
  the player set it, but `PhaseBanner._on_phase_changed()` always calls `_animate()` — it never
  reads `sm.phase_banner`. The "Skip" option does nothing. The same is true of `combat_animations`:
  it is defined, persisted, and surfaced in the UI, but no code reads it (there is no combat
  animation system yet).
- **Root Cause:** Settings were defined ahead of the features that consume them.
- **Recommended Fix:** In `PhaseBanner._on_phase_changed`, early-return when
  `get_node_or_null("/root/SettingsManager")` reports `phase_banner == "skip"`. For
  `combat_animations`, either hide that option in `SettingsScreen` until the animation system lands,
  or document it as inert. Don't ship a toggle that silently does nothing.
- **Tradeoffs:** None for `phase_banner`. For `combat_animations`, hiding the option is the honest
  choice for MVP.

### [SEVERITY: Medium]
- **File & Line:** `scripts/ui/MainMenu.gd` / `scripts/ui/MapMenu.gd`
- **Problem:** `SettingsScreen.gd` and `SettingsScreen.tscn` are complete and functional, but
  nothing instantiates or navigates to them. `MainMenu` has only New Game / Quit (Settings is a
  "Phase 3 placeholder"), and `MapMenu` has only End Turn / Close. The settings UI is dead code
  from the player's perspective.
- **Root Cause:** Screen built before its entry point.
- **Recommended Fix:** Add a "Settings" button to `MainMenu` (and optionally `MapMenu`) that shows
  `SettingsScreen` and wires its `back_pressed` signal. If this is intentionally deferred, that is
  fine — but note it in the milestone tracker so the screen isn't assumed live. Combined with the
  previous two findings, the settings subsystem needs a pass before it can be called done.
- **Tradeoffs:** None; this is a small amount of wiring.

### [SEVERITY: Medium]
- **File & Line:** `scripts/autoloads/GameState.gd:129`
- **Problem:**
  ```gdscript
  var res: UnitData = load(roster_path + f).duplicate(true)
  ```
  `load()` can return `null` for a corrupt or malformed `.tres` even when the file exists.
  `null.duplicate(true)` crashes immediately. The subsequent `if res:` check is dead — `res` is
  already assigned the result of `.duplicate()`, so a crash happens before the guard runs.
- **Root Cause:** Guard placed after the dereference instead of before it.
- **Recommended Fix:**
  ```gdscript
  var loaded := load(roster_path + f)
  if loaded == null:
      push_error("GameState: failed to load roster file '%s'" % f)
      continue
  var res: UnitData = loaded.duplicate(true)
  ```
  `GameMap._spawn_units():127` has the same shape — it checks `ResourceLoader.exists()` first, which
  helps, but `exists()` does not guarantee a successful parse. Apply the same null-check there.
- **Tradeoffs:** None.

### [SEVERITY: Medium]
- **File & Line:** `scripts/core/MapCursor.gd:96-105`, `176-185`
- **Problem:** `_unhandled_input` / `_handle_mouse_motion` only short-circuit on `State.LOCKED`. In
  `UNIT_MOVED` (ActionMenu open), `TARGETING`, and `STAFF_TARGETING` the cursor still moves freely
  on arrow keys and mouse motion. `ActionMenu._input` consumes only up/down/cancel, so left/right
  and the mouse leak through and slide the cursor. In `TARGETING`, the cursor can drift off the
  valid attack tiles; `_on_confirm` → `_show_attack_preview` then finds no enemy under the cursor
  and silently does nothing, so the attack appears unresponsive.
- **Root Cause:** Targeting modes were designed for keyboard tile-cycling but the free-move input
  path was never gated for them.
- **Recommended Fix:** In `TARGETING`/`STAFF_TARGETING`, intercept arrow keys to cycle `current_tile`
  among `_attack_tiles`/`_heal_tiles` instead of free movement, and ignore `InputEventMouseMotion`
  (or snap the cursor to the nearest valid target tile). In `UNIT_MOVED`, suppress cursor movement
  entirely while the ActionMenu is open.
- **Tradeoffs:** Slightly more state-specific input handling in an already large class — but it is
  the correct behavior and is needed before this is playable with a mouse.

### [SEVERITY: Low]
- **File & Line:** `scripts/autoloads/DataManager.gd:26-43`, `scripts/core/GameMap.gd:129`,
  `scripts/autoloads/GameState.gd:131`
- **Problem:** Data integrity is enforced with `assert()` (cross-reference validation, non-empty
  `unit_id`). `assert()` is stripped from Godot 4 release builds, so in a shipped build a `.tres`
  with a bad id or empty `unit_id` passes silently. An empty `unit_id` in particular weakens the
  `required_survivor_ids` defeat check, which matches on that field.
- **Root Cause:** `assert` used as a runtime validator rather than a debug-only invariant. This was
  partially addressed in the 2026-05-15 review (the `get_*` accessors now `push_error`), but the
  startup validators were not converted.
- **Recommended Fix:** Replace `assert` in `_validate_cross_references` and the `unit_id` checks
  with `push_error` (or `push_warning`) so the message survives into release builds. Keep `assert`
  only for true never-can-happen invariants.
- **Tradeoffs:** `push_error` does not halt execution, so callers should still tolerate bad data —
  which the `get_*` accessors already do.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/GridManager.gd:183-207` (`get_movement_range`), `233-259`
  (`get_movement_path`)
- **Problem:** The Dijkstra frontier is a plain `Array`; when a tile is relaxed to a lower cost it
  is `append`ed again without removing the stale copy, so the frontier accumulates duplicates and
  each pop does an O(n) linear min-scan. Correctness is fine; it is just O(n²)-ish on the frontier.
- **Root Cause:** Simplest-thing-that-works for MVP map sizes (explicitly acknowledged in comments).
- **Recommended Fix:** Not urgent at current map sizes. When maps grow, either skip popped entries
  whose recorded cost is stale (the `EnemyAI._flood_costs` heap already does exactly this) or track
  a visited set. `EnemyAI._flood_costs` is the better pattern — consider consolidating all three
  flood-fills onto one shared helper.
- **Tradeoffs:** None beyond the effort; flagged so it is a conscious deferral, not an oversight.

### [SEVERITY: Low]
- **File & Line:** `scripts/ui/HUD.gd:73-83`
- **Problem:** `_show_unit` only refreshes when the cursor moves or a unit is selected/deselected.
  After combat resolves, the unit info panel's HP line is stale until the cursor next moves. The
  `_hp_bar` on the unit sprite updates correctly via `take_damage`; only the HUD panel lags.
- **Root Cause:** HUD listens to `cursor_moved` / `unit_selected` but not to `unit_damaged` /
  `unit_healed` / `combat_resolved`.
- **Recommended Fix:** Connect `HUD` to `EventBus.unit_damaged` and `unit_healed`; if the changed
  unit is the one currently displayed, re-run `_show_unit`.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/MapCursor.gd:535-554` (`_cycle_to_next_unit`),
  `scripts/core/TurnManager.gd:141` comment
- **Problem:** Two minor inconsistencies. (1) Tab/`next_unit` only cycles units in `READY` state,
  skipping `MOVED` units that have moved but not yet committed an action — those are still
  actionable. (2) `are_all_player_units_done()`'s comment says it is used for "auto-end-phase", but
  no code auto-ends the turn when the last unit becomes `DONE`; the player must open the map menu.
- **Root Cause:** Feature drift — the comment predates a decision to require manual end-turn.
- **Recommended Fix:** Include `MOVED` units in the `_cycle_to_next_unit` candidate set (use
  `_turn.can_unit_act(u)`). Update or remove the stale "auto-end-phase" comment, or implement the
  auto-end if that is still desired.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/resources/InventoryEntry.gd:17`
- **Problem:** `uses_remaining` defaults to `0`. A weapon or item entry constructed without
  explicitly setting uses is permanently unusable (filtered out by every `uses_remaining > 0`
  check). This is a quiet footgun for hand-authored `.tres` files and future code paths. The
  session notes already flag a possible `-1 = infinite` convention.
- **Root Cause:** Default chosen before a sentinel convention was settled.
- **Recommended Fix:** Decide the convention deliberately. If `-1` will mean infinite, audit every
  `uses_remaining > 0` / `<= 0` site (`Unit.use_weapon_durability`, `ItemHandler.apply_item`,
  `ActionMenu.show_for`, `ItemMenu.show_for`) so a `-1` entry reads as usable and never decrements
  below `-1`. Until then, keep `validate()` strict and document the default.
- **Tradeoffs:** A convention change touches many call sites — do it as one focused pass, not
  incrementally.

---

## 3. Positive Observations

1. **Genuinely useful comments.** Non-obvious decisions are explained where they live — the combat
   context dictionary schema at the top of `CombatResolver.gd`, the headless autoload-ordering
   notes in `GameState`/`EventBus`, the "capture the weapon before durability decrement" warning in
   `MapCursor._execute_staff_heal`. These explain *why*, not *what*, which is exactly right.
2. **Clean stateless combat engine.** `CombatResolver` separates `preview_combat` (no RNG, no side
   effects, snapshot/restore around modifier collection) from `resolve_combat` + `apply_combat_result`.
   The preview cannot corrupt live state, and the resolve path recomputes death/EXP from what
   actually landed rather than trusting the simulation — that is a thoughtful guard against
   weapon-break divergence.
3. **Decoupled architecture via EventBus.** Systems communicate through signals rather than direct
   references. UI panels (`HUD`, `LevelUpScreen`, `GameOverScreen`, `CombatHUD`, `PhaseBanner`) are
   pure listeners and could be removed without touching game logic.
4. **Test-aware design.** `GridManager._get_units()`, the `_terrain_fallback` map, and the
   `is_inside_tree()` guards let core logic run under `--script` headless tests without spinning up
   autoloads. The `SkillHandler` dispatch table turns a missing skill into a startup error instead
   of a silent no-op.
5. **Data-driven content.** Maps, classes, weapons, skills, and items are all `.tres` resources;
   adding a map is adding a `MapData` file. `WeaponData`'s formula-string range (`"MAG/2"`) is a
   tidy way to keep dynamic ranges data-side.

---

## 4. Architectural Observations

- **`MapCursor` is a 640-line FSM god class.** Already tracked as deferred item D-1. It owns input,
  selection, movement, targeting, previewing, the action/item/map menus, camera scrolling, and the
  end-turn confirmation dialog. It is the single largest correctness risk surface in the project
  (the input-gating bug above is a direct symptom) and the only core class with no unit tests
  because it cannot be exercised in isolation. The proposed split into
  Input/Selection/Targeting sub-objects should happen before Phase 2 piles staff/dance/rescue
  actions on top.
- **Settings live in two places.** `SettingsManager` is the persisted source of truth, but
  `GameState` keeps its own `permadeath_enabled` / `leveling_method` / `max_skills` /
  `max_inventory` copies. Duplicated state with a one-time sync is the root of the stale-cache bug.
  Pick one owner.
- **Autoload access is string-path coupling.** Nearly every cross-system call goes through
  `get_node_or_null("/root/SomeAutoload")`. This is a deliberate workaround for the headless
  compile-ordering issue (well documented), but it converts what would be compile-time errors into
  runtime `null` checks scattered across the codebase. A thin typed accessor module
  (`func skill_handler() -> Node`) would centralize the lookups and the null handling.
- **The save/snapshot system is half-built.** `GameState` has an in-memory snapshot used by Retry,
  with `TODO save-system` notes acknowledging enemy state and terrain mutations are out of scope.
  The inventory deep-copy bug (Finding 1) is in this exact code and will become a save-corruption
  bug, not just a Retry bug, when the suspend-save milestone lands. Fix it now.
- **Inert settings vs. missing features.** `combat_animations` and `phase_banner` are wired
  end-to-end except for the consumer. This is a symptom of building configuration ahead of
  behavior; it is harmless until a player toggles a setting that does nothing.

---

## 5. Prioritized Action Plan

Ordered by impact-to-effort.

1. **Fix the counter-kill EXP bug** (`CombatResolver.gd:566`). One-line change, pure correctness
   win, add a regression test. (High impact, trivial effort.)
2. **Deep-copy `InventoryEntry` in the Retry snapshot and restore** (`GameState.gd`). Small change,
   prevents a real loss of Retry integrity now and save corruption later. Extend
   `test_snapshot_coverage.gd` with an inventory-mutation round-trip. (High impact, low effort.)
3. **Null-check `load()` before `.duplicate()`** in `GameState.load_default_roster` and
   `GameMap._spawn_units`. Removes a crash path. (Medium impact, trivial effort.)
4. **Resolve the settings subsystem**: drop `GameState`'s cached settings copies (or add a
   `settings_changed` signal), make `PhaseBanner` honor `phase_banner`, and either wire up
   `SettingsScreen` or hide the inert `combat_animations` option. Treat this as one focused pass.
   (Medium impact, low-medium effort.)
5. **Gate `MapCursor` input by state**: suppress free cursor movement during `UNIT_MOVED`, and make
   `TARGETING`/`STAFF_TARGETING` cycle among valid target tiles instead of moving freely. (Medium
   impact, medium effort — and a good first slice of the D-1 refactor.)
6. **Convert startup `assert()` validators to `push_error`** so bad `.tres` data is caught in
   release builds. (Low-medium impact, low effort.)
7. **Polish**: refresh the HUD unit panel on `unit_damaged`/`unit_healed`; include `MOVED` units in
   Tab cycling; fix the stale "auto-end-phase" comment. Batch these. (Low impact, low effort.)
8. **Deferred**: settle the `InventoryEntry.uses_remaining` sentinel convention, and consolidate the
   three Dijkstra flood-fills onto one heap-based helper when map sizes grow. (Low impact now.)

---

## Assumptions Flagged

- I assumed `Array.duplicate(true)` does not duplicate `Resource` elements (standard Godot 4
  behavior). If the snapshot is later observed to restore inventory correctly, verify the engine
  version's behavior — but the documented behavior supports Finding 1.
- I assumed `SettingsScreen` has no entry point because none appears in `MainMenu`/`MapMenu`. If a
  separate scene or debug path opens it, Finding "SettingsScreen unreachable" is reduced to the
  stale-cache issue only.
- I assumed the counter-kill EXP behavior is unintended. If "no EXP for counter-kills" is a
  deliberate design rule, Finding 2 is invalid — but the asymmetry with the attacker side strongly
  suggests a bug.
- Combat is currently instant (no animation layer), so `combat_animations` having no consumer is
  expected for MVP; it is flagged only as a UI-honesty issue.
