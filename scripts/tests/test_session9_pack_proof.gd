extends SceneTree
# Session 9 authored-adopter proof. The FE proving-grounds pack supplies the
# composition; the live CrossingService resolves it through ActionEffectRunner.

const AdopterPack = preload("res://scripts/tests/support/adopter_pack.gd")

const PACK_RELATIVE_PATH := "Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds"
const PACK_ID := "prometheus-proving-grounds-internal-fe"
const PACK_VERSION := "0.1.0"

var passed := 0
var failed := 0


class VisibilityAuthority:
	extends RefCounted
	var discovered_units: Dictionary = {}
	var refresh_count := 0

	func commit_reveal(spotted: Array[Node], _mover: Node) -> void:
		for unit in spotted:
			discovered_units[unit] = true

	func refresh() -> void:
		refresh_count += 1


class AuthoredCrossing:
	extends RefCounted
	var authority: RefCounted
	var spotted: Node

	func _init(p_authority: RefCounted, p_spotted: Node) -> void:
		authority = p_authority
		spotted = p_spotted

	func probe(context: Dictionary) -> Variant:
		if context["tile"] != Vector2i(1, 0):
			return null
		return {
			"id": "authored_world_reveal",
			"interrupt": "halt",
			"composition_id": "fog_reveal",
			"subjects": {"visibility": authority},
			"event_metadata": {"spotted": [spotted], "mover": context["unit"]},
		}


func check(ok: bool, label: String) -> void:
	if ok:
		print("OK  %s" % label)
		passed += 1
	else:
		print("FAIL %s" % label)
		failed += 1


func _init() -> void:
	print("=== Session 9 FE Pack Adopter Proof ===")
	await process_frame
	var located := AdopterPack.locate(PACK_RELATIVE_PATH)
	if located["state"] == AdopterPack.ABSENT:
		print("SKIP: session 9 pack proof -- %s" % located["detail"])
		print("  The authored world-effect adopter coverage is NOT verified in this environment.")
		quit(0)
		return
	if located["state"] == AdopterPack.MISSING:
		print("FAIL session 9 pack proof -- %s" % located["detail"])
		print("Results: 0 passed, 1 failed")
		quit(1)
		return

	var data_manager := root.get_node_or_null("DataManager")
	var registry := root.get_node_or_null("RegistryManager")
	var crossing := root.get_node_or_null("CrossingService")
	if data_manager == null or registry == null or crossing == null:
		print("FAIL required runtime autoloads are unavailable")
		print("Results: 0 passed, 1 failed")
		quit(1)
		return
	if not data_manager.select_tier2_campaign_source(located["path"], PACK_ID, PACK_VERSION):
		print("FAIL selecting the authored FE campaign source")
		quit(1)
		return
	check(
		registry.has_entry("effect_compositions", "fog_reveal"),
		"select_campaign loads the pack-authored world composition"
	)

	var mover := Node.new()
	var spotted := Node.new()
	root.add_child(mover)
	root.add_child(spotted)
	var authority := VisibilityAuthority.new()
	var authored := AuthoredCrossing.new(authority, spotted)
	crossing.clear_consumers()
	check(
		crossing.register_consumer("authored_world", authored.probe).is_empty(),
		"the authored world source registers without an engine source switch"
	)
	var path: Array[Vector2i] = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)]
	var outcome: CrossingOutcome = crossing.resolve(mover, path)
	check(
		outcome.fired == ["authored_world_reveal"] and outcome.errors.is_empty(),
		"the crossing commits the authored composition through the shared runner"
	)
	check(
		authority.discovered_units.has(spotted),
		"the composition commits its visibility participant"
	)
	check(
		outcome.halted and outcome.destination() == Vector2i(1, 0),
		"adapter-owned interruption remains deterministic"
	)
	crossing.clear_consumers()
	mover.queue_free()
	spotted.queue_free()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
