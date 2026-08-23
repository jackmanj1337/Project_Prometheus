---
Role: dated
---

# Harsh Code Review — 2026-05-13c

Reviewer: Claude (Opus 4.7) using the new godot-analyzer MCP tools.
Scope: every file under `scripts/`, `scenes/`, `data/`, plus `tools/godot-analyzer-mcp/`.
Tone: deliberately harsh per request — issues are listed without softening. Severity tags:
**CRITICAL** (will break or already broken), **HIGH** (latent bug, data corruption, or visible misbehaviour), **MEDIUM** (correctness/maintainability), **LOW** (style/polish).

---

## 0. Verdict in one line

The architecture is genuinely good (clean autoload split, single‑source‑of‑truth constants, deterministic vs random level‑up paths, decoupled GridManager, broad test coverage). The damage is in the **details**: a brand‑new MCP tool is silently broken, several "fixed" bugs have new variants, and combat/AI carry subtle race conditions and double‑counted modifiers that the tests cannot catch because the mocks are shaped exactly like the production bugs.

---

## 0a. Decisions log (locked 2026-05-13c)

After review walkthrough with the user, the following decisions were made. Implementation is queued for the next session(s); the review items below remain as the source‑of‑truth description of each issue.

| # | Item | Decision |
|---|---|---|
| 1 | §3.1 Miracle skill text vs code mismatch | **Update docs** to match code ("survive at 1 HP"). |
| 2 | §9b.1 Empty roster/enemy `unit_id` | **Populate** with filename‑style ids (`unit_01_soldier`, `e1_soldier`, etc.) + add a DataManager assert that every roster `unit_id` is non‑empty. |
| 3 | §9b.3 Dead SkillHandler dispatch arms | **Keep + stub** — replace bodies with `# [STUB — M9]` markers matching the SkillHandler movement‑override pattern. |
| 4 | §9b.4 SettingsScreen orphan script | **Add to MVP build list** — create `SettingsScreen.tscn` so the Settings menu actually works. |
| 5 | §5.2 DataManager null returns | **Option A — Assert at load.** Validator in `DataManager._ready` resolves every id reference across loaded resources; getters drop the null path; downstream null checks deleted. |
| 6 | §5.3 Snapshot/restore drift | **Option A — Manual + coverage test.** Keep `_snapshot_unit_data`/`_restore_unit_data` explicit; add a test that walks `UnitData.get_property_list()` and fails when a property is missing from the snapshot (with an allowlist for intentional exclusions). |
| 7 | §5.12 ConditionManager stub warning spam | **Drop the warnings + add `# STUB — M8` markers** (same treatment as decision 3 — different file, same pattern). |
| 8 | §7.1 Inventory dict shape | **Option A — Migrate now to typed Resource.** Define `InventoryEntry extends Resource`; convert all roster + enemy `.tres`; update all consumers. Estimated half a day of careful work, all‑or‑nothing. |
| 9 | §7.4 `tile_position` location | **Option A — Move to UnitData.** Confirmed by the save‑model discussion below (§0b): shifting‑terrain saves make 9A the only architecture that doesn't grow parallel structures. |

The review sections below preserve the full analysis of each item — including options not chosen — for future reference.

---

## 0b. Save‑system implications (added 2026-05-13c)

The user noted that future maps may include shifting terrain and destructible locations, which means active map state will eventually need to be in save data. This forces a commitment to **suspend‑style saves** (save anywhere, restore exactly where you were) rather than metagame‑only checkpoints. The current snapshot system has three quiet assumptions that suspend saves with shifting terrain break:

1. **"MapData is the source of truth for terrain."** Today `MapData.grid` is loaded once and painted onto `TileMapLayer_Terrain`. `GridManager.get_terrain_at` reads live from the TileMapLayer, so it sees runtime mutations. But on save→reload the disk MapData says "wall" while the save said "plain"; the snapshot has no terrain field. Restore would silently revert the player's wall‑destruction work.
2. **"Enemies are disposable; reload from disk."** Today `GameMap._spawn_units` does `load(path).duplicate(true)` for each enemy. Restore = scene reload = fresh enemies at map‑start placements with full HP. For suspend saves mid‑combat, that destroys the actual enemy state you want to preserve (mid‑combat HP, broken weapons, current position).
3. **"`_map_start_snapshot` is the only snapshot."** Single in‑memory snapshot taken at map start. Suspend saves want snapshots at arbitrary points AND need to survive a disk round‑trip (serializable to `.cfg`/`.json`), which the current dict‑with‑Resource‑references shape can't do cleanly.

Two new architectural questions surface from this — **not decided yet, intentionally deferred** until the save model itself is scoped:

### N1 — Terrain state in saves
| Pattern | Pro | Con |
|---|---|---|
| Snapshot live TileMapLayer as `Array[String]` at save time | Simple; mirrors the existing grid shape | Larger save files; redundant when nothing's changed |
| Store only diffs from `MapData.grid` (dict of tile → terrain) | Smaller; explicit "what changed" | Locked to the original MapData version — if a patch ships a new map revision, saves can't restore cleanly |
| Deep‑copy the whole MapData into the snapshot | Bulletproof; supports map evolution mid‑campaign | Heaviest; serializing MapData adds complexity |

