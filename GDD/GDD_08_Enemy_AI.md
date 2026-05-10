# GDD_08 — Enemy AI

---

## Overview

Enemy AI is isolated in `EnemyAI.gd`. It is called once per enemy phase by
`TurnManager.start_enemy_phase()` and resolves all enemy turns sequentially.

The system is built for extensibility: each enemy unit has an `ai_profile` string
in their `MapData` placement entry. The AI dispatcher reads this string and calls the
corresponding decision function. Adding a new AI profile requires only adding a new
function — no structural changes.

---

## Architecture

### `EnemyAI.gd`

```gdscript
extends Node

# Called by TurnManager. Resolves all enemy turns one at a time.
func run_enemy_phase() -> void:
    var enemies = GameState.get_living_enemy_units()
    for enemy in enemies:
        await take_turn(enemy)
        await get_tree().create_timer(0.3).timeout   # Brief pause between enemies

# Dispatches to the correct AI profile function
func take_turn(unit: Node) -> void:
    var profile: String = unit.data.ai_profile
    match profile:
        "basic":     await _run_basic(unit)
        "passive":   await _run_passive(unit)
        # Future profiles added here
        _:
            push_warning("Unknown AI profile: " + profile)
            await _run_basic(unit)   # fallback

# ─── AI Profiles ────────────────────────────────────────────────────────────

func _run_basic(unit: Node) -> void:
    # See full algorithm below
    pass

func _run_passive(unit: Node) -> void:
    # Does not move or attack; stands still
    # Used for Phase 2 reinforcements, sleeping units, etc.
    pass
```

---

## Basic AI Profile (`"basic"`)

The default profile for all MVP enemies. Behavior: move toward the weakest
attackable player unit and attack it.

### Decision Algorithm (Step by Step)

```
1. Find all player units this enemy can reach and attack this turn
   (i.e., units within movement + attack range)

2. If any attackable targets exist:
   a. Score each target (see Scoring below)
   b. Select highest-scoring target
   c. Find the best tile to attack from (see Positioning below)
   d. Move to that tile
   e. Attack the target

3. If no targets are in range this turn:
   a. Find the closest player unit (Manhattan distance)
   b. Move as far as possible toward that unit (stopping short of
      entering its weapon range if possible — OPTIONAL, skip for MVP)
   c. Do not attack; end turn
```

### Scoring Targets

When multiple targets are attackable, the AI scores each and picks the highest.

```gdscript
func _score_target(attacker: Node, target: Node) -> float:
    var preview = CombatResolver.preview_combat(attacker, target)

    # Primary: can we kill them?
    var expected_damage = preview.attacker_dmg * preview.attacker_attacks
    var can_kill = expected_damage >= target.data.hp

    # Secondary: lowest HP target (finisher mentality)
    var hp_score = 1.0 - (float(target.data.hp) / float(target.data.max_hp))

    # Tertiary: highest expected damage we can deal
    var damage_score = float(expected_damage) / float(target.data.max_hp)

    # Penalty: how much damage can target deal back to us?
    var counter_damage = preview.defender_dmg * preview.defender_attacks
    var survival_score = 1.0 - (float(counter_damage) / float(attacker.data.hp))
    survival_score = clamp(survival_score, 0.0, 1.0)

    if can_kill:
        return 1000.0 + hp_score   # Always prefer a kill
    return (hp_score * 0.5) + (damage_score * 0.3) + (survival_score * 0.2)
```

### Finding the Best Attack Tile

After selecting a target, the AI must choose which tile to stand on when attacking.

```gdscript
func _find_best_attack_tile(attacker: Node, target: Node) -> Vector2i:
    var reachable = GridManager.get_movement_range(attacker)
    var weapon = attacker.get_equipped_weapon()
    var valid_tiles: Array[Vector2i] = []

    for tile in reachable:
        if GridManager.can_attack_from_tile(attacker, tile, target):
            # Exclude tiles occupied by other units (already handled in get_movement_range)
            valid_tiles.append(tile)

    if valid_tiles.is_empty():
        return attacker.tile_position   # Cannot reach — stay put

    # Among valid tiles, prefer the one with the best terrain defense for the attacker
    var best_tile = valid_tiles[0]
    var best_def = -1

    for tile in valid_tiles:
        var terrain = GridManager.get_terrain_at(tile)
        var def_bonus = _get_terrain_def_bonus(terrain)
        if def_bonus > best_def:
            best_def = def_bonus
            best_tile = tile

    return best_tile

func _get_terrain_def_bonus(terrain: String) -> int:
    match terrain:
        "fort":     return 2
        "mountain": return 2
        "forest":   return 1
        _:          return 0
```

### Movement Toward Closest Unit (No Target in Range)

```gdscript
func _move_toward_closest_player(unit: Node) -> void:
    var players = GameState.get_living_player_units()
    if players.is_empty():
        return

    # Find closest player unit by Manhattan distance
    var closest: Node = null
    var min_dist: int = 999999
    for p in players:
        var dist = abs(p.tile_position.x - unit.tile_position.x) \
                 + abs(p.tile_position.y - unit.tile_position.y)
        if dist < min_dist:
            min_dist = dist
            closest = p

    # Get movement range and pick the tile in range closest to the target
    var reachable = GridManager.get_movement_range(unit)
    if reachable.is_empty():
        return

    var best_tile = unit.tile_position
    var best_dist = min_dist
    for tile in reachable:
        var dist = abs(closest.tile_position.x - tile.x) \
                 + abs(closest.tile_position.y - tile.y)
        if dist < best_dist:
            best_dist = dist
            best_tile = tile

    if best_tile != unit.tile_position:
        var path = GridManager.get_path_to(unit, best_tile)
        await unit.move_along_path(path)
```

