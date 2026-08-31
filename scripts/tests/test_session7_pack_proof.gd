extends SceneTree
# Session 7 adopter proof: combat, items, progression and skills, exercised
# against the AUTHORED Fire-Emblem proving-grounds pack rather than a fixture.
#
# The migration is only real if a campaign somebody authored still plays through
# it, so this selects that pack the way the game does — DataManager's Tier-2
# campaign source, the same call select_campaign() makes — and then drives its
# own units, weapons, items and skills through the shared transaction.
#
# It is deliberately NOT a unit test of the transaction. The unit tests live in
# test_combat.gd, test_skill_item_handler.gd and test_skill_effect_registry.gd;
# what this proves is that authored content reaches the migrated paths.
#
# KNOWN GATE LIMITATION, shared with test_shared_effect_pack_proof.gd: when the
# sibling pack checkout is unreachable this SKIPS rather than fails, so the
# gated exact-tree run does not exercise it. That hole is
# SHARED-EFFECT-PROOF-GATE-ENFORCEMENT-2026-08-31; do not close this proof's
# rows on a run that printed the skip line.

const UnitScene = preload("res://scenes/units/Unit.tscn")
const CombatResolverScript = preload("res://scripts/core/CombatResolver.gd")
const ProgressionCoordinatorScript = preload("res://scripts/items/ProgressionCoordinator.gd")

const PACK_ID := "prometheus-proving-grounds-internal-fe"
const PACK_VERSION := "0.1.0"
const ROSTER_ID := "roster_map_950_promotion_validation"

var _passed := 0
var _failed := 0


func _check(value: bool, label: String) -> void:
	if value:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s" % label)
		_failed += 1


func _pack_path() -> String:
	var candidates: Array[String] = [
		ProjectSettings.globalize_path(
			"res://../Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds"
		),
		(
			OS
			. get_environment("PWD")
			. path_join("../Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds")
			. simplify_path()
		),
		(
			OS
			. get_environment("PWD")
			. path_join("repo/Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds")
			. simplify_path()
		),
	]
	for candidate in candidates:
		if DirAccess.dir_exists_absolute(candidate):
			return candidate
	return ""


# Builds a live unit from an authored roster entry — the same UnitData the game
# would deploy, not a mock shaped to suit the test.
func _unit_from_roster(roster: Array, unit_id: String, tile: Vector2i, team: String) -> Node:
	for data in roster:
		if String(data.unit_id) != unit_id:
			continue
		var unit: Node = UnitScene.instantiate()
		root.add_child(unit)
		unit.initialize(data, tile, team)
		return unit
	return null


func _entry_for(unit: Node, item_id: String) -> RefCounted:
	for entry in unit.data.inventory:
		if String(entry.item_id) == item_id:
			return entry
	return null