### N2 — Enemy unit state in saves
| Pattern | Pro | Con |
|---|---|---|
| Snapshot every live enemy's UnitData, parallel to player roster snapshot | Matches existing player pattern; full state preserved | Doubles snapshot scope; need a stable identity scheme for enemies (current enemy `.tres` files have empty `unit_id` — see 9b.1) |
| Snapshot only initial placements; enemies reset to map start on load | Minimal scope | Incompatible with suspend saves mid‑combat; only works for "save between maps" |

**Recommendation:** decide N1 + N2 when the save‑system milestone is scoped, not now. What matters today:

- Decision **9A** (move `tile_position` to UnitData) is locked because it's the only choice compatible with *any* suspend‑save model — every alternative grows parallel structures (player positions, enemy positions, terrain state) instead of consolidating onto a single snapshotable shape.
- Decision **6A** (snapshot coverage test) is locked because the snapshot scope is going to grow as map state and enemy state move into it; the test prevents silent omissions during that growth.
- **Add `# TODO save-system` banners** to `MapData.gd` and `GameState.gd` flagging that terrain mutations and live enemy state are out of scope for the current snapshot — so the next person touching either file sees the expansion point.

---

## 1. CRITICAL — the brand‑new MCP server is half‑broken

### 1.1 `validate_onready_paths` never finds a scene

Tested against every UI script that *clearly has a scene attached* (`HUD.gd`, `MapCursor.gd` parent scene, `ActionMenu.gd`, etc.). Every single call returned:

> `No scene found using this script — cannot validate paths.`

…yet `find_scenes_with_script("res://scripts/ui/HUD.gd")` correctly returns `scenes/ui/HUD.tscn`. Root cause is in `tools/godot-analyzer-mcp/tools/script.py:6‑16`:

```python
def _resolve(path_str, project_root):
    if path_str.startswith("res://"):
        return project_root / path_str[6:]
    return Path(path_str)          # ← keeps it RELATIVE

def _to_res(path, project_root):
    try:
        return "res://" + path.relative_to(project_root).as_posix()
    except ValueError:
        return str(path)           # ← raised because path is relative
```

When the caller passes `"scripts/ui/HUD.gd"` (no `res://`), `_resolve` returns the bare relative `Path("scripts/ui/HUD.gd")`. `_to_res` then calls `relative_to(project_root)` on it, which raises `ValueError`, so the function falls into the `except` branch and returns `"scripts/ui/HUD.gd"`. The comparison `node["script"] == script_res` then fails because `parse_tscn` stores the script field as `"res://scripts/ui/HUD.gd"` (with prefix).

**Why this matters:** the entire reason this MCP tool was written — catching stale @onready paths — is non‑functional. We shipped a tool last session that returns "no scene found" for every UI script.

**Fix (≈3 lines):**

```python
def _resolve(path_str: str, project_root: Path) -> Path:
    if path_str.startswith("res://"):
        return project_root / path_str[6:]
    p = Path(path_str)
    return p if p.is_absolute() else (project_root / p)
```

That single change makes `_to_res` succeed and `validate_onready_paths` work. Recommend adding a smoke‑test script under `tools/godot-analyzer-mcp/` so this can't regress silently again.

### 1.2 No tests for the MCP server at all

The server is pure stdlib Python — testing it with `pytest` (or even a `python3 -m unittest` file) would have caught 1.1 in 30 seconds. Right now the only "test" is whether Claude Code launches without an error.

**Recommendation:** add `tools/godot-analyzer-mcp/tests/test_script_paths.py` that calls each tool with both `res://...` and bare `scripts/...` inputs and asserts the scene‑hit count.

---

## 2. CRITICAL — combat correctness bugs

### 2.1 Charm aura double‑counts (CombatResolver + SkillHandler)

`CombatResolver._collect_combat_modifiers()` iterates `gs.all_units` and fires `on_combat_apply_modifiers` for every unit that is **not** the attacker or defender (CombatResolver.gd:62‑66). That's correct *as far as it goes* — but `_apply_charm` (SkillHandler.gd:161‑177) then writes the +10 bonus to **both** `atk_mod` and `def_mod` whenever the bearer is on the same team. Result:

- A Charm bearer on the attacker's team buffs the attacker (good).
- The **same** charm bearer also buffs the defender if the defender happens to be on the same team as the bearer (impossible in 1v1 PvE, but it will fire in friendly‑vs‑friendly tests, mock fights, or duel/spar mechanics later).
- More importantly: nothing stops two Charms from stacking on the same unit — both fire and the attacker gets +20/+20.

The intent per FE convention is "+10 once, regardless of how many charmers". Either pick the highest in range, or apply once per matchup.

**Severity:** HIGH today, CRITICAL once a second Charm‑class character lands.

### 2.2 `apply_trigger` ignores its return value for most callers

`SkillHandler.apply_trigger()` returns the (possibly mutated) `context` (SkillHandler.gd:34). `CombatResolver._collect_combat_modifiers` calls it three times without capturing the return value (lines 66, 70, 72). Today every skill mutates the dict by reference, so the return value is redundant — but `_apply_miracle` already proves the pattern of "rebind via return" exists in `_resolve_single_attack` (CombatResolver.gd:304). One future skill that does `context = {…}` (rebuilds the dict) will silently no‑op for the calls that drop the return value.

**Fix:** Either remove the return value entirely (commit to mutation‑in‑place) or capture it everywhere. Pick one and write a contract in the docstring.

