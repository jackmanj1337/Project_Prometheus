# Code Review & Documentation Audit — 2026-05-18

Reviewer: Claude
Scope: **full-codebase review** + **full documentation audit** (per
`AGENT/Docs/code_review_instructions.txt`, plus the user's request to check the
GDD/Docs for bugs, bad design, and design↔doc divergence).

Files read in full: every script under `scripts/` (autoloads, core, units, skills,
items, resources, ui, shared — 38 production files), `project.godot`, sample
`.tres` data (`soldier.tres`, `iron_sword.tres`, roster files), and the GDD set
(via subagent). Suite re-run this pass: **18 suites / 347 tests green**
(`bash run_tests.sh`, exit 0) — matches Session K's recorded state.

---

## 1. Executive Summary

**Code quality: 8 / 10. Documentation quality: 4 / 10.**

The *code* is in genuinely good shape: a clean data-driven architecture, disciplined
null-guarding for headless/`--script` mode, a well-factored combat pipeline, and
347 passing tests covering every major system. No Critical issues and no High
correctness bugs were found — the combat resolver's strike/follow-up/vantage logic,
the Dijkstra movement core, and the snapshot/Retry path were all traced and are
sound. The findings against the code are maintainability-grade: a player-facing
**dead setting**, some **UI→system coupling**, **unreached validation code**, and a
handful of stale comments.

The *documentation* is the real concern, and it is what most of this review covers.
`GDD_01_Architecture.md` has drifted so far from the code that following it would
actively produce bugs — wrong resource field names, wrong API signatures, a wrong
folder tree, a wrong autoload list, and a wrong Input Map. Several GDD files also
contradict each other. The code is the trustworthy source of truth today; the
design docs are not.

---

## 2. Code Issues Found

### [SEVERITY: Medium]
- **File & Line:** `scripts/autoloads/SettingsManager.gd:14` (`combat_animations`);
  consumed nowhere.
- **Problem:** `combat_animations` ("all" / "player_only" / "enemy_only" / "none")
  is loaded, saved, and exposed in `SettingsScreen`, but a repo-wide grep finds
  **zero** readers outside Settings code. Combat is resolved synchronously with no
  animation path (`MapCursorTargeting._resolve_attack` and `EnemyAI` both call
  `resolve_combat` → `apply_combat_result` back-to-back, no `await`). The player can
  toggle an option that does nothing.
- **Root Cause:** The setting was scaffolded ahead of a combat-animation feature
  that was never built; nothing keys off it.
- **Recommended Fix:** Either (a) disable/grey the option in `SettingsScreen` with a
  "[Phase 2]" label until a combat-animation system exists, or (b) when that system
  lands, branch on `SettingsManager.combat_animations` in the combat-playback path.
  Until then, option (a) is honest UX. Same scrutiny applies to any other
  scaffolded-but-inert setting — `phase_banner` and `level_up_screen` *are* consumed
  (`PhaseBanner.gd`, `LevelUpScreen.gd`), so only `combat_animations` is dead.
- **Tradeoffs:** None for (a); (b) is the real fix but is feature work, not a fix.

### [SEVERITY: Medium]
- **File & Line:** `scripts/ui/HUD.gd:138-139`.
- **Problem:** `_update_terrain` reads `_grid.TERRAIN_DEF_BONUS` /
  `_grid.TERRAIN_DODGE_BONUS` — reaching directly into another node's constants by
  name. GDScript resolves this dynamically, so renaming/moving those constants
  breaks the HUD with no compile-time warning. The UI layer should not know
  GridManager's internal constant layout.
- **Root Cause:** Convenience access instead of a published query method.
- **Recommended Fix:** Add `GridManager.get_terrain_bonuses(tile) -> Dictionary`
  returning `{"def":…, "dodge":…}` and have the HUD call that. (`Unit.gd:135-148`
  already reads the same two constants the same way — fold both callers onto the
  accessor.)
- **Tradeoffs:** One extra method; gives GridManager a stable public contract.

