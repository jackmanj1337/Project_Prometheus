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
# it stays crisp. content_scale_factor stays GLOBAL 1 (SettingsManager) so the HUD
# and game map are untouched — this is a menu-only mechanism (the v0.2.0 split).
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

# Meta key under which a scroll-frame panel stores its authored (scene) size, so
# every recenter derives the frame from that base instead of from whatever size the
# previous apply left behind (V026-01a).
const _BASE_SIZE_META := "_menu_scale_base_size"

# Meta flag: true while _recenter is mid-write of target.size. That write emits
# `resized`, which re-enters _recenter through the reactive hook below; the flag makes
# that nested pass a no-op so a single call still finishes the center (re-entrancy
# guard, V028-03).
const _RECENTER_GUARD_META := "_menu_scale_recentering"

# Meta flag: true once a centered target's `resized` signal is wired to the reactive
# re-center. Connected once per target and survives repeated apply_to calls (V028-03).
const _RESIZE_HOOKED_META := "_menu_scale_resize_hooked"

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
	if sm != null and sm.has_method("get_menu_scale"):
		return float(sm.call("get_menu_scale"))
	return 1.0


# Crisp scale entry point. `centered` panels are shrink-wrapped/kept-size and
# recentred in the viewport; contextual menus (centered=false) keep their authored
# cursor anchor and just grow in place from their top-left.
static func apply_to(target: Control, factor: float, centered: bool = true) -> void:
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

	if centered:
		_recenter(target)


# Deferred variant for grow-to-content panels whose content is sized dynamically
# (dynamic labels, autowrap, freshly-built rows). On first show a grow-to-content
# panel's combined_minimum_size is computed against un-laid-out children, which can
# yield a degenerate (narrow/tall) frame that the CENTER/KEEP_SIZE anchors then pin
# (V025-05a). We apply once immediately, then re-apply after one layout frame when
# the children have real sizes. The panel is held transparent for that frame so the
# pre-layout size never flashes on screen.
static func apply_to_deferred(target: Control, factor: float, centered: bool = true) -> void:
	if target == null:
		return
	if not target.is_inside_tree():
		apply_to(target, factor, centered)
		return
	var prev_modulate := target.modulate
	target.modulate.a = 0.0  # hide the pre-layout frame (mitigate the one-frame flash)
	apply_to(target, factor, centered)
	await target.get_tree().process_frame
	if not is_instance_valid(target):
		return
	if target.is_inside_tree():
		apply_to(target, factor, centered)
	target.modulate = prev_modulate


# Returns the panel's visual size for any lingering callers. Control.scale is now
# always ONE, so this equals target.size; kept for API stability.
static func scaled_size(target: Control) -> Vector2:
	if target == null:
		return Vector2.ZERO
	return target.size * target.scale


# --- internals ---------------------------------------------------------------


# Assigns the factor-scaled Theme (default text + container metrics) and scales
# every explicit font-size / constant override under the target off its base.
static func _apply_type_scale(target: Control, factor: float) -> void:
	target.theme = _scaled_theme(factor)
	_scale_overrides(target, factor)


# Builds (and caches) a Theme whose default font size and container spacing are
# scaled by `factor`. Derived fresh from engine defaults so factor 1 == default.
static func _scaled_theme(factor: float) -> Theme:
	var key := roundi(factor * 1000.0)  # stable cache key for float factors
	if _theme_cache.has(key):
		return _theme_cache[key]
	var theme := Theme.new()
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
	var sz := _panel_size(target)
	if sz.x <= 0.0 or sz.y <= 0.0:
		return factor
	var fit: float = minf(vp.x / sz.x, vp.y / sz.y)
	if fit >= 1.0:
		return factor
	return maxf(factor * fit, 0.0)


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


# Centres the panel in the viewport at its natural size AND installs a reactive hook
# so it re-centres whenever the ENGINE later changes the panel size. Grow-to-content
# panels are first resized to their content min; scroll panels keep their authored
# frame. The CENTER preset anchors all four edges to 0.5 so centring survives a window
# resize, uniform across every menu regardless of how the scene authored its anchors.
#
# V028-03 root cause: the old code was a one-shot imperative offset-bake — it hard-set
# target.size then baked absolute CENTER offsets against the size AT THAT INSTANT. But
# Godot computes the panel's real final size in a LATER deferred layout pass, so any
# post-bake growth left the panel off-centre until the next explicit re-apply. That one
# bug was patched per-trigger four times (V025-05a first show, V026-01a 2.0x apply,
# V027-04a edge drag, V028-03 maximize). The fix reacts to the panel's own `resized`
# signal, which fires at the exact frame the size settles, so we never have to guess
# the settle frame with deferred re-applies.
static func _recenter(target: Control) -> void:
	if not target.is_inside_tree():
		return
	# Wire the reactive re-center once. `resized` fires every time the engine (or our
	# own size write below) changes the panel size, so centring always tracks reality.
	if not target.get_meta(_RESIZE_HOOKED_META, false):
		target.resized.connect(_on_centered_target_resized.bind(target))
		target.set_meta(_RESIZE_HOOKED_META, true)
	# Re-entrancy guard: the target.size write below emits `resized`, which re-enters
	# this via the hook. Skip that nested pass — the outer call finishes the centring.
	if target.get_meta(_RECENTER_GUARD_META, false):
		return
	target.set_meta(_RECENTER_GUARD_META, true)
	if not _has_scroll_container(target):
		target.size = target.get_combined_minimum_size()
	else:
		# V026-01a: with horizontal scrolling disabled, the scaled rows' minimum
		# width propagates up through the ScrollContainer — the layout pass then
		# grows the panel rightward/downward AFTER this recenter ran. Size the frame
		# NOW from the authored base and the current content minimum (capped to the
		# viewport); the reactive hook re-centres again if the engine settles on a
		# different size, so this no longer has to be exact.
		var base: Vector2 = target.get_meta(_BASE_SIZE_META, target.size)
		target.set_meta(_BASE_SIZE_META, base)
		var min_size: Vector2 = target.get_combined_minimum_size()
		var vp: Vector2 = target.get_viewport_rect().size
		target.size = Vector2(
			minf(maxf(base.x, min_size.x), vp.x),
			minf(maxf(base.y, min_size.y), vp.y))
	target.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	target.set_meta(_RECENTER_GUARD_META, false)


# Reactive re-center: re-runs centring at the exact frame the engine changes the panel
# size (deferred first-layout, window-resize font re-measure, Windows maximize). This
# standing constraint replaces the per-trigger deferred re-applies (V028-03).
static func _on_centered_target_resized(target: Control) -> void:
	if not is_instance_valid(target) or not target.is_inside_tree():
		return
	_recenter(target)