### 2.3 `apply_combat_result` decrements durability for missed staff/projectile attacks correctly… but for **missed** "always‑use" weapons on a unit that already broke its weapon, the `broken` guard runs *before* the durability decrement (CombatResolver.gd:515‑522). That is actually correct now — but look at the order:

```gdscript
if weapon_id != "" and broken.get(atk, "") == weapon_id:
    continue                                  # skip the exchange entirely

if exchange["loses_durability"] and …:
    if atk.use_weapon_durability(weapon_id):  # may set broken[atk]
```

A weapon that breaks in exchange N also has `loses_durability=true` in exchange N — fine. But the **next** exchange from the same unit also had `loses_durability` calculated up front in `_resolve_single_attack` (line 311‑313), so its `hit`/`damage` were computed against a weapon the unit no longer has. We then `continue` and skip applying them, **but the EXP totals at the bottom (line 491) and the `defender_died` check (line 481) were already baked in by `resolve_combat`**, which had no idea the weapon would break.

Result: if the brave-sword test in `test_combat.gd:428‑440` were extended to include EXP attribution, you'd see EXP awarded for hits that never landed.

**Severity:** HIGH. The test only asserts HP afterwards, not EXP — so this is exactly the kind of bug current coverage misses.

### 2.4 `MockUnit.use_weapon_durability` in `test_combat.gd` does **not** mirror production semantics

Production `Unit.use_weapon_durability()` decrements `entry["uses_remaining"]` and removes the entry when it hits 0. The mock just decrements a single `_weapon_uses` integer and **never** sets `_weapon` to null. So in the brave‑break test (test_combat.gd:428‑440), the second exchange's `get_equipped_weapon()` still returns the broken weapon. The fact that production *also* still returns the broken weapon (because `apply_combat_result` reads `weapon` from the exchange dict captured pre‑combat, not via `get_equipped_weapon()`) saves the test, but the mock and production now diverge in a way that hides future bugs.

**Fix:** make the mock null out `_weapon` when uses hit 0, matching the entry‑removal semantic.

### 2.5 `compute_damage`'s S‑rank bonus double‑applies through `Unit.damage()`

`Unit.damage()` adds `+1` for S‑rank (Unit.gd:296‑298). `CombatResolver.compute_damage` *also* adds `s_bonus = 1` for S‑rank (CombatResolver.gd:193‑194). However, `compute_damage` doesn't call `Unit.damage()` — it computes raw from `base_stat + mt + s_bonus`. So today there's no double‑application. But `Unit.damage()` is a **public** function used by no production caller and only exists to satisfy `test_unit_stats.gd`. It is the **only** function that returns the offensive number without subtracting defender defence — every real caller goes through `CombatResolver.compute_damage`.

**Severity:** MEDIUM — `Unit.damage()` is dead code waiting to be miscalled. Either delete it and update the test, or refactor `CombatResolver.compute_damage` to use it. Two formulas, one definition.

### 2.6 Damage multipliers cannot reduce damage to 0 below the multiplier path

`_resolve_single_attack` (CombatResolver.gd:291‑293) does:

```gdscript
var dmg_mult: float = actor_mod["damage_multiplier"]
if dmg_mult != 1.0:
    damage = maxi(0, int(damage * dmg_mult))
```

`dmg_mult` defaults to 1.0 and is never assigned anywhere in the codebase (grep confirms). It's declared in `_build_combat_context` (line 35,37) and never written. That's dead infrastructure — fine until a skill writes to it, then `int(damage * 0.5)` truncates toward zero in a surprising way for non‑integer products. Document the rounding rule.

---

## 3. CRITICAL/HIGH — gameplay logic bugs

### 3.1 `Miracle` skill description says "halve", implementation guarantees survival

`SkillData "miracle"` description: `"LUK% chance to halve a fatal blow."` (verified via MCP).
`SkillHandler._apply_miracle` (SkillHandler.gd:104‑115) sets `context["damage"] = sim_hp - 1`. That's "survive with 1 HP", not "halve". Either rewrite the data file's description or rewrite the implementation. Pick one and update the GDD if needed.

**Decision required:**
| Option | Pro | Con |
|---|---|---|
| Keep "survive at 1 HP" (current code) | Matches Sacred Stones convention; simpler | Need to update text in `miracle.tres` and likely GDD |
| Change to "halve damage" (per text) | Less swingy; matches the literal description | Allows mutual‑kill outcomes where the proc still kills; new behavioural test needed |

Recommendation: keep the code, update the text — it's the FE‑standard behaviour and players will expect it.

### 3.2 `EnemyAI._flood_costs` has O(N²) frontier scan and ignores enemy occupants

`_flood_costs` (EnemyAI.gd:227‑248) does a Dijkstra but:
- Re‑scans the entire frontier each iteration (line 232‑235). For a 42×26 map that's up to ~1 000 cells × ~1 000 = a million comparisons per enemy turn. Today that's tolerable; once you add bigger maps or pathing‑heavy AI it will stutter.
- Doesn't check `get_unit_at(next)` at all — the cost map is built as if the map were empty of units. Combined with `_find_nearest`, this means the AI's "nearest" estimate can route through walls of allied or enemy bodies that physically block movement. Reasonable for "estimate distance to a target", arguably wrong for "pick a move tile".

**Fix:** Replace the linear scan with a min‑heap (Godot 4 has `PriorityQueue` via `Array` + `bsearch_custom` or use the GDScript pattern of `var heap := []` with insertion‑sorted push). And either document the "ignore occupants" choice in the comment block or check occupancy where it matters.