### [SEVERITY: Medium]
- **File & Line:** `scripts/autoloads/DataManager.gd:26-45` (`_validate_cross_references`).
- **Problem:** Startup validation checks only two things: class `starting_skills`
  resolve, and skill `activation_chance_stat` is a known stat. It does **not**
  validate weapon `effect_tags` (a typo'd `effective_armored` vs `effective_armoured`
  silently never triggers — and `_is_effective` matches against the
  `GameConstants.TAG_*` strings, so a bad tag is a silent no-op), class
  `proficiencies`, weapon `magic_triangle_type`, or item `effect_id`s. The
  "fail loud at load" discipline the project otherwise applies (`GameMap._validate_map`,
  `SkillData.validate`) stops short here.
- **Root Cause:** Validation was added incrementally and never extended to the
  weapon/item catalogues.
- **Recommended Fix:** Extend `_validate_cross_references` to check weapon
  `effect_tags` against the `GameConstants.TAG_*` set, weapon/skill `weapon_type`
  against the canonical list, and item `effect_id` against `ItemHandler`'s known
  effects. Each as `push_error` so bad data surfaces at boot.
- **Tradeoffs:** A little more startup code; catches data typos that are otherwise
  invisible until a weapon "mysteriously" fails to be effective in play.

### [SEVERITY: Medium]
- **File & Line:** `scripts/resources/InventoryEntry.gd:42-57` (`validate()`).
- **Problem:** `InventoryEntry.validate()` is a thorough, well-written checker —
  and it is **never called**. The only `.validate()` call in the codebase is
  `skill.validate()` (`DataManager.gd:20`). A `.tres` with a weapon entry missing
  `weapon_id`, or an unset `entry_type`, loads silently; the failure surfaces later
  as a confusing null/empty-string symptom far from the bad data.
- **Root Cause:** The validator was written for the ARCH-05 `InventoryEntry`
  refactor but no caller was wired up.
- **Recommended Fix:** Call it where unit data is first materialised — e.g. in
  `GameState.load_default_roster()` and `GameMap._spawn_units()` after `duplicate()`,
  iterate `data.inventory` and call `entry.validate()`. Or validate inside
  `DataManager` if inventory ever moves into a loaded catalogue.
- **Tradeoffs:** None — it is pure upside; the code already exists.

### [SEVERITY: Medium]
- **File & Line:** `scripts/ui/NewGameScreen.gd:64-72` (`_on_start`).
- **Problem:** If `get_node_or_null("/root/GameState")` returns null, the `if gs:`
  block (rules + `load_default_roster`) is skipped but
  `change_scene_to_file("…/GameMap.tscn")` still runs unconditionally — loading a
  battle with an empty roster. `GameMap._spawn_units` then auto-recovers by calling
  `load_default_roster` itself, so this is not fatal today, but the screen's chosen
  permadeath/leveling rules are silently dropped.
- **Root Cause:** The scene change sits outside the guard.
- **Recommended Fix:** `if gs == null: push_error(...); return` before the scene
  change, so a missing autoload fails loud instead of dropping the player's choices.
- **Tradeoffs:** None — GameState is an autoload that should always exist.

### [SEVERITY: Low]
- **File & Line:** `scripts/ui/HUD.gd:42`.
- **Problem:** `_ready()` calls `_on_phase_changed(0)` with a magic `0` to seed the
  phase label; `_on_phase_changed` compares against `GameState.Phase.PLAYER`. Works
  only because `PLAYER` is enum index 0.
