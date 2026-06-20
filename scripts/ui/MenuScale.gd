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
	target.scale = Vector2.ONE * _fit_factor(target, factor)


# V021-08: clamp the requested scale so the scaled control still fits the viewport
# on both axes. Tall menus (e.g. the character sheet) otherwise overflow the top and
# bottom edges at high Menu Scale and become unreachable. Uniform (min-axis) keeps the
# aspect ratio. Falls back to the raw factor when the target isn't in the tree yet or
# has no measurable size (no viewport to clamp against). This is the layout-fit half;
# the crispness rework (V021-18) replaces the .scale mechanism wholesale later.
static func _fit_factor(target: Control, factor: float) -> float:
	if not target.is_inside_tree():
		return factor
	var sz: Vector2 = target.size
	if sz.x <= 0.0 or sz.y <= 0.0:
		return factor
	var vp: Vector2 = target.get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return factor
	return minf(factor, minf(vp.x / sz.x, vp.y / sz.y))


static func scaled_size(target: Control) -> Vector2:
	if target == null:
		return Vector2.ZERO
	return target.size * target.scale
