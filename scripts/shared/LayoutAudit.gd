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
			if not viewport_rect.encloses(rect):
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
