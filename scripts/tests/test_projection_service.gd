extends SceneTree

const GameConstants = preload("res://scripts/shared/GameConstants.gd")
const UnitDataScript = preload("res://scripts/resources/UnitData.gd")
const WeaponDataScript = preload("res://scripts/resources/WeaponData.gd")
const InventoryEntryScript = preload("res://scripts/resources/InventoryEntry.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")
const ActionContextScript = preload("res://scripts/actions/ActionContext.gd")
const EffectStateViewScript = preload("res://scripts/actions/EffectStateView.gd")

var _passed := 0
var _failed := 0


class MockUnit:
	extends Node
	var data: Resource
	var tile_position := Vector2i.ZERO
	var team := "blue"
	var weapon: Resource

	func get_equipped_weapon() -> Resource:
		return weapon

	func has_quality(_quality: String) -> bool:
		return false

	func has_vulnerability(_quality: String) -> bool:
		return false

	func has_skill(skill_id: String) -> bool:
		return skill_id in data.skills

	func effective_modifiers(sink: RefCounted = null) -> Array:
		if sink != null and sink.has_method("effective_modifiers"):
			return sink.effective_modifiers(self)
		return data.active_modifiers

	func get_effective_stat(stat_name: String, sink: RefCounted = null) -> int:
		var value := int(data.get(stat_name))
		for modifier in effective_modifiers(sink):
			if modifier.get("stat", "") == stat_name:
				value += int(modifier.get("delta", 0))
		return maxi(0, value)

	func battle_speed(use_weapon: Resource = null, sink: RefCounted = null) -> int:
		var equipped := use_weapon if use_weapon != null else weapon
		return (
			get_effective_stat("speed", sink)
			- maxi(0, int(equipped.wt) - get_effective_stat("strength", sink))
		)

	func accuracy(use_weapon: Resource = null, sink: RefCounted = null) -> int:
		var equipped := use_weapon if use_weapon != null else weapon
		return (
			get_effective_stat("skill", sink) * 2
			+ get_effective_stat("luck", sink)
			+ int(equipped.hit)
		)

	func dodge(use_weapon: Resource = null, sink: RefCounted = null) -> int:
		return battle_speed(use_weapon, sink) * 2 + get_effective_stat("luck", sink)

	func crit_rate(use_weapon: Resource = null, sink: RefCounted = null) -> int:
		var equipped := use_weapon if use_weapon != null else weapon
		return get_effective_stat("skill", sink) / 2 + int(equipped.crit)

	func crit_avoid(sink: RefCounted = null) -> int:
		return get_effective_stat("luck", sink)

	func get_terrain_def_bonus() -> int:
		return 0

	func get_terrain_dodge_bonus() -> int:
		return 0

	func get_weapon_rank(track: String) -> String:
		return GameConstants.weapon_rank_for_wexp(int(data.weapon_wexp.get(track, 0)))


func _make_unit(id: String, team_id: String, tile: Vector2i) -> MockUnit:
	var unit_data := UnitDataScript.new()
	unit_data.unit_id = id
	unit_data.unit_name = id
	unit_data.hp = 30
	unit_data.max_hp = 30
	unit_data.strength = 10
	unit_data.defense = 5
	unit_data.skill = 10
	unit_data.speed = 10
	unit_data.luck = 5
	var weapon := WeaponDataScript.new()
	weapon.id = "%s_sword" % id
	weapon.combat_family = "sword"
	weapon.wexp_track = "sword"
	weapon.mt = 6
	weapon.hit = 85
	weapon.wt = 5
	weapon.range_min_formula = "1"
	weapon.range_max_formula = "1"
	var unit := MockUnit.new()
	unit.data = unit_data
	unit.weapon = weapon
	unit.team = team_id
	unit.tile_position = tile
	root.add_child(unit)
	return unit


func _check(condition: bool, label: String) -> void:
	if condition:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1


func _mutable_unit_state_bytes(unit: Node) -> PackedByteArray:
	return var_to_bytes_with_objects(
		{
			"hp": unit.data.hp,
			"active_modifiers": unit.data.active_modifiers,
			"skill_use_counters": unit.data.skill_use_counters,
			"inventory": unit.data.inventory,
		}
	)


