class_name ResourceTransaction extends RefCounted

var ok: bool = false
var failure_reason: String = ""
var missing_resources: Array[String] = []
var shortfalls: Dictionary = {}
var wallets_touched: Array[String] = []
var deltas: Dictionary = {}
var display_summary: Array[Dictionary] = []
var committed: bool = false
var reserved: bool = false
var refunded: bool = false
var refundable: bool = true

# Runtime-only wallet records make refunds reverse the committed deltas instead
# of recalculating costs. They are deliberately absent from save data.
var _wallet_records: Array[Dictionary] = []


static func failure(reason: String):
	var result = load("res://scripts/resources/ResourceTransaction.gd").new()
	result.failure_reason = reason
	return result
