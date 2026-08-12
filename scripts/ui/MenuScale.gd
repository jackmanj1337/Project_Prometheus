extends RefCounted
# Shared menu/modal scale helper. The SettingsManager owns the saved scale and
# calls every node in GROUP via apply_menu_scale(factor); nodes also call this
# from _ready/open so late-instantiated menus pick up the current setting.
#
# V021-18 (D2) — CRISP scaling. The old mechanism bitmap-stretched the panel via
# `Control.scale`, which blurred all text at >1.0x. We now leave `Control.scale`
# at ONE and instead scale TYPE: a factor-scaled Theme drives every default-sized
# label (default_font_size + container metrics), and a tree-walk scales each
# explicit `theme_override_font_sizes` / `theme_override_constants` (titles, etc.)
# off a captured base. Text is rendered at its true pixel size at every factor, so
# it stays crisp. This is a menu-only TYPE-scaling mechanism (the v0.2.0 split).
#
# UI-VIEWPORT-ASPECT-2026-07-31: the global window content_scale_factor is NO LONGER a
# fixed 1 — it is now a persisted user setting (the viewport expand model) owned by
# SettingsManager._apply_content_scale. To stop the two from multiplying, the factor
# fed here is get_effective_menu_scale() = get_menu_scale() / content_scale_factor, so a
# menu keeps the same ON-SCREEN size regardless of the global factor. This module still
# only touches menu type; it never writes the window factor.
#
# Deviation from the design doc (display_scaling_resolution_design_2026-06-20.md,
# D2): the doc assumed one authored base Theme with the per-node overrides removed.
# The scenes still carry explicit overrides (GameOver title=48, LevelUp 20/16/14/12,
# headers), which a root Theme cannot reach. Rather than restyle + re-verify all
# ~11 scenes, we derive the scaled Theme from the engine default at runtime AND
# walk the overrides. Factor 1 is byte-identical to today, and this stays
# forward-compatible: an authored base Theme can later seed _scaled_theme() and the
# walk simply finds nothing once the overrides are gone.

const GROUP := "menu_scale_targets"

# Godot 4's engine-default font size; the scaled Theme's default_font_size is
# round(this * factor) so a factor-1 menu matches the untouched engine default.
const _BASE_DEFAULT_FONT_SIZE := 16

# Meta key under which each walked node stores its base (factor-1) override values,
# so re-applying at a new factor scales off the original, never compounding.
const _BASE_META := "_menu_scale_base_overrides"

# Meta key under which a target's pre-existing (authored/design) theme is captured the
# first time apply_to touches it, so every later _scaled_theme() call derives from the
# real base instead of the previously-assigned scaled theme (V030-BUG-01: MenuScale used
# to reassign `target.theme` to a bare Theme.new() unconditionally, silently discarding
# any custom theme — e.g. manasoul_ui.tres — that scene authoring had set directly on the
# target node).
const _BASE_THEME_META := "_menu_scale_base_theme"

# Container spacing/margin constants scaled in the derived Theme so layout density
# tracks the font growth. Each entry is [theme_type, constant_name, base_value];
# base values are the engine defaults. Per-node constant overrides are handled
# separately by the override walk.
const _SCALED_CONSTANTS: Array = [
	["BoxContainer", "separation", 4],
	["HBoxContainer", "separation", 4],
	["VBoxContainer", "separation", 4],
	["GridContainer", "h_separation", 4],
	["GridContainer", "v_separation", 4],
]

# One derived Theme per rounded factor, built lazily and reused across menus.
static var _theme_cache: Dictionary = {}


static func factor_from_settings(node: Node) -> float:
	if node == null:
		return 1.0
	var sm := node.get_node_or_null("/root/SettingsManager")
	# get_effective_menu_scale reconciles the menu factor against the global content
	# scale so menus keep a fixed on-screen size (UI-VIEWPORT-ASPECT-2026-07-31). Fall
	# back to the raw menu scale, then 1.0, for older SettingsManager shapes.
	if sm != null and sm.has_method("get_effective_menu_scale"):
		return float(sm.call("get_effective_menu_scale"))
	if sm != null and sm.has_method("get_menu_scale"):
		return float(sm.call("get_menu_scale"))
	return 1.0


