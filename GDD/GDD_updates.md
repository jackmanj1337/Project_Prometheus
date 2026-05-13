# GDD_10 — Phase 2 Implementation Roadmap

---

## How to Use This Document

This document is a direct continuation of `GDD_09_Checklist.md`. It covers two things:

1. **Mandatory MVP Amendments** — architectural changes that must be made to the M1–M4
   milestone work *before or alongside* that work. These are not optional additions; without
   them, Phase 2 content cannot be bolted on without refactoring. Each amendment names the
   milestone it modifies.

2. **Phase 2 Milestones (M8–M13)** — new milestones to implement after the MVP (M7) is
   stable. Each produces a testable build.

**Priority rules used in this document:**

- Tasks that require changing existing combat, grid, or data systems are **mandatory MVP
  amendments** and are implemented immediately alongside the relevant MVP milestone.
- Tasks that add new `effect_id` match blocks, new `.tres` data files, or new UI panels
  on top of working infrastructure are **Phase 2 additions**.
- The **Laguz System (M12)** is fully specced and ready to implement but is marked
  `[DEFERRED]` — it does not block any MVP milestone. Its *data fields* are added in the
  MVP amendment to M1 so that no future refactoring of `UnitData` or `ClassData` is needed.
- The **Pair Up mechanic** is explicitly out of scope and will not appear in this document.
  Pair Up skills (Dual Strike+, Dual Guard+, Dual Support+) are noted as content placeholders
  only — their data resources can be created, but their logic will not be implemented.

---

## Status Snapshot

| Milestone | Status | Notes |
| --- | --- | --- |
| MVP Amendments — M1 Data Layer (A1) | ✅ Complete | ConditionManager registered; unit_id defaults fine for MVP |
| MVP Amendments — M3 Unit (A2) | ✅ Complete | All modifier hooks wired in TurnManager/CombatResolver/GameMap |
| MVP Amendments — M4 Combat (A3) | ✅ Complete | Context pipeline, multi-strike, Miracle sim-HP, faire/breaker |
| MVP Amendments — M2/M3 Grid (A4) | ⏳ Partial | Movement range done; MapCursor confirm step remains |
| M8 — Status Conditions | — | After M7 |
| M9 — Skill Content Implementation | — | After M8 |
| M10 — Extra-Turn System | — | After M9 |
| M11 — Content Expansion | — | After M10 |
| M12 — Laguz System | [DEFERRED] | After M11; fully specced below |
| M13 — Awakening Supplement | [DEFERRED] | After M12 |

---

## Part 1: Mandatory MVP Amendments

---

### Amendment A1 — Data Layer (modifies Milestone 1)

**Goal:** Extend all resource classes with the fields required by Phase 2 systems. All
new fields must have safe defaults so existing `.tres` files load without error. Serialization
of runtime state (modifiers, conditions, counters) is intentionally in `UnitData` rather than
on the `Unit` node so that mid-battle suspend saves can serialize everything from `UnitData`
alone — no scene tree traversal required. **Complete before closing M1.**

#### `UnitData.gd` — new fields

```gdscript
# ── Modifier system ───────────────────────────────────────────────────────────
# Serializable list of active temporary stat changes.
# All mid-battle save/load reads this array directly.
@export var active_modifiers: Array[Dictionary] = []
# Each entry:
# {
#   "stat":          String,  # "strength" | "magic" | "defense" | "resistance" | "skill" | "speed"
#                            # | "luck" | "movement" | "accuracy" | "dodge" | "crit"
#                            # | "crit_avoid" | "damage" | "damage_taken_pct"
#   "delta":         int,     # positive = buff, negative = debuff
#   "source":        String,  # effect_id of the skill/item that applied it (for stacking rules)
#   "duration":      int,     # turns remaining; -1 = lasts until explicitly removed
#   "duration_type": String   # "turn"      = decrements at start of holder's turn
#                            # "map_turn"  = decrements after full player + enemy phase
#                            # "combat"    = removed after next combat ends
#                            # "permanent" = never auto-removed (stat item bonuses)
# }

# ── Skill usage tracking ──────────────────────────────────────────────────────
# Counters for skills with per-map or per-combat limits.
# Reset to {} in reset_map_state(). Serialized for mid-battle saves.
@export var skill_use_counters: Dictionary = {}
# e.g. { "challenge": 2, "rise": 1, "strike_true": 0 }
# Key = effect_id of the skill. Value = number of times used this map.

# ── Damage tracking ───────────────────────────────────────────────────────────
# Cumulative damage taken this map (for Vengeance skill). Reset in reset_map_state().
@export var damage_taken_this_map: int = 0

# ── Laguz infrastructure ──────────────────────────────────────────────────────
# All fields default to 0 / false / "" for Beorc units — safe to ignore.
# Full logic implemented in M12. Fields are present now to prevent future UnitData refactoring.
@export var shift_gauge: int = 0
@export var is_shifted: bool = false
@export var shift_profile_id: String = ""
# shift_profile_id mirrors ClassData.id for the unit's Laguz class; empty for Beorc.
```

#### `ClassData.gd` — new fields

```gdscript
# ── Laguz gauge parameters ────────────────────────────────────────────────────
# All default to 0 / false / "" for Beorc classes.
@export var is_laguz: bool = false
@export var max_shift_gauge: int = 0
@export var shift_gauge_start: int = 0
@export var shift_gain_per_turn_humanoid: int = 0
@export var shift_gain_per_turn_animal: int = 0
@export var shift_gain_per_combat_humanoid: int = 0
@export var shift_gain_per_combat_animal: int = 0
@export var animal_stat_bonus_pct: float = 0.5    # +50% for standard Laguz
@export var natural_weapon_type: String = ""       # "fang" | "claw" | "beak" | "talon" etc.
@export var animal_con_bonus_pct: float = 0.75    # CON increases ~75% in animal form
```

#### `WeaponData.gd` — new fields

```gdscript
@export var strikes_per_attack: int = 1
# Set to 2 for all Brave weapons. Controls exchange sequence in CombatResolver.
# Attacker fires strikes_per_attack times before defender counters.

@export var is_natural_weapon: bool = false
# True for Laguz Fang/Claw/Beak/Talon. No cost, no uses; innate to animal form.
# Unit.get_equipped_weapon() returns the natural weapon when is_shifted = true
# and data.natural_weapon_type matches a WeaponData with this flag set.
# Rank for natural weapons is determined by the unit's wexp in that weapon type.
```

#### `SkillData.gd` — new fields and updated trigger docstring

```gdscript
@export var max_uses_per_map: int = -1
# -1 = unlimited. Checked against UnitData.skill_use_counters[effect_id].
# Examples: Rise = 3, Challenge = 3, Favoured = 1.

@export var max_uses_per_combat: int = -1
# -1 = unlimited. Checked at combat start; counter cleared after combat.
# Examples: Strike True = 1.

# Updated trigger docstring — add these to the existing list:
# "on_combat_apply_modifiers" — fires before combat stats are calculated;
#     used by aura skills (Charm, Daunt, Anathema, Motivate, etc.) to inject
#     flat bonuses into the combat context for attacker or defender.
# "on_ally_attacked"          — fires on units adjacent to a unit being attacked;
#     used by Parry and Redirect.
# "on_enemy_leaves_adjacent"  — fires when an enemy moves away from adjacency;
#     used by No Escape.
# "on_map_start"              — fires once per unit when the map loads.
# "on_shift"                  — fires when a Laguz unit changes form.
```

#### New autoload: `ConditionManager.gd`

Register after `DataManager` in the autoload order:
`EventBus → SettingsManager → GameState → DataManager → ConditionManager`

This is a **stub** in M1 — fully implemented in M8. It must exist now so that other
systems can call into it without failing.

```gdscript
extends Node

# Stub — all methods are no-ops until M8.

func apply_condition(unit: Node, condition_type: String, duration: int) -> void:
    pass  # [STUB — implement in M8]

func remove_condition(unit: Node, condition_type: String) -> void:
    pass

func tick_conditions(unit: Node) -> void:
    pass

func has_condition(unit: Node, condition_type: String) -> bool:
    return false

func clear_all_conditions(unit: Node) -> void:
    pass
```

#### Checklist — Amendment A1

- [x] Add all new `active_modifiers`, `skill_use_counters`, `damage_taken_this_map`,
      `shift_gauge`, `is_shifted`, `shift_profile_id` fields to `UnitData.gd`
- [x] Add all new Laguz gauge fields to `ClassData.gd`
- [x] Add `strikes_per_attack` and `is_natural_weapon` to `WeaponData.gd`
- [x] Add `max_uses_per_map`, `max_uses_per_combat` to `SkillData.gd`
- [x] Update `SkillData.gd` trigger docstring with the 5 new trigger type strings
- [x] Create `scripts/autoloads/ConditionManager.gd` with stub methods
- [x] Register `ConditionManager` as autoload after `DataManager`
- [ ] Verify: existing `.tres` files load without error after field additions
- [x] Verify: `ConditionManager` node is present at `/root/ConditionManager` at runtime
- [x] Update `GameState.take_map_snapshot()` to deep-copy `active_modifiers`,
      `skill_use_counters`, `damage_taken_this_map`, `shift_gauge`, and `is_shifted`
      from each player `UnitData` into the snapshot — these are runtime state, not just base stats

---

### Amendment A2 — Unit Script (modifies Milestone 3)

**Goal:** Refactor `Unit.gd` so all combat stat reads go through a modifier-aware
accessor. Add modifier lifecycle methods. All existing tests must still pass after
the refactor. **Complete before M4 begins.**

#### New methods to add to `Unit.gd`