func _init() -> void:
	await process_frame
	var projection := root.get_node_or_null("ProjectionService")
	var combat := root.get_node_or_null("CombatResolver")
	var rng := root.get_node_or_null("RngService")
	var game_state := root.get_node_or_null("GameState")
	if projection == null or combat == null or rng == null or game_state == null:
		print("\nResults: 0 passed, 1 failed")
		quit(1)
		return

	var attacker := _make_unit("projection_attacker", "blue", Vector2i.ZERO)
	var defender := _make_unit("projection_defender", "red", Vector2i(1, 0))
	attacker.data.active_modifiers.append(
		{
			"stat": "strength",
			"delta": 2,
			"source": "projection_fixture",
			"duration": 1,
			"duration_type": "turn"
		}
	)
	defender.data.active_modifiers.append(
		{
			"stat": "defense",
			"delta": 1,
			"source": "projection_fixture",
			"duration": 1,
			"duration_type": "turn"
		}
	)
	attacker.data.inventory.append(InventoryEntryScript.make_weapon("iron_sword", 40))
	defender.data.inventory.append(InventoryEntryScript.make_item("vulnerary", 3))
	var direct: Dictionary = combat.preview_combat(attacker, defender)
	var rng_before: Dictionary = rng.to_save_dict().duplicate(true)
	var gold_before: int = game_state.party_gold
	var attacker_before := _mutable_unit_state_bytes(attacker)
	var defender_before := _mutable_unit_state_bytes(defender)
	var result = projection.project_combat(attacker, defender, "test")
	_check(
		result.valid and result.visible_outcome == direct,
		"combat projection delegates to the existing preview math"
	)
	_check(
		(
			result.rng_summary.get("attacker_hit") == direct["attacker_hit"]
			and result.rng_summary.get("committed_draws") == 0
		),
		"projection reports odds without committed draws"
	)
	_check(
		rng.to_save_dict() == rng_before and game_state.party_gold == gold_before,
		"projection preserves RNG and resource save fields"
	)
	_check(
		(
			_mutable_unit_state_bytes(attacker) == attacker_before
			and _mutable_unit_state_bytes(defender) == defender_before
		),
		"projection preserves both units' HP, modifiers, counters, and inventory bytes"
	)
	var invalid = projection.project_combat(attacker, null)
	_check(
		not invalid.valid and invalid.failure_reason == "missing_target",
		"invalid combat target returns a structured failure"
	)

	var registry := root.get_node_or_null("RegistryManager")
	var primitive := RegistryEntryScript.new()
	primitive.id = "projection_set_value"
	primitive.family = "action_primitives"
	primitive.label_key = "test.projection"
	primitive.owner_feature = "SHARED-EFFECT-PROJECTION"
	primitive.kind = "mutation"
	primitive.primitive_handler = "set_state_value"
	primitive.params_schema = {
		"authority_id": {"type": "string", "required": true},
		"save_field": {"type": "string", "required": true},
		"value": {"type": "variant", "required": true},
	}
	primitive.save_fields.assign(["campaign_vars.projection_proof"])
	primitive.docs_text = "Projection fixture primitive."
	primitive.test_fixture = {"value": true}
	var composition := RegistryEntryScript.new()
	composition.id = "projection_proof"
	composition.family = "effect_compositions"
	composition.label_key = "test.projection"
	composition.owner_feature = "SHARED-EFFECT-PROJECTION"
	composition.kind = "composition"
	(
		composition
		. composition
		. assign(
			[
				{
					"step_id": "project",
					"primitive_id": "projection_set_value",
					"params":
					{
						"authority_id": "campaign",
						"save_field": "campaign_vars.projection_proof",
						"value": true,
					},
					"target": {"kind": "campaign"},
				}
			]
		)
	)
	composition.docs_text = "Projection fixture composition."
	composition.test_fixture = {"source": "test"}
	registry._catalog.register_entry(primitive)
	registry._catalog.register_entry(composition)
	var live := {"campaign_vars.projection_proof": false}
	var effect_context = ActionContextScript.new("story", {})
	effect_context.target_refs["campaign"] = "projection_campaign"
	effect_context.state_view = EffectStateViewScript.new()
	effect_context.state_view.register_authority(
		"campaign",
		func(field, _ref): return live[field],
		func(field, _ref, value): live[field] = value
	)
	var effect_result = projection.project_effect("projection_proof", effect_context, "test")
	_check(
		(
			effect_result.valid
			and not live["campaign_vars.projection_proof"]
			and effect_result.state_deltas.size() == 1
			and effect_result.rng_summary.committed_draws == 0
		),
		"effect projection exposes the prepared journal without state or RNG mutation"
	)

	print("\nResults: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