### 3.3 `EnemyAI._choose_heal_move_tile` picks the lowest HP ally regardless of how injured

The loop (EnemyAI.gd:106‑128) tracks `best_target_hp` initialised to `0x7FFFFFFF` and selects any ally with `hp < best_target_hp`. That picks the ally with the **lowest absolute HP**, not the one missing the most HP. A wounded armour at 30/40 will be ignored in favour of a healthy thief at 18/18 — wait, no: `hp >= max_hp` filters out healthy allies on line 116. So that case is fine. But it still favours a high‑HP unit at 20/40 over a low‑HP unit at 22/22 (no, 22/22 is filtered out)… OK so the filter saves it.

What it does NOT favour is **most‑injured by percentage**. A knight at 30/60 (50%) loses to a thief at 18/20 (90%). Compare ratios, not absolutes.

**Fix:** `var injury_pct := float(max_hp - hp) / float(max_hp)` and maximise that.

### 3.4 `TurnManager.start_player_phase` calls `check_victory_conditions` after restoring units' READY state

`start_player_phase` (TurnManager.gd:72‑86) ticks modifiers, applies fort healing, applies start‑of‑turn skills, then resets each player unit to READY, **then** calls `check_victory_conditions`. If the player has already lost (no living players) we still spend a frame setting nonexistent units to READY and calling `reset_appearance` on null/freed nodes. The `is_instance_valid` guard on line 82 saves us from a crash, but the whole phase shouldn't run if the map is already over.

**Fix:** call `check_victory_conditions` first; early‑return if `_map_over`.

### 3.5 `Boot.gd` doesn't fall back if `MainMenu.tscn` is missing

If MainMenu.tscn is deleted/renamed, `Boot.gd:8` pushes an error and the game freezes on the empty Boot scene with no UI. At minimum, `quit()` after the error or render an error label.

### 3.6 `Unit.handle_death()` ordering can lose data on permadeath

```gdscript
if gs.permadeath_enabled:
    data.is_incapacitated = true
gs.unregister_unit(self)
...
queue_free()
```

`data` is a Resource shared with `player_roster` (after `duplicate(true)` at load time). Setting `is_incapacitated` works. But the unit is also removed from `_player_units`/`_enemy_units`. `queue_free()` is deferred — if any listener of `unit_died` calls `gs.get_living_player_units()` on the **same frame**, the freed unit is already excluded via the `_player_units.erase(unit)` in `unregister_unit`, which is correct. So this is fine *today*, but the comment "Either way the scene node is freed" obscures that `data` survives via the roster. Worth a one‑line comment.

### 3.7 `MapCursor._scroll_camera_if_needed` assumes default zoom 1.0

`_scroll_camera_if_needed` (MapCursor.gd:583‑607) computes `tiles_w` from raw viewport pixels / TILE_SIZE. If anyone ever sets `_camera.zoom != Vector2.ONE`, the math is wrong by exactly the zoom factor. Either assert zoom == 1 or divide by zoom.

### 3.8 `_undo_move_and_reselect` doesn't unlock the cursor first