```gdscript
# ── Stat access ───────────────────────────────────────────────────────────────

func get_effective_stat(stat_name: String) -> int:
    # Returns base stat + sum of all active_modifiers matching stat_name.
    # For "strength", "magic", "defense", "resistance", "skill", "speed", "luck", "movement":
    #   reads the corresponding data field, then applies all deltas.
    # Result is clamped to minimum 0 for all stats.
    var base: int = data.get(stat_name)
    var total: int = base
    for mod in data.active_modifiers:
        if mod["stat"] == stat_name:
            total += mod["delta"]
    return max(0, total)

func has_skill(skill_id: String) -> bool:
    # Convenience method — checks data.skills array for the given effect_id.
    # Used by GridManager, CombatResolver, SkillHandler without coupling to UnitData directly.
    return skill_id in data.skills

func get_skill_uses_remaining(effect_id: String, max_per_map: int) -> int:
    # Returns how many uses of this skill remain this map.
    # -1 means unlimited (max_per_map == -1).
    if max_per_map == -1:
        return -1
    var used: int = data.skill_use_counters.get(effect_id, 0)
    return max(0, max_per_map - used)

func consume_skill_use(effect_id: String) -> void:
    data.skill_use_counters[effect_id] = data.skill_use_counters.get(effect_id, 0) + 1

# ── Modifier lifecycle ────────────────────────────────────────────────────────

func add_modifier(stat: String, delta: int, source: String,
                  duration: int, duration_type: String) -> void:
    # Removes any existing modifier from the same source first (no duplicate stacking
    # of the same skill — multiple castings refresh the duration instead).
    remove_modifier(source)
    data.active_modifiers.append({
        "stat": stat, "delta": delta, "source": source,
        "duration": duration, "duration_type": duration_type
    })

func remove_modifier(source: String) -> void:
    data.active_modifiers = data.active_modifiers.filter(
        func(m): return m["source"] != source
    )

func tick_modifiers(duration_type: String) -> void:
    # Called by TurnManager. duration_type matches the type to decrement.
    # "turn" is called at the start of this unit's turn.
    # "map_turn" is called at the end of the full round (after enemy phase).
    for mod in data.active_modifiers:
        if mod["duration_type"] == duration_type and mod["duration"] > 0:
            mod["duration"] -= 1
    data.active_modifiers = data.active_modifiers.filter(
        func(m): return m["duration"] != 0
    )

func clear_combat_modifiers() -> void:
    # Removes all "combat" duration_type modifiers. Called after each combat resolves.
    data.active_modifiers = data.active_modifiers.filter(
        func(m): return m["duration_type"] != "combat"
    )

func reset_map_state() -> void:
    # Called when the map loads (before snapshot is taken) and on retry.
    data.active_modifiers.clear()
    data.skill_use_counters.clear()
    data.damage_taken_this_map = 0

# ── Refactored combat stat functions ─────────────────────────────────────────
# All existing functions below must be updated to use get_effective_stat()
# instead of reading data.strength, data.speed, etc. directly. Examples:

func battle_speed(weapon: WeaponData = null) -> int:
    var w: WeaponData = weapon if weapon else get_equipped_weapon()
    if not w:
        return get_effective_stat("speed")
    return get_effective_stat("speed") - max(0, w.wt - get_effective_stat("strength"))

func accuracy(weapon: WeaponData = null) -> int:
    var w: WeaponData = weapon if weapon else get_equipped_weapon()
    var hit_bonus: int = w.hit if w else 0
    return get_effective_stat("skill") * 2 + get_effective_stat("luck") + hit_bonus

func dodge() -> int:
    return battle_speed() * 2 + get_effective_stat("luck")

# ... and so on for damage(), crit_rate(), crit_avoid()
```

#### Checklist — Amendment A2

- [x] Add `get_effective_stat(stat_name)` to `Unit.gd`
- [x] Add `has_skill(skill_id)` to `Unit.gd`
- [x] Add `get_skill_uses_remaining()` and `consume_skill_use()` to `Unit.gd`
- [x] Add `add_modifier()`, `remove_modifier()`, `tick_modifiers()`,
      `clear_combat_modifiers()`, `reset_map_state()` to `Unit.gd`
- [x] Refactor `battle_speed()` to use `get_effective_stat()`
- [x] Refactor `accuracy()` to use `get_effective_stat()`
- [x] Refactor `dodge()` to use `get_effective_stat()`
- [x] Refactor `damage()` to use `get_effective_stat()`
- [x] Refactor `crit_rate()` to use `get_effective_stat()`
- [x] Refactor `crit_avoid()` to use `get_effective_stat()`
- [x] Hook `tick_modifiers("turn")` into `TurnManager.start_player_phase()` for each
      player unit, and into the start of each enemy's AI turn
- [x] Hook `tick_modifiers("map_turn")` into `TurnManager.start_player_phase()` (fires
      once per full round, at the top of the player phase)
- [x] Hook `clear_combat_modifiers()` into `CombatResolver` after each combat resolves
- [x] Hook `reset_map_state()` into `GameMap._ready()` for all units, *before*
      `GameState.take_map_snapshot()` is called
- [ ] Verify: all existing unit stat tests still pass after refactor
- [ ] Verify: adding a +5 STR modifier makes `get_effective_stat("strength")` return base + 5
- [ ] Verify: a "turn" duration modifier expires after the correct number of turns
- [ ] Verify: `has_skill("nihil")` returns true iff the skill id is in the unit's skills array

---

### Amendment A3 — Combat Resolver (modifies Milestone 4)

**Goal:** Restructure `CombatResolver` around a modifier pipeline so that all future
skill effects (aura buffs, weapon effectiveness, multi-strike, damage multipliers)
plug in cleanly without touching the core math. **Complete alongside M4.**

#### New internal structures

```gdscript
# Combat context — built fresh at the start of every resolve_combat() and preview_combat().
# Passed by reference to all helper functions and SkillHandler during combat.
# Keys that external systems read/write:

# context = {
#   "attacker":             Node,          # attacker Unit node
#   "defender":             Node,          # defender Unit node
#   "attacker_weapon":      WeaponData,    # null if unarmed
#   "defender_weapon":      WeaponData,    # null if cannot counterattack
#   "is_player_initiated":  bool,          # true if player unit is the attacker
#   "turn_number":          int,           # from GameState.turn_number
#
#   "atk_mod": {                           # flat additions applied AFTER base calculation
#       "accuracy":   0,                   # +/- to final hit%
#       "damage":     0,                   # +/- to damage (post-formula, pre-effectiveness)
#       "crit":       0,                   # +/- to crit%
#       "crit_avoid": 0,
#       "dodge":      0,
#       "strikes":    0,                   # extra attacks (Adept, etc.)
#       "damage_multiplier": 1.0,          # multiplies final damage (Charge, Dragonskin)
#   },
#   "def_mod": { same keys },
#
#   "flags": {
#       "nihil":                  false,   # defender's battle skills are suppressed
#       "vantage":                false,   # defender attacks first
#       "skip_effectiveness":     false,   # Nullify / Dragonskin / Iron Rune
#       "attacker_ignores_def":   0.0,     # fraction of DEF ignored (Luna = 0.5)
#       "attacker_ignores_res":   0.0,
#       "defender_ignores_def":   0.0,
#       "defender_ignores_res":   0.0,
#       "lifesteal_pct":          0.0,     # attacker heals this fraction of damage dealt
#       "vengeance_bonus":        0,       # flat damage added from Vengeance accumulation
#   }
# }
```

#### New and modified methods

```gdscript
# ── Context and modifier pipeline ─────────────────────────────────────────────

func _build_combat_context(attacker: Node, defender: Node) -> Dictionary:
    # Constructs the initial context dict with zero modifiers.
    # Reads GameState.turn_number and determines is_player_initiated.

func _collect_combat_modifiers(context: Dictionary) -> void:
    # Step 1: Apply active_modifiers from both units' UnitData.
    #         Modifiers with stat "accuracy"/"damage"/"crit"/"dodge" map to context.*_mod fields.
    # Step 2: Call SkillHandler.apply_trigger(unit, "on_combat_apply_modifiers", context)
    #         for every unit on the map.
    #         Aura skills (Charm, Daunt, Anathema, Motivate, etc.) check distance and
    #         write into context.atk_mod or context.def_mod.
    # Step 3: Check equipped items (equip-type inventory entries) for modifiers.
    # Step 4: Call SkillHandler.apply_trigger(attacker, "on_combat_start", context)
    #         and apply_trigger(defender, "on_combat_start", context).
    #         This is where Vantage, Nihil, Resolve, Wrath, etc. set their flags.

# ── Effectiveness ─────────────────────────────────────────────────────────────

func _get_effectiveness_multiplier(weapon: WeaponData, target: Node,
                                    context: Dictionary) -> float:
    # Returns 1.0 normally, 3.0 if weapon has an effectiveness tag matching a
    # special_quality of the target, 4.0 if attacker also has Giantkiller skill.
    # Returns 1.0 if context.flags.skip_effectiveness is true (Dragonskin/Nullify).
    # Effectiveness tag → special_quality mapping:
    #   "effective_flying"  → Flying
    #   "effective_beast"   → Beast
    #   "effective_dragon"  → Dragon
    #   "effective_armour"  → Armoured
    #   "effective_mount"   → Mounted
    #   "effective_laguz"   → Laguz

# ── Multi-strike exchange sequence ────────────────────────────────────────────

func resolve_combat(attacker: Node, defender: Node) -> Dictionary:
    var context := _build_combat_context(attacker, defender)
    _collect_combat_modifiers(context)

    var atk_strikes: int = context.attacker_weapon.strikes_per_attack \
                           + context.atk_mod.strikes  if context.attacker_weapon else 0
    var def_strikes: int = 0
    if can_counterattack(defender, attacker.tile_position) and context.defender_weapon:
        def_strikes = context.defender_weapon.strikes_per_attack + context.def_mod.strikes

    var exchanges: Array = []

    # Vantage: defender goes first
    if context.flags.vantage:
        for _i in def_strikes:
            exchanges.append(_resolve_single_attack(defender, attacker, context, true))
            if attacker.data.hp <= 0: break
        def_strikes = 0  # defender already used their attacks

    # Attacker's strikes
    for _i in atk_strikes:
        exchanges.append(_resolve_single_attack(attacker, defender, context, false))
        if defender.data.hp <= 0: break

    # Defender's counter (unless Vantage already fired)
    if def_strikes > 0 and attacker.data.hp > 0:
        for _i in def_strikes:
            exchanges.append(_resolve_single_attack(defender, attacker, context, true))
            if attacker.data.hp <= 0: break

    # Follow-up
    var follow_up_unit := get_follow_up_attacker(attacker, defender)
    if follow_up_unit and follow_up_unit.data.hp > 0:
        var follow_up_target := defender if follow_up_unit == attacker else attacker
        if follow_up_target.data.hp > 0:
            exchanges.append(_resolve_single_attack(follow_up_unit, follow_up_target,
                                                    context, follow_up_unit != attacker))

    # Post-combat skill triggers
    SkillHandler.apply_trigger(attacker, "on_combat_end", context)
    SkillHandler.apply_trigger(defender, "on_combat_end", context)

    # Damage tracking for Vengeance
    # (accumulated in _resolve_single_attack per hit taken)

    return {
        "exchanges":            exchanges,
        "attacker_final_hp":    attacker.data.hp,
        "defender_final_hp":    defender.data.hp,
        "attacker_exp":         calculate_exp(attacker, defender, defender.data.hp <= 0),
        "attacker_wexp":        context.attacker_weapon.wexp if context.attacker_weapon else 0
    }

func _resolve_single_attack(actor: Node, target: Node,
                              context: Dictionary, is_counter: bool) -> Dictionary:
    # Applies context modifiers (atk_mod / def_mod based on actor role),
    # rolls hit, rolls crit, computes damage with effectiveness multiplier,
    # applies damage_multiplier from context.flags,
    # calls SkillHandler.apply_trigger(actor, "on_attack", context) before rolling,
    # calls SkillHandler.apply_trigger(actor, "on_hit", context) if hit lands,
    # calls SkillHandler.apply_trigger(target, "on_damaged", context) after damage,
    # calls SkillHandler.apply_trigger(actor, "on_kill", context) if target dies,
    # increments target.data.damage_taken_this_map by damage dealt.
    # Returns { actor, target, hit: bool, crit: bool, damage: int }

# ── Skill counter helpers ─────────────────────────────────────────────────────

func _skill_available(unit: Node, skill_data: SkillData) -> bool:
    if skill_data.max_uses_per_map == -1:
        return true
    return unit.get_skill_uses_remaining(skill_data.effect_id,
                                          skill_data.max_uses_per_map) > 0

func _consume_skill(unit: Node, skill_data: SkillData) -> void:
    if skill_data.max_uses_per_map != -1:
        unit.consume_skill_use(skill_data.effect_id)
```