- **Recommended Fix:** `_on_phase_changed(GameState.Phase.PLAYER)`.
- **Tradeoffs:** None.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/CombatResolver.gd:612-615` (`apply_combat_result`).
- **Problem:** `EventBus.combat_started` is emitted at the *top of apply*, i.e.
  **after** `resolve_combat` has already rolled all RNG and built the exchange list.
  Any future listener that hears `combat_started` as "a fight is about to begin"
  (intro animation, camera focus) would actually receive it once the maths is
  finished. The signal name implies a pre-combat hook it cannot provide.
- **Root Cause:** The resolve/apply split was introduced later; `combat_started`
  predates it and stayed at the apply boundary.
- **Recommended Fix:** Either emit `combat_started` at the top of `resolve_combat`,
  or rename it to something apply-phase-accurate (e.g. `combat_applying`). Document
  the chosen contract on the signal in `EventBus.gd`.
- **Tradeoffs:** Moving the emit changes ordering for any current listener — there
  are none today (only `combat_resolved` is consumed, by `CombatHUD`), so now is the
  cheap moment to fix it.

### [SEVERITY: Low]
- **File & Line:** `scripts/units/Unit.gd:183-186` (`has_skill`).
- **Problem:** `has_skill()` checks only `data.skills`, not `data.mastery_skills`.
  This is harmless **today** — the one mastery skill (`s_rank_mastery`) is dispatched
  through `SkillHandler.apply_trigger`, which correctly unions both lists
  (`SkillHandler.gd:90-91`). But `CombatResolver._get_effectiveness_multiplier` uses
  `has_skill("giantkiller")`, and any future earned/mastery skill queried through
  `has_skill()` would be silently invisible.
- **Recommended Fix:** Have `has_skill()` check both arrays:
  `return skill_id in data.skills or skill_id in data.mastery_skills`.
- **Tradeoffs:** None — matches the union `apply_trigger` already does.

### [SEVERITY: Low]
- **File & Line:** `scripts/resources/UnitData.gd:7` (`tile_position`),
  `:37` (`mastery_skills`).
- **Problem:** Both are plain `var`, not `@export`. The header comments claim each
  is "serialized for … save system" / "stored on UnitData so the snapshot and save
  system can serialize it." A non-exported `var` is **not** written by
  `ResourceSaver` to a `.tres`. The in-memory Retry path is fine — `GameState`'s
  snapshot copies these fields by hand — but a future `ResourceSaver`-based suspend
  save would silently drop them, contradicting the comment.
- **Root Cause:** `tile_position` is intentionally non-exported (it is map-runtime
  state, not authored data); `mastery_skills` is intentionally non-exported (earned
  at runtime, never authored). The *comments* overstate by saying "serialized."
- **Recommended Fix:** Reword both comments to "captured by `GameState`'s manual
  snapshot (not by `ResourceSaver` — it is not `@export`ed)." When the real save
  system lands, decide explicitly whether it serialises these via the manual
  snapshot dict or needs them exported.
- **Tradeoffs:** None — comment-only.

### [SEVERITY: Low]
- **File & Line:** `scripts/core/TurnManager.gd:36-49` (`_apply_fort_healing`).
- **Problem:** The function comment says "fort/throne tiles" but only `"fort"`
  terrain is matched (`:46`). There is no `"throne"` terrain in
  `GameMap._CHAR_TO_SOURCE` or `GridManager._DEFAULT_MOVE_COSTS`.
- **Recommended Fix:** Drop "throne" from the comment, or add the terrain when
  thrones are introduced. Comment-only today.
- **Tradeoffs:** None.

### [SEVERITY: Low — carry-overs from `code_review_2026-05-17`, still open]
- `MapCursorSelection.gd:60` — redundant `_grid == null` half of the `plan_path_to`
  guard (review 2026-05-17 §2). Still present.
- `test_map_cursor_selection.gd:90` — comment misdescribes which tile the
  out-of-range loop picks (review 2026-05-17 §2). Still present.
- *Resolved since 2026-05-17:* the `open_menu`/ESCAPE shadowing (review 2026-05-17,
  Medium) **is fixed** — `project.godot` now binds `open_menu` to **M** (keycode 77)
  only, with `cancel` on X+ESCAPE. The `OPEN_MENU` intent is reachable again. The
  2026-05-17 action-plan item 1 can be marked done.

---

## 3. Documentation Audit

This is the headline of the review. The code is healthy; the docs are not. Findings
are grouped by how much damage they would do.

### 3a. HIGH — would mislead a developer straight into a bug

**D-1. `GDD_01` resource field names are wrong.** `GDD_01:761-816` documents
`UnitData` with abbreviated stat fields `mag/def/res/skl/spd/luk/mov/con/los`. The
actual `UnitData.gd:19-27` uses full names `magic/defense/resistance/skill/speed/
luck/movement/constitution/line_of_sight`. `GDD_01:602` even gives the example
`get_effective_stat("spd")` — there is no `spd` property, so that call returns 0.
The class `.tres` files (`soldier.tres`) and `Unit._GROWTH_STATS` both use the full
names — code and data agree; only the GDD is wrong.

**D-2. `GDD_01` `inventory` type is wrong.** `GDD_01:784,819-838` documents
`inventory: Array[Dictionary]` with a Dictionary "Inventory Entry Format"
(`entry["type"]`). The code uses a typed `InventoryEntry` Resource
(`UnitData.gd:39`); the discriminator is `entry_type`, accessed via
`is_weapon()/is_item()/is_equip()`. `Unit.get_equipped_weapon_entry()` returns
`InventoryEntry`, not `Dictionary` (`GDD_01:596` says `Dictionary`). Code written to
the GDD's `entry["type"]` shape crashes. `InventoryEntry.gd` is not even listed in
`GDD_01`'s resource section.

**D-3. `GDD_01` `WeaponData` range fields do not exist.** `GDD_01:861-862,889`
documents `range_min`/`range_max` ints. The code (`WeaponData.gd:19-20`) has
`range_min_formula`/`range_max_formula` strings, read via `get_range_min(unit)` /
`get_range_max(unit)`. `GDD_09:155-156` *acknowledges* this change — so `GDD_01`
and `GDD_09` contradict each other (see D-9).

**D-4. `GDD_01` CombatResolver API is wrong wholesale.** `GDD_01:523-560` documents
methods that do not exist as named: `compute_battle_speed`, `compute_accuracy`
(real: `compute_hit_pct`), `compute_crit_rate` (real: `compute_crit_pct`),
`_apply_weapon_triangle`, `_apply_terrain`, `_roll_hit`, `_roll_crit` — none exist.
`resolve_combat`'s documented return `{exchanges, attacker_final_hp,
defender_final_hp, attacker_exp, attacker_wexp}` is wrong: the real return is
`{exchanges, attacker_died, defender_died, context}` (`CombatResolver.gd:601`), and
EXP is applied by `apply_combat_result()` — a function `GDD_01` never mentions at
all. `preview_combat`'s documented keys (`attacker_hit_pct`, `attacker_dmg`, …) are
all wrong (real: `attacker_hit`, `attacker_damage`, `attacker_crit`, `can_counter`,
`defender_vantage`, …).

**D-5. `GDD_01` Unit API divergences.** `GDD_01:639` documents
`use_weapon_durability() -> void`; real signature is
`use_weapon_durability(weapon_id := "") -> bool` (`Unit.gd:367`). `GDD_01:626` lists
a combat-stat method `damage(weapon)` on `Unit` — there is none (damage lives only
in `CombatResolver.compute_damage`); a call to `unit.damage(...)` per the GDD hits a
missing method. `perform_staff_heal()` exists in code but not in the GDD.

**D-6. `leveling_method` strings: GDD vs code.** `GDD_02` ("Leveling Methods")
presents Point Buy / Coin Flip / Dice Roll / Growth Rates as four selectable
methods; `GDD_01:260,328` defaults `leveling_method = "growth_rates"`. The code
implements exactly two values — `"growth_random"` and `"growth_fixed"` — defaults to
`"growth_random"` (`GameState.gd:15`), and `Unit.level_up()` matches only
`"growth_fixed"` vs. an else-random fallback. `NewGameScreen._LEVELING_OPTIONS` is
`["growth_random","growth_fixed"]` — so code + UI are internally consistent, but
none of the GDD's four method names exist, and Point Buy / Coin Flip / Dice Roll are
unimplemented despite being presented as features. (No code bug — purely a doc
divergence — but a developer trusting `GDD_02` would build against ghost methods.)

### 3b. MEDIUM — stale/wrong but not directly dangerous

**D-7. `GDD_01` folder tree is substantially wrong.** It omits real files
(`scripts/core/Boot.gd`, `EnemyAI.gd`, `GameMap.gd`, the three `MapCursor*` slices,
`scripts/shared/GameConstants.gd`, `scripts/items/ItemHandler.gd`,
`scripts/skills/SkillHandler.gd`, `scripts/resources/InventoryEntry.gd`,
`scripts/tests/`, `scripts/tools/`). It places `EnemyAI.gd` under a `scripts/ai/`
folder that does not exist (real: `scripts/core/EnemyAI.gd`). It lists a
`scripts/units/UnitStatBlock.gd` helper that **was never created** — yet
`GDD_09:319-323` *and* the `Unit.gd:6` header comment both still describe it (a
three-document phantom — see D-9). Its `scenes/ui/` list names
`UnitInfoPanel.tscn`, `TerrainInfoPanel.tscn`, `TargetSelectList.tscn`,
`VictoryScreen.tscn` — none exist.

**D-8. `GDD_01` autoload list is wrong.** It documents 4–5 autoloads. `project.godot`
registers **10**: `GameConstants, EventBus, SettingsManager, GameState, DataManager,
ConditionManager, SkillHandler, ItemHandler, CombatResolver, EnemyAI`. `GDD_01`
never says `GameConstants/SkillHandler/ItemHandler/CombatResolver/EnemyAI` are
autoloads — and worse, `GDD_01:161-164` draws `CombatResolver` and `EnemyAI` as
**child Nodes of `GameMap.tscn`**, contradicting their autoload registration (the
code reaches them via `/root/CombatResolver`, `/root/EnemyAI`). `GDD_01` contradicts
itself here.

**D-9. GDD internal contradictions.**
- *Range fields:* `GDD_01:861` (`range_min:int`) vs `GDD_09:155` (`range_min_formula`
  string) — `GDD_09` notes the change, `GDD_01` was never updated.
- *Hit/crit roll comparator:* `GDD_02` "Single Attack Resolution" says "roll ≤
  To-Hit %"; `GDD_01:558` documents `_roll_hit` as `randi() % 100 < pct`. The code
  uses `<` (`CombatResolver.gd:347,354`) — correct FE convention, matches `GDD_01`,
  contradicts `GDD_02`.
- *`UnitStatBlock.gd`:* described as real by `GDD_01:128`, `GDD_09:319-323`, and the
  `Unit.gd:6` comment; the file does not exist (all stat math is inline in `Unit.gd`).
- *`CombatResolver`/`EnemyAI` location:* `GDD_01` scene tree (child node) vs.
  autoload reality (see D-8).

**D-10. Input Map divergences (`GDD_01:703-718` vs `project.godot [input]`).**
`open_menu` — GDD says "Escape, Enter"; real binding is **M** (keycode 77) only.
`open_settings` (O key) is a real action absent from the GDD table. `confirm`,
`cancel`, `next_unit`, `prev_unit`, `show_danger_zone` match. (This is a *good*
state — the M-key rebinding fixed the 2026-05-17 ESCAPE bug — but the GDD never
recorded it.)

**D-11. `GDD_01` API drift on GameState / TurnManager / MapCursor / MapData.**
- `GameState`: GDD shows public `player_units`/`enemy_units`/`selected_unit`; code
  has private `_player_units`/`_enemy_units` and no `selected_unit` (selection lives
  in `MapCursorSelection`). Code adds `party_gold`/`party_items` the GDD omits.
- `TurnManager`: GDD `start_map(map_data)` vs real `start_map(map_data, grid)`; GDD's
  `_combat_lock` field does not exist; `record_move_start()` is real but undocumented.
- `MapCursor`: GDD documents `_state: String` + `const CURSOR_SPEED`; code uses an
  `enum State` and has no `CURSOR_SPEED` (key-repeat constants moved to
  `GameConstants`/`MapCursorInput`). GDD's "Add Now" zoom hooks
  (`ZOOM_LEVELS`, `_handle_zoom`) were not added.
- `MapData`: GDD `required_survivor_names` vs real `required_survivor_ids`
  (matched against `unit_id`); GDD omits `MapData.grid` and `camera_start_tile`.

**D-12. `GDD_09` status snapshot is stale.** `GDD_09:33` claims "155 passing across
8 suites" — actual is **18 suites / 347 tests**. `GDD_09:21` claims "39 .tres files"
— actual is ~46 (6 classes + 10 weapons + 2 items + 13 skills + 6 roster + 8
enemies + 1 map). `GDD_09` lists "Skills (12 files)"; `data/skills/` has **13**
(`s_rank_mastery.tres` is the unlisted extra). `GDD_09:22` says roster `unit_id` is
"not set (safe default '')" — but the roster `.tres` files **do** set it
(`unit_01_soldier.tres` → `unit_id = "unit_01_soldier"`), and
`GameState.load_default_roster:135` *skips* any file with an empty `unit_id`, so the
GDD's "safe default" claim is doubly wrong.

### 3c. LOW — cosmetic / naming

**D-13.** `EventBus.phase_changed` is typed `(new_phase: int)` in code with a
comment (an autoload can't reference `GameState.Phase` at parse time); `GDD_01:433`
shows the idealised `(new_phase: GameState.Phase)`. Functionally equivalent.

**D-14.** `GDD_01:392-401` shows the weapon triangle as `DataManager._weapon_triangle`;
it actually lives in `GameConstants.WEAPON_TRIANGLE` (the values match).

**D-15.** `GDD_01:723-739` frames `ai_profile`/`is_default_roster` as a pending
"Field Addendum"; they are already integrated into `UnitData.gd:49-51`.

**D-16.** `MapData.gd:19` comment says `required_survivor_ids` holds "unit names";
it holds `unit_id`s.

---

## 4. Positive Observations

1. **Headless-mode discipline is consistent and correct.** Every core/unit script
   reaches autoloads via `get_node_or_null("/root/…")` guarded by `is_inside_tree()`,
   and uses `.get()/.set()/.call()` for the `class_name`-less autoloads. This is the
   exact pattern the project's MEMORY notes prescribe, and it is applied uniformly —
   it is why 347 tests run under `--script` with no SceneTree.

2. **The combat pipeline is well-factored and genuinely side-effect-honest.**
   `resolve_combat` / `apply_combat_result` cleanly separate "compute the exchange
   list" from "commit HP/EXP/durability/death", weapon breakage is modelled inside
   the simulation so no discarded exchanges leak, and `preview_combat` snapshots and
   restores the exact mutable fields a skill could touch. The `_run_strike_series`
   single guarded loop behind all four strike series (attacker / counter / vantage /
   follow-up) means the "stop if either side is dead" rule cannot drift — I traced
   the vantage + follow-up interaction and the defender's total strike count is
   correctly preserved across the reorder.

3. **Strong "fail loud at load" instinct where it exists.** `GameMap._validate_map`
   asserts grid dimensions and terrain chars; `DataManager` `push_error`s on unknown
   ids and validates skill cross-references; `GameState.load_default_roster` and
   `GameMap._spawn_units` null-check `load()` results before `duplicate()` and skip
   bad data with `push_error` (deliberately not `assert`, so release builds still
   surface it). The comments explain *why* `push_error`-not-`assert` repeatedly.

4. **The RefCounted-slice pattern keeps `MapCursor` legible.** `MapCursorTargeting`,
   `MapCursorSelection`, and `MapCursorInput` each inject their dependencies via
   `setup()` and own one concern, so `MapCursor` stays a readable FSM. Encapsulation
   holds — the slices are referenced only by `MapCursor` and their tests.

5. **Comments explain non-obvious decisions, not just restate code.** The Nihil
   negate pre-pass rationale, the `effective_def` vs raw-DEF ordering, the
   "deep-copy each `InventoryEntry` individually because `Array.duplicate(true)`
   shares Resource refs" note in `GameState._snapshot_unit_data`, the
   `damage_taken_this_map` "count HP lost not raw damage" comment — these document
   reasoning a maintainer would otherwise reverse-engineer or break.

---

## 5. Architectural Observations

- **The documentation has become a liability, not an asset.** This is the dominant
  architectural finding. `GDD_01_Architecture.md` is the document a new contributor
  would read first, and it is wrong about resource fields, every major API
  signature, the folder layout, the autoload set, and the Input Map. The project's
  own `AGENTS.md` mandates docs-as-source-of-truth ("All Documentation should go and
  be read from the appropriate subfolder"), but the *code* is currently the only
  reliable spec. The drift is concentrated and explicable — `GDD_01` was never
  revised after four refactors (the `InventoryEntry` typing / ARCH-05, the stat-name
  expansion, the range-formula change, the CombatResolver context-pipeline rewrite /
  A3) — so the fix is bounded: rewrite `GDD_01`'s "Resource Class Definitions" and
  "Key Script Function Signatures" sections against the code, and reconcile the
  three documents still citing the phantom `UnitStatBlock.gd`.

- **Validation coverage is asymmetric.** Map grids, skills, and id lookups fail loud;
  inventory entries and weapon/item data do not (`InventoryEntry.validate` unused;
  `DataManager` skips the weapon/item catalogues). The "fail at load" net has holes
  in exactly the places — authored `.tres` data — where typos are most likely.

- **UI→system coupling is mostly clean but leaks in two spots.** `HUD` reaching into
  `GridManager`'s constants (and `Unit.gd` doing the same) is the one place the
  otherwise-tidy EventBus/`setup()` boundary is bypassed. A `get_terrain_bonuses()`
  accessor closes it.

- **Scaffolding has outpaced features in the settings layer.** `combat_animations`
  is a player-visible toggle with no backing system; `GameState.max_skills` /
  `max_inventory` are documented-as-inert caps. This is fine as forward-planning *if*
  the inert options are visibly marked; today `combat_animations` is not.

- **Enemy `_unit_states` entries go stale.** `TurnManager.start_map` registers
  enemies as `READY`; after an enemy phase they sit at `DONE` and are never reset
  (only `team == "player"` units are). Harmless — `EnemyAI` ignores `_unit_states`
  and `can_unit_act` is queried for player units only — but it is dead state that a
  future "enemy can act twice" feature could trip over.

---

## 6. Prioritized Action Plan

Ordered by impact ÷ effort.

1. **Rewrite `GDD_01`'s "Resource Class Definitions" and "Key Script Function
   Signatures" sections against the code** (D-1 → D-5, D-11). Highest impact: this
   is the doc that would actively cause bugs. Mechanical, ~1 session.
2. **Fix `GDD_01`'s folder tree, autoload list, and Input Map; delete the
   `UnitStatBlock.gd` phantom from `GDD_01`, `GDD_09`, and the `Unit.gd:6` comment**
   (D-7, D-8, D-10, D-9). Same pass as #1.
3. **Refresh `GDD_09`'s status snapshot** — 18 suites / 347 tests, real `.tres`
   count, 13 skills, the `unit_id`-is-set correction (D-12). Five-minute edit.
4. **Reconcile the GDD self-contradictions** (D-9): pick the `≤`-vs-`<` roll
   wording (code uses `<` — fix `GDD_02`), and the range-field and autoload-vs-node
   contradictions.
5. **Wire up `InventoryEntry.validate()`** in `load_default_roster` /
   `_spawn_units`, and extend `DataManager._validate_cross_references` to the
   weapon/item catalogues (code Medium #4 and #3). Closes the validation gap.
6. **Mark `combat_animations` as `[Phase 2]` / disabled in `SettingsScreen`** until
   a combat-animation system exists (code Medium #1). Honest UX, trivial.
7. **Add `GridManager.get_terrain_bonuses()` and route `HUD` + `Unit` through it**
   (code Medium #2). Closes the coupling leak.
8. **Low-effort cleanups:** `HUD._on_phase_changed` magic number; `has_skill()`
   union; `combat_started` emit timing/rename; the two 2026-05-17 carry-over Lows;
   the `tile_position`/`mastery_skills` comment wording.

Items 1–4 are the substance of what was asked for and should be done together as a
single "docs resync" pass. None of the code findings are urgent — there is no
Critical or High code bug and the suite is fully green.

---

## Assumptions Flagged

- I assume `GDD_01` is *intended* to be a current technical reference (its detail
  level implies so). If it is instead treated as a frozen original-design record
  with `GDD_updates.md` as the live delta, the D-series findings are "expected
  drift" rather than defects — but in that case `GDD_01` should carry a banner
  saying so, because nothing currently signals it.
- I did not exhaustively diff every `.tres` data file against its resource schema;
  I spot-checked `soldier.tres`, `iron_sword.tres`, and the roster files, all of
  which matched the code. A full data-vs-schema sweep is a separate exercise.
- The UI scene `.tscn` `@onready` paths and signal wiring were verified clean by a
  subagent pass (all 59 paths resolve); I did not re-verify each by hand.
- Suite was read and re-run: 18 suites / 347 tests green (`bash run_tests.sh`,
  exit 0).
