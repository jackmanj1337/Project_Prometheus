extends SceneTree
## Authored-pack adoption proof for the sprite composition schema.
##
## This is intentionally a player-boundary test: select the real FE pack, start
## its campaign, resolve the first playable roster, and let Unit consume the
## resolved class visual metadata. The pure schema suite proves rejection rules;
## this proves authored content reaches the runtime path.

const AdopterPack = preload("res://scripts/tests/support/adopter_pack.gd")
const UnitScene = preload("res://scenes/units/Unit.tscn")

const PACK_RELATIVE_PATH := "Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds"
const PACK_ID := "prometheus-proving-grounds-internal-fe"
const PACK_VERSION := "0.1.0"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Sprite Composition FE Pack Adopter Proof ===")
	var located := AdopterPack.locate(PACK_RELATIVE_PATH)
	if located["state"] == AdopterPack.ABSENT:
		print("SKIP: sprite composition pack proof -- %s" % located["detail"])
		print("  The authored-pack adopter coverage is NOT verified in this environment.")
		quit(0)
		return
	if located["state"] == AdopterPack.MISSING:
		print("FAIL sprite composition pack proof -- %s" % located["detail"])
		print("\nResults: 0 passed, 1 failed")
		quit(1)
		return

	var data_manager := root.get_node_or_null("DataManager")
	var campaign_manager := root.get_node_or_null("CampaignManager")
	if data_manager == null or campaign_manager == null:
		print("FAIL required runtime autoloads are unavailable")
		print("\nResults: 0 passed, 1 failed")
		quit(1)
		return

	var passed := 0
	var failed := 0
	var pack_path: String = located["path"]
	var selected: bool = data_manager.select_tier2_campaign_source(pack_path, PACK_ID, PACK_VERSION)
	if selected and campaign_manager.start_campaign("proving_grounds"):
		print("OK  the authored FE campaign is selected and started")
		passed += 1
	else:
		print("FAIL selecting or starting the authored FE campaign")
		failed += 1

	var class_data: ClassData = data_manager.get_class_data("cavalier")
	var composition: Dictionary = class_data.sprite_composition if class_data != null else {}
	var palettes: Dictionary = class_data.faction_palettes if class_data != null else {}
	if (
		composition.get("id", "") == "cavalier_unit"
		and composition.get("layers", []).size() == 3
		and composition["layers"][0]["id"] == "shadow"
		and composition["layers"][1]["id"] == "body"
		and palettes.size() == 4
		and palettes.has("cavalier_blue")
	):
		print("OK  the authored class exposes its resolved layer order and four faction palettes")
		passed += 1
	else:
		print("FAIL authored class visual metadata: %s / %s" % [composition, palettes])
		failed += 1

	var roster: Array = data_manager.get_campaign_pack_roster("roster_default")
	var unit_data: UnitData = roster[0] if not roster.is_empty() else null
	var unit: Unit = UnitScene.instantiate()
	root.add_child(unit)
	if unit_data != null:
		unit.initialize(unit_data, Vector2i.ZERO, "blue")
	await process_frame
	var applied: Dictionary = unit.apply_pack_sprite_asset(data_manager.pack_assets())
	if (
		unit_data != null
		and applied.get("composition", {}).get("id", "") == "cavalier_unit"
		and applied.get("faction_palettes", {}).size() == 4
	):
		print("OK  a deployed authored unit carries the composition through sprite setup")
		passed += 1
	else:
		print("FAIL deployed unit composition handoff: %s" % applied)
		failed += 1

	unit.queue_free()
	campaign_manager.end_campaign()
	print("\nResults: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