#### Checklist — Amendment A3

- [x] Add `_build_combat_context()` to `CombatResolver.gd`
- [x] Add `_collect_combat_modifiers()` to `CombatResolver.gd`
- [x] Add `_get_effectiveness_multiplier()` to `CombatResolver.gd`
- [x] Refactor `resolve_combat()` to use context, multi-strike loop, and vantage flag
- [x] Refactor `preview_combat()` to use the same context pipeline (no RNG; no side effects)
- [x] Add `_resolve_single_attack()` extracting single-attack logic from the exchange loop
- [x] Add `_skill_available()` and `_consume_skill()` to `CombatResolver.gd`
- [x] Ensure `_resolve_single_attack()` increments `target.data.damage_taken_this_map`
- [x] Ensure `clear_combat_modifiers()` is called on both units after `resolve_combat()` returns
- [x] Verify: Brave Sword (strikes_per_attack = 2) produces two attacker attacks before counter
- [ ] Verify: weapon effectiveness (e.g. iron bow vs flying unit) triples Mt correctly
- [ ] Verify: Giantkiller on attacker applies 4× Mt against effective target
- [ ] Verify: Nullify skill on defender sets `skip_effectiveness = true` in context
- [ ] Verify: `preview_combat()` returns identical base numbers to `resolve_combat()` (before RNG)
- [ ] Verify: `damage_taken_this_map` on a unit increments correctly across multiple combats
- [ ] Verify: skill counter prevents a Rise or Challenge use past its per-map limit

---

### Amendment A4 — Grid System (modifies Milestones 2 and 3)

**Goal:** Add per-unit movement rule overrides to `GridManager` so movement-modifying
skills (Acrobat, Pass, Swiftfoot, Phasing, Nimble) can be added in Phase 2 without
touching pathfinding core logic. **Complete before M4 begins.**

#### Modified and new methods in `GridManager.gd`

```gdscript
func get_move_cost(tile: Vector2i, unit: Node) -> int:
    var terrain: String = get_terrain_at(tile)
    # Check skill-based overrides FIRST.
    # Any skill that flattens all terrain costs inserts here.
    # SkillHandler returns -1 if no override, or the overriding cost.
    var override: int = SkillHandler.get_move_cost_override(unit, terrain)
    if override != -1:
        return override
    # Then standard terrain cost table (unchanged from M2 implementation).

func is_passable(tile: Vector2i, unit: Node) -> bool:
    var terrain: String = get_terrain_at(tile)
    if terrain == "wall":
        # Wall is impassable to ALL units in MVP.
        # Phasing skill is checked here in Phase 2.
        if SkillHandler.can_phase_through(unit, terrain):
            return true
        return false
    var occupant: Node = get_unit_at(tile)
    if occupant == null:
        return true
    if occupant.team == unit.team:
        return true   # always pass through allies
    # Enemy-occupied tile: normally blocks. Pass skill overrides this.
    return SkillHandler.can_pass_through_enemies(unit)

func can_end_on_tile(tile: Vector2i, unit: Node) -> bool:
    # NEW — separates "can move through" from "can stop here".
    # A unit with Pass can move through enemy tiles but cannot end on one.
    # Called at the end of path validation in get_movement_range() and move confirmation.
    var occupant: Node = get_unit_at(tile)
    if occupant == null:
        return true
    if occupant.team == unit.team:
        return false  # cannot stack with allies
    return false      # cannot end on enemy even with Pass
```

#### New stub methods to add to `SkillHandler.gd`

These return safe defaults until their skill effects are implemented in M9.

```gdscript
func get_move_cost_override(unit: Node, terrain: String) -> int:
    # Returns the overriding cost if a skill applies, -1 if no override.
    # Checks: Acrobat (all non-wall terrain → 1), Swiftfoot (terrain penalties → 1),
    #         Nimble (Laguz Cat: all terrain → 1), Feral Instincts with Nimble.
    return -1  # [STUB — implement in M9]

func can_pass_through_enemies(unit: Node) -> bool:
    # Returns true if the unit has the Pass skill (Trickster occult).
    return false  # [STUB — implement in M9]

func can_phase_through(unit: Node, terrain: String) -> bool:
    # Returns true if the unit has the Phasing skill (Sage promotion).
    return false  # [STUB — implement in M9]
```

#### Checklist — Amendment A4

- [x] Add `SkillHandler.get_move_cost_override()` stub to `SkillHandler.gd`
- [x] Add `SkillHandler.can_pass_through_enemies()` stub to `SkillHandler.gd`
- [x] Add `SkillHandler.can_phase_through()` stub to `SkillHandler.gd`
- [x] Modify `GridManager.get_move_cost()` to call `get_move_cost_override()` first
- [x] Modify `GridManager.is_passable()` to check `can_pass_through_enemies()` for enemies
- [x] Add `GridManager.can_end_on_tile()` as a separate method
- [x] Update `get_movement_range()` to call `can_end_on_tile()` when marking reachable tiles
- [ ] Update move confirmation in `MapCursor.gd` to call `can_end_on_tile()` before allowing
      the move to be committed
- [ ] Verify: stubs return safe defaults and existing pathfinding tests still pass
- [ ] Verify: path through an ally tile is still walkable but not stoppable

---

## Part 2: Phase 2 Milestones

---

## Milestone 8 — Status Conditions

**Goal:** Full implementation of all status conditions. Units can be inflicted with
conditions via weapons, staves, and skills. Conditions tick down each turn, have
their prescribed effects, and can be removed by Restore staves and Panacea items.
**Test:** Apply each condition via a staff or skill in a test map. Verify visual
indicator appears. Verify all mechanical effects. Verify removal by Restore staff.

### Condition Definitions

All conditions store as `{ "type": String, "turns_remaining": int }` in
`UnitData.conditions`. The `ConditionManager` autoload (stubbed in M1) is
fully implemented here.

| Condition | Effect | Duration | Tick Point |
| --- | --- | --- | --- |
| Poison | −3 HP at start of holder's turn; −10 Accuracy and Dodge during combat | 5 turns | Start of holder's turn |
| Sleep | Cannot move, act, or counterattack; Dodge set to 0 | 3 turns | Start of holder's turn |
| Silence | Cannot use tomes or staves | 4 turns | Start of holder's turn |
| Berserk | Must attack the most vulnerable unit in range each turn (including allies) | 3 turns | Start of holder's turn |
| Stun | Cannot move, act, or counterattack; Dodge set to 0 | 1 turn | Start of holder's turn |
| Hex | −6 STR and −6 MAG (via active_modifiers, "combat" duration_type by default) | Custom | Applied by skill |

### `ConditionManager.gd` — full implementation

```gdscript
extends Node

const CONDITION_POISON   := "poison"
const CONDITION_SLEEP    := "sleep"
const CONDITION_SILENCE  := "silence"
const CONDITION_BERSERK  := "berserk"
const CONDITION_STUN     := "stun"

func apply_condition(unit: Node, condition_type: String, duration: int) -> void:
    # Do not stack: refresh duration if already present.
    remove_condition(unit, condition_type)
    unit.data.conditions.append({ "type": condition_type, "turns_remaining": duration })
    EventBus.condition_applied.emit(unit, condition_type)
    # For Poison, also add active_modifier to accuracy and dodge:
    if condition_type == CONDITION_POISON:
        unit.add_modifier("accuracy", -10, "poison_acc", -1, "permanent")
        unit.add_modifier("dodge",    -10, "poison_dod", -1, "permanent")
    _update_unit_visual(unit)

func remove_condition(unit: Node, condition_type: String) -> void:
    unit.data.conditions = unit.data.conditions.filter(
        func(c): return c["type"] != condition_type
    )
    if condition_type == CONDITION_POISON:
        unit.remove_modifier("poison_acc")
        unit.remove_modifier("poison_dod")
    _update_unit_visual(unit)
    EventBus.condition_removed.emit(unit, condition_type)

func tick_conditions(unit: Node) -> void:
    # Called by TurnManager at the start of the unit's turn.
    # Apply per-turn effects, then decrement. Remove at 0.
    for condition in unit.data.conditions.duplicate():
        match condition["type"]:
            CONDITION_POISON:
                unit.take_damage(3)
                EventBus.unit_damaged.emit(unit, 3)
        condition["turns_remaining"] -= 1
    unit.data.conditions = unit.data.conditions.filter(
        func(c): return c["turns_remaining"] > 0
    )
    _update_unit_visual(unit)

func has_condition(unit: Node, condition_type: String) -> bool:
    for condition in unit.data.conditions:
        if condition["type"] == condition_type:
            return true
    return false

func clear_all_conditions(unit: Node) -> void:
    # Called by Boon skill and Restore staff.
    for condition in unit.data.conditions:
        if condition["type"] == CONDITION_POISON:
            unit.remove_modifier("poison_acc")
            unit.remove_modifier("poison_dod")
    unit.data.conditions.clear()
    _update_unit_visual(unit)

func _update_unit_visual(unit: Node) -> void:
    # Updates the condition icon above the unit sprite.
    # Priority: Berserk > Sleep > Stun > Silence > Poison
    # [PLACEHOLDER] icon display
```

### Condition enforcement hooks

```gdscript
# In TurnManager: start of each unit's activation (player and enemy)
ConditionManager.tick_conditions(unit)
if ConditionManager.has_condition(unit, "sleep") or ConditionManager.has_condition(unit, "stun"):
    TurnManager.set_unit_state(unit, UnitState.DONE)
    return  # unit cannot act

# In CombatResolver._collect_combat_modifiers():
if ConditionManager.has_condition(defender, "sleep") or ConditionManager.has_condition(defender, "stun"):
    context.flags.defender_cannot_counter = true
    context.def_mod.dodge = -9999  # cannot dodge

# In ActionMenu: grey out "Staff" and tomes if unit has Silence
if ConditionManager.has_condition(acting_unit, "silence"):
    # disable staff and tome options

# In EnemyAI: Berserk overrides normal AI — attack highest-damage target regardless of team
if ConditionManager.has_condition(unit, "berserk"):
    _run_berserk(unit)  # new AI profile
```

### New EventBus signals

```gdscript
signal condition_applied(unit: Node, condition_type: String)
signal condition_removed(unit: Node, condition_type: String)
```

### Poison weapon effect

Venin weapons (Venin Axe, Venin Edge, Venin Lance, Venin Bow, Venin Dagger, Toxin tome)
inflict Poison on hit. Add `"effect_tags": ["poison_on_hit"]` to each Venin weapon `.tres`.
Handle in `SkillHandler.apply_trigger(attacker, "on_hit", context)` — if weapon has
`"poison_on_hit"` tag, call `ConditionManager.apply_condition(defender, "poison", 5)`.

### Checklist — M8