# Crisp scale entry point: scales menu TYPE (font sizes) only, never bitmap-stretches.
# Positioning is now the SCENE's job — centered panels use center anchors + grow_both and
# contextual menus keep their authored cursor anchor (viewport expand anchoring refactor,
# UI-VIEWPORT-ASPECT-2026-07-31). MenuScale no longer imperatively re-centres anything.
static func apply_to(target: Control, factor: float) -> void:
	if target == null:
		return
	target.scale = Vector2.ONE  # never bitmap-scale text — that was the blur source

	var f := factor
	_apply_type_scale(target, f)
	# V021-08 fit clamp without bitmap scale: if the scaled content would overflow
	# the viewport, dial the factor down and re-apply (overrides scale off the
	# captured base, so re-applying is idempotent, never compounded).
	f = _clamp_to_viewport(target, f)
	if not is_equal_approx(f, factor):
		_apply_type_scale(target, f)


# Deferred variant for grow-to-content panels whose content is sized dynamically
# (dynamic labels, autowrap, freshly-built rows). On first show a grow-to-content
# panel's combined_minimum_size is computed against un-laid-out children, which can
# yield a degenerate (narrow/tall) frame before the layout settles (V025-05a). We
# type-scale once immediately, then again after one layout frame when the children have
# real sizes. The panel is held transparent for that frame so the pre-layout size never
# flashes on screen; the scene's center anchors keep it centred throughout.
static func apply_to_deferred(target: Control, factor: float) -> void:
	if target == null:
		return
	if not target.is_inside_tree():
		apply_to(target, factor)
		return
	var prev_modulate := target.modulate
	target.modulate.a = 0.0  # hide the pre-layout frame (mitigate the one-frame flash)
	apply_to(target, factor)
	await target.get_tree().process_frame
	if not is_instance_valid(target):
		return
	if target.is_inside_tree():
		apply_to(target, factor)
	target.modulate = prev_modulate


# Returns the panel's visual size for any lingering callers. Control.scale is now
# always ONE, so this equals target.size; kept for API stability.
static func scaled_size(target: Control) -> Vector2:
	if target == null:
		return Vector2.ZERO
	return target.size * target.scale


# Grows or shrinks a non-scroll panel to the largest size that fits an authored
# safe rectangle, then centers it inside that rectangle.
static func apply_to_fit_rect(
	target: Control, available: Rect2, min_factor: float = 0.5, max_factor: float = 3.0
) -> void:
	if target == null or not target.is_inside_tree():
		return
	target.scale = Vector2.ONE
	var factor := 1.0
	_apply_type_scale(target, factor)
	for _iteration in 5:
		var next_factor := clampf(
			_fit_factor(_panel_size(target), available.size, factor), min_factor, max_factor
		)
		if is_equal_approx(next_factor, factor):
			break
		factor = next_factor
		_apply_type_scale(target, factor)
	var size := _panel_size(target)
	if size.x > available.size.x + 0.5 or size.y > available.size.y + 0.5:
		factor = maxf(_fit_factor(size, available.size, factor), 0.0)
		_apply_type_scale(target, factor)
	target.size = _panel_size(target)
	target.position = available.position + (available.size - target.size) * 0.5


# --- internals ---------------------------------------------------------------


# Assigns the factor-scaled Theme (default text + container metrics) and scales
# every explicit font-size / constant override under the target off its base.
static func _apply_type_scale(target: Control, factor: float) -> void:
	if not target.has_meta(_BASE_THEME_META):
		# First touch: capture whatever theme scene authoring put on this node (or null)
		# BEFORE we ever overwrite it, so it survives every future rescale.
		target.set_meta(_BASE_THEME_META, target.theme)
	var base_theme: Theme = target.get_meta(_BASE_THEME_META)
	target.theme = _scaled_theme(factor, base_theme)
	_scale_overrides(target, factor)