func _init() -> void:
	print("=== Session 7 FE Pack Adopter Proof ===")
	await process_frame
	var data_manager := root.get_node_or_null("DataManager")
	var pack_path := _pack_path()
	if data_manager == null or pack_path.is_empty():
		print("SKIP session 7 pack proof: sibling FE proving_grounds checkout unavailable")
		quit(0)
		return
	if not data_manager.select_tier2_campaign_source(pack_path, PACK_ID, PACK_VERSION):
		print("FAIL selecting the authored FE campaign source")
		quit(1)
		return
	print("OK  the authored FE proving-grounds campaign source is selected")
	_passed += 1

	var roster: Array = data_manager.get_campaign_pack_roster(ROSTER_ID)
	var attacker := _unit_from_roster(roster, "m950_mercenary", Vector2i(0, 0), "blue")
	var defender := _unit_from_roster(roster, "m950_cavalier", Vector2i(1, 0), "red")
	if attacker == null or defender == null:
		print("FAIL the authored roster did not yield both proof units")
		quit(1)
		return
	print("OK  two units are deployed from the authored map_950 roster")
	_passed += 1

	# ---- passive skills answer as contributions, not as effects ----
	var skill_handler := root.get_node_or_null("SkillHandler")
	var swiftfoot = data_manager.get_skill("swiftfoot")
	attacker.data.skills.append("swiftfoot")
	_check(
		(
			swiftfoot != null
			and skill_handler.get_move_cost_override(attacker, "forest") == 1
			and skill_handler.get_move_cost_override(attacker, "sea") == -1
		),
		"an authored passive skill answers its movement query through the contribution registry"
	)
	attacker.data.skills.erase("swiftfoot")

	# ---- a resolved fight prepares everything and commits nothing ----
	var combat := root.get_node_or_null("CombatResolver")
	attacker.data.skills.append("swordfaire")
	var defender_hp_before: int = defender.data.hp
	var attacker_wexp_before: int = attacker.get_weapon_wexp("sword")
	var weapon_entry = attacker.get_equipped_weapon_entry()
	var uses_before: int = weapon_entry.uses_remaining if weapon_entry != null else -1

	var record: Array[String] = combat.make_attack_event_record(
		attacker, defender, attacker.tile_position
	)
	var result: Dictionary = combat.resolve_combat(attacker, defender, record)
	var landed: bool = (result["exchanges"] as Array).any(func(e): return e["hit"])
	var entry_after_resolve = attacker.get_equipped_weapon_entry()
	_check(
		(
			landed
			and defender.data.hp == defender_hp_before
			and attacker.get_weapon_wexp("sword") == attacker_wexp_before
			and (
				(entry_after_resolve.uses_remaining if entry_after_resolve != null else -1)
				== uses_before
			)
		),
		"a fight between authored units resolves without writing HP, weapon EXP or durability"
	)
	_check(
		not (result["transaction"].save_fields_touched() as Array).is_empty(),
		"the prepared fight declares the save fields it will touch"
	)

	combat.apply_combat_result(result, attacker, defender)
	var entry_after_apply = attacker.get_equipped_weapon_entry()
	_check(
		(
			defender.data.hp < defender_hp_before
			and attacker.get_weapon_wexp("sword") > attacker_wexp_before
			and (
				(entry_after_apply.uses_remaining if entry_after_apply != null else -1)
				< uses_before
			)
		),
		"applying it commits HP, weapon EXP and durability together"
	)

	var hp_after_apply: int = defender.data.hp
	combat.apply_combat_result(result, attacker, defender)
	_check(
		defender.data.hp == hp_after_apply,
		"applying the same fight twice changes nothing the second time"
	)
	attacker.data.skills.erase("swordfaire")

	# ---- the authored vulnerary heals and is spent together ----
	var item_handler := root.get_node_or_null("ItemHandler")
	defender.data.inventory.append(
		load("res://scripts/resources/InventoryEntry.gd").make_item("vulnerary", 3)
	)
	var vulnerary = _entry_for(defender, "vulnerary")
	var hp_before_item: int = defender.data.hp
	var item_outcome: Dictionary = item_handler.apply_item(defender, vulnerary)
	_check(
		(
			item_outcome.get("ok", false)
			and defender.data.hp > hp_before_item
			and vulnerary.uses_remaining == 2
		),
		"the authored vulnerary heals and spends one use in one transaction"
	)

	var unheld = load("res://scripts/resources/InventoryEntry.gd").make_item("vulnerary", 3)
	var hp_before_unheld: int = defender.data.hp
	var unheld_outcome: Dictionary = item_handler.apply_item(defender, unheld)
	_check(
		(
			not unheld_outcome.get("ok", false)
			and defender.data.hp == hp_before_unheld
			and unheld.uses_remaining == 3
		),
		"a vulnerary the unit does not hold heals nothing and spends nothing"
	)

	# ---- the authored master seal and the class change land together ----
	var coordinator := root.get_node_or_null("ProgressionCoordinator")
	var seal = _entry_for(attacker, "master_seal")
	var class_before := String(attacker.data.class_id)
	var seal_uses_before: int = seal.uses_remaining if seal != null else -1
	var promotion: Dictionary = coordinator.commit_promotion(attacker, "hero", seal)
	var seal_after = _entry_for(attacker, "master_seal")
	var seal_uses_after: int = seal_after.uses_remaining if seal_after != null else -1
	var promoted: bool = String(attacker.data.class_id) != class_before
	_check(
		(
			(promotion.get("ok", false) and promoted and seal_uses_after < seal_uses_before)
			or (
				not promotion.get("ok", false)
				and not promoted
				and seal_uses_after == seal_uses_before
			)
		),
		"the authored master seal and the class change either both land or neither does"
	)
	print(
		(
			"    (promotion outcome: ok=%s class %s -> %s, seal uses %d -> %d)"
			% [
				promotion.get("ok", false),
				class_before,
				String(attacker.data.class_id),
				seal_uses_before,
				seal_uses_after
			]
		)
	)

	print("\nResults: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
