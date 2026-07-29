extends SceneTree

const DeathContextScript = preload("res://scripts/death/DeathContext.gd")
const DeathDispositionScript = preload("res://scripts/death/DeathDisposition.gd")
const InventoryEntryScript = preload("res://scripts/resources/InventoryEntry.gd")
const UnitDataScript = preload("res://scripts/resources/UnitData.gd")

var _gs: Node


class MockUnit:
	extends Node
	var data: UnitData
	var team: String = "blue"
	var tile_position: Vector2i = Vector2i(2, 3)


func _make_unit(id: String) -> MockUnit:
	var unit := MockUnit.new()
	unit.data = UnitDataScript.new()
	unit.data.unit_id = id
	unit.data.hp = 0
	unit.data.inventory.append(InventoryEntryScript.make_item("vulnerary", 2))
	get_root().add_child(unit)
	_gs.register_unit(unit)
	return unit


func _init() -> void:
	var relay := Node.new()
	root.add_child(relay)
	await process_frame
	_gs = relay.get_node_or_null("/root/GameState")
	var lifecycle: Node = relay.get_node_or_null("/root/DeathLifecycle")
	var bus: Node = relay.get_node_or_null("/root/EventBus")
	relay.queue_free()
	if _gs == null or lifecycle == null or bus == null:
		print("\nResults: 0 passed, 1 failed (missing autoload)")
		quit(1)
		return
	var passed := 0
	var failed := 0
	var old_permadeath: bool = _gs.campaign_rules.permadeath_enabled
	lifecycle.disposition = DeathDispositionScript.new()

	_gs.campaign_rules.permadeath_enabled = true
	var classic := _make_unit("classic")
	var classic_events := [0]
	var count_classic := func(_unit): classic_events[0] += 1
	bus.unit_died.connect(count_classic)
	var classic_result = lifecycle.handle_death(
		DeathContextScript.from_subject(classic, "test", "classic")
	)
	bus.unit_died.disconnect(count_classic)
	if (
		classic_result.ok
		and classic_result.incapacitated
		and classic.data.is_incapacitated
		and not (classic in _gs.all_units)
		and classic_events[0] == 1
	):
		print("OK  classic death incapacitates, unregisters, and emits once")
		passed += 1
	else:
		print("FAIL classic lifecycle result")
		failed += 1

	_gs.campaign_rules.permadeath_enabled = false
	var casual := _make_unit("casual")
	var inventory_before: Array = casual.data.inventory.duplicate()
	var casual_result = lifecycle.handle_death(
		DeathContextScript.from_subject(casual, "hazard", "fixture")
	)
	if casual_result.ok and not casual_result.incapacitated and not casual.data.is_incapacitated:
		print("OK  casual death preserves deployable unit data")
		passed += 1
	else:
		print("FAIL casual lifecycle result")
		failed += 1
	if casual.data.inventory == inventory_before and casual_result.inventory_events.is_empty():
		print("OK  no-op disposition leaves inventory untouched")
		passed += 1
	else:
		print("FAIL no-op disposition changed inventory")
		failed += 1

	var snap := _make_unit("snapshot")
	var ctx = DeathContextScript.from_subject(snap, "combat", "attack")
	snap.data.inventory.clear()
	if (
		ctx.subject_id == "snapshot"
		and ctx.tile == Vector2i(2, 3)
		and ctx.inventory_snapshot.size() == 1
	):
		print("OK  death context captures identity, tile, and inventory at entry")
		passed += 1
	else:
		print("FAIL death context snapshot")
		failed += 1
	_gs.unregister_unit(snap)
	snap.queue_free()

	var missing = lifecycle.handle_death(null)
	if not missing.ok and missing.failure_reason == "missing death subject":
		print("OK  missing subject returns a structured failure")
		passed += 1
	else:
		print("FAIL missing subject failure")
		failed += 1

	_gs.campaign_rules.permadeath_enabled = old_permadeath
	print("\nResults: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
