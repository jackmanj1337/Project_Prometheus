extends Node

const CostSpecScript = preload("res://scripts/resources/CostSpec.gd")
const ResourceTransactionScript = preload("res://scripts/resources/ResourceTransaction.gd")


func quote(costs: Array, ctx: Dictionary = {}) -> RefCounted:
	return _prepare(costs, ctx)


func reserve(costs: Array, ctx: Dictionary = {}) -> RefCounted:
	var transaction: RefCounted = _prepare(costs, ctx)
	if transaction.ok:
		# No consumer needs held balances yet. Preserve a transient reservation
		# record without changing the wallet; commit always revalidates live state.
		transaction.reserved = true
	return transaction


func commit(costs: Array, ctx: Dictionary = {}) -> RefCounted:
	var transaction: RefCounted = _prepare(costs, ctx)
	if not transaction.ok:
		return transaction
	_apply_records(transaction._wallet_records)
	transaction.committed = true
	return transaction


func refund(transaction: RefCounted, _ctx: Dictionary = {}) -> RefCounted:
	if transaction == null or not transaction.committed:
		return ResourceTransactionScript.failure(
			"ResourceLedger: only committed transactions can be refunded"
		)
	if transaction.refunded:
		return ResourceTransactionScript.failure("ResourceLedger: transaction was already refunded")
	if not transaction.refundable:
		return ResourceTransactionScript.failure("ResourceLedger: transaction is not refundable")

	var refund_result := ResourceTransactionScript.new()
	for record in transaction._wallet_records:
		var reverse: Dictionary = record.duplicate()
		reverse["delta"] = -int(record["delta"])
		var current := _read_wallet(reverse)
		if current + int(reverse["delta"]) < 0:
			refund_result.failure_reason = (
				"ResourceLedger: refund would overdraw '%s'" % reverse["resource_id"]
			)
			refund_result.shortfalls[reverse["resource_id"]] = -(current + int(reverse["delta"]))
			return refund_result
		refund_result._wallet_records.append(reverse)
	for reverse in refund_result._wallet_records:
		_record_public_delta(refund_result, reverse)
	_apply_records(refund_result._wallet_records)
	refund_result.ok = true
	refund_result.committed = true
	transaction.refunded = true
	return refund_result


func _prepare(costs: Array, ctx: Dictionary) -> RefCounted:
	var result := ResourceTransactionScript.new()
	var registry := get_node_or_null("/root/RegistryManager")
	if registry == null:
		result.failure_reason = "ResourceLedger: RegistryManager is unavailable"
		return result
	if costs.is_empty():
		result.ok = true
		return result

	var aggregated: Dictionary = {}
	for value in costs:
		if not (value is CostSpecScript):
			result.failure_reason = "ResourceLedger: costs must be CostSpec resources"
			return result
		var cost: Resource = value
		var amount_result := CostFormulaRegistry.evaluate(
			"fixed" if cost.formula_term == "" else cost.formula_term,
			{"amount": cost.amount} if cost.formula_term == "" else cost.formula_parameters,
			ctx
		)
		if not amount_result.ok:
			result.failure_reason = "ResourceLedger: %s" % amount_result.error
			return result
		var resolved_amount := int(amount_result.value)
		var entry = registry.call("entry", "resource_types", cost.resource_id)
		if entry == null:
			result.missing_resources.append(cost.resource_id)
			result.failure_reason = "ResourceLedger: unknown resource '%s'" % cost.resource_id
			return result
		if cost.scope == "" or not cost.scope in entry.subjects:
			result.failure_reason = (
				"ResourceLedger: resource '%s' does not support scope '%s'"
				% [cost.resource_id, cost.scope]
			)
			return result
		var record := _resolve_wallet(cost, ctx, entry)
		if record.is_empty():
			result.failure_reason = (
				"ResourceLedger: subject binding '%s' did not resolve" % cost.subject_binding
			)
			return result
		var key: String = record["key"]
		if aggregated.has(key):
			aggregated[key]["delta"] = int(aggregated[key]["delta"]) - resolved_amount
			aggregated[key]["refundable"] = bool(aggregated[key]["refundable"]) and cost.refundable
		else:
			record["delta"] = -resolved_amount
			record["refundable"] = cost.refundable
			aggregated[key] = record
		(
			result
			. display_summary
			. append(
				{
					"resource_id": cost.resource_id,
					"amount": resolved_amount,
					"ui": cost.ui_summary.duplicate(true),
				}
			)
		)

	for record in aggregated.values():
		var current := _read_wallet(record)
		var final_value: int = current + int(record["delta"])
		if final_value < 0:
			result.shortfalls[record["resource_id"]] = -final_value
			result.failure_reason = "ResourceLedger: insufficient '%s'" % record["resource_id"]
			return result
		result._wallet_records.append(record)
		result.refundable = result.refundable and bool(record["refundable"])
		_record_public_delta(result, record)
	result.ok = true
	return result


func _resolve_wallet(cost: Resource, ctx: Dictionary, entry: Resource) -> Dictionary:
	if entry.primitive_handler == "party_gold_wallet":
		var game_state: Object = ctx.get("game_state", get_node_or_null("/root/GameState"))
		if game_state == null:
			return {}
		return {
			"key": "party:%s" % cost.resource_id,
			"resource_id": cost.resource_id,
			"scope": "party",
			"target": game_state,
			"property": &"party_gold",
		}
	if entry.primitive_handler == "unit_gold_wallet":
		var binding: String = cost.subject_binding if cost.subject_binding != "" else "unit"
		var subject: Variant = ctx.get(binding)
		if subject is Node and subject.get("data") != null:
			subject = subject.get("data")
		if not (subject is Object) or subject.get("gold") == null:
			return {}
		return {
			"key": "unit:%s:%s" % [subject.get_instance_id(), cost.resource_id],
			"resource_id": cost.resource_id,
			"scope": "unit",
			"target": subject,
			"property": &"gold",
		}
	return {}


func _read_wallet(record: Dictionary) -> int:
	return int((record["target"] as Object).get(record["property"]))


func _apply_records(records: Array[Dictionary]) -> void:
	for record in records:
		var target: Object = record["target"]
		target.set(record["property"], _read_wallet(record) + int(record["delta"]))


func _record_public_delta(result: RefCounted, record: Dictionary) -> void:
	var key: String = record["key"]
	result.wallets_touched.append(key)
	result.deltas[key] = int(record["delta"])
