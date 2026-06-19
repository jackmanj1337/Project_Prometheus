extends RefCounted
# Shared menu/modal scale helper. The SettingsManager owns the saved scale and
# calls every node in GROUP via apply_menu_scale(factor); nodes also call this
# from _ready/open so late-instantiated menus pick up the current setting.

const GROUP := "menu_scale_targets"


static func factor_from_settings(node: Node) -> float:
	if node == null:
		return 1.0
	var sm := node.get_node_or_null("/root/SettingsManager")
	if sm != null and sm.has_method("get_menu_scale"):
		return float(sm.call("get_menu_scale"))
	return 1.0


static func apply_to(target: Control, factor: float, centered: bool = true) -> void:
	if target == null:
		return
	target.pivot_offset = target.size * 0.5 if centered else Vector2.ZERO
	target.scale = Vector2.ONE * factor


static func scaled_size(target: Control) -> Vector2:
	if target == null:
		return Vector2.ZERO
	return target.size * target.scale
