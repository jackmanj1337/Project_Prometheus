extends SceneTree

const BridgeScript = preload("res://scripts/autoloads/WebTestBridge.gd")


# The map snapshot reads only `tile_to_world` off the grid and `current_tile`/`_state` off
# the cursor, so the real GridManager and MapCursor -- which need a tilemap, a camera and a
# TurnManager between them -- are more setup than the arithmetic under test deserves.
class BridgeGridStub:
	extends Node2D
	const SIZE := 16.0
	const HALF := SIZE / 2.0

	func tile_to_world(tile: Vector2i) -> Vector2:
		return Vector2(tile.x * SIZE + HALF, tile.y * SIZE + HALF)


class BridgeCursorStub:
	extends Node2D
	var current_tile := Vector2i(3, 4)
	var _state := 3  # State.TARGETING


# Stands in for a screen MainMenu embeds: it records that the gallery opened THIS node
# rather than a copy of it, which is the whole property under test.
class EmbeddedScreenStub:
	extends Control
	var opened := false

	func open() -> void:
		opened = true
		show()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var passed := 3
	var failed := 0
	var bridge := BridgeScript.new()
	root.add_child(bridge)
	var label := Label.new()
	label.text = "A deliberately long bridge label"
	label.size = Vector2(20, 10)
	root.add_child(label)
	await process_frame

	var snapshot: Dictionary = bridge._control_snapshot(label)
	var truncation: Dictionary = snapshot.get("truncation", {})
	if snapshot.get("text", "") != label.text:
		print("FAIL bridge control snapshot omitted label text")
		quit(1)
		return
	if (
		not truncation.has("fits")
		or not truncation.has("measuredTextWidth")
		or not truncation.has("overrunBehavior")
		or not truncation.has("availableWidth")
	):
		print("FAIL bridge control snapshot omitted truncation evidence")
		quit(1)
		return
	print("OK  bridge publishes text and measured truncation evidence")
	var inherited_theme := Theme.new()
	inherited_theme.take_over_path("res://tests/inherited_theme.tres")
	var theme_owner := Control.new()
	theme_owner.theme = inherited_theme
	root.remove_child(label)
	theme_owner.add_child(label)
	root.add_child(theme_owner)
	var provenance: Dictionary = bridge._theme_provenance(label)
	if (
		provenance.get("source") != "control"
		or provenance.get("resource") != inherited_theme.resource_path
	):
		print("FAIL bridge omitted inherited theme provenance: %s" % [provenance])
		quit(1)
		return
	print("OK  bridge publishes the inherited theme resource and owner")

	# THE `[ITR-6]` READOUT ROW. An interaction row is a RichTextLabel carrying escaped
	# authored text inside the surface's colour markup. Both halves are asserted: the row's
	# text reaches a harness at all, and it reaches it as the words a PLAYER reads rather
	# than as bbcode — a harness matching an authored profile label against the raw markup
	# would pass on a row whose visible text is empty. Truncation is deliberately absent; see
	# `_control_snapshot`.
	var readout_row := RichTextLabel.new()
	readout_row.bbcode_enabled = true
	readout_row.fit_content = true
	readout_row.text = "[color=#7fd4ff]\u25b2 Hallowed Rites  Dmg +6[/color]"
	root.add_child(readout_row)
	await process_frame
	var row_snapshot: Dictionary = bridge._control_snapshot(readout_row)
	if (
		row_snapshot.get("text", "") == "\u25b2 Hallowed Rites  Dmg +6"
		and not row_snapshot.has("truncation")
	):
		print("OK  bridge publishes an interaction readout row as parsed player-facing text")
		passed += 1
	else:
		print("FAIL bridge interaction readout row snapshot: %s" % [row_snapshot])
		failed += 1
	readout_row.queue_free()
	var import_button := Button.new()
	import_button.name = "BtnImport"
	if bridge._semantic_control_id(import_button) != "campaign.import":
		print("FAIL bridge omitted stable campaign import id")
		quit(1)
		return
	var value := LineEdit.new()
	value.name = "Value"
	if bridge._semantic_control_id(value) != "text-entry.value":
		print("FAIL bridge omitted stable text-entry value id")
		quit(1)
		return
	var codes := bridge._diagnostic_codes_from_text(
		"Import failed: vocabulary_value_unknown at classes[0]."
	)
	if codes != ["vocabulary_value_unknown"]:
		print("FAIL bridge did not retain stable import diagnostic code: %s" % [codes])
		quit(1)
		return
	print("OK  bridge publishes stable semantic ids and import diagnostic codes")
	var holder := Control.new()
	holder.name = "Holder"
	root.add_child(holder)
	var frame := Control.new()
	frame.name = "Panel"
	holder.add_child(frame)
	var actionable := Button.new()
	actionable.name = "Actionable"
	actionable.text = "Action"
	holder.add_child(actionable)
	var label_only := Label.new()
	label_only.name = "LabelOnly"
	holder.add_child(label_only)
	bridge.set("_publish_all_rects", false)
	var focusable_rects: Dictionary = {}
	var focusable_controls: Array[String] = []
	bridge._collect_controls(holder, holder, focusable_controls, focusable_rects)
	if (
		focusable_rects.has("Actionable")
		and focusable_rects.has("Panel")
		and not focusable_rects.has("LabelOnly")
		and focusable_controls == ["Actionable"]
		and focusable_rects["Actionable"].has("theme")
		and focusable_rects["Actionable"].has("truncation")
	):
		print("OK  bridge defaults to complete actionable control snapshots")
		passed += 1
	else:
		print(
			(
				"FAIL bridge default rectangle scope: %s / %s"
				% [focusable_controls, focusable_rects.keys()]
			)
		)
		failed += 1
	bridge.set("_publish_all_rects", true)
	var full_rects: Dictionary = {}
	var full_controls: Array[String] = []
	bridge._collect_controls(holder, holder, full_controls, full_rects)
	if (
		full_rects.has("Actionable")
		and full_rects.has("LabelOnly")
		and full_controls == ["Actionable"]
	):
		print("OK  bridge opt-in full rectangle scope retains non-focusable controls")
		passed += 1
	else:
		print("FAIL bridge full rectangle scope: %s / %s" % [full_controls, full_rects.keys()])
		failed += 1
	# THE GALLERY OPENS THE SCREEN THE SCENE ALREADY HAS. A second copy added under a
	# parent that already holds that node name is renamed by Godot, and the bridge names a
	# screen by node name -- so the panel would be open and focused while `screen` still
	# said `main-menu`, which is exactly how v073-regression.mjs came to time out at its
	# first step against v0.8.0 (V073-GALLERY-BOOT-BROKEN-2026-09-21). The decoy is placed
	# FIRST because NewGameScreen instances its own CampaignLibraryScreen and sits ahead of
	# the Main Menu's copy in child order: a recursive find_child reaches the nested one.
	var menu_scene := Control.new()
	menu_scene.name = "MainMenu"
	var decoy_host := Control.new()
	decoy_host.name = "NewGameScreen"
	decoy_host.hide()
	var decoy := EmbeddedScreenStub.new()
	decoy.name = "CampaignLibraryScreen"
	decoy_host.add_child(decoy)
	menu_scene.add_child(decoy_host)
	var embedded_library := EmbeddedScreenStub.new()
	embedded_library.name = "CampaignLibraryScreen"
	embedded_library.hide()
	menu_scene.add_child(embedded_library)
	root.add_child(menu_scene)
	var scene_before := current_scene
	current_scene = menu_scene
	var children_before := menu_scene.get_child_count()
	await bridge._open_gallery_screen("campaign-library")
	await process_frame
	var gallery_screen_id := String(bridge._active_screen().get("id", ""))
	current_scene = scene_before
	if (
		embedded_library.opened
		and not decoy.opened
		and menu_scene.get_child_count() == children_before
		and gallery_screen_id == "campaign-library"
	):
		print("OK  gallery opens the embedded campaign library and the bridge can name it")
		passed += 1
	else:
		print(
			(
				"FAIL gallery campaign-library: embedded=%s decoy=%s children %d->%d screen=%s"
				% [
					embedded_library.opened,
					decoy.opened,
					children_before,
					menu_scene.get_child_count(),
					gallery_screen_id,
				]
			)
		)
		failed += 1
	# THE MAP ADDRESS BLOCK. A battle map publishes no clickable Control, so the harness
	# addresses tiles by arithmetic on `origin` and `step`. Both are asserted against the
	# grid they were derived from, because an off-by-one-tile address is the failure that
	# would otherwise show up as a browser journey clicking empty ground.
	var map_scene := Node2D.new()
	map_scene.name = "GameMap"
	var grid_stub := BridgeGridStub.new()
	grid_stub.name = "GridManager"
	map_scene.add_child(grid_stub)
	var cursor_stub := BridgeCursorStub.new()
	cursor_stub.name = "MapCursor"
	map_scene.add_child(cursor_stub)
	root.add_child(map_scene)
	var previous_scene := current_scene
	current_scene = map_scene
	await process_frame
	var map_snapshot: Dictionary = bridge._map_snapshot()
	current_scene = previous_scene
	var origin: Dictionary = map_snapshot.get("origin", {})
	var step: Dictionary = map_snapshot.get("step", {})
	# ASSERT THE PROPERTY THE HARNESS RELIES ON, not the pixel values. The published point
	# is the grid's world position under the live canvas and screen transforms, so its
	# absolute scale depends on the viewport the run happens to have -- pinning a number
	# here would fail on any window but one and would prove nothing besides. What the
	# harness needs is that `origin + tile * step` lands on the tile it names, and the tile
	# checked below is a THIRD one, not either of the two `origin` and `step` were derived
	# from, so a transform that was not linear would be caught rather than cancelled out.
	var probe := Vector2i(3, 4)
	var expected: Vector2 = bridge._tile_point(grid_stub, probe)
	var computed := Vector2(
		float(origin.get("x", 0.0)) + probe.x * float(step.get("x", 0.0)),
		float(origin.get("y", 0.0)) + probe.y * float(step.get("y", 0.0))
	)
	if (
		map_snapshot.get("cursorTile", []) == [3, 4]
		and map_snapshot.get("cursorState", "") == "targeting"
		and computed.distance_to(expected) < 0.01
		and float(step.get("x", 0.0)) > 0.0
	):
		print("OK  bridge publishes a tile address a harness can compute a click point from")
		passed += 1
	else:
		print("FAIL bridge map snapshot: %s" % [map_snapshot])
		failed += 1
	map_scene.queue_free()
	menu_scene.queue_free()
	holder.queue_free()
	bridge.queue_free()
	theme_owner.queue_free()
	import_button.queue_free()
	value.queue_free()
	print("\nResults: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
