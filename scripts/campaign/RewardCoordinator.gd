class_name RewardCoordinator extends RefCounted

## Makes the existing victory gold credit and party-item custody one operation.

const CostSpecScript = preload("res://scripts/resources/CostSpec.gd")
const EffectTransactionScript = preload("res://scripts/actions/EffectTransaction.gd")
const LedgerParticipantScript = preload("res://scripts/actions/ResourceLedgerParticipant.gd")
const ItemCustodyScript = preload("res://scripts/campaign/PartyItemCustodyParticipant.gd")


static func grant(ledger: Node, game_state: Node, gold: int, item_ids: Array[String]) -> Dictionary:
	if ledger == null or game_state == null:
		return {"ok": false, "code": "missing_authority"}
	var transaction := EffectTransactionScript.new()
	transaction.add_participant(ItemCustodyScript.new(game_state, item_ids))
	if gold != 0:
		var cost = CostSpecScript.fixed("party_gold", "party", -gold)
		var reservation: RefCounted = ledger.reserve([cost], {"game_state": game_state})
		if not reservation.ok:
			return {
				"ok": false, "code": "resource_prepare_failed", "error": reservation.failure_reason
			}
		# Ledger goes last. Custody is reversible if its final revalidation fails.
		transaction.add_participant(LedgerParticipantScript.new(ledger, reservation))
	var outcome: Dictionary = transaction.commit()
	if not outcome.ok:
		return outcome
	return {
		"ok": true,
		"gold_earned": gold,
		"total_gold": int(game_state.party_gold),
		"items_awarded": item_ids.duplicate(true),
	}
