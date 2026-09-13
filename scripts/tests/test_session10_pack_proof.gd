extends SceneTree
# Session 10 authored-adopter proof. The FE proving-grounds map supplies the
# reward; the live coordinator commits its wallet and custody as one operation.

const AdopterPack = preload("res://scripts/tests/support/adopter_pack.gd")
const RewardCoordinatorScript = preload("res://scripts/campaign/RewardCoordinator.gd")

const PACK_RELATIVE_PATH := "Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds"
const PACK_ID := "prometheus-proving-grounds-internal-fe"
const PACK_VERSION := "0.1.0"
const MAP_SOURCE := "campaign-pack://prometheus-proving-grounds-internal-fe/0.1.0/map_001"


func _init() -> void:
	print("=== Session 10 FE Pack Adopter Proof ===")
	await process_frame
	var located := AdopterPack.locate(PACK_RELATIVE_PATH)
	if located["state"] == AdopterPack.ABSENT:
		print("SKIP: session 10 pack proof -- %s" % located["detail"])
		print("  The authored victory-reward adopter coverage is NOT verified in this environment.")
		quit(0)
		return
	if located["state"] == AdopterPack.MISSING:
		print("FAIL session 10 pack proof -- %s" % located["detail"])
		print("Results: 0 passed, 1 failed")
		quit(1)
		return

	var data_manager := root.get_node_or_null("DataManager")
	var game_state := root.get_node_or_null("GameState")
	var ledger := root.get_node_or_null("ResourceLedger")
	if data_manager == null or game_state == null or ledger == null:
		print("FAIL required runtime autoloads are unavailable")
		quit(1)
		return
	if not data_manager.select_tier2_campaign_source(located["path"], PACK_ID, PACK_VERSION):
		print("FAIL selecting the authored FE campaign source")
		quit(1)
		return
	var authored_map: MapData = data_manager.resolve_map_data(MAP_SOURCE)
	if authored_map == null:
		print("FAIL resolving the authored FE reward map")
		quit(1)
		return

	game_state.party_gold = 100
	game_state.party_items.clear()
	var receipt: Dictionary = RewardCoordinatorScript.grant(
		ledger, game_state, authored_map.reward_gold, authored_map.reward_items
	)
	var passed: bool = (
		receipt.get("ok", false)
		and authored_map.reward_gold == 500
		and game_state.party_gold == 600
		and receipt.get("gold_earned", 0) == 500
		and receipt.get("total_gold", 0) == 600
	)
	print(
		(
			"OK  selected FE campaign commits its authored victory reward"
			if passed
			else "FAIL authored reward did not commit"
		)
	)
	print("Results: %d passed, %d failed" % [1 if passed else 0, 0 if passed else 1])
	quit(0 if passed else 1)
