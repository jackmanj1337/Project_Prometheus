extends Control
# Small engine-owned notification for the open apply_rule_flip seam.

@onready var _label: Label = $Panel/Label
var _generation := 0


func _ready() -> void:
	hide()
	var bus := get_node_or_null("/root/EventBus")
	if bus != null:
		bus.campaign_rule_flipped.connect(_on_campaign_rule_flipped)


func _on_campaign_rule_flipped(
	rule_id: String, value: Variant, reason: String, revert_scope: String
) -> void:
	_generation += 1
	var generation := _generation
	var scope := "this map" if revert_scope == "end_of_map" else "campaign"
	_label.text = (
		"Rule changed — %s: %s (%s; %s)" % [rule_id.capitalize(), str(value), reason, scope]
	)
	show()
	get_tree().create_timer(4.0).timeout.connect(
		func():
			if generation == _generation:
				hide()
	)
