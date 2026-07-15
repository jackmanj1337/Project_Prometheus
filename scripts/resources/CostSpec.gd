class_name CostSpec extends Resource

# Positive amounts spend a resource; negative amounts credit it. Formula terms
# are reserved for the later predicate/formula foundation.
@export var resource_id: String = ""
@export var scope: String = ""
@export var amount: int = 0
@export var formula_term: String = ""
@export var subject_binding: String = ""
@export var previewable: bool = true
@export var refundable: bool = true
@export var allow_partial: bool = false
@export var ui_summary: Dictionary = {}


static func fixed(
		id: String, wallet_scope: String, value: int,
		binding: String = "", can_refund: bool = true):
	var cost = load("res://scripts/resources/CostSpec.gd").new()
	cost.resource_id = id
	cost.scope = wallet_scope
	cost.amount = value
	cost.subject_binding = binding
	cost.refundable = can_refund
	return cost