After Cancel from ActionMenu, `_undo_move_and_reselect` sets state to `UNIT_SELECTED` (MapCursor.gd:496) but earlier `_try_move_selected_to_cursor` set `_state = State.LOCKED` during the tween. If the user manages to Cancel **during** the tween (action_menu_cancelled fires from the menu that's not even visible yet), state goes LOCKED → MOVED → action menu → Cancel → UNIT_SELECTED but the unit is still mid‑tween. The tween then completes and overwrites the position the user thinks they just snapped back to.

**Fix:** kill the tween in `_undo_move_and_reselect`, or guard with "ignore cancel while LOCKED".

---

## 4. HIGH — broken or misleading tests

### 4.1 `test_unit_stats.gd` instantiates `Unit.new()` outside the scene tree and never calls `_ready()`

`unit := Unit.new()` (line 26) — `@onready` vars (`_sprite`, `_hp_bar`) stay null. `take_damage()` and `heal()` happen to early‑return on null `_hp_bar`, so the test passes. **But this is testing a node in a state that production will never see.** The first time `Unit.gd` references `_hp_bar` without a null guard, every test in this file breaks.

**Fix:** instantiate from `Unit.tscn` and add to a temp `Node` parent so `@onready` resolves.

### 4.2 `MockUnit` in `test_combat.gd` reimplements production formulas

The mock copies (with subtle drift) the formulas from `Unit.gd`:

```gdscript
# Mock accuracy: skill*2 + luck + weapon.hit
# Real accuracy: same — but with S-rank +10 (mock returns false to has_s_rank, so never +10)
```

The mock **cannot** test S‑rank behaviour because it always returns false. That's why `test_combat.gd` doesn't have a single S‑rank assertion. `test_unit_stats.gd` covers it via `Unit.accuracy(iron_lance)`. Two formulas, two test paths — if either drifts the other is silent.

**Recommendation:** delete `MockUnit.accuracy/dodge/damage/etc` and have the mock delegate to a real `Unit` node. Or have CombatResolver depend on a UnitStatBlock interface (typed object) so it can be tested without a Node at all.

### 4.3 `run_tests.sh` "PASS" is unreliable

```bash
out=$(godot --headless ... | grep "Results")
if [[ "$out" == *"failed"* && ! "$out" == *"0 failed"* ]]; then
```

This greps for the literal word "Results" — if a test crashes before printing the summary line, `out` is empty, the `failed` check passes vacuously, and the suite is silently green. Also: `set -e` is not set, so a Godot launch failure (path wrong, missing project.godot) is invisible.

**Fix:** Check Godot's exit code. Every test already does `quit(0 if failed == 0 else 1)`. Just use `if ! godot --headless ... --script ...; then fail_count=$((fail_count+1)); fi`.

### 4.4 No tests for SkillHandler, ItemHandler, TurnManager, MapCursor menus

Skills have 12 effect_ids; not one has a unit test. ItemHandler has the "unknown effect_id consumes item" regression that was supposedly fixed last session — there's no test that exercises the unknown‑effect path. TurnManager's victory/defeat branching has zero coverage. The map‑victory and defeat tests would be 20 lines each.

---

## 5. MEDIUM — code smells

### 5.1 Autoload ordering is fragile and documented in comments only

`project.godot` defines 10 autoloads. SettingsManager talks about ordering: "GameState autoload runs after SettingsManager". This is enforced by **list order in project.godot** — there is no runtime guard. If someone reorders via the editor, GameState's `_ready` will read uninitialised values silently.

**Fix:** add a `_ready` order assert in DataManager / GameState that checks `Engine.has_singleton("…")` or that the dependency is initialised, and `push_error` if not.

### 5.2 `DataManager.get_class_data` returns null silently for unknown ids

Every getter (get_weapon, get_item, get_skill, get_class_data) does `push_error` + `return null`. Every caller then does `if x == null: return` or worse, derefs immediately (e.g. `Unit._get_class_data` line 70‑72 → caller calls `.growth_rates` on null = crash in `level_up`).

**Fix:** decide whether to `assert` (loud, dev‑facing) or to provide a `_fallback_class` sentinel. Right now we have the worst of both: an error log nobody reads, then a crash later. Recommend `assert` in `DataManager._ready` that every required id exists, then unchecked deref everywhere else.

### 5.3 `GameState` snapshot/restore is hand‑maintained twin lists of 18 fields

If any field is added to `UnitData`, three files need updating: `UnitData.gd`, `GameState._snapshot_unit_data`, `GameState._restore_unit_data`. Easy to miss.

**Options:**
| Approach | Pro | Con |
|---|---|---|
| `data.duplicate(true)` — store the whole resource | Single line | Snapshots way more than needed; `Resource.duplicate` is shallow for some types |
| Reflection: `for prop in data.get_property_list(): snap[prop] = data.get(prop)` | Auto‑syncs new fields | Brittle if you add transient/computed properties |
| Stay manual, add a test | Explicit | Tedious; the test itself is hand‑maintained |

Recommendation: option 2 with an explicit allowlist of property names. The list lives in one place, the snapshot/restore code shrinks to one loop.

### 5.4 `Unit._find_grid_manager` walks the tree every call until cached

`_get_grid_manager` (Unit.gd:143‑155) caches `_grid_manager` after the first successful find. But the cache‑miss path (`return null`) doesn't memoise — every terrain query before GridManager is wired walks the whole tree. Cheap, but the call site is in `get_terrain_def_bonus` which fires inside `compute_damage` which fires inside the AI loop. Cap the search depth or set a "tried and failed" flag.

### 5.5 `CombatResolver._restore_unit_state` for previews skips `damage_taken_this_map`, `growth_accumulators`, `is_shifted`, `shift_gauge`

`_snapshot_unit_state` (CombatResolver.gd:344‑351) only captures `hp`, `active_modifiers`, `skill_use_counters`. Any future on_combat_start skill that mutates `damage_taken_this_map` (Vengeance — listed in your "M9" plan) will leak that mutation into live state every time the player hovers a target for the preview panel.

**Fix:** snapshot every mutable field, or — cleaner — pass a `preview: bool` flag through context and have skills early‑return for the side‑effecting bits.

### 5.6 `WeaponData._eval_formula` is a static function calling `unit.get_effective_stat`

Static method receives a `Node` arg and pokes at `data.magic` directly (lines 84‑91). That couples `WeaponData` (a Resource) to `Unit`'s data shape. The formula parsing is good; the integration is weird. Either make it an instance method on `Unit` (`unit.eval_weapon_formula(formula)`) or pass a stat‑lookup callable.

### 5.7 `GameMap._validate_map` `push_error`s but does not abort

After a bad terrain char (line 151), the loop continues and `_paint_terrain` still runs. If `_CHAR_TO_SOURCE.get(ch, 6)` returns 6 (wall) for unknown chars, you silently paint walls where the designer intended… something. Add a `return` after the first error in a row, or maintain a `valid: bool` flag and bail in `_ready` if false.

### 5.8 `GameState.load_default_roster` ignores `dir.list_dir_begin` return value

`list_dir_begin()` returns an `Error` (Godot 4.3). Same in `DataManager._load_directory`. If the directory exists but iteration fails (permissions, IO error), we silently load nothing.

### 5.9 Long `match` arms in `SkillHandler._execute_skill`

12 effect_ids in a single match; each dispatches to a hand‑named function. Fine for now; once you add the 30+ M9 skills, dispatch via a `Dictionary[String, Callable]` will scale better and let you register skills from data instead of code.

### 5.10 `LevelUpScreen.gd` queues unbounded

`_on_unit_leveled_up` appends to `_queue` (LevelUpScreen.gd:33). If the player auto‑resolves a fight that level‑ups 5 units simultaneously (unlikely in MVP, certain in arenas/grinding), the user has to press A 5 times. Acceptable for MVP but worth a TODO.

### 5.11 `SettingsScreen.gd` references `SettingsManager` as a class name

Lines 83, 109, 114, 119, 123, 128, 133, 138, 143 use bare `SettingsManager` (line 83: `var sm := SettingsManager`). This works because autoloads register a global of that name in Godot 4, but tests that don't have the autoload registered will crash with `Identifier "SettingsManager" not declared`. Other scripts consistently use `get_node_or_null("/root/SettingsManager")`. Pick one pattern.

### 5.12 `ConditionManager` is 5 stubs that all `push_warning`

Calling `has_condition(unit, "poison")` from any combat path right now floods the console with warnings *and* returns false. That's not a stub, that's a footgun — a future caller assumes "false = no poison" which is correct, but also "false = no_op" which masks the fact you forgot to implement. **Either** raise the warning to `push_error` and crash in dev builds, **or** drop the warning entirely and replace it with a `# STUB — M8` comment. Right now everyone learns to ignore those warnings, then misses a real one.

### 5.13 `MapCursor` uses `_unhandled_input` + `_input` simultaneously, plus directly polled mouse buttons

The middle‑mouse danger zone (lines 158‑166) lives in `_input`, while keys and left/right clicks live in `_unhandled_input`. Splitting the handler across two callbacks means it's easy to swallow an event in one and miss the other path. Consolidate.

### 5.14 `_held_dir` reset relies on `is_action_released` matching by direction

`MapCursor._input` (lines 142‑147) only resets `_held_dir` if the released action's direction matches `_held_dir`. If you press Right, hold, then press Left (still holding Right), then release Right — `_held_dir` is now Left from the new press, and releasing Right matches Left only if both happen to point the same way, which they don't, so the loop continues. Edge case but reproducible.

---

## 6. LOW — style / polish

- **Magic number `0x7FFFFFFF`** appears 5+ times across `EnemyAI` and `GridManager`. Define `const INT_MAX := 0x7FFFFFFF` once.
- **`for i in arr.size():`** is the canonical Godot 4 form but mixed with `for i in range(arr.size())`. Pick one (`for i in arr.size()` is faster).
- **`var name: String =`** shadows the built‑in `Object.name`. Rename to `tname`/`source_name` in tileset generators.
- **`team in [...]` vs `if not ("team" in unit)`** — verbose Duck‑typing scattered through GridManager. Make Unit `class_name` consistent and just type‑hint `attacker: Unit`.
- **Trailing blank line / mixed tab indentation** — `MapCursor.gd` ends with two blank lines; `EventBus.gd` and others end without one. Run `gdformat`.
- **`push_warning` used as control flow** — search shows 9 warnings that the program proceeds past. If "warning" means "user should care", split into recoverable (push_warning) and developer‑error (push_error or assert).
- **`@onready var _x: Type = $Path`** is correct, but `_panel` in MapMenu/PhaseBanner is unused after `_ready`. Drop or `@warning_ignore("unused_private_class_variable")`.
- **`CombatHUD` script attached to `CombatHUDLayer` (a CanvasLayer) but file says "extends CanvasLayer"** — confirmed via MCP. Naming is fine; just note that the `Layer` suffix in the node name suggests scaffolding, not the actual HUD.

---

## 7. Architectural decisions worth your attention

### 7.1 Inventory as `Array[Dictionary]` vs typed Resource

Already flagged in `UnitData.gd:36` (`TODO ARCH-05`). The current dict shape is unsafe: nothing stops a typo'd `"weapon_id"` → `"weaponid"` from compiling. Migrating to `class InventoryEntry extends Resource` with typed fields catches this at parse time.

| Option | Pro | Con |
|---|---|---|
| Stay Dict | Easy serialisation; zero migration | Typos are runtime crashes, autocomplete useless |
| Typed Resource | Compile‑time safety, autocomplete, can attach methods (`is_weapon()`) | Migration: every save file & every test must change |
| Variant: keep Dict, add `InventoryEntry.from_dict(d)` helper | Incremental | Two shapes coexist, drift risk |

Recommendation: full typed Resource migration before Phase 2. The longer you wait, the more save data exists in the old format.

### 7.2 `EnemyAI` has three almost‑identical "find tile" loops

`_choose_move_tile`, `_choose_heal_move_tile`, and the inner loop of `_act` all walk move_tiles and score them. Extract a `_score_move_tiles(tiles, scorer: Callable) -> Vector2i` so the scoring logic is in one place.

### 7.3 Tests are SceneTree scripts, not GUT/GdUnit

All 8 tests are hand‑rolled `extends SceneTree` files. Pros: zero deps, run in CI directly. Cons: no fixtures, no setup/teardown, every file rebuilds its own assertion harness, no parameterised cases.

| Option | Pro | Con |
|---|---|---|
| Stay hand‑rolled | No deps; works today | Boilerplate; weak failure messages; no fixtures |
| Migrate to GUT | Mature; readable output; broad community use | Adds an addon dep; slight CI complexity |
| Migrate to GdUnit4 | Modern; better Godot 4 integration; mocking built in | Smaller community; learning curve |

Recommendation: revisit after Phase 1 ships. Don't migrate mid‑sprint, but don't grow the hand‑rolled set past ~12 files either.

### 7.4 `tile_position` lives on Unit, not on UnitData

This is *correct* for a scene‑bound unit but means anything that wants to reason about position from data alone (the snapshot system, the AI's flood, save/load) reaches into the Node. Two camps:

- "Position is presentation, stays on Unit" — current design.
- "Position is state, lives on UnitData" — easier to serialise.

You will hit this when you implement saves. Plan the decision now.

---

## 8. Quick wins (would close 8 issues in < 1 hour)

1. Fix `tools/godot-analyzer-mcp/tools/script.py:_resolve` (1.1) — 3 lines.
2. Fix `run_tests.sh` to use exit codes (4.3) — 5 lines.
3. Update `miracle.tres` description (3.1) — 1 string.
4. Capture `apply_trigger` returns in `_collect_combat_modifiers` (2.2) — 3 lines.
5. Add early `check_victory_conditions` to `start_player_phase` (3.4) — 2 lines.
6. Snapshot `damage_taken_this_map` in `_snapshot_unit_state` (5.5) — 1 line.
7. Add `const INT_MAX := 0x7FFFFFFF` to `GameConstants` (6) — 1 line.
8. Tighten `MapCursor.lock()` to also clear `_held_initial`/`_held_timer` (5.14 + cleanup) — 2 lines.

---

## 9. What this report is NOT covering

- Performance benchmarks (no profiler runs).
- Visual/UI polish — none of the UI scenes were inspected as rendered output, only structurally.
- Save/load correctness — the system doesn't exist yet.
- Audio bus correctness — `_apply_audio` silently skips missing buses; can't verify without a Godot session.
- The `assets/` folder contents — placeholder PNGs only.

---

## 9b. Findings from the *fixed* MCP analyser (added 2026-05-13c)

After patching the path‑resolution bug and adding stdlib smoke tests (commit `4011f1f`), I ran the analyser plus complementary scripts across the whole codebase. The validator itself is now clean — but it uncovered seven new issues in the project.

### 9b.1 CRITICAL — every roster `unit_id` is empty

All 6 files in `data/roster/default/` have `unit_id = ""`. `TurnManager.check_victory_conditions` (TurnManager.gd:191‑200) iterates `_map_data.required_survivor_ids` and matches against `u.data.unit_id`. No current map populates `required_survivor_ids`, so the bug is dormant — **but the instant any future map (Chapter 2 Lord chapter, escort missions, etc.) adds even one required survivor, the check sees no living unit with that id and emits `map_defeat` immediately**, because every living unit's `unit_id` is the empty string.

**Why this is a "we shipped a fuse" bug:** the data validator never complained because empty string is a legal value for an `@export var unit_id: String = ""`. The map‑level data, the survivor logic, and the unit data files are individually fine — only together do they fail.

**Fix:** set `unit_id` on each roster file (`"unit_01_soldier"`, `"unit_02_mercenary"`, etc.) and add a `DataManager._validate_roster()` step that asserts each loaded roster unit has a non‑empty unit_id. Same goes for enemy `.tres` files — they also have empty `unit_id` and the boss check (a future feature) will rely on it.

### 9b.2 HIGH — `SkillData.activation_chance_stat` / `activation_divisor` are decorative

Every `data/skills/*.tres` has the `activation_chance_stat` and `activation_divisor` fields populated (e.g. `miracle.tres`: `stat="luck", divisor=1`), but **nothing in SkillHandler reads them**. Verified via `grep -n activation_chance` across all engine files — zero hits in scripts/core or scripts/skills.

Today this only "works" for Miracle because `_apply_miracle` does its own hand‑rolled `randi() % 100 < luk` (SkillHandler.gd:113) and Miracle's data says `divisor=1` so LUK/1 == LUK%. Pure coincidence. The moment you add Astra (SKL/2), Sol (SKL%), Luna (SKL%), etc., the data layer's intent is silently ignored — `apply_trigger` fires the effect with 100% probability.

**Fix:** move the activation roll into `SkillHandler.apply_trigger`:

```gdscript
if skill.activation_chance_stat != "":
    var stat_val: int = unit.get_effective_stat(skill.activation_chance_stat)
    var chance: int = stat_val / max(1, skill.activation_divisor)
    if (randi() % 100) >= chance:
        continue   # skill did not proc this trigger
```

Then delete the duplicated roll inside `_apply_miracle`.

### 9b.3 MEDIUM — 4 dispatch arms in SkillHandler have no corresponding data

`SkillHandler._execute_skill` dispatches `charm`, `anathema`, `daunt`, `stat_bonus` — but no `data/skills/*.tres` file uses those effect_ids. Either scaffolding for M9 (mark with `# [STUB — M9]` and a TODO) or stale code. Same risk as the `ConditionManager` stubs (5.12): noise that hides real warnings later.

Verified by intersecting `_execute_skill` match arms against `effect_id` values in all skill resources.

### 9b.4 MEDIUM — `SettingsScreen.gd` is an orphan script with no scene

`find_scenes_with_script("scripts/ui/SettingsScreen.gd")` returns `No scenes found`. The script has 11 `@onready` references to nodes that exist only in a comment block at the top of the file ("Expected scene structure"). Until the scene is actually created in the Godot editor, the entire Settings UI is dead — and worse, anyone who attaches this script to a freshly created Control will crash on `_ready()` because the @onready paths won't resolve.

The MCP `validate_onready_paths` now correctly flags this as "No scene found — cannot validate paths" (after the 4011f1f fix). Treat it as a hard P1 if Settings is in scope for the next release; otherwise add a `# TODO: scene pending` banner at the top of the file.

### 9b.5 LOW — Breaker `effect_params` omit the `dodge` knob

`_apply_breaker` (SkillHandler.gd:139) reads `effect_params.get("dodge", 50)`. All three breaker `.tres` files set only `"weapon_type"` and `"hit"`. Behaviour today: defender‑side dodge bonus silently defaults to 50, which is correct, but invisible to anyone editing the data files. A designer raising the hit bonus to 60 will be surprised the dodge bonus didn't follow.

**Fix:** add `"dodge": 50` explicitly to bowbreaker/lancebreaker/swordbreaker. Removes the magic default and documents the design.

### 9b.6 LOW — MCP `tscn` parser is fragile to Godot 4.4+ `uid="..."` attribute

The regex in `parsers/tscn.py:30` requires `[ext_resource type="..." path="..." id="..."]` in exact order. Godot 4.4 introduced `uid="..."` *between* type and path on saved scenes. None of this project's `.tscn` files use it today (verified by greppping `ext_resource.*uid`), so the analyser works. If you ever resave a scene in 4.4+, that scene's ext_resources silently become invisible to the analyser.

**Fix (≈1 line):** replace the strict regex with a loose `\[ext_resource\b([^\]]*?)\]` match plus a key/value split for type/path/id.

### 9b.7 LOW — MCP `gdscript` parser doesn't handle `$"Quoted"` or `%UniqueName`

The @onready regex (`parsers/gdscript.py:18`) matches `$([^\s#\n]+)` — bare paths only. Godot supports `$"Node With Spaces/Child"` and `%UniqueSceneName` as alternative node lookups. Nothing in the project uses either today; flagged so the validator's "OK" can be trusted only against the input shapes it actually parses.

### 9b.8 Sanity findings (no bugs, but worth knowing)

- **No dead `ext_resource` references** anywhere — every script/scene/resource path in every `.tscn` and `.tres` resolves to an existing file. Good.
- **No autoload script is also attached to a scene node.** No double‑instance footguns.
- **No script is attached to two different scenes.** No silent fork/clone risk.
- **All weapons in roster + enemy inventories are equippable** (proficiency rank ≥ weapon rank). Inventory data and class proficiencies are consistent.
- **All `class_id`, `weapon_id`, `item_id`, and skill `id` references resolve.** Cross‑checked roster + enemies + map data against the four `data/<category>/` catalogues.
- **`ai_profile` values used by map data** (`"basic"` only) are all handled by `EnemyAI._act`. The dispatched profiles `passive` and `healer` are present in code but not yet used by any enemy.
- **No duplicate ids within `data/classes`, `data/weapons`, `data/items`, or `data/skills`.** `DataManager._load_directory`'s last‑write‑wins behaviour is currently safe.
- **All 8 `unit_data_path` entries in `map_001`'s `enemy_placements` point to existing files.**

---

## 10. Implementation plan (ordered, per locked decisions in §0a)

Ordered so cheap/contained items land first and high‑risk migrations are isolated.

1. ~~**Fix the MCP server** (1.1 + 1.2)~~ — DONE, commit `4011f1f`.
2. **Update Miracle description** (decision 1 → §3.1) — one string in `data/skills/miracle.tres`.
3. **Populate `unit_id` on every roster + enemy `.tres`** (decision 2 → §9b.1) — filename‑style ids + DataManager assert.
4. **Stub the dead SkillHandler dispatch arms** (decision 3 → §9b.3) — replace bodies with `# [STUB — M9]` comments.
5. **Drop ConditionManager warning spam** (decision 7 → §5.12) — replace `push_warning` with `# STUB — M8` comments.
6. **DataManager assert‑at‑load** (decision 5 → §5.2) — validator in `_ready`; drop downstream null guards.
7. **Wire `activation_chance_stat`/`activation_divisor` into `SkillHandler.apply_trigger`** (§9b.2) — also delete the duplicated roll inside `_apply_miracle`.
8. **Move `tile_position` from Unit to UnitData** (decision 9 → §7.4) — ~5 sites change; enables save‑system architecture from §0b.
9. **Snapshot coverage test** (decision 6 → §5.3) — `UnitData.get_property_list()` walk; allowlist for intentional exclusions.
10. **Add `# TODO save-system` banners** to `MapData.gd` + `GameState.gd` (§0b) — explicit pointer for the next person touching either file.
11. **Inventory → typed Resource migration** (decision 8 → §7.1) — half a day, all‑or‑nothing; do this last in the queue so it doesn't block smaller fixes.
12. **Add SettingsScreen.tscn** (decision 4 → §9b.4) — MVP build‑list item.
13. **Add SkillHandler and ItemHandler unit tests** (§4.4) — backfill coverage for the two biggest gaps.
14. **Re‑order TurnManager phase callbacks** (§3.4) and tighten cursor locking (§3.8, §5.14) — combat‑adjacent polish.

Items **N1 (terrain in saves)** and **N2 (enemy state in saves)** are deferred to the save‑system milestone — see §0b.

— End of report —
