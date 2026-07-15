extends Node
## Single mutation funnel for unit death and future non-combat death producers.

const DeathDispositionScript = preload("res://scripts/death/DeathDisposition.gd")
const DeathResultScript = preload("res://scripts/death/DeathResult.gd")

var disposition: RefCounted = DeathDispositionScript.new()


func handle_death(ctx: RefCounted) -> RefCounted:
	if ctx == null or ctx.subject == null:
		return DeathResultScript.failure("missing death subject")
	var unit: Node = ctx.subject
	var unit_data = unit.get("data")
	if unit_data == null:
		return DeathResultScript.failure("death subject has no unit data")

	var result: RefCounted = DeathResultScript.new()
	result.subject_id = ctx.subject_id
	var gs := get_node_or_null("/root/GameState")
	if gs != null:
		var rules: CampaignRules = gs.get("campaign_rules") as CampaignRules
		if rules != null and rules.permadeath_enabled:
			unit_data.set("is_incapacitated", true)
			result.incapacitated = true

	result = disposition.apply(ctx, result)
	var pair_up := get_node_or_null("/root/PairUpRegistry")
	if pair_up != null and pair_up.has_method("release_support_from_fallen_lead"):
		pair_up.release_support_from_fallen_lead(unit)
	if gs != null:
		gs.unregister_unit(unit)
		result.removed_from_map = true

	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.unit_died.emit(unit)
	result.ok = true
	if ctx.result_sink.is_valid():
		ctx.result_sink.call(result)
	unit.queue_free()
	return result