- [ ] Implement `ConditionManager.apply_condition()` with duplicate-refresh logic
- [ ] Implement `ConditionManager.remove_condition()` with modifier cleanup for Poison
- [ ] Implement `ConditionManager.tick_conditions()` with Poison damage
- [ ] Implement `ConditionManager.has_condition()`
- [ ] Implement `ConditionManager.clear_all_conditions()` (for Restore/Boon/Panacea)
- [ ] Add `condition_applied` and `condition_removed` signals to `EventBus.gd`
- [ ] Hook `tick_conditions()` into `TurnManager` at the start of each unit's activation
- [ ] Hook Sleep and Stun lock into `TurnManager` to skip acting units
- [ ] Hook Sleep and Stun `defender_cannot_counter` flag into `CombatResolver`
- [ ] Hook Silence check into `ActionMenu` to disable tome/staff options
- [ ] Hook Berserk profile into `EnemyAI`; add `_run_berserk()` function
- [ ] Add `"poison_on_hit"` effect tag to all Venin weapon `.tres` files
- [ ] Handle `"poison_on_hit"` tag in `SkillHandler.apply_trigger("on_hit")`
- [ ] Implement condition icon display above unit sprite `[PLACEHOLDER visual]`
- [ ] Create `.tres` data for Restore staff (`effect_tags: ["remove_conditions"]`)
- [ ] Handle Restore staff use calling `ConditionManager.clear_all_conditions(target)`
- [ ] Handle Panacea item use calling `ConditionManager.clear_all_conditions(self)`
- [ ] Verify: a Poisoned unit takes 3 damage at the start of each of its turns
- [ ] Verify: Poison expires after 5 turns
- [ ] Verify: a Sleeping unit cannot move, act, or counterattack
- [ ] Verify: Sleep expires after 3 turns
- [ ] Verify: a Silenced unit cannot use staves or tomes in the Action Menu
- [ ] Verify: a Stunned unit loses its turn and cannot counterattack (1 turn)
- [ ] Verify: a Berserk unit attacks the most vulnerable target regardless of team
- [ ] Verify: Restore staff removes all conditions from the target
- [ ] Verify: Panacea removes all conditions from the user
- [ ] Verify: Venin weapon inflicts Poison on a successful hit

---

## Milestone 9 — Skill Content Implementation

**Goal:** Implement all skill `effect_id` handlers that were architecturally deferred
from MVP. All skills present in the base handbook and Awakening supplement are
functional. **Test:** Equip each category of skill on a test unit and manually verify
its effect triggers correctly and produces the expected change in numbers or behavior.

This milestone adds `match` blocks to `SkillHandler.apply_trigger()` for every
deferred effect. The infrastructure (modifier pipeline, trigger types, counter system)
is already in place from the MVP amendments.

### Generic stat skills — passive bonuses

These use `trigger = "passive"` and `effect_id = "stat_bonus"`. The SkillHandler
reads `effect_params` to know which stat and amount to add as a permanent modifier
when the unit is initialized. Already handled if the MVP implementation supports
`effect_params` — verify and stub if not.

- [ ] Implement `"stat_bonus"` effect: reads `effect_params["stat"]` and
      `effect_params["delta"]` and calls `unit.add_modifier(stat, delta, skill.id, -1, "permanent")`
      when the unit initializes
- [ ] Create `.tres` files for all generic stat-bonus skills:
      Barrier (+2 RES), Celerity (+2 MOV), Clear Vision (+2 LoS), Focus (+2 MAG),
      Fortunate (+2 LUK), Perceptive (+2 LoS), Prowess (+2 SKL), Swift (+2 SPD),
      Tough (+2 DEF), Vigor (+5 MaxHP), Zeal (+2 STR)

### Aura skills — `on_combat_apply_modifiers`

Called for every unit on the map during `_collect_combat_modifiers()` in
`CombatResolver`. Each aura checks distance from the skill holder to the attacker
or defender, then adds to `context.atk_mod` or `context.def_mod`.

- [x] Implement `"charm"` aura: allies within 3 spaces of skill holder gain +10 accuracy
      and +10 dodge during combat *(SkillHandler implemented; .tres file is Phase 2)*
- [x] Implement `"anathema"` aura: enemies within 3 spaces of skill holder suffer −10
      accuracy and −10 dodge during combat *(SkillHandler implemented; .tres file is Phase 2)*
- [x] Implement `"daunt"` aura: enemies within 3 spaces suffer −10 accuracy and −10 crit
      *(SkillHandler implemented; .tres file is Phase 2)*
- [ ] Implement `"motivate"` aura: adjacent allies gain +3 DEF, RES, and LUK during combat
- [ ] Implement `"air_superiority"` aura on skill holder: +4 STR, SKL, SPD when fighting
      a Flying unit
- [ ] Implement `"flanking"`: +3 STR, SKL, SPD when an ally is on the opposite side of
      the target. Check if a player ally occupies the tile directly opposite the attacker
      relative to the defender.
- [ ] Implement `"demoiselle"`: male allied units within 3 spaces take −4 damage
- [ ] Implement `"gentilhomme"`: female allied units within 3 spaces take −4 damage
- [ ] Implement Awakening `"charm"` (Lord/Bride version): same as Charm above — confirm
      they share the same `effect_id`
