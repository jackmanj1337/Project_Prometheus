extends SceneTree

const CostSpecScript = preload("res://scripts/resources/CostSpec.gd")


func _init() -> void:
	print("=== ResourceLedger Test ===")
	var passed := 0
	var failed := 0

	var registry: Node = load("res://scripts/autoloads/RegistryManager.gd").new()
	registry.name = "RegistryManager"
	root.add_child(registry)
	var game_state: Node = load("res://scripts/autoloads/GameState.gd").new()
	game_state.name = "GameState"
	root.add_child(game_state)
	var ledger: Node = load("res://scripts/autoloads/ResourceLedger.gd").new()
	ledger.name = "ResourceLedger"
	root.add_child(ledger)
	await process_frame

	game_state.party_gold = 100
	var spend: Resource = CostSpecScript.fixed("party_gold", "party", 30)
	var quote: RefCounted = ledger.quote([spend])
	if quote.ok and quote.deltas["party:party_gold"] == -30 and game_state.party_gold == 100:
		print("OK  party quote reports spend without mutation")
		passed += 1
	else:
		print(
			(
				"FAIL party quote: ok=%s deltas=%s gold=%d"
				% [quote.ok, quote.deltas, game_state.party_gold]
			)
		)
		failed += 1

	var committed: RefCounted = ledger.commit([spend])
	var refunded: RefCounted = ledger.refund(committed)
	if committed.ok and committed.committed and refunded.ok and game_state.party_gold == 100:
		print("OK  party spend commits and recorded-delta refund restores it")
		passed += 1
	else:
		print(
			(
				"FAIL party spend/refund: commit=%s refund=%s gold=%d"
				% [committed.failure_reason, refunded.failure_reason, game_state.party_gold]
			)
		)
		failed += 1

	var credit: RefCounted = ledger.commit([CostSpecScript.fixed("party_gold", "party", -25)])
	if credit.ok and game_state.party_gold == 125:
		print("OK  negative fixed cost credits party gold")
		passed += 1
	else:
		print("FAIL party credit: %s gold=%d" % [credit.failure_reason, game_state.party_gold])
		failed += 1

	game_state.party_gold = 100
	var scaled_cost: Resource = CostSpecScript.scaled(
		"party_gold", "party", "quantity", "unit_price"
	)
	var scaled_quote: RefCounted = ledger.quote([scaled_cost], {"quantity": 3, "unit_price": 20})
	var scaled_commit: RefCounted = ledger.commit([scaled_cost], {"quantity": 3, "unit_price": 20})
	if scaled_quote.ok and scaled_commit.ok and game_state.party_gold == 40:
		print("OK  registered quantity cost quotes purely and commits once")
		passed += 1
	else:
		print("FAIL registered quantity cost: %s" % scaled_commit.failure_reason)
		failed += 1

	var unit := UnitData.new()
	unit.gold = 40
	var unit_spend: Resource = CostSpecScript.fixed("unit_gold", "unit", 15, "buyer")
	var unit_quote: RefCounted = ledger.quote([unit_spend], {"buyer": unit})
	var unit_commit: RefCounted = ledger.commit([unit_spend], {"buyer": unit})
	if unit_quote.ok and unit_commit.ok and unit.gold == 25:
		print("OK  unit binding quotes and spends UnitData.gold")
		passed += 1
	else:
		print(
			(
				"FAIL unit wallet: quote=%s commit=%s gold=%d"
				% [unit_quote.failure_reason, unit_commit.failure_reason, unit.gold]
			)
		)
		failed += 1

	game_state.party_gold = 80
	unit.gold = 50
	var both: RefCounted = (
		ledger
		. commit(
			[
				CostSpecScript.fixed("party_gold", "party", 20),
				CostSpecScript.fixed("unit_gold", "unit", 10, "unit"),
			],
			{"unit": unit}
		)
	)
	if both.ok and game_state.party_gold == 60 and unit.gold == 40:
		print("OK  multi-wallet spend commits atomically")
		passed += 1
	else:
		print(
			(
				"FAIL multi-wallet success: %s party=%d unit=%d"
				% [both.failure_reason, game_state.party_gold, unit.gold]
			)
		)
		failed += 1

	game_state.party_gold = 80
	unit.gold = 5
	var failed_both: RefCounted = (
		ledger
		. commit(
			[
				CostSpecScript.fixed("party_gold", "party", 20),
				CostSpecScript.fixed("unit_gold", "unit", 10, "unit"),
			],
			{"unit": unit}
		)
	)
	if not failed_both.ok and game_state.party_gold == 80 and unit.gold == 5:
		print("OK  multi-wallet shortfall mutates nothing")
		passed += 1
	else:
		print(
			(
				"FAIL atomic shortfall: ok=%s party=%d unit=%d"
				% [failed_both.ok, game_state.party_gold, unit.gold]
			)
		)
		failed += 1

	var unknown: RefCounted = ledger.commit([CostSpecScript.fixed("missing_wallet", "party", 1)])
	if not unknown.ok and unknown.missing_resources == ["missing_wallet"]:
		print("OK  unknown resource fails validation")
		passed += 1
	else:
		print("FAIL unknown resource: ok=%s missing=%s" % [unknown.ok, unknown.missing_resources])
		failed += 1

	game_state.party_gold = 10
	var original: Resource = CostSpecScript.fixed("party_gold", "party", 7)
	var recorded: RefCounted = ledger.commit([original])
	original.amount = 999
	var recorded_refund: RefCounted = ledger.refund(recorded)
	if recorded_refund.ok and game_state.party_gold == 10:
		print("OK  refund uses committed delta instead of changed cost")
		passed += 1
	else:
		print(
			(
				"FAIL recorded refund: %s gold=%d"
				% [recorded_refund.failure_reason, game_state.party_gold]
			)
		)
		failed += 1

	# A failed multi-record refund must not claim it applied earlier reverse deltas.
	game_state.party_gold = 20
	unit.gold = 0
	var credited: RefCounted = (
		ledger
		. commit(
			[
				CostSpecScript.fixed("party_gold", "party", 5),
				CostSpecScript.fixed("unit_gold", "unit", -10, "unit"),
			],
			{"unit": unit}
		)
	)
	unit.gold = 0
	var failed_refund: RefCounted = ledger.refund(credited)
	if (
		not failed_refund.ok
		and failed_refund.wallets_touched.is_empty()
		and failed_refund.deltas.is_empty()
		and game_state.party_gold == 15
		and unit.gold == 0
	):
		print("OK  failed refund reports no unapplied wallet deltas")
		passed += 1
	else:
		print(
			(
				"FAIL failed refund reporting: wallets=%s deltas=%s party=%d unit=%d"
				% [
					failed_refund.wallets_touched,
					failed_refund.deltas,
					game_state.party_gold,
					unit.gold
				]
			)
		)
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
