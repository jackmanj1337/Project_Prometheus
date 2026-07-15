class_name DeathContext extends RefCounted
## Immutable-at-entry facts used by the shared death lifecycle.

var subject: Node = null
var subject_id: String = ""
var source_domain: String = "unknown"
var source_id: String = ""
var responsible_actor: Node = null
var timing_bucket: String = "immediate"
var inventory_snapshot: Array = []
var map_context: Dictionary = {}
var tile: Vector2i = Vector2i.ZERO
var simultaneous_group_id: String = ""
var death_mode_refs: Dictionary = {}
var object_ref: String = ""
var result_sink: Callable = Callable()


static func from_subject(unit: Node, domain: String = "unknown", id: String = "") -> RefCounted:
	var ctx: RefCounted = load("res://scripts/death/DeathContext.gd").new()
	ctx.subject = unit
	ctx.source_domain = domain
	ctx.source_id = id
	if unit != null:
		ctx.tile = unit.get("tile_position")
		var unit_data = unit.get("data")
		if unit_data != null:
			ctx.subject_id = str(unit_data.get("unit_id"))
			var inventory = unit_data.get("inventory")
			if inventory != null:
				ctx.inventory_snapshot = inventory.duplicate(true)
	return ctx
