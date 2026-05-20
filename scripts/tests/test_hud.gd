extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_hud.gd
# Verifies HUD.tscn instantiates and the debug-mode banner — the red "DEBUG MODE"
# label — toggles with the debug-build flag via _apply_debug_banner(), and that
# the text lists the active debug aids when any are flipped on.

func _init() -> void:
	print("=== HUD Test ===")
	var passed := 0
	var failed := 0

	var packed := load("res://scenes/ui/HUD.tscn")
	if packed == null:
		print("FAIL could not load HUD.tscn"); quit(1); return
	var hud: Control = packed.instantiate()
	root.add_child(hud)
	await process_frame

	# The debug-mode banner label must exist.
	var label: Label = hud.get_node_or_null("DebugLabel")
	if label != null:
		print("OK  DebugLabel node present"); passed += 1
	else:
		print("FAIL no DebugLabel node"); failed += 1

	# _apply_debug_banner(true, []) shows the banner with the base text.
	# Typed locals — _apply_debug_banner's `active_aids` is Array[String], and
	# an untyped `[]` literal won't satisfy that typed parameter.
	if label != null:
		var no_aids: Array[String] = []
		var one_aid: Array[String] = ["force-levelup"]
		var two_aids: Array[String] = ["force-levelup", "growth-boost"]

		hud._apply_debug_banner(true, no_aids)
		if label.visible and label.text == "● DEBUG MODE":
			print("OK  banner shown with base text when no aids active"); passed += 1
		else:
			print("FAIL base banner: visible=%s text=%q" % [label.visible, label.text])
			failed += 1

		# _apply_debug_banner(true, [...]) lists each active aid by name.
		hud._apply_debug_banner(true, one_aid)
		if label.visible and label.text == "● DEBUG MODE — force-levelup":
			print("OK  banner lists a single active aid"); passed += 1
		else:
			print("FAIL one-aid banner: text=%q" % label.text); failed += 1

		hud._apply_debug_banner(true, two_aids)
		if label.visible and label.text == "● DEBUG MODE — force-levelup, growth-boost":
			print("OK  banner joins multiple active aids"); passed += 1
		else:
			print("FAIL multi-aid banner: text=%q" % label.text); failed += 1

		# is_debug=false hides the banner AND clears the text — the strict
		# invariant prevents a stale aid list from sitting under the hidden label.
		hud._apply_debug_banner(false, one_aid)
		if not label.visible and label.text == "":
			print("OK  banner hidden and text cleared when debug inactive"); passed += 1
		else:
			print("FAIL hide path: visible=%s text=%q" % [label.visible, label.text])
			failed += 1

	# Flipping a GameState debug flag must re-emit through EventBus and refresh
	# the banner — the live-update path used from the remote debugger.
	var gs := root.get_node_or_null("GameState")
	var bus := root.get_node_or_null("EventBus")
	if gs != null and bus != null and label != null:
		# Start clean so a leftover value from another suite can't skew us.
		gs.debug_force_levelup = false
		gs.debug_growth_boost = false
		await process_frame
		var empty_aids: Array[String] = []
		hud._apply_debug_banner(true, empty_aids)  # baseline text
		gs.debug_force_levelup = true       # setter -> signal -> _refresh_debug_banner
		await process_frame
		# OS.is_debug_build() is true under --script, so visible stays true; the
		# refresh re-reads the live flag list and rewrites the text.
		if label.text.find("force-levelup") != -1:
			print("OK  flag toggle refreshes banner text"); passed += 1
		else:
			print("FAIL flag toggle did not refresh: text=%q" % label.text); failed += 1
		# Reset the flags after toggling — defensive only; each suite runs in
		# its own godot process under run_tests.sh, so this state never leaks
		# across suites. Cheap belt-and-braces against future test layering.
		gs.debug_force_levelup = false
		gs.debug_growth_boost = false
	else:
		print("SKIP live flag-toggle test (GameState/EventBus autoload absent)")

	# ── Playtest 3 #6 — info panel follows the cursor during selection ────────
	# When a unit is selected, the panel used to latch on that unit and ignore
	# the cursor — so the player couldn't see the enemy they were about to
	# attack. The new behaviour: always prefer the unit under the cursor;
	# fall back to the selected unit only on an empty tile.
	var stub_grid_script := GDScript.new()
	stub_grid_script.source_code = """
extends Node
var _at: Dictionary = {}
func set_unit(tile: Vector2i, unit) -> void: _at[tile] = unit
func get_unit_at(tile: Vector2i): return _at.get(tile, null)
const TERRAIN_DEF_BONUS: Dictionary = {\"plain\": 0}
const TERRAIN_DODGE_BONUS: Dictionary = {\"plain\": 0}
func get_terrain_at(_t: Vector2i) -> String: return \"plain\"
"""
	stub_grid_script.reload()
	var stub_grid: Node = stub_grid_script.new()
	root.add_child(stub_grid)
	hud._grid = stub_grid

	# Two stub units with a `data` property — base Node has no `data`, so we
	# need a tiny script that declares it for HUD._show_unit's `unit.data` reads.
	var stub_unit_script := GDScript.new()
	stub_unit_script.source_code = """
extends Node
var data
"""
	stub_unit_script.reload()
	var unit_a: Node = stub_unit_script.new()
	var unit_a_data := UnitData.new()
	unit_a_data.unit_name = "Selected Hero"
	unit_a_data.class_id = "soldier"
	unit_a_data.hp = 20; unit_a_data.max_hp = 20
	unit_a.data = unit_a_data
	var unit_b: Node = stub_unit_script.new()
	var unit_b_data := UnitData.new()
	unit_b_data.unit_name = "Hovered Enemy"
	unit_b_data.class_id = "soldier"
	unit_b_data.hp = 15; unit_b_data.max_hp = 20
	unit_b.data = unit_b_data
	root.add_child(unit_a)
	root.add_child(unit_b)
	stub_grid.set_unit(Vector2i(1, 1), unit_a)
	stub_grid.set_unit(Vector2i(3, 3), unit_b)

	hud._on_unit_selected(unit_a)
	hud._on_cursor_moved(Vector2i(3, 3))   # cursor on enemy
	if hud._displayed_unit == unit_b:
		print("OK  HUD follows cursor onto another unit during selection (playtest 3 #6)")
		passed += 1
	else:
		print("FAIL hover-on-other-unit: displayed=%s want=%s" % [hud._displayed_unit, unit_b])
		failed += 1

	hud._on_cursor_moved(Vector2i(5, 5))   # cursor on empty tile, unit still selected
	if hud._displayed_unit == unit_a:
		print("OK  HUD falls back to the selected unit on empty tile (playtest 3 #6)")
		passed += 1
	else:
		print("FAIL empty-tile-fallback: displayed=%s want=%s" % [hud._displayed_unit, unit_a])
		failed += 1

	hud._on_unit_deselected()
	hud._on_cursor_moved(Vector2i(5, 5))   # no selection now, empty tile → nothing
	if hud._displayed_unit == null:
		print("OK  HUD clears panel on empty tile with no selection (playtest 3 #6)")
		passed += 1
	else:
		print("FAIL post-deselect empty: displayed=%s want=null" % hud._displayed_unit)
		failed += 1

	unit_a.queue_free(); unit_b.queue_free()
	stub_grid.queue_free()

	# ── M16 stage 4: objective readout ──────────────────────────────────────────
	# _build_objective_lines reads MapData + GameState.get_alliance_group("blue").
	# Legacy fields (objective_type / turn_limit / required_survivor_ids) and
	# authored conditions (victory_conditions / defeat_conditions) both feed in;
	# headers ("Win:" / "Lose:") only appear when at least one entry follows.
	var md_obj := MapData.new()
	md_obj.objective_type = "rout"
	var c_obj_prot := ObjectiveCondition.new()
	c_obj_prot.type = "protect"; c_obj_prot.unit_ids = ["leader"] as Array[String]
	md_obj.defeat_conditions = {"allies": [c_obj_prot]}
	var lines: Array[String] = hud._build_objective_lines(md_obj)
	if lines.size() == 4 \
			and lines[0] == "Win:" and lines[1].find("Rout all hostiles") != -1 \
			and lines[2] == "Lose:" and lines[3].find("Protect: leader") != -1:
		print("OK  HUD objective lines: legacy rout + authored protect"); passed += 1
	else:
		print("FAIL HUD objective lines: %s" % str(lines)); failed += 1

	# Empty MapData → no lines (panel stays hidden).
	if hud._build_objective_lines(MapData.new()).is_empty():
		print("OK  HUD objective lines: empty MapData → no lines"); passed += 1
	else:
		print("FAIL empty mapdata produced lines"); failed += 1

	hud.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