# Builds (and caches) a Theme whose default font size and container spacing are
# scaled by `factor`, derived from `base_theme` (the target's original authored theme)
# if it has one, or from engine defaults otherwise. Deriving from base_theme preserves
# any custom StyleBoxes/fonts it defines — only the default font size and the spacing
# constants below are overridden on top.
static func _scaled_theme(factor: float, base_theme: Theme) -> Theme:
	var base_id := base_theme.get_instance_id() if base_theme != null else 0
	var key := "%d:%d" % [roundi(factor * 1000.0), base_id]  # stable cache key for float factors
	if _theme_cache.has(key):
		return _theme_cache[key]
	var theme: Theme = base_theme.duplicate() if base_theme != null else Theme.new()
	theme.default_font_size = roundi(_BASE_DEFAULT_FONT_SIZE * factor)
	for entry in _SCALED_CONSTANTS:
		theme.set_constant(entry[1], entry[0], roundi(int(entry[2]) * factor))
	_theme_cache[key] = theme
	return theme


# Walks the target and its descendants, scaling each authored font-size / constant
# override off the base captured in node meta the first time it is seen.
static func _scale_overrides(target: Control, factor: float) -> void:
	var stack: Array[Node] = [target]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Control:
			_scale_node_overrides(node, factor)
		for child in node.get_children():
			stack.push_back(child)


static func _scale_node_overrides(node: Control, factor: float) -> void:
	var bases: Dictionary = node.get_meta(_BASE_META, {})
	for prop in node.get_property_list():
		var name: String = prop["name"]
		if name.begins_with("theme_override_font_sizes/"):
			var key := name.substr("theme_override_font_sizes/".length())
			if not node.has_theme_font_size_override(key):
				continue
			var base: int = bases.get(name, node.get_theme_font_size(key))
			bases[name] = base
			node.add_theme_font_size_override(key, roundi(base * factor))
		elif name.begins_with("theme_override_constants/"):
			var key := name.substr("theme_override_constants/".length())
			if not node.has_theme_constant_override(key):
				continue
			var base: int = bases.get(name, node.get_theme_constant(key))
			bases[name] = base
			node.add_theme_constant_override(key, roundi(base * factor))
	if not bases.is_empty():
		node.set_meta(_BASE_META, bases)


# Reduces `factor` so the target's scaled size still fits the viewport on both axes
# (V021-08: a tall menu must keep its top + bottom reachable). Returns the
# (possibly reduced) factor. Scroll-based panels already fit (they scroll), so only
# grow-to-content menus can trip the clamp.
static func _clamp_to_viewport(target: Control, factor: float) -> float:
	if not target.is_inside_tree():
		return factor
	var vp: Vector2 = target.get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return factor
	var fit := _fit_factor(_panel_size(target), vp, factor)
	return factor if fit >= factor else fit


static func _fit_factor(size: Vector2, available: Vector2, base_factor: float) -> float:
	if size.x <= 0.0 or size.y <= 0.0 or available.x <= 0.0 or available.y <= 0.0:
		return base_factor
	var fit: float = minf(available.x / size.x, available.y / size.y)
	return maxf(base_factor * fit, 0.0)


# The size a centered panel should occupy. A panel built around a ScrollContainer
# is a fixed frame that scrolls — keep its authored size. Everything else grows
# (or shrinks) to wrap its content's current minimum size.
static func _panel_size(target: Control) -> Vector2:
	if _has_scroll_container(target):
		return target.size
	return target.get_combined_minimum_size()


static func _has_scroll_container(node: Node) -> bool:
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is ScrollContainer:
			return true
		for child in n.get_children():
			stack.push_back(child)
	return false

# NOTE: imperative centring was removed in the viewport expand anchoring refactor
# (UI-VIEWPORT-ASPECT-2026-07-31). Panels now centre themselves declaratively via scene
# anchors (center + grow_both, scroll frames via custom_minimum_size), which the engine
# keeps centred through window resizes and content growth with no reactive hook. This
# retired _recenter / _on_centered_target_resized and the V025-05a/V026-01a/V027-04a/
# V028-03 re-entrancy + resize-hook machinery they had accreted.
