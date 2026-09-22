extends SceneTree
# A label must never draw over its own button art.
#
# `SAVE-ROW-BUTTON-ART-OVERRUN-2026-09-22`: the Load Game save-row actions drew
# "Manage Campaigns", "Retry", "Delete" and "Export" past the gold end caps of the
# nine-patch behind them, while the web bridge reported `truncation.fits = true` with
# `measuredTextWidth <= availableWidth` for every one of them. Both were right. The
# CONTROL was big enough; the PAINTED INTERIOR was not, because `content_margin`
# (12) was smaller than `texture_margin` (14), so the text box legally extended two
# pixels into each protected cap. Nothing outside anything, so no containment
# assertion and no clip-aware click could ever see it -- which is why this is a
# theme-resource invariant rather than a layout test.
#
# THE INVARIANT IS SCALE-FREE, AND THAT IS THE MEASURED POINT. A shrink-to-fit
# button is exactly `text + content margins` wide at every menu factor, so the
# shortfall against the art is the same 4px at factor 1.0, 1.5 and 2.0. MenuScale
# scales `default_font_size` and container separation but not stylebox margins, and
# it does not need to: the defect was never scale-dependent.
#
# SLIDERS ARE EXEMPT ON PURPOSE. `SB_slider_track` and `SB_slider_fill` carry
# `content_margin_left/right = 0` against a 12px/10px cap because the grabber is
# meant to travel the full painted width -- there is no glyph to protect.

const THEME_PATH := "res://assets/themes/manasoul_ui.tres"

# Horizontal only. `texture_margin_top/bottom` is 4 on the button strip against a
# content margin of 7, so the vertical direction already clears with room to spare,
# and a panel's vertical inset is a spacing decision rather than a protected cap.
const _SIDES := ["left", "right"]

var _passed := 0
var _failed := 0


func _init() -> void:
	print("=== Theme StyleBox Margin Test ===")
	_button_labels_clear_their_end_caps()
	await _a_minimum_width_button_stays_inside_its_art_at_every_menu_factor()
	print("\n=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % label)
	else:
		_failed += 1
		print("  FAIL: %s%s" % [label, ("  [%s]" % detail) if detail != "" else ""])


func _button_labels_clear_their_end_caps() -> void:
	print("\n-- every button stylebox reserves at least its own cap width --")
	var theme: Theme = load(THEME_PATH)
	_check("the theme loads", theme != null)
	if theme == null:
		return
	var checked := 0
	for type_name in theme.get_stylebox_type_list():
		# OptionButton and MenuButton share the strip and carry their own wider caps;
		# checking every button-family type keeps a new state from slipping through.
		if not type_name.ends_with("Button"):
			continue
		for stylebox_name in theme.get_stylebox_list(type_name):
			var box: StyleBox = theme.get_stylebox(stylebox_name, type_name)
			if not (box is StyleBoxTexture):
				continue
			var textured: StyleBoxTexture = box
			for side in _SIDES:
				var cap: float = textured.get("texture_margin_%s" % side)
				var inset: float = textured.get("content_margin_%s" % side)
				checked += 1
				_check(
					"%s/%s clears its %s cap" % [type_name, stylebox_name, side],
					inset >= cap,
					"content %.0f < texture %.0f" % [inset, cap]
				)
	_check("button styleboxes were actually found", checked > 0, "checked %d margins" % checked)


func _a_minimum_width_button_stays_inside_its_art_at_every_menu_factor() -> void:
	print("\n-- a shrink-to-fit label fits the painted interior at 1.0, 1.5 and 2.0 --")
	var MenuScaleScript := load("res://scripts/ui/MenuScale.gd")
	var theme: Theme = load(THEME_PATH)
	for factor in [1.0, 1.5, 2.0]:
		var holder := Control.new()
		holder.theme = theme
		root.add_child(holder)
		var button := Button.new()
		# The exact label the walk caught, because it is the widest of the save-row
		# actions and the one the evidence shot shows overrunning both ends.
		button.text = "Manage Campaigns"
		holder.add_child(button)
		MenuScaleScript.apply_to(holder, factor)
		await process_frame
		await process_frame
		var box: StyleBoxTexture = button.get_theme_stylebox("normal")
		var font: Font = button.get_theme_font("font")
		var size: int = button.get_theme_font_size("font_size")
		var text_width: float = (
			font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		)
		var painted: float = button.size.x - box.texture_margin_left - box.texture_margin_right
		_check(
			"factor %.1f: the label fits between the caps" % factor,
			text_width <= painted,
			(
				"text %.1f > painted interior %.1f (button %.1f wide)"
				% [text_width, painted, button.size.x]
			)
		)
		holder.queue_free()
		await process_frame
