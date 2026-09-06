extends RefCounted
## A settled layout probe for the visible Control tree.
##
## It returns structured findings instead of printing or pushing errors. The caller owns
## the DiagnosticsLog budget and supplies a dedupe key from each finding's stable path and
## geometry, so the same frame can be audited repeatedly without becoming a log storm.

const CATEGORY := &"layout"
const EDGE_EPSILON := 0.5


static func audit(root: Node, viewport_rect: Rect2, reason: String = "settled") -> Array:
	var findings: Array = []
	if root == null:
		return findings
	_walk(root, viewport_rect, reason, findings)
	var focus_owner := root.get_viewport().gui_get_focus_owner() if root.is_inside_tree() else null
	if _has_visible_dialog(root) and focus_owner == null:
		(
			findings
			. append(
				_record(
					&"focus_lost",
					{
						"reason": reason,
						"focus_owner": "",
					}
				)
			)
		)
	return findings


static func _walk(node: Node, viewport_rect: Rect2, reason: String, findings: Array) -> void:
	if node is Control:
		var control := node as Control
		if control.visible and control.is_inside_tree():
			var rect := control.get_global_rect()
			var path := str(control.get_path())
			var overflow := _overflow_of(control, rect, viewport_rect)
			if not overflow.is_empty():
				(
					findings
					. append(
						_record(
							&"control_overflow",
							{
								"path": path,
								"reason": reason,
								"rect": str(rect),
								"viewport": str(viewport_rect),
								"clipped_by": overflow["clipped_by"],
								"clip_rect": str(overflow["clip_rect"]),
								"axes": overflow["axes"],
							}
						)
					)
				)
			if _is_dialog_name(control.name) and control.size.x > 0.0 and control.size.y > 0.0:
				(
					findings
					. append(
						_record(
							&"dialog_geometry",
							{
								"path": path,
								"reason": reason,
								"rect": str(rect),
								"viewport": str(viewport_rect),
							}
						)
					)
				)
			if control is Label and _label_is_clipped(control as Label):
				(
					findings
					. append(
						_record(
							&"label_clipped",
							{
								"path": path,
								"reason": reason,
								"text_length": (control as Label).text.length(),
								"size": str(control.size),
								"minimum": str((control as Label).get_minimum_size()),
							}
						)
					)
				)
	for child in node.get_children():
		_walk(child, viewport_rect, reason, findings)


# WHY THIS IS NOT `viewport_rect.encloses(rect)` (V0717-04).
#
# It was, and a ScrollContainer's content is SUPPOSED to exceed the viewport --
# that is what makes it scroll. So the Settings screen reported its whole subtree as
# overflowing on every settle, e.g. a 1709 px-tall margin inside a 720 px viewport.
# The cost was not the noise: 388 of the 401 layout records the v0.7.17 return
# retained were that one screen, and the 400-record cap fired at t=150 s of a
# 3,300 s session, so the entire fullscreen pass, the 4K window and every one of
# Section 3's resizes went unrecorded -- while the checklist asked the tester to
# return the ZIP so those very records could be correlated with a screenshot. An
# instrument with a fixed budget and an unbounded false-positive rate spends its
# whole budget on false positives, earliest in the session, when the least
# interesting thing is happening.
#
# So a control is measured against the rect that actually clips it -- its nearest
# clipping ancestor, or the viewport when it has none -- and overflow ALONG A
# SCROLLING AXIS of a ScrollContainer ancestor is not a finding. Overflow on the
# other axis still is: a row too wide for a vertically-scrolling list is a real
# defect and the commonest one this audit exists to catch.
#
# Returns {} for no finding, else {clipped_by, clip_rect, axes}.
static func _overflow_of(control: Control, rect: Rect2, viewport_rect: Rect2) -> Dictionary:
	var clipper := _clipping_ancestor(control)
	var clip_rect := clipper.get_global_rect() if clipper != null else viewport_rect
	var axes := PackedStringArray()
	if (
		rect.position.x < clip_rect.position.x - EDGE_EPSILON
		or rect.end.x > clip_rect.end.x + EDGE_EPSILON
	):
		axes.append("x")
	if (
		rect.position.y < clip_rect.position.y - EDGE_EPSILON
		or rect.end.y > clip_rect.end.y + EDGE_EPSILON
	):
		axes.append("y")
	if axes.is_empty():
		return {}
	if clipper is ScrollContainer:
		var scroll := clipper as ScrollContainer
		var remaining := PackedStringArray()
		for axis in axes:
			if (
				axis == "x"
				and scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
			):
				continue
			if axis == "y" and scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
				continue
			remaining.append(axis)
		axes = remaining
		if axes.is_empty():
			return {}
	return {
		"clipped_by": str(clipper.get_path()) if clipper != null else "viewport",
		"clip_rect": clip_rect,
		"axes": axes,
	}


# The nearest ancestor that actually clips: a ScrollContainer (which always does),
# or any Control with clip_contents set. Everything else lets its children draw
# outside it, so measuring against it would invent overflow that no viewer sees.
static func _clipping_ancestor(control: Control) -> Control:
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return parent as ScrollContainer
		if parent is Control and (parent as Control).clip_contents:
			return parent as Control
		parent = parent.get_parent()
	return null


static func _label_is_clipped(label: Label) -> bool:
	if label.text.is_empty() or label.size.x <= 0.0:
		return false
	var minimum := label.get_minimum_size()
	var overrun_configured := (
		label.clip_text or label.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
	)
	if not overrun_configured:
		return false
	if minimum.x > label.size.x + EDGE_EPSILON:
		return true
	var font := label.get_theme_font("font")
	if font == null:
		return false
	var font_size := label.get_theme_font_size("font_size")
	var measured := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	return measured > label.size.x + EDGE_EPSILON


static func _has_visible_dialog(node: Node) -> bool:
	if node is Control and node.visible and _is_dialog_name(node.name):
		return true
	for child in node.get_children():
		if _has_visible_dialog(child):
			return true
	return false


static func _is_dialog_name(node_name: StringName) -> bool:
	var normalized := String(node_name).to_lower()
	return normalized.contains("dialog") or normalized.contains("popup")


static func _record(event: StringName, fields: Dictionary) -> Dictionary:
	return {"category": CATEGORY, "event": event, "fields": fields}