- [ ] Implement `"tailwind"`: adjacent allies get +5 SPD (Laguz Hawk promotion — defer
      Laguz-specific trigger to M12; implement the aura logic here so it's ready)
- [ ] Implement `"solidarity"`: when this unit is Support in a Pair Up — skip; Pair Up
      is out of scope

### Combat skills — `on_attack`, `on_hit`, `on_kill`, `on_damaged`

- [ ] Implement `"sol"`: `on_attack` SKL/2% activation; attacker heals 50% of damage dealt
      in that attack. Call `attacker.heal(floor(damage * 0.5))`
- [ ] Implement `"luna"`: `on_attack` SKL/2%; set `context.flags.attacker_ignores_def = 0.5`
      for that attack
- [ ] Implement `"ignis"`: `on_attack` SKL/2%; if physical attack, add `floor(attacker.get_effective_stat("magic") / 2)` to damage (vs DEF); if magical, add `floor(STR/2)` to damage (vs RES)
- [ ] Implement `"aether"`: `on_attack` SKL/2%; simultaneously triggers Sol and Luna effects
- [ ] Implement `"vengeance"`: `on_attack` SKL/2%; add `floor(attacker.data.damage_taken_this_map / 2)` to damage
- [ ] Implement `"lifetaker"`: `on_kill`; attacker heals `floor(killing_blow_damage / 2)`
- [ ] Implement `"galeforce"`: `on_kill`; check `skill_use_counters["galeforce"] == 0`;
      if so, reset attacker state to READY and consume one use
- [ ] Implement `"aggressor"`: `on_combat_apply_modifiers`; if `context.is_player_initiated`
      and attacker has Aggressor, add +10 to `context.atk_mod.damage`
- [ ] Implement `"loot"`: `on_kill`; add 20 gold to `attacker.data.gold`
- [ ] Implement `"gamble"`: `player_activated` before attack; halve accuracy, double crit
      for that combat. Add "active" flag cleared after combat end
- [ ] Implement `"wrath"`: `on_combat_apply_modifiers` passive check; if attacker HP ≤ 50%,
      add +50 to `context.atk_mod.crit`
- [ ] Implement `"resolve"`: passive; if unit HP ≤ 50%, `get_effective_stat()` multiplies
      STR, MAG, SKL, SPD by 1.5. Implement as a modifier applied/removed by a tick check,
      or handle directly in `get_effective_stat()` with a HP threshold branch
- [ ] Implement `"frenzy"`: passive; +50% STR when HP ≤ 50% (Berserker promotion) — same
      pattern as Resolve but STR only
- [ ] Implement `"adept"`: `on_attack` SKL/2% during non-additional attacks: add 1 to
      `context.atk_mod.strikes`
- [ ] Implement `"cancel"`: `on_attack` SKL/2%; set a flag on the defender that negates
      their next attack this combat
- [ ] Implement `"corrosion"`: `on_attack` SKL/2%; reduce defender's equipped weapon uses
      by attacker's level
- [ ] Implement `"drain"` (Warlock): `on_hit` on crit; attacker heals 50% of crit damage
- [ ] Implement `"cripple"` (Warrior occult): `on_hit` on crit; apply −50% STR modifier to
      defender for 2 turns (`add_modifier("strength", -floor(strength * 0.5), "cripple", 2, "map_turn")`)
- [ ] Implement `"reaper"` (Assassin): `on_combat_apply_modifiers`; if weapon type is
      "knife" or "dagger", double effective SKL for crit calculation
- [ ] Implement `"nihil"`: `on_combat_start`; set `context.flags.nihil = true` preventing
      SkillHandler from calling the defender's battle skills
- [ ] Implement `"vantage"`: `on_combat_start`; set `context.flags.vantage = true`
- [ ] Implement `"discipline"` (Negate weapon triangle): `on_combat_apply_modifiers`;
      zero out any weapon triangle bonuses in context
- [ ] Implement `"unorthodox"` (Reverse weapon triangle): `on_combat_apply_modifiers`;
      negate the triangle result before it is applied (flip advantage ↔ disadvantage)
- [ ] Implement `"nullify"` (Negate bonus damage): `on_combat_start`; set
      `context.flags.skip_effectiveness = true`
- [ ] Implement `"pavise"` (Great Knight): `on_combat_start`; set
      `context.flags.defender_negate_crits = true`; enforce in `_resolve_single_attack()`
- [ ] Implement `"patience"` (Awakening): `on_combat_apply_modifiers`; if
      `!context.is_player_initiated` and unit is defender, add +10 accuracy and +10 dodge
- [ ] Implement `"prescience"` (Awakening): +15 Hit/Dodge when initiating
- [ ] Implement `"underdog"` (Awakening Villager): +15 Hit/Dodge vs higher-level enemy
- [ ] Implement `"lucky_seven"` (Awakening): +20 Hit/Dodge on turns 1–7
- [ ] Implement `"odd_rhythm"`: +15 Hit/Dodge on odd `context.turn_number`
- [ ] Implement `"even_rhythm"`: +15 Hit/Dodge on even `context.turn_number`
- [ ] Implement `"rightful_king"` (Great Lord): `on_combat_apply_modifiers`; before each
      activation roll, add +10 to the activation percentage (hook into `_roll_activation_pct()`)
- [ ] Add `_roll_activation_pct(base_pct: int, unit: Node) -> bool` helper to
      SkillHandler that adds any Rightful King bonus before rolling

### Faire and Breaker skills

- [x] Implement `"*faire"` family: `on_combat_start`; if attacker has the matching
      faire skill and weapon type matches, add +5 to `context.atk_mod.damage`
- [x] Create MVP `.tres` for: Swordfaire, Lancefaire, Bowfaire (sword/lance/bow coverage)
- [ ] Create remaining `.tres` for: Axefaire, Tomefaire (Phase 2 content)
- [x] Implement `"*breaker"` family: `on_combat_start`; check defender's equipped
      weapon type; add +50 accuracy to the holder's side
- [x] Create MVP `.tres` for: Swordbreaker, Lancebreaker, Bowbreaker
- [ ] Create remaining `.tres` for: Axebreaker, Tomebreaker (Phase 2 content)

### Defensive and damage-reduction skills

- [ ] Implement `"dragonskin"` (Manakete): `on_combat_start`; set
      `context.flags.damage_multiplier` for defender to 0.5; also set
      `context.flags.skip_effectiveness = true`. Note: Dragonskin is a Laguz-tier
      skill but the flag infrastructure is ready
- [ ] Implement `"ironhide"` (Wyvern Lord): `on_combat_start`; if attacker's weapon rank
      is E or D and `!weapon.uses_mag`, set `context.atk_mod.damage` to a value that
      floors final damage to 0
- [ ] Implement `"iote_shield"` (Awakening, flying only): `on_combat_start`; set
      `skip_effectiveness = true` for all flying-effective weapons against this unit
- [ ] Implement `"aegis"` (Mage Knight): passive `get_effective_stat("defense")` adds 25% of
      RES to DEF. Handle as a dynamic modifier in `get_effective_stat()` rather than
      a stored modifier, since RES can change
- [ ] Implement `"charge"` (Great Knight occult): `on_combat_apply_modifiers`; if unit
      used full movement before attacking, apply 1.5× damage multiplier

### Reactive skills — `on_ally_attacked`, `on_enemy_leaves_adjacent`

These require the new trigger types added in Amendment A1.

- [ ] Hook `on_ally_attacked` trigger: in `CombatResolver.resolve_combat()`, after the
      context is built, fire `SkillHandler.apply_trigger(adjacent_unit, "on_ally_attacked", context)`
      for all units adjacent to the defender (not on the attacker's team). The context
      includes the full combat so skills can read damage values
- [ ] Implement `"counter"` (Vanguard occult): `on_damaged` SKL/2%; if damage source is
      range 1 melee, apply the same damage amount to the attacker (no counterattack roll)
- [ ] Implement `"parry"` (Guardian occult): `on_ally_attacked` SKL/2%; if damage would
      be ≥ 50% of target's current HP, set damage to 0 and deal half to attacker instead
- [ ] Implement `"redirect"` (Guardian promotion): `player_activated` once per turn;
      unit takes the hit for an adjacent ally, recalculated against this unit's DEF or RES
- [ ] Hook `on_enemy_leaves_adjacent` trigger: in `Unit.move_along_path()`, after each
      tile step, check if any enemy that was adjacent at the previous tile is no longer
      adjacent; emit the trigger for eligible units
- [ ] Implement `"no_escape"` (Warrior occult): `on_enemy_leaves_adjacent` SKL/2%;
      make one attack against the leaving enemy with no counterattack from them

### Per-map activated skills

- [ ] Implement `"challenge"` (Paladin occult): `player_activated` 3×/map; apply +3 STR,
      SPD, SKL, DEF when fighting the selected target. Store selected enemy node ID in
      a skill context dict on the unit. Clear when a different target is chosen
- [ ] Implement `"rise"` (Necromancer promotion): `player_activated` 3×/map; on kill,
      create a new unit node with ½ the dead unit's stats (rounded down), team = player,
      ai_profile = "passive", placed on the vacated tile
- [ ] Implement `"strike_true"` (Paladin promotion): if attacker missed by ≤10%, re-roll
      once. Track via `max_uses_per_combat = 1` in SkillData

### Movement skills (using A4 stubs)

- [ ] Implement `SkillHandler.get_move_cost_override()` for `"acrobat"`:
      return 1 for all terrain except wall and deep sea
- [ ] Implement `get_move_cost_override()` for `"swiftfoot"`:
      return 1 for all terrain that normally costs > 1 (except wall and sea)
- [ ] Implement `SkillHandler.can_pass_through_enemies()` for `"pass"`: return true
- [ ] Implement `SkillHandler.can_phase_through()` for `"phasing"`: allow passing
      through wall tiles during one movement per turn. Track via a per-turn flag reset
      in `TurnManager`
- [ ] Implement `"smite"`: replaces standard Shove; pushes target 2 tiles instead of 1.
      Modify Shove action handler to check for Smite and adjust distance
- [ ] Implement `"lunge"`: `player_activated`; allows initiating combat with a range-1
      weapon as though it were range 2. Add +10 to `context.atk_mod.crit`. The unit
      must occupy a tile that would be in range-2 of the target. No movement occurs
- [ ] Implement `"dash"` (Hero promotion): allow one diagonal move step per activation
      of the action. Diagonal costs the same as one orthogonal move. Increment available
      diagonal steps at levels 6, 11, 16. Track per-combat diagonal steps on Unit
- [ ] Implement `"bulldozer"` (Brawler promotion): after shoving an enemy, apply a
      `"stun"` condition for 1 turn (movement = 0 equivalent — use the Stun condition
      with a flag checked in TurnManager to set MOV to 0)
- [ ] Implement `"trample"` (Raider promotion): `player_activated`; during movement,
      deal 4 damage to each enemy tile passed through; unit takes 2 damage per enemy hit.
      Resolved in `Unit.move_along_path()` when Trample is active
- [ ] Implement `"hit_and_run"` (Hawk occult): `on_kill`; after killing an enemy during
      player phase, unit may move up to full MOV, healing 1 HP per tile moved
- [ ] Implement `"bastion"` (General promotion): `player_activated` as an action; marks
      one adjacent empty tile as blocked until this unit's next turn. Store the blocked
      tile in `GameState` or `GridManager._bastion_tiles: Dictionary` (unit → tile).
      `is_passable()` checks this dict. Clear at start of unit's next turn
- [ ] Implement `"nimble"` (Cat promotion — deferred to M12): stub now, wire in M12

### Healing and support skills at start_of_turn

- [ ] Implement `"renewal"` (already in MVP): verify it calls `unit.heal(ceil(data.max_hp * 0.1))`
- [ ] Implement `"boon"` (Paragon promotion): `start_of_turn`; for each adjacent ally,
      call `ConditionManager.clear_all_conditions(ally)` (requires M8)
- [ ] Implement `"holy_aura"` (Bishop occult): `start_of_turn` LUK/2%; allies in 2-space
      radius heal 20% of their max HP
- [ ] Implement `"grace"` (Heron promotion — Laguz): defer to M12; stub here
- [ ] Implement `"holy_conduit"` (Valkyrie promotion): `on_hit` on crit with light tome;
      adjacent ally heals HP equal to damage dealt

### Weapon-buff skills

- [ ] Implement `"infuse"` (Soulblade): `player_activated` before attack; reduce crit to 0,
      add `floor(MAG/2)` to damage calculated against RES instead of DEF for that attack
- [ ] Implement `"firebreathing"` (Dracoknight): fire attribute spells additionally hit
      one tile in a straight line behind the target. Resolve in a new AoE handler
      (see M9 AoE section)
- [ ] Implement `"vortex"` (Raven promotion — Laguz): defer to M12

### Awakening-specific skills

- [ ] Implement `"veteran"` (Tactician starting): in `Unit.add_exp()`, if unit has
      `"veteran"`, multiply amount by 1.5 before adding
- [ ] Create `.tres` files for all Awakening generic skills:
      Sol, Luna, Ignis, Aether, Galeforce, Aggressor, Vengeance, Lifetaker,
      Patience, Solidarity, Iote's Shield, Acrobat, Pass, Lucky Seven, Odd Rhythm,
      Even Rhythm, Prescience, Underdog, all Faire skills, all Breaker skills,
      all Rally skills (data files; Rally effects in M10), all Pair Up skills (data files only)
- [ ] Create `.tres` files for Awakening class-specific skills:
      Veteran, Rightful King, Ignis, Anathema, Vengeance, Tomebreaker, Lifetaker,
      Shadowgift, Beastbane, Stoneborn, Dragonskin, Wyrmsbane, Special Dance,
      Charm, Galeforce, Sol, Acrobat, Pass, Aggressor, Swordfaire, Deliverer,
      Lancebreaker, Odd Rhythm, Even Rhythm, Rally Magic, Rally Spectrum

### AoE damage framework

Several skills require attacking multiple targets simultaneously (Firebreathing, Inferno,
Whirlwind, Holy Aura, Meteor-type siege tomes). This needs a thin AoE layer on top of
`CombatResolver`.

- [ ] Add `resolve_aoe_attack(attacker: Node, target_tiles: Array[Vector2i]) -> Array[Dictionary]`
      to `CombatResolver`
- [ ] For each tile in `target_tiles`, if a unit occupies it and it is an enemy, apply
      the attacker's damage calculation against that unit. No counterattacks from AoE targets
      unless noted by the skill
- [ ] Apply weapon durability once for the whole AoE use (not per-target)
- [ ] Implement Firebreathing: fire spells hit target tile and one tile directly behind it
      (straight line away from attacker). Call `resolve_aoe_attack()` with both tiles
- [ ] Implement Inferno (Dracoknight occult): `on_hit` MAG/2%; primary target takes
      normal damage; adjacent enemies receive an `active_modifier` of `delta = -floor(MAG/2)`
      to `"hp"` with `duration_type = "turn"` (applied at their next turn start).
      Use a new `"delayed_damage"` duration type ticked in ConditionManager
- [ ] Implement Whirlwind (Raven occult): `on_hit` SPD/2%; push all enemies adjacent to
      attacker back 1 tile. Use existing Shove logic per adjacent enemy. Damage resolved
      against primary target only

### Checklist — M9 (summary)

- [ ] All generic stat-bonus skill `.tres` files created and passive effect working
- [ ] All aura skills verified in combat preview numbers
- [ ] All combat skills (Sol through Cancel) verified with manual test combats
- [ ] All Faire and Breaker skill `.tres` files created and verified
- [ ] Movement skill stubs replaced with real implementations in SkillHandler
- [ ] Reactive skills (Counter, Parry, Redirect, No Escape) verified with edge cases
- [ ] Per-map skills (Challenge, Rise, Strike True) use counter system correctly
- [ ] AoE framework implemented and used by Firebreathing
- [ ] All Awakening skill `.tres` files created
- [ ] Rightful King bonus hooks into activation rolls correctly
- [ ] Verify: a unit with no skills still functions identically to before M9

---

## Milestone 10 — Extra-Turn System (Canto and Dancer)

**Goal:** Units with Canto (Bard line, Heron), Special Dance (Dancer), Galeforce,
Encore, and Master Horseman can grant additional turns to themselves or allies within
the rules of each skill. **Test:** Use each extra-turn mechanic in a live map. Verify
turn state transitions. Verify per-map/per-turn limits. Verify cursor and UI behave
correctly during the extra turn.

### TurnManager extensions

```gdscript
func grant_extra_turn(unit: Node, options: Dictionary = {}) -> void:
    # Reactivates a DONE or MOVED unit.
    # options can include:
    #   "can_move": bool    (default true)
    #   "can_act": bool     (default true)
    #   "is_self": bool     (true for Galeforce/Encore; false for Canto/Dance targets)
    # Sets unit state to READY (or MOVED if can_move = false).
    # Emits EventBus.extra_turn_granted(unit).
    # The MapCursor must re-lock input until the extra turn is resolved.
    set_unit_state(unit, UnitState.READY if options.get("can_move", true) else UnitState.MOVED)
    EventBus.extra_turn_granted.emit(unit)

signal extra_turn_granted(unit: Node)  # add to EventBus.gd
```

### Canto skill implementation

Canto is a `player_activated` class skill. Triggering Canto:

- The Canto-holder selects one adjacent ally who is `DONE` this turn.
- `TurnManager.grant_extra_turn(target)` is called.
- Promotion modifiers:
  - **Resonance** (Troubadour): Canto can target up to 2 adjacent allies instead of 1.
  - **Battle Cry** (Skald): Canto target(s) gain +3 STR, MAG, SPD until end of their
    extra turn. Apply via `target.add_modifier()` with `duration_type = "combat"`.
  - **Reverberate** (Heron): In animal form only — Canto targets ALL adjacent allies.
    (Wire to M12 Laguz shift state check.)

```gdscript
# In ActionMenu — add "Canto" option for units with the skill
# Canto action handler:
func _execute_canto(canto_unit: Node) -> void:
    var max_targets: int = 2 if canto_unit.has_skill("resonance") else 1
    # Show target selection UI filtered to adjacent DONE allies
    # On confirm per target:
    if canto_unit.has_skill("battle_cry"):
        target.add_modifier("strength", 3, "battle_cry", 1, "combat")
        target.add_modifier("magic", 3, "battle_cry_mag", 1, "combat")
        target.add_modifier("speed", 3, "battle_cry_spd", 1, "combat")
    TurnManager.grant_extra_turn(target)
    # After max_targets resolved, canto_unit is set to DONE
    TurnManager.set_unit_state(canto_unit, TurnManager.UnitState.DONE)
```

### Encore (Skald occult)

`on_combat_end` SKL/2%; after Skald initiates combat, grant an extra turn to the Skald
itself. Max 2× per turn — tracked via `skill_use_counters["encore"]`. Uses
`TurnManager.grant_extra_turn(skald, { "is_self": true })`.

### Special Dance (Dancer)

Special Dance is a `player_activated` class skill with these rules:
- Target: one adjacent ally who has already acted this turn (state = `DONE`).
- Cannot target the same unit consecutively. Track via `last_dance_target: NodePath` on unit.
- Cannot target self.
- Player chooses one stat (STR, SPD, SKL, or LUK); target gains +4 to that stat for 1 turn.
- Dancer's turn ends.

```gdscript
func _execute_special_dance(dancer: Node, target: Node, chosen_stat: String) -> void:
    target.add_modifier(chosen_stat, 4, "special_dance", 1, "map_turn")
    dancer.data.skill_use_counters["last_dance_target"] = str(target.get_instance_id())
    TurnManager.grant_extra_turn(target)
    TurnManager.set_unit_state(dancer, TurnManager.UnitState.DONE)
```

### Galeforce (Dark Flier promotion)

Already specified in M9's `"galeforce"` implementation. Confirm here that:
- `grant_extra_turn(self, { "is_self": true })` is called correctly
- `skill_use_counters["galeforce"]` prevents double-activation per map turn

### Master Horseman (Nomad Trooper occult)

`on_combat_end` after a turn-ending action, SKL/2%: unit may move again and then
perform one more action. Implement as:
- Set unit state back to MOVED (can act but not move again after the second action).
- Track with `skill_use_counters["master_horseman"]` (once per turn).

### Rally skills

Rally skills are `player_activated` actions. They end the user's turn and buff
all allies within 3 spaces for 1 full round.

- [ ] Add "Rally" to the ActionMenu as an option when unit has any Rally skill
- [ ] Show a skill submenu listing all Rally skills the unit has
- [ ] On confirm, call `rally_handler(caster, radius: int, modifiers: Dictionary)`
      which iterates all allies within radius, applies `add_modifier()` for each stat
      in the modifiers dict with `duration = 1` and `duration_type = "map_turn"`
- [ ] Implement all 8 Rally `.tres` skills using the same `effect_id = "rally"` with
      `effect_params` specifying stat and delta. Special-case Rally Spectrum (+2 to all)
- [ ] Verify: Rally modifiers appear in the unit's stat readout and expire correctly

### Checklist — M10

- [ ] Add `grant_extra_turn()` to `TurnManager`
- [ ] Add `extra_turn_granted` signal to `EventBus.gd`
- [ ] Implement Canto action in `ActionMenu`; select adjacent DONE allies
- [ ] Implement Resonance modifier on Canto (up to 2 targets)
- [ ] Implement Battle Cry modifier (stat boost on Canto targets)
- [ ] Implement Encore (self extra-turn after combat, 2× per turn max)
- [ ] Implement Special Dance with consecutive-target tracking
- [ ] Implement stat choice selection UI for Special Dance `[PLACEHOLDER UI]`
- [ ] Verify: Galeforce triggers and grants a second turn after a kill
- [ ] Verify: Master Horseman re-enables an action after post-combat movement
- [ ] Implement Rally action in ActionMenu with skill submenu
- [ ] Implement `rally_handler()` in SkillHandler
- [ ] Create all 8 Rally skill `.tres` files with appropriate `effect_params`
- [ ] Verify: Rally Spectrum buffs all 8 stats simultaneously
- [ ] Verify: Rally modifiers expire exactly 1 full round after being applied
- [ ] Verify: Dancer cannot target the same unit twice in a row
- [ ] Verify: cursor input is locked correctly during an ally's extra turn
- [ ] Verify: a unit that uses Galeforce is only granted one extra turn per map turn even
      if they kill multiple enemies during that extra turn

---

## Milestone 11 — Content Expansion

**Goal:** All classes, weapons, skills, and items from the base handbook and Awakening
supplement exist as `.tres` files and load without error. No new systems are required
— this milestone is purely data. **Test:** `DataManager` loads all resources without
errors. Verify every class, weapon, and skill appears correctly in the editor Inspector.

### Classes

- [ ] Create `ClassData.tres` for all Beorc base classes not in MVP:
      Archer, Bard, Brigand, Cavalier, Druid, Fighter, Knight, Mage, Mercenary,
      Myrmidon, Nomad, Pegasus Knight, Soldier, Thief, Wyvern Rider
- [ ] Create `ClassData.tres` for all Beorc promoted classes:
      Ranger, Sniper, Skald, Troubadour, Berserker, Brawler, Paladin, Vanguard,
      Bishop, Paragon, Necromancer, Warlock, Guardian, Warrior, General, Great Knight,
      Mage Knight, Sage, Hero, Sentinel, Soulblade, Swordmaster, Nomad Trooper, Raider,
      Falcoknight, Valkyrie, Commander, Halberdier, Assassin, Rogue,
      Dracoknight, Wyvern Lord
- [ ] Create `ClassData.tres` for all Awakening supplement classes:
      Lord, Tactician, Dark Mage, Barbarian, Dancer, Villager
- [ ] Create `ClassData.tres` for all Awakening promoted classes:
      Great Lord, Grandmaster, Sorcerer, Dark Knight, Bow Knight, War Monk, War Cleric,
      Dark Flier, Griffon Rider, Trickster, Dread Fighter, Bride
- [ ] Create `ClassData.tres` for all Laguz base classes (Laguz fields populated;
      logic deferred to M12):
      Cat, Tiger, Hawk, Heron, Raven, Taguel, Manakete
- [ ] Verify: Cavalier `proficiencies` correctly represents "choose one of Axe/Lance/Sword"
      — implement as a new `ClassData` field `proficiency_choice: bool = false` with
      `proficiency_options: Array[String]` presented to the player/GM at unit creation
- [ ] Verify: Mage `proficiencies` supports "choose two Anima types"
- [ ] Verify: Dancer does not have a `promotes_to` entry (non-promoting class)
- [ ] Verify: Villager `promotes_to` is empty (GM-discretion promotion handled at runtime)

### Weapons

- [ ] Create `WeaponData.tres` for all axes (Bronze through Urvan, including Bolt Axe,
      Brave Axe, Halberd, Hammer, Wyrm Axe, etc.)
- [ ] Create `WeaponData.tres` for all bows (Bronze through Rienfleche, including
      Bright Bow with `magic_triangle_type = "light"`, Double Bow with `range_min = 1`)
- [ ] Create `WeaponData.tres` for all lances (Bronze through Wishblade, including
      Flame Lance with `magic_triangle_type = "fire"`, Brave Lance)
- [ ] Create `WeaponData.tres` for all swords (Bronze through Vague Katti, including
      Sonic Sword with `magic_triangle_type = "wind"`, Runesword with lifesteal tag,
      Brave Sword)
- [ ] Create `WeaponData.tres` for all knives (Bronze Knife through Peshkatz)
- [ ] Create `WeaponData.tres` for all staves (Heal through Ashera Staff)
- [ ] Create `WeaponData.tres` for all Fire tomes (Fire through Forblaze);
      Forblaze has a unique AoE — add `effect_tags: ["aoe_straight_line"]` and handle
      in the AoE framework from M9
- [ ] Create `WeaponData.tres` for all Thunder tomes (Thunder through Arcblast)
- [ ] Create `WeaponData.tres` for all Wind tomes (Wind through Aircalibur);
      Aircalibur has range 1–4
- [ ] Create `WeaponData.tres` for all Light tomes (Light through Aureola);
      Chastise and Aura have special `mt` formulas — add `effect_tags` to handle at runtime
- [ ] Create `WeaponData.tres` for all Dark tomes (Flux through Ereshkigal);
      Twilight ignores RES (`effect_tags: ["ignore_res"]`), Eclipse sets HP to 1
      (`effect_tags: ["set_hp_1"]`), Nosferatu has lifesteal (`effect_tags: ["lifesteal"]`)
- [ ] Create `WeaponData.tres` for all Laguz natural weapons (Beak/Claw/Fang/Talon
      at ranks E/D/C/A/S); set `is_natural_weapon = true` on all
- [ ] Create `WeaponData.tres` for Taguel Beaststones and Manakete Dragonstones
- [ ] Create `WeaponData.tres` for stationary battlefield weapons (Ballista variants,
      Onager); add `effect_tags: ["aoe_adjacent"]` to Onager
- [ ] Set `strikes_per_attack = 2` on: Brave Axe, Brave Bow, Brave Dagger,
      Brave Lance, Brave Sword
- [ ] Verify: all weapon `effect_tags` for effectiveness are spelled identically to the
      strings used in `_get_effectiveness_multiplier()` in CombatResolver

### Skills

- [ ] Create `SkillData.tres` for all generic handbook skills not yet created
- [ ] Create `SkillData.tres` for all promotion and occult skills not yet created
- [ ] Create `SkillData.tres` for all Awakening generic skills
- [ ] Create `SkillData.tres` for all Awakening class-specific skills
- [ ] Create `SkillData.tres` placeholder for all Laguz-specific skills
      (Feral Instincts, Wildheart, Primal Tenacity, Untamed Persistence, Pounce,
      Hit and Run, Ancient Verse, Whirlwind, Roar; mark `effect_id` as `"deferred_laguz"`)
- [ ] Create `SkillData.tres` for Pair Up skills (data only — logic never implemented):
      Dual Strike+, Dual Guard+, Dual Support+ (mark with a comment in description field)
- [ ] Verify: `DataManager._load_directory()` loads all new skill files without errors

### Items

- [ ] Create `ItemData.tres` for all healing items (Herb, Vulnerary, Concoction, Elixir)
- [ ] Create `ItemData.tres` for all Laguz items (Laguz Stone, Laguz Pearl, Laguz Gem);
      effects deferred to M12 — stubs that print a warning in MVP
- [ ] Create `ItemData.tres` for condition items (Antitoxin, Panacea)
- [ ] Create `ItemData.tres` for all key items (Chest Key, Door Key, Master Key)
- [ ] Create `ItemData.tres` for equip items (Full Guard, Wing Guard, Laguz Guard,
      Iron Rune, Knight Ring, Knight Ward); implement equip-slot logic:
      only 1 equip item may be active; it is read by `_collect_combat_modifiers()`
- [ ] Implement equip-item effects in `_collect_combat_modifiers()`:
      Full Guard → `skip_effectiveness = true`, Iron Rune → `defender_negate_crits = true`,
      Knight Ring → unit treated as Mounted for movement remainder, Knight Ward → stat bonus
- [ ] Create `ItemData.tres` for all stat items (Arms Scroll, Boots, Dracoshield, etc.)
- [ ] Implement stat item effects: permanent `add_modifier()` with `duration_type = "permanent"`
      where appropriate, or direct `UnitData` stat increase for items like Boots (+2 MOV permanent)
- [ ] Create `ItemData.tres` for sellable items (gems, Coin)
- [ ] Create `ItemData.tres` for all promotion items (Master Seal, class-specific seals,
      Laguz Seal, Occult Scroll)
- [ ] Create `ItemData.tres` for other items (Light Rune, Pure Water, Torch)
- [ ] Implement Light Rune: places a blocked-tile marker like Bastion (see M9) but
      uses 1 of the item's remaining uses per placement
- [ ] Implement Pure Water and Ward staff: apply `add_modifier("resistance", 7, "pure_water", -1, "map_turn")`
      where duration counts down by 1 each full round until reaching 0
- [ ] Implement Torch: `add_modifier("line_of_sight", 4, "torch", -1, "map_turn")` with same countdown
- [ ] Verify: no item causes a crash if used when the relevant Phase 2 system is not yet
      fully implemented — all stub paths must print a warning and no-op gracefully

### Checklist — M11

- [ ] All class `.tres` files load in DataManager without errors
- [ ] All weapon `.tres` files load without errors; Brave weapons have `strikes_per_attack = 2`
- [ ] All skill `.tres` files load without errors
- [ ] All item `.tres` files load without errors
- [ ] Equip item slot logic enforces 1-at-a-time limit
- [ ] Verify a promoted Cavalier can be created with the correct proficiency choice flow
- [ ] Verify Dancer has no promotion option in the class data

---

## Milestone 12 — Laguz System `[DEFERRED]`

**Goal:** Full Laguz gameplay. Laguz units have a functional shift gauge that fills and
drains each turn and per combat. They can shift to animal form gaining stat boosts and
natural weapons, and shift back. All Laguz-specific skills are active. Laguz items work.
**Test:** Play a map with one Laguz unit. Verify gauge fills in humanoid form, shifts on
confirm, stats update, natural weapon equips, and gauge drains in animal form. Verify
all Laguz class skills trigger correctly.

**Pre-condition:** M11 complete (all Laguz data `.tres` files exist).

### Data architecture (already in UnitData and ClassData from Amendment A1)

No new fields required. All shift gauge parameters live in `ClassData`. Runtime state
(`shift_gauge`, `is_shifted`) lives in `UnitData` and is already included in snapshots.

### Shift gauge system

```gdscript
# In TurnManager.start_player_phase() and per-enemy-turn:
func _tick_shift_gauge(unit: Node) -> void:
    if not unit.data.shift_profile_id:
        return  # not a Laguz
    var class_data: ClassData = DataManager.get_class_data(unit.data.shift_profile_id)
    if unit.data.is_shifted:
        unit.data.shift_gauge -= class_data.shift_gain_per_turn_animal
    else:
        unit.data.shift_gauge += class_data.shift_gain_per_turn_humanoid
    unit.data.shift_gauge = clamp(unit.data.shift_gauge, 0, class_data.max_shift_gauge)
    # Force-shift or force-unshift at gauge limits:
    if unit.data.is_shifted and unit.data.shift_gauge == 0:
        _unshift(unit)
    EventBus.shift_gauge_changed.emit(unit, unit.data.shift_gauge)

# Per-combat gauge change (call from CombatResolver after exchange resolves):
func _apply_combat_shift_change(unit: Node) -> void:
    var class_data: ClassData = DataManager.get_class_data(unit.data.shift_profile_id)
    if unit.data.is_shifted:
        unit.data.shift_gauge -= class_data.shift_gain_per_combat_animal
    else:
        unit.data.shift_gauge += class_data.shift_gain_per_combat_humanoid
    unit.data.shift_gauge = clamp(unit.data.shift_gauge, 0, class_data.max_shift_gauge)
    if unit.data.is_shifted and unit.data.shift_gauge == 0:
        _unshift(unit)
    EventBus.shift_gauge_changed.emit(unit, unit.data.shift_gauge)
```

### Shifting — form change

```gdscript
func _shift(unit: Node) -> void:
    # Requires shift_gauge at max (or Feral Instincts active).
    # Applies animal form stat bonuses as active_modifiers with duration = -1, source = "shift".
    var class_data: ClassData = DataManager.get_class_data(unit.data.shift_profile_id)
    var pct: float = class_data.animal_stat_bonus_pct  # 0.5 normally; 0.25 with Feral Instincts
    for stat in ["strength", "magic", "defense", "resistance", "skill", "speed"]:
        var base: int = unit.data.get(stat)
        unit.add_modifier(stat, floor(base * pct), "shift", -1, "permanent")
    # CON boost:
    unit.add_modifier("constitution", floor(unit.data.constitution * class_data.animal_con_bonus_pct),
                       "shift_con", -1, "permanent")
    # MOV +2:
    unit.add_modifier("movement", 2, "shift_mov", -1, "permanent")
    unit.data.is_shifted = true
    SkillHandler.apply_trigger(unit, "on_shift", {})
    EventBus.unit_shifted.emit(unit, true)

func _unshift(unit: Node) -> void:
    unit.remove_modifier("shift")
    unit.remove_modifier("shift_con")
    unit.remove_modifier("shift_mov")
    unit.data.is_shifted = false
    SkillHandler.apply_trigger(unit, "on_shift", {})
    EventBus.unit_shifted.emit(unit, false)
```

### Natural weapons

```gdscript
# In Unit.get_equipped_weapon():
# When unit.data.is_shifted, return the natural weapon for the unit's wexp rank.
func get_equipped_weapon() -> WeaponData:
    if data.is_shifted and data.shift_profile_id:
        var class_data: ClassData = DataManager.get_class_data(data.shift_profile_id)
        var weapon_type: String = class_data.natural_weapon_type  # "fang" | "claw" | etc.
        var rank: String = _get_weapon_rank(weapon_type)
        # Look up the natural weapon matching type + rank:
        return DataManager.get_natural_weapon(weapon_type, rank)
    # Standard equipped weapon logic:
    for entry in data.inventory:
        if entry["type"] == "weapon" and entry["uses_remaining"] > 0:
            var weapon := DataManager.get_weapon(entry["weapon_id"])
            if weapon and can_equip(weapon):
                return weapon
    return null
```

### Humanoid Laguz combat restriction

```gdscript
# In CombatResolver._build_combat_context():
# A Laguz in humanoid form can ONLY counterattack — they cannot initiate.
# Check: if attacker.data.shift_profile_id and not attacker.data.is_shifted:
#    this unit may not initiate combat. Enforce in MapCursor._on_confirm():
#    the Attack option is hidden if acting unit is an unshifted Laguz.
# This unit CAN appear as the defender and counter using their natural weapon IF shifted,
# or cannot counter at all if humanoid (no weapon to counter with).
```

### Laguz-specific action: Shift

- Add "Shift" to `ActionMenu` when the acting unit has `shift_profile_id` set.
- Shifting is a free action (does not end turn) if the gauge is at maximum.
- Feral Instincts allows shifting at any gauge level (at reduced bonus; see skill).
- Unshifting is always a free action.

### Laguz items

- **Laguz Stone**: adds `shift_gain_per_turn_humanoid × 2` to shift gauge (simulates 1 round
  in humanoid form). Does not shift the unit directly.
- **Laguz Pearl**: fills gauge to maximum. Does not shift.
- **Laguz Gem**: fills gauge to maximum (3 uses).
- All three: implement in the item use handler. Emit `EventBus.shift_gauge_changed`.

### Primal Tenacity skill

At the end of each map, if the unit has Primal Tenacity, save `shift_gauge` to
`UnitData` (already stored there). On next map load, instead of resetting
`shift_gauge` to `class_data.shift_gauge_start`, use the saved value.
Add a flag check in `GameMap._ready()` after spawning units.

### Laguz-specific skills — full implementation

- [ ] Implement `"feral_instincts"`: reduces bonus to 25% (`pct = 0.25` in `_shift()`);
      reduces MOV bonus by 1 (`add_modifier("movement", 1, ...)` instead of 2); allows
      shifting at any gauge level; EXP gain is halved while shifted (check in `Unit.add_exp()`)
- [ ] Implement `"wildheart"`: add 5 to `unit.data.shift_gauge` at map start (can stack;
      check count of "wildheart" in skills array and multiply)
- [ ] Implement `"primal_tenacity"`: preserve shift gauge between maps (see above)
- [ ] Implement `"untamed_persistence"`: add +2 to `shift_gain_per_turn_humanoid` at
      runtime (per instance of the skill in the skills array)
- [ ] Implement `"nimble"` (Cat): `get_move_cost_override` returns 1 for all non-wall terrain
- [ ] Implement `"tailwind"` (Hawk): aura skill — already wired in M9; activate now
- [ ] Implement `"grace"` (Heron): `start_of_turn`; adjacent allies heal MAG HP
- [ ] Implement `"reverberate"` (Heron): when Heron is in animal form and Canto is used,
      target ALL adjacent allies rather than 1
- [ ] Implement `"pounce"` (Cat occult): `player_activated`; after movement in a straight
      line, swap positions with enemy at the end of that line; make 3 consecutive attacks
      instead of normal attacks; resolved via `resolve_combat` called 3 times with
      counterattack suppressed on attacks 2 and 3
- [ ] Implement `"hit_and_run"` (Hawk occult): already specced in M9; ensure the
      "move after combat" hook respects Hawk's flying movement rules
- [ ] Implement `"ancient_verse"` (Heron occult): `player_activated`; replaces Canto;
      presents 3 choices — heal MAG HP, grant +DEF/RES equal to ¼ LUK, or restore
      2 weapon uses to equipped weapon
- [ ] Implement `"vortex"` (Raven promotion): `player_activated`; attack as though using
      an Elwind of rank equal to highest proficiency, calculated with SKL instead of MAG
      for damage, without needing the tome or proficiency
- [ ] Implement `"rend"` (Tiger promotion): `player_activated` before attack; crit is
      reduced to 0 and weapon Mt is doubled for that attack
- [ ] Implement `"roar"` (Tiger occult): `on_attack` STR/2%; deal 3× STR damage and
      inflict Stun on defender (requires M8)
- [ ] Implement `"beastbane"` (Taguel): +50 Hit/Dodge vs Beast, Mounted, or Armoured units
- [ ] Implement `"stoneborn"` (Taguel occult): `start_of_turn` while shifted; SKL/2%;
      choose 1 enemy within 2 spaces; apply `add_modifier("defense", -4, "stoneborn", 1, "turn")`
      and same for RES
- [ ] Implement `"dragonskin"` (Manakete): already specced in M9; activate here
- [ ] Implement `"wyrmsbane"` (Manakete occult): +50 Hit/Dodge vs Dragon, Mounted, Armoured

### HUD — Shift Gauge display

```gdscript
# New UI element in HUD.tscn: ShiftGaugePanel (CanvasLayer child)
# Only visible when selected unit has shift_profile_id set.
# Shows:
#   - Gauge fill bar (shift_gauge / max_shift_gauge)
#   - Current form label ("Humanoid" / "Animal")
#   - Animal-form stat preview (what stats will be in animal form)
# Updates on EventBus.shift_gauge_changed signal.
# [PLACEHOLDER visual — use a ProgressBar for MVP of this milestone]
```

### New EventBus signals for Laguz

```gdscript
signal shift_gauge_changed(unit: Node, new_value: int)
signal unit_shifted(unit: Node, is_animal_form: bool)
```

### Checklist — M12

- [ ] Add `shift_gauge_changed` and `unit_shifted` signals to `EventBus.gd`
- [ ] Implement `_tick_shift_gauge()` in TurnManager, called for each unit at turn start
- [ ] Implement `_apply_combat_shift_change()` in TurnManager; hook into
      `CombatResolver.resolve_combat()` post-resolution
- [ ] Implement `_shift()` and `_unshift()` in TurnManager or a new `LaguzManager.gd` autoload
- [ ] Implement `Unit.get_equipped_weapon()` Laguz branch with rank-matched natural weapon
- [ ] Add `DataManager.get_natural_weapon(type, rank)` lookup method
- [ ] Enforce humanoid Laguz combat restriction in `MapCursor` and `ActionMenu`
- [ ] Add "Shift" option to `ActionMenu` for Laguz units
- [ ] Implement gauge-at-max check for standard shift; Feral Instincts bypass
- [ ] Implement all 3 Laguz item effects (Stone, Pearl, Gem)
- [ ] Implement Primal Tenacity gauge preservation (save/load between maps)
- [ ] Create `ShiftGaugePanel` UI scene and script `[PLACEHOLDER visual]`
- [ ] Wire `ShiftGaugePanel` to `shift_gauge_changed` signal
- [ ] Implement all Laguz class skills listed above
- [ ] Verify: Cat gauge fills and drains at correct per-turn and per-combat rates
- [ ] Verify: shift applies correct +50% (or +25% with Feral Instincts) stat modifiers
- [ ] Verify: natural weapons match the correct rank based on wexp
- [ ] Verify: unshifted Laguz cannot initiate combat
- [ ] Verify: Reverberate causes Canto to target all adjacent allies when Heron is shifted
- [ ] Verify: Primal Tenacity preserves gauge value correctly between two maps
- [ ] Verify: Wildheart stacks correctly with multiple copies of the skill
- [ ] Verify: a Taguel and Manakete function identically to standard Laguz in terms of
      gauge mechanics, using their Beaststone/Dragonstone weapons in animal form

---

## Milestone 13 — Awakening Supplement `[DEFERRED]`

**Goal:** All Awakening classes, skills, and rules are fully functional. The Lord,
Tactician, Dancer, Villager, Dark Mage, Barbarian, Taguel, and Manakete class lines
are playable alongside all Awakening promoted classes. All Awakening skills work.
**Test:** Play a map with a full Awakening roster. Verify every class-specific skill
triggers. Verify Galeforce does not infinite-loop.

**Pre-condition:** M11 and M12 complete.

### New game rules from the Awakening supplement

The following rules differences from the base handbook must be enforced:

- **Dark Mage** is distinct from **Druid** — same Dark proficiency, different base stats
  and skill line (Anathema starting skill, Vengeance/Tomebreaker or Lifetaker/Shadowgift
  on promotion). No code change required — handled by ClassData.
- **Barbarian** promotes to Berserker or Warrior (same promoted classes as Brigand).
  Add `"berserker"` and `"warrior"` to `Barbarian.promotes_to`.
- **Dark Knight** is an alternate promotion for **Mage** in addition to Mage Knight and
  Sage. Add `"dark_knight"` to `Mage.promotes_to`.
- **Dancer** does not promote. Enforce by leaving `promotes_to` empty and hiding the
  promotion option in UI when `promotes_to.is_empty()`.
- **Villager** promotes at GM discretion to any non-mounted non-magical class.
  Implement as a runtime class selection presented to the player at promotion,
  filtered by the allowed class list. Store the chosen promoted class in UnitData.
- **Griffon Rider** does NOT have the Dragon special quality. Verify ClassData.
- **Master Seal** works on all Beorc classes including Awakening additions.
- **Laguz Seal** works on Taguel and Manakete in addition to standard Laguz.

### Awakening class-specific skills

All data files created in M11. Wire effect_id implementations here for any
class skills not already implemented in M9:

- [ ] Verify `"veteran"` (Tactician) is implemented and working (from M9)
- [ ] Verify `"rightful_king"` (Great Lord) activation bonus is working (from M9)
- [ ] Verify `"ignis"` (Grandmaster) is implemented (from M9)
- [ ] Verify `"anathema"` (Dark Mage) aura is working (from M9)
- [ ] Verify `"vengeance"` (Sorcerer) is implemented (from M9)
- [ ] Verify `"tomebreaker"` (Sorcerer) is working (Breaker family from M9)
- [ ] Verify `"lifetaker"` (Dark Knight) is implemented (from M9)
- [ ] Implement `"shadowgift"` (Dark Knight/Sorcerer occult): allows equipping Dark tomes
      regardless of proficiency. Add a check in `Unit.can_equip()`: if unit has Shadowgift
      and weapon type is "dark" or any dark-type, bypass the proficiency rank check
- [ ] Verify `"beastbane"` (Taguel) and `"stoneborn"` are implemented (from M12)
- [ ] Verify `"dragonskin"` (Manakete) and `"wyrmsbane"` are implemented (from M12)
- [ ] Verify `"special_dance"` (Dancer) is implemented (from M10)
- [ ] Verify `"charm"` (Lord/Bride) is implemented (from M9)
- [ ] Verify `"galeforce"` (Dark Flier) is implemented and respects once-per-map-turn limit
- [ ] Verify `"sol"` (War Monk/War Cleric) is implemented (from M9)
- [ ] Verify `"acrobat"` (Trickster) movement override is working (from M9)
- [ ] Verify `"pass"` (Trickster occult) movement override is working (from M9)
- [ ] Verify `"aggressor"` (Dread Fighter) applies correctly on initiation (from M9)
- [ ] Verify `"swordfaire"` (Dread Fighter occult) works (Faire family from M9)
- [ ] Implement `"deliverer"` (Griffon Rider): grant Savior effect (no rescue penalties)
      plus no MOV penalty while rescuing. Verify Savior is implemented; if so, Deliverer
      reuses the same modifier logic
- [ ] Verify `"lancebreaker"` (Griffon Rider occult) is working (Breaker family from M9)
- [ ] Verify `"odd_rhythm"` (War Monk) is implemented (from M9)
- [ ] Verify `"rally_magic"` (Dark Flier occult) is implemented (Rally family from M10)

### Promotion options for existing classes

- [ ] Update `Mage.promotes_to` to include `"dark_knight"` option
- [ ] Update `Brigand.promotes_to` to verify it includes both Berserker and Warrior
- [ ] Add `Barbarian.promotes_to = ["berserker", "warrior"]`
- [ ] Update any UI that lists promotion choices to handle classes with 3+ options

### Checklist — M13

- [ ] All Awakening class data verified in editor Inspector
- [ ] Dancer promotion restriction enforced in UI
- [ ] Villager runtime promotion class-selection UI implemented
- [ ] Shadowgift bypasses Dark tome proficiency check correctly
- [ ] Dark Knight available as Mage promotion option in UI
- [ ] Griffon Rider confirmed to lack Dragon special quality in ClassData
- [ ] All Awakening skills verified functional via test play
- [ ] Galeforce verified it cannot trigger more than once per map turn even with
      multiple kills during an extra turn
- [ ] Laguz Seal functions on Taguel and Manakete
- [ ] Verify: no skill or class change causes an error when a unit with that class/skill
      is serialized and deserialized for the mid-battle suspend save

---

## Phase 3 Backlog (Post-Awakening)

The following items are planned but not yet milestoned. Implement after M13 is stable.

### Content

- [ ] All remaining handbook classes not covered in M11 (GM-discretion additions)
- [ ] Full forging UI and shop system (already architected in GDD_09 Phase 2 backlog)
- [ ] Class promotion UI for classes with 3+ promotion paths

### Systems

- [ ] Between-map save / load (GDD_09 Phase 2 backlog)
- [ ] Mid-battle suspend save — full serialization of: all unit `UnitData` (including
      `active_modifiers`, `conditions`, `skill_use_counters`, `shift_gauge`, `is_shifted`),
      all unit tile positions, TurnManager state (current phase, turn number, unit states),
      EnemyAI state (which enemies have acted), active Bastion/Light Rune blocked tiles,
      current map ID. The `UnitData` field design from Amendment A1 ensures all runtime
      state is serializable without scene tree traversal.
- [ ] Fog of war and LoS (GDD_09 Phase 2 backlog)
- [ ] Rescue and carry system (GDD_09 Phase 2 backlog)
- [ ] Ally NPC phase (GDD_09 Phase 2 backlog)
- [ ] Additional AI profiles: territorial, guard_tile, healer, boss (GDD_09 Phase 2 backlog)
- [ ] Stationary weapon interaction (Ballista/Onager use by player; already have WeaponData)
- [ ] Door and chest interaction system (Pick skill, Unlock staff, Key items)
- [ ] Pre-battle deployment screen

### Maps

- [ ] Maps 002–005 per GDD_09 Phase 2 backlog (Seize, Boss Defeat, Escape, Survive/Defend)

### Polish

- [ ] [PLACEHOLDER] All unit sprites and class portraits
- [ ] [PLACEHOLDER] Terrain tile sprites
- [ ] [PLACEHOLDER] UI panel art and Shift Gauge visual
- [ ] [PLACEHOLDER] Combat animations — hit, miss, crit, death
- [ ] [PLACEHOLDER] Skill activation flash effects
- [ ] [PLACEHOLDER] Music per phase and map
- [ ] [PLACEHOLDER] Sound effects (shift, condition apply, skill trigger, etc.)
- [ ] [PLACEHOLDER] Story and dialogue system
- [ ] Steam / itch.io / GitHub release packaging