### Full Basic AI Turn

```gdscript
func _run_basic(unit: Node) -> void:
    # --- Step 1: Find all reachable attackable targets ---
    var reachable_tiles = GridManager.get_movement_range(unit)
    var attackable_targets: Dictionary = {}  # target Node -> best attack tile

    for tile in reachable_tiles:
        var enemies_from_tile = GridManager.get_attackable_enemies_from_tile(unit, tile)
        for target in enemies_from_tile:   # "enemies" from AI's perspective = player units
            if not attackable_targets.has(target):
                attackable_targets[target] = tile
            else:
                # Keep the better tile (prefer higher terrain DEF)
                var current_best = attackable_targets[target]
                var terrain_current = GridManager.get_terrain_at(current_best)
                var terrain_new = GridManager.get_terrain_at(tile)
                if _get_terrain_def_bonus(terrain_new) > _get_terrain_def_bonus(terrain_current):
                    attackable_targets[target] = tile

    # --- Step 2: Attack if possible ---
    if not attackable_targets.is_empty():
        # Score each target and pick best
        var best_target: Node = null
        var best_score: float = -1.0
        for target in attackable_targets.keys():
            var score = _score_target(unit, target)
            if score > best_score:
                best_score = score
                best_target = target

        var attack_tile = _find_best_attack_tile(unit, best_target)

        # Move
        if attack_tile != unit.tile_position:
            var path = GridManager.get_path_to(unit, attack_tile)
            await unit.move_along_path(path)

        # Attack
        var result = CombatResolver.resolve_combat(unit, best_target)
        # Apply result (same combat pipeline as player attacks)
        await _apply_combat_result(result, unit, best_target)

    # --- Step 3: No target — move toward closest player ---
    else:
        await _move_toward_closest_player(unit)
```

---

## Staff AI (Phase 2)

For enemies that carry staves (healers), add a `"healer"` profile:

```
Priority order:
1. Heal the lowest-HP ally within staff range if HP < 75% of max
2. Otherwise, fall back to basic movement-toward-player behavior
3. Never attack directly (unless they have a weapon too)
```

---

## Future AI Profiles (Phase 2+)

These profiles are designed but not implemented in MVP. Register them in `take_turn()`'s
`match` block when ready.

| Profile | Behavior |
|---|---|
| `"passive"` | Never moves or attacks. Used for Phase 2 sleeping units or stationary guards |
| `"territorial"` | Attacks any player unit that enters its patrol radius; otherwise stays put |
| `"guard_tile"` | Never leaves a designated tile; attacks if a player comes in range |
| `"healer"` | Prioritizes healing allied units below 75% HP; otherwise acts as basic |
| `"aggressive"` | Same as basic but ignores counter-damage penalty in scoring — always attacks |
| `"boss"` | Same as basic but uses terrain-optimal positioning more aggressively; uses items |

Store the profile string in the enemy's `UnitData`:
```gdscript
# In UnitData.gd
@export var ai_profile: String = "basic"
```

---

## AI Execution Timing

During the enemy phase, the cursor is locked and input is disabled. Each enemy action
is animated so the player can follow what is happening.

| Event | Duration |
|---|---|
| Enemy movement (per tile) | 0.12 seconds per tile (matches player movement speed) |
| Pause before attacking | 0.2 seconds |
| Combat resolution display | Same as player combat (flash + HP update) |
| Pause between enemies | 0.3 seconds |
| Phase banner display | 1.4 seconds total (0.3 slide in, 0.8 hold, 0.3 slide out) |

All timings are constants defined at the top of `EnemyAI.gd` and `TurnManager.gd`
so they can be adjusted easily.

---

## Applying Combat Results

Both player and enemy combat use the same pipeline after `CombatResolver.resolve_combat()`
returns. This shared function lives in `CombatResolver.gd` or a helper:

```gdscript
# In CombatResolver.gd
func apply_combat_result(result: Dictionary, attacker: Node, defender: Node) -> void:
    for exchange in result.exchanges:
        var actor: Node = exchange.actor
        var target: Node = exchange.target

        if exchange.hit:
            # [PLACEHOLDER] play hit animation / flash
            target.take_damage(exchange.damage)
            if exchange.weapon_broke:
                actor.use_weapon_durability()
        else:
            # [PLACEHOLDER] play miss animation / "Miss" text
            pass

        await get_tree().create_timer(0.25).timeout   # Brief pause per hit

    attacker.add_exp(result.attacker_exp)
    attacker.add_wexp(attacker.get_equipped_weapon().weapon_type, result.attacker_wexp)
```

---

## Testing the AI

A minimal test checklist for the MVP AI:

- [ ] Enemy with a melee weapon attacks adjacent player unit
- [ ] Enemy with a ranged weapon attacks from range without closing
- [ ] Enemy moves toward nearest player when no target in range
- [ ] Enemy with highest score target (kill shot) attacks that target, not lowest HP
- [ ] Enemy stops moving when it reaches weapon range; does not overshoot
- [ ] Enemy correctly cannot counterattack player using ranged weapon from outside melee range
- [ ] Two enemies do not attempt to occupy the same tile
- [ ] Enemy on Fort/Throne tile heals 10% HP at start of their turn
- [ ] Enemy phase ends after all enemies have acted
- [ ] Player phase begins correctly after enemy phase
