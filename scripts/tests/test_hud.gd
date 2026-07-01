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
		var two_aids: Array[String] = ["force-levelup", "growth+300"]

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
		if label.visible and label.text == "● DEBUG MODE — force-levelup, growth+300":
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
		gs.debug_hotseat_override = true
		await process_frame
		if label.text.find("hotseat-all") != -1:
			print("OK  F9 hotseat override appears in the debug banner"); passed += 1
		else:
			print("FAIL hotseat override missing from banner: text=%q" % label.text); failed += 1
		# Reset the flags after toggling — defensive only; each suite runs in
		# its own godot process under run_tests.sh, so this state never leaks
		# across suites. Cheap belt-and-braces against future test layering.
		gs.debug_force_levelup = false
		gs.debug_growth_boost = false
		gs.debug_hotseat_override = false
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
func get_terrain_bonuses(_t: Vector2i) -> Dictionary: return {\"def\": 0, \"dodge\": 0}
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
var team: String = "blue"
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

	# ── Pair Up bonus indicator on the unit-info panel (playtest #8.5 follow-up) ──
	# A paired lead's panel must show the support's contribution (queried on demand,
	# since the bonus is a combat-only modifier). A non-lead must not show it.
	var gs_pu := root.get_node_or_null("GameState")
	var reg_pu := root.get_node_or_null("PairUpRegistry")
	var res_pu := root.get_node_or_null("PairUpBonusResolver")
	if gs_pu != null and reg_pu != null and res_pu != null:
		gs_pu.call("reset_map_state")
		reg_pu.call("clear")
		gs_pu.set("pair_up_enabled", true)
		var lead: Node = stub_unit_script.new()
		var lead_data := UnitData.new()
		lead_data.unit_name = "PU Lead"; lead_data.class_id = "soldier"; lead_data.unit_id = "hud_lead"
		lead_data.hp = 20; lead_data.max_hp = 20
		lead.data = lead_data
		var supp: Node = stub_unit_script.new()
		var supp_data := UnitData.new()
		supp_data.unit_name = "PU Support"; supp_data.class_id = "cavalier"; supp_data.unit_id = "hud_supp"
		supp_data.hp = 20; supp_data.max_hp = 20
		supp_data.strength = 10; supp_data.defense = 10; supp_data.speed = 9
		supp_data.skill = 8; supp_data.luck = 4
		supp.data = supp_data
		root.add_child(lead); root.add_child(supp)
		gs_pu.call("register_unit", lead)
		gs_pu.call("register_unit", supp)
		reg_pu.call("pair", "hud_lead", "hud_supp")

		hud._show_unit(lead)
		var pu_label = hud.get_node_or_null("UnitInfoPanel/VBox/PairUpLabel")
		# V021-07: the map HUD pair-up line now names only the off-map support — the
		# per-stat bonus deltas were dropped (the full breakdown lives on the `I` sheet).
		var lead_shows: bool = pu_label != null and pu_label.visible \
			and "Support: PU Support" in pu_label.text \
			and not ("Paired" in pu_label.text) and not ("Str" in pu_label.text)
		hud._show_unit(supp)   # support is not the lead → indicator hidden
		var supp_hides: bool = pu_label != null and not pu_label.visible
		if lead_shows and supp_hides:
			print("OK  unit-info names the Pair Up support (no stat deltas) on a lead, hides it otherwise (V021-07)")
			passed += 1
		else:
			print("FAIL pair-up indicator: lead_shows=%s supp_hides=%s text=%s" % [
				lead_shows, supp_hides, (pu_label.text if pu_label != null else "<no label>")])
			failed += 1
		reg_pu.call("clear")
		gs_pu.call("reset_map_state")
		lead.queue_free(); supp.queue_free()
	else:
		print("SKIP pair-up indicator (autoload missing)")

	unit_a.queue_free(); unit_b.queue_free()
	stub_grid.queue_free()

	# ── M16: objective readout ──────────────────────────────────────────────────
	# _build_objective_lines reads MapData.victory_conditions / defeat_conditions
	# for blue's alliance group ("allies"). Headers ("Win:" / "Lose:") only
	# appear when at least one entry follows.
	var md_obj := MapData.new()
	var c_obj_rout := ObjectiveCondition.new()
	c_obj_rout.type = "rout"
	var c_obj_prot := ObjectiveCondition.new()
	c_obj_prot.type = "protect"; c_obj_prot.unit_ids = ["leader"] as Array[String]
	md_obj.victory_conditions = {"allies": [c_obj_rout]}
	md_obj.defeat_conditions = {"allies": [c_obj_prot]}
	var lines: Array[String] = hud._build_objective_lines(md_obj)
	if lines.size() == 4 \
			and lines[0] == "Win:" and lines[1].find("Rout all hostiles") != -1 \
			and lines[2] == "Lose:" and lines[3].find("Protect: leader") != -1:
		print("OK  HUD objective lines: authored rout + protect"); passed += 1
	else:
		print("FAIL HUD objective lines: %s" % str(lines)); failed += 1

	# Empty MapData → no lines (panel stays hidden).
	if hud._build_objective_lines(MapData.new()).is_empty():
		print("OK  HUD objective lines: empty MapData → no lines"); passed += 1
	else:
		print("FAIL empty mapdata produced lines"); failed += 1

	# ── C3: phase label identifies both faction and controller ────────────────
	var gs2 := root.get_node_or_null("GameState")
	if gs2 != null:
		var md_phase := MapData.new()
		var f_red := FactionData.new()
		f_red.id = "red"
		f_red.display_name = "Invaders"
		md_phase.factions = [f_red] as Array[FactionData]
		gs2.map_data = md_phase
		var tm_stub := Node.new()
		var tm_stub_script := GDScript.new()
		tm_stub_script.source_code = "extends Node\nfunc active_faction() -> String: return \"red\"\n"
		tm_stub_script.reload()
		tm_stub.set_script(tm_stub_script)
		tm_stub.name = "TurnManager"
		var gm_stub := Node.new()
		gm_stub.name = "GameMap"
		gm_stub.add_child(tm_stub)
		root.add_child(gm_stub)
		hud._on_phase_changed(GameState.Phase.ENEMY, "red")
		var phase_label: Label = hud.get_node("PhaseLabel")
		if phase_label.text == "INVADERS - AI PHASE":
			print("OK  C3: HUD phase label uses faction and controller")
			passed += 1
		else:
			print("FAIL C3 HUD phase label: %q" % phase_label.text)
			failed += 1
		gm_stub.queue_free()
	else:
		print("SKIP C3 HUD phase label test (GameState autoload absent)")

	# ── Phase 1 More Info: terrain expansion ────────────────────────────────────
	# A second stub grid + selected-unit setup so the expanded mode has a
	# meaningful tile + actor context. TurnManager stub mirrors the gates
	# TileActions queries; only "seize" fires for this test so we know the
	# Actions row picks it up.
	var more_grid_script := GDScript.new()
	more_grid_script.source_code = """
extends Node
func get_terrain_at(_t: Vector2i) -> String: return \"forest\"
func get_terrain_bonuses(_t: Vector2i) -> Dictionary: return {\"def\": 1, \"dodge\": 15}
func get_unit_at(_t: Vector2i): return null
"""
	more_grid_script.reload()
	var more_grid: Node = more_grid_script.new()
	root.add_child(more_grid)

	var more_turn_script := GDScript.new()
	more_turn_script.source_code = """
extends Node
func can_seize(_u: Node, _t: Vector2i) -> bool: return true
func can_escape(_u: Node, _t: Vector2i) -> bool: return false
"""
	more_turn_script.reload()
	var more_turn: Node = more_turn_script.new()
	root.add_child(more_turn)

	# Direct injection — setup() also connects turn_changed which the stub
	# doesn't expose, so we wire fields manually.
	hud._grid = more_grid
	hud._turn_manager = more_turn

	# Selected unit so the Actions row has someone to gate against.
	var more_unit_script := GDScript.new()
	more_unit_script.source_code = "extends Node\nvar data\n"
	more_unit_script.reload()
	var more_unit: Node = more_unit_script.new()
	more_unit.data = UnitData.new()
	root.add_child(more_unit)
	hud._on_unit_selected(more_unit)

	# Compact view: only the original three rows are populated; the
	# expansion rows stay hidden until the player presses more_info.
	hud._on_cursor_moved(Vector2i(2, 2))
	if not hud._terrain_desc.visible \
			and not hud._terrain_moves.visible \
			and not hud._terrain_actions.visible \
			and hud._terrain_hint.visible \
			and not hud._terrain_more_panel.visible:
		print("OK  terrain panel starts compact, hint visible"); passed += 1
	else:
		print("FAIL compact start: desc=%s moves=%s actions=%s hint=%s" \
			% [hud._terrain_desc.visible, hud._terrain_moves.visible,
				hud._terrain_actions.visible, hud._terrain_hint.visible])
		failed += 1

	# V021-05 Description page: description + actions populated, move costs on the
	# OTHER page (hidden here), hint hidden. Match a substring from
	# MoreInfoContent.TERRAIN["forest"] to prove the lookup landed on the right entry.
	hud._terrain_more_page = hud.TERRAIN_PAGE_DESCRIPTION
	hud._update_terrain(Vector2i(2, 2))
	var desc_page_ok: bool = (
		hud._terrain_more_panel.visible
		and hud._terrain_desc.visible
		and "Slows most ground units" in hud._terrain_desc.text
		and hud._terrain_actions.visible
		and "Seize" in hud._terrain_actions.text
		and not hud._terrain_moves.visible
		and not hud._terrain_hint.visible
	)
	if desc_page_ok:
		print("OK  V021-05 Description page shows description + actions (no move costs)")
		passed += 1
	else:
		print("FAIL desc page: desc=%s|%s moves_vis=%s actions=%s|%s hint=%s" \
			% [hud._terrain_desc.visible, hud._terrain_desc.text,
				hud._terrain_moves.visible,
				hud._terrain_actions.visible, hud._terrain_actions.text,
				hud._terrain_hint.visible])
		failed += 1

	# V021-05 Movement page: move-cost table visible (incl. the V021-11 Flying row),
	# description hidden.
	hud._terrain_more_page = hud.TERRAIN_PAGE_MOVEMENT
	hud._update_terrain(Vector2i(2, 2))
	var move_page_ok: bool = (
		hud._terrain_more_panel.visible
		and hud._terrain_moves.visible
		and "Foot" in hud._terrain_moves.text
		and "Mounted" in hud._terrain_moves.text
		and "Flying" in hud._terrain_moves.text
		and not hud._terrain_desc.visible
	)
	if move_page_ok:
		print("OK  V021-05 Movement page shows the move-cost table incl. Flying (V021-11)")
		passed += 1
	else:
		print("FAIL move page: moves=%s|%s desc_vis=%s" \
			% [hud._terrain_moves.visible, hud._terrain_moves.text, hud._terrain_desc.visible])
		failed += 1

	# Move-cost row uses "—" for impassable rather than the raw 999.
	var wall_grid_script := GDScript.new()
	wall_grid_script.source_code = """
extends Node
func get_terrain_at(_t: Vector2i) -> String: return \"wall\"
func get_terrain_bonuses(_t: Vector2i) -> Dictionary: return {\"def\": 0, \"dodge\": 0}
func get_unit_at(_t: Vector2i): return null
"""
	wall_grid_script.reload()
	var wall_grid: Node = wall_grid_script.new()
	root.add_child(wall_grid)
	hud._grid = wall_grid
	hud._update_terrain(Vector2i(0, 0))
	if "—" in hud._terrain_moves.text and "999" not in hud._terrain_moves.text:
		print("OK  wall renders move cost as — instead of 999"); passed += 1
	else:
		print("FAIL wall move-cost text: %q" % hud._terrain_moves.text); failed += 1

	# W6a: player-facing tile coords are one-based — internal Vector2i(0,0) shows
	# as Tile (1, 1). Storage stays zero-based; this is a display-only +1.
	hud._update_terrain(Vector2i(0, 0))
	if hud._terrain_coord.text == "Tile (1, 1)":
		print("OK  W6a tile coord (0,0) renders as one-based (1, 1)"); passed += 1
	else:
		print("FAIL W6a coord at (0,0): %q" % hud._terrain_coord.text); failed += 1
	hud._update_terrain(Vector2i(7, 4))
	if hud._terrain_coord.text == "Tile (8, 5)":
		print("OK  W6a tile coord (7,4) renders as one-based (8, 5)"); passed += 1
	else:
		print("FAIL W6a coord at (7,4): %q" % hud._terrain_coord.text); failed += 1

	# Actions row hides when no unit is selected (on the Description page).
	hud._terrain_more_page = hud.TERRAIN_PAGE_DESCRIPTION
	hud._on_unit_deselected()
	hud._update_terrain(Vector2i(0, 0))
	if not hud._terrain_actions.visible:
		print("OK  actions row hides when no unit is selected"); passed += 1
	else:
		print("FAIL actions row visible without a selected unit"); failed += 1

	# V021-05 Hidden state: the whole More Info box hides (frees map area), hint returns.
	hud._terrain_more_page = hud.TERRAIN_PAGE_HIDDEN
	hud._update_terrain(Vector2i(0, 0))
	if not hud._terrain_desc.visible and not hud._terrain_moves.visible \
			and not hud._terrain_actions.visible and hud._terrain_hint.visible \
			and not hud._terrain_more_panel.visible:
		print("OK  V021-05 Hidden page hides the whole More Info box"); passed += 1
	else:
		print("FAIL hidden page: rows still visible"); failed += 1

	# V021-05 F-cycle: Hidden → Description → Movement → Hidden.
	hud._terrain_more_page = hud.TERRAIN_PAGE_HIDDEN
	hud._cursor_tile = Vector2i(0, 0)
	hud.cycle_terrain_more_page()
	var cyc1: bool = hud._terrain_more_page == hud.TERRAIN_PAGE_DESCRIPTION
	hud.cycle_terrain_more_page()
	var cyc2: bool = hud._terrain_more_page == hud.TERRAIN_PAGE_MOVEMENT
	hud.cycle_terrain_more_page()
	var cyc3: bool = hud._terrain_more_page == hud.TERRAIN_PAGE_HIDDEN \
		and not hud._terrain_more_panel.visible
	if cyc1 and cyc2 and cyc3:
		print("OK  V021-05 more_info cycles Hidden → Description → Movement → Hidden"); passed += 1
	else:
		print("FAIL cycle: c1=%s c2=%s c3=%s" % [cyc1, cyc2, cyc3]); failed += 1

	# V023-09a: click paging should hit both the compact panel and either expanded
	# page. The movement page used to miss because only TerrainCorner's compact
	# footprint was checked.
	hud._terrain_more_page = hud.TERRAIN_PAGE_DESCRIPTION
	hud._update_terrain(Vector2i(0, 0))
	await process_frame
	var compact_hit: bool = hud.terrain_corner_contains_screen_position(
		hud._terrain_panel.get_global_rect().get_center())
	var description_hit: bool = hud.terrain_corner_contains_screen_position(
		hud._terrain_more_panel.get_global_rect().get_center())
	hud._terrain_more_page = hud.TERRAIN_PAGE_MOVEMENT
	hud._update_terrain(Vector2i(0, 0))
	await process_frame
	var movement_hit: bool = hud.terrain_corner_contains_screen_position(
		hud._terrain_more_panel.get_global_rect().get_center())
	if compact_hit and description_hit and movement_hit:
		print("OK  V023-09a terrain click hit-test covers compact and expanded pages")
		passed += 1
	else:
		print("FAIL terrain click hit-test: compact=%s desc=%s movement=%s" % [
			compact_hit, description_hit, movement_hit])
		failed += 1

	# More Info is a separate, bounded, scrollable box — not part of the basic
	# stats panel. The scroll caps the visible height so long terrain text
	# scrolls instead of growing the panel off-screen.
	var separate_ok: bool = (
		hud._terrain_more_panel != hud._terrain_panel
		and hud._terrain_desc.get_parent().get_parent() == hud._terrain_scroll
		and hud._terrain_scroll.get_parent() == hud._terrain_more_panel
	)
	var bounded_ok: bool = (
		hud._terrain_scroll.custom_minimum_size.y > 0.0
		and hud._terrain_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
	)
	if separate_ok and bounded_ok:
		print("OK  More Info box is separate from the basic panel and scroll-bounded")
		passed += 1
	else:
		print("FAIL more-info structure: separate=%s bounded=%s min_y=%s mode=%d" \
			% [separate_ok, bounded_ok, str(hud._terrain_scroll.custom_minimum_size.y),
				hud._terrain_scroll.vertical_scroll_mode])
		failed += 1

	more_unit.queue_free(); more_grid.queue_free()
	wall_grid.queue_free(); more_turn.queue_free()

	hud.queue_free()
	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
