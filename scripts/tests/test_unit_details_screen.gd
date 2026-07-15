extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_unit_details_screen.gd
# Verifies UnitDetailsScreen.tscn instantiates, the new HBox-based layout's
# @onready vars resolve, the opaque Dimmer exists, open()/_close drive
# visibility, and the More Info side panel responds to clicks and the
# `more_info` cycle. Tracks the Phase 1 More Info migration from
# AGENT/Docs/more_info_mode_plan_2026-05-24.md.


func _poll_action(screen: Control, action: String) -> void:
	Input.action_press(action, 1.0)
	screen._process(0.016)
	Input.action_release(action)
	screen._process(0.016)


func _init() -> void:
	print("=== UnitDetailsScreen Test ===")
	var passed := 0
	var failed := 0

	var dm: Node = load("res://scripts/autoloads/DataManager.gd").new()
	dm.name = "DataManager"
	root.add_child(dm)
	await process_frame

	var packed := load("res://scenes/ui/UnitDetailsScreen.tscn")
	if packed == null:
		print("FAIL could not load UnitDetailsScreen.tscn")
		quit(1)
		return
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame

	# Opaque Dimmer makes the page modal.
	if screen.get_node_or_null("Dimmer") != null:
		print("OK  Dimmer node present (#1)")
		passed += 1
	else:
		print("FAIL no Dimmer node (#1)")
		failed += 1

	# Every node the script's @onready vars depend on must exist after the
	# More Info layout switch to Panel/HBox/{VBox, InfoVBox}.
	var expected := [
		"Panel/HBox/MainScroll",
		"Panel/HBox/MainScroll/VBox/TitleLabel",
		"Panel/HBox/MainScroll/VBox/StatsLabel",
		"Panel/HBox/MainScroll/VBox/InventoryLabel",
		"Panel/HBox/MainScroll/VBox/SkillsLabel",
		"Panel/HBox/MainScroll/VBox/WexpLabel",
		"Panel/HBox/MainScroll/VBox/BtnPair",
		"Panel/HBox/MainScroll/VBox/BtnBack",
		"Panel/HBox/InfoVBox/InfoTitle",
		"Panel/HBox/InfoVBox/InfoHint",
		"Panel/HBox/InfoVBox/InfoDescription",
		"Panel/HBox/InfoVBox/InfoModifiers",
	]
	var all_present := true
	for path in expected:
		if screen.get_node_or_null(path) == null:
			all_present = false
			print("FAIL missing node: " + path)
			failed += 1
	if all_present:
		print("OK  all @onready-referenced nodes resolve")
		passed += 1

	var main_scroll := screen.get_node_or_null("Panel/HBox/MainScroll") as ScrollContainer
	var panel := screen.get_node_or_null("Panel") as PanelContainer
	if (
		main_scroll != null
		and panel != null
		and main_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
	):
		print("OK  character sheet main column uses a scroll frame (V023-02a)")
		passed += 1
	else:
		print("FAIL character sheet scroll frame missing or disabled")
		failed += 1
	if main_scroll != null and not main_scroll.follow_focus:
		print("OK  character sheet lookahead is the sole focus-scroll owner")
		passed += 1
	else:
		print("FAIL character sheet has competing engine and custom focus scrolling")
		failed += 1

	# V025-02a: the main column must NOT scroll horizontally — long inventory/wexp
	# rows wrap within the column instead of summoning a horizontal scrollbar.
	if (
		main_scroll != null
		and main_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED
	):
		print("OK  V025-02a character sheet horizontal scroll is disabled")
		passed += 1
	else:
		print(
			(
				"FAIL sheet h-scroll not disabled: mode=%s"
				% [main_scroll.horizontal_scroll_mode if main_scroll != null else "<none>"]
			)
		)
		failed += 1

	# V025-02b: the Back button must be shrink-centered with a bounded width, not
	# stretched to fill the whole column.
	var btn_back := screen.get_node_or_null("Panel/HBox/MainScroll/VBox/BtnBack") as Button
	if (
		btn_back != null
		and btn_back.size_flags_horizontal == Control.SIZE_SHRINK_CENTER
		and btn_back.custom_minimum_size.x > 0.0
	):
		print("OK  V025-02b Back button is shrink-centered with a bounded width")
		passed += 1
	else:
		print(
			(
				"FAIL Back button sizing: flags=%s min_x=%s"
				% [
					btn_back.size_flags_horizontal if btn_back != null else "<none>",
					btn_back.custom_minimum_size.x if btn_back != null else "<none>"
				]
			)
		)
		failed += 1

	# V025-02c: the stats More-Info panel puts the NUMBERS (modifier breakdown) above
	# the PROSE (description), and the prose fills the full remaining height so a short
	# description doesn't shrink the box. Assert order + that only the prose expands.
	var info_mods := screen.get_node_or_null("Panel/HBox/InfoVBox/InfoModifiers") as Control
	var info_desc := screen.get_node_or_null("Panel/HBox/InfoVBox/InfoDescription") as Control
	if (
		info_mods != null
		and info_desc != null
		and info_mods.get_index() < info_desc.get_index()
		and (info_desc.size_flags_vertical & Control.SIZE_EXPAND) != 0
		and (info_mods.size_flags_vertical & Control.SIZE_EXPAND) == 0
	):
		print("OK  V025-02c More-Info shows numbers above prose with a full-height prose box")
		passed += 1
	else:
		print(
			(
				"FAIL More-Info layout: mods_idx=%s desc_idx=%s desc_flags=%s mods_flags=%s"
				% [
					info_mods.get_index() if info_mods != null else "<none>",
					info_desc.get_index() if info_desc != null else "<none>",
					info_desc.size_flags_vertical if info_desc != null else "<none>",
					info_mods.size_flags_vertical if info_mods != null else "<none>"
				]
			)
		)
		failed += 1

	# open() populates the title from the unit and shows the page.
	var d := UnitData.new()
	d.unit_name = "Test Knight"
	d.class_id = "soldier"
	d.level = 7
	d.internal_level = 7
	d.strength = 9
	d.movement = 6
	d.growth_rates = {"strength": 20}
	d.growth_accumulators = {"strength": 35}
	d.weapon_wexp = {"lance": 130, "axe": 50}
	d.unit_id = "details_lead"
	d.defense = 8
	d.active_modifiers = [
		{"stat": "strength", "delta": 2, "source": "tonic", "duration": 1, "duration_type": "turn"},
		{
			"stat": "movement",
			"delta": 1,
			"source": "pair_up",
			"duration": -1,
			"duration_type": "combat"
		},
		# A net debuff on defense (8 -> 5) must render red.
		{
			"stat": "defense",
			"delta": -3,
			"source": "poison",
			"duration": -1,
			"duration_type": "permanent"
		},
	]
	var stub_script := GDScript.new()
	stub_script.source_code = """
extends Node
const GameConstants = preload(\"res://scripts/shared/GameConstants.gd\")
var data = null
var team: String = \"blue\"
func get_effective_stat(stat_name: String) -> int:
	var base = data.get(stat_name)
	var total: int = int(base) if base != null else 0
	for mod in data.active_modifiers:
		if String(mod.get(\"stat\", \"\")) == stat_name:
			total += int(mod.get(\"delta\", 0))
	return max(0, total)
func get_stored_weapon_rank(track: String) -> String:
	return GameConstants.weapon_rank_for_wexp(int(data.weapon_wexp.get(track, 0)))
func is_weapon_track_available(track: String) -> bool:
	return track == \"lance\"
"""
	stub_script.reload()
	var stub_unit: Node = stub_script.new()
	stub_unit.data = d
	root.add_child(stub_unit)

	screen.open(stub_unit)
	var title_ok: bool = (
		screen.visible and "Test Knight" in screen._title.text and "7" in screen._title.text
	)
	if title_ok:
		print("OK  open() shows the page and fills the title (#1)")
		passed += 1
	else:
		print("FAIL open(): visible=%s title=%s" % [screen.visible, screen._title.text])
		failed += 1

	# Stats panel: each stat is now a [url=stat:...] link with the colored
	# current value. Boosted Strength shows green and the link is intact.
	var stats_text: String = screen._stats.text
	var stats_ok: bool = (
		"[url=stat:strength]Str  [color=#5fd35f]11 [/color][/url]" in stats_text
		and "[url=stat:movement]Mov  [color=#5fd35f]7  [/color][/url]" in stats_text
		and "[url=stat:hp]HP" in stats_text
		# V020-15: CON and LoS appear on the sheet as selectable utility-stat rows.
		and "[url=stat:constitution]Con" in stats_text
		and "[url=stat:line_of_sight]LoS" in stats_text
	)
	if stats_ok:
		print("OK  stats panel renders selectable [url=...] rows with coloured current values")
		passed += 1
	else:
		print("FAIL stats panel: %s" % stats_text)
		failed += 1

	# V020-11: class summary section renders a selectable class row.
	var class_text: String = screen._class_lbl.text
	var class_ok: bool = "[url=class:soldier]" in class_text and "Class:" in class_text
	if class_ok:
		print("OK  class summary renders a selectable class row (V020-11)")
		passed += 1
	else:
		print("FAIL class summary: %s" % class_text)
		failed += 1

	# V021-10: the inline class row is compact (no relocated detail), and the class
	# More Info side panel carries the detail + the resolved movement type (V021-11).
	var inline_compact: bool = (
		not ("Weapons:" in class_text) and not ("Class skills:" in class_text)
	)
	var class_panel: String = screen._class_description("soldier")
	var panel_has_detail: bool = "Movement:" in class_panel and "Infantry" in class_panel
	if inline_compact and panel_has_detail:
		print("OK  class detail relocated to More Info with resolved movement type (V021-10/11)")
		passed += 1
	else:
		print("FAIL class relocation: compact=%s panel=%s" % [inline_compact, class_panel])
		failed += 1

	var archer_panel: String = screen._class_description("archer")
	if "equipped weapon" in archer_panel and not ("Cannot attack adjacent" in archer_panel):
		print("OK  archer copy keeps bow range weapon-driven (V023-08a)")
		passed += 1
	else:
		print("FAIL archer copy is stale: %s" % archer_panel)
		failed += 1

	# Compact stats use the same effective-display total as More Info, including
	# combat-only Pair Up bonuses. The paired-unit button opens the hidden support
	# sheet and then lets the player return to the lead.
	var gs_pair := root.get_node_or_null("GameState")
	var reg_pair := root.get_node_or_null("PairUpRegistry")
	var res_pair := root.get_node_or_null("PairUpBonusResolver")
	if gs_pair != null and reg_pair != null and res_pair != null:
		gs_pair.call("reset_map_state")
		reg_pair.call("clear")
		var pair_rules: CampaignRules = gs_pair.get("campaign_rules") as CampaignRules
		pair_rules.pair_up_enabled = true
		var support_data := UnitData.new()
		support_data.unit_id = "details_support"
		support_data.unit_name = "Support Cavalier"
		support_data.class_id = "cavalier"
		support_data.hp = 20
		support_data.max_hp = 20
		support_data.strength = 10
		support_data.defense = 10
		support_data.speed = 9
		support_data.skill = 8
		support_data.luck = 4
		var support_unit: Node = stub_script.new()
		support_unit.data = support_data
		root.add_child(support_unit)
		gs_pair.call("register_unit", stub_unit)
		gs_pair.call("register_unit", support_unit)
		reg_pair.call("pair", "details_lead", "details_support")
		screen.open(stub_unit)
		var bonuses: Dictionary = res_pair.call("bonuses_for", support_unit)
		var expected_str: int = int(d.strength) + 2 + int(bonuses.get("strength", 0))
		var compact_expected := "Str  [color=#5fd35f]%s[/color]" % ("%-3d" % expected_str)
		var compact_uses_pair: bool = compact_expected in screen._stats.text
		var pair_button_visible: bool = (
			screen._btn_pair.visible and screen._btn_pair.text == "View Support"
		)
		screen._on_pair_button_pressed()
		var opened_support: bool = (
			"Support Cavalier" in screen._title.text
			and screen._btn_pair.visible
			and screen._btn_pair.text == "View Lead"
		)
		screen._on_pair_button_pressed()
		var returned_to_lead: bool = "Test Knight" in screen._title.text
		if compact_uses_pair and pair_button_visible and opened_support and returned_to_lead:
			print(
				"OK  compact stats include Pair Up effective values and paired-unit button swaps sheets"
			)
			passed += 1
		else:
			print(
				(
					"FAIL pair sheet: compact=%s button=%s support=%s return=%s stats=%s title=%s"
					% [
						compact_uses_pair,
						pair_button_visible,
						opened_support,
						returned_to_lead,
						screen._stats.text,
						screen._title.text
					]
				)
			)
			failed += 1
		# V020 follow-up: the next_unit / prev_unit action jumps straight to the
		# paired partner (no focus nav), so a d-pad user can reach the View
		# Support/Lead button. Drive it through _input with a synthetic action event.
		# Screen is back on the lead here, with the pair button visible.
		var jump_ev := InputEventAction.new()
		jump_ev.action = "next_unit"
		jump_ev.pressed = true
		screen._input(jump_ev)
		if "Support Cavalier" in screen._title.text:
			print("OK  next_unit action jumps to the paired partner (controller pair-jump)")
			passed += 1
		else:
			print("FAIL next_unit pair-jump: title=%s" % screen._title.text)
			failed += 1
		screen._on_pair_button_pressed()  # back to the lead for the remaining checks

		# V031-GP-05: the pair button is also a selectable "pair" control entry —
		# plain directional traversal (not just the pair-jump shortcut) reaches
		# it, focuses the button, and confirm activates it.
		var pair_entry_idx := -1
		for i in screen._entries.size():
			var entry_any: Dictionary = screen._entries[i]
			if (
				String(entry_any.get("category", "")) == "control"
				and String(entry_any.get("key", "")) == "pair"
			):
				pair_entry_idx = i
				break
		var pair_entry_registered: bool = pair_entry_idx != -1
		var walk_guard := 0
		while screen._current_index != pair_entry_idx and walk_guard <= screen._entries.size():
			screen._move_selection(1)
			walk_guard += 1
		var pair_focused: bool = screen._btn_pair.has_focus()
		var confirm_ev := InputEventAction.new()
		confirm_ev.action = "confirm"
		confirm_ev.pressed = true
		screen._input(confirm_ev)
		var confirm_swapped: bool = "Support Cavalier" in screen._title.text
		screen._on_pair_button_pressed()  # back to the lead again
		# Selection scrolling resolves the owning section label as its target
		# (the custom selector moves a text highlight, so follow_focus can't).
		var wexp_entry: Dictionary = {}
		for entry_any2 in screen._entries:
			if String(entry_any2.get("category", "")) == "wexp":
				wexp_entry = entry_any2
				break
		var scroll_label_resolves: bool = (
			not wexp_entry.is_empty()
			and screen._section_label_for_entry(wexp_entry) == screen._wexp
		)
		if pair_entry_registered and pair_focused and confirm_swapped and scroll_label_resolves:
			print(
				"OK  V031-GP-05 traversal reaches the pair entry, confirm activates it, sections resolve for scroll"
			)
			passed += 1
		else:
			print(
				(
					"FAIL V031-GP-05: registered=%s focused=%s swapped=%s label=%s idx=%d cur=%d"
					% [
						pair_entry_registered,
						pair_focused,
						confirm_swapped,
						scroll_label_resolves,
						pair_entry_idx,
						screen._current_index
					]
				)
			)
			failed += 1

		reg_pair.call("clear")
		gs_pair.call("reset_map_state")
		support_unit.queue_free()
	else:
		print("SKIP compact Pair Up stat / paired-unit button test (autoload missing)")

	# WEXP panel: track rows are also [url=wexp:...] links so they open
	# More Info; unavailable tracks stay dimmed but selectable.
	var wexp_text: String = screen._wexp.text
	if (
		"[url=wexp:lance]Lance  D  130 / 200 to C[/url]" in wexp_text
		and (
			"[url=wexp:axe][color=#9a9aa6]Axe  E  50 / 100 to D (Unavailable)[/color][/url]"
			in wexp_text
		)
	):
		print("OK  WEXP panel rows are selectable, unavailable tracks dimmed")
		passed += 1
	else:
		print("FAIL WEXP panel: %s" % wexp_text)
		failed += 1

	# Side panel starts in the hint state — nothing selected yet.
	if screen._info_hint.visible and screen._info_desc.text == "" and screen._info_mods.text == "":
		print("OK  side panel starts in the hint state")
		passed += 1
	else:
		print("FAIL side panel initial state")
		failed += 1

	# Click a stat -> side panel shows its description + modifier breakdown.
	screen._on_entry_clicked("stat:strength")
	var desc_text: String = screen._info_desc.text
	var mods_text: String = screen._info_mods.text
	var click_ok: bool = (
		screen._info_title.text == "Str"
		and not screen._info_hint.visible
		and "Physical" in desc_text
		# Decomposition rows (class resolved from "soldier").
		and "Personal base" in mods_text
		and "Class base" in mods_text
		and "Soldier" in mods_text
		and "Class cap" in mods_text
		# Effective is shown and rendered green because the +2 tonic raises it.
		and "Effective" in mods_text
		and "11" in mods_text
		and "#5fd35f" in mods_text
		and "Growth 70%" in mods_text
		and "Fixed 35 / 100" in mods_text
		# The bonus row lists the source + signed delta.
		and "Bonuses:" in mods_text
		and "Tonic" in mods_text
		and "+2" in mods_text
	)
	if click_ok:
		print("OK  clicking a stat populates description + breakdown rows (green when boosted)")
		passed += 1
	else:
		print(
			(
				"FAIL stat click: title=%s desc=%s mods=%s"
				% [screen._info_title.text, desc_text, mods_text]
			)
		)
		failed += 1

	# Click a debuffed stat -> effective renders red (net-negative), not green.
	screen._on_entry_clicked("stat:defense")
	var def_text: String = screen._info_mods.text
	if "#ff6b6b" in def_text and not ("#5fd35f" in def_text) and "poison" in def_text:
		print("OK  a net-debuffed stat renders the effective value red")
		passed += 1
	else:
		print("FAIL debuff render: %s" % def_text)
		failed += 1

	# Click a stat with no active bonuses -> block shows the "none" notice plus
	# the decomposition, not an empty block, and is NOT green.
	screen._on_entry_clicked("stat:luck")
	var luck_text: String = screen._info_mods.text
	if (
		"No active bonuses" in luck_text
		and "Class cap" in luck_text
		and not ("#5fd35f" in luck_text)
	):
		print("OK  zero-bonus stats render the decomposition + 'none' notice, no green")
		passed += 1
	else:
		print("FAIL zero-bonus render: %s" % luck_text)
		failed += 1

	# Non-stat entries (wexp here) get a description but no modifier rows.
	screen._on_entry_clicked("wexp:lance")
	if (
		screen._info_title.text == "Lance"
		and "Weapon experience" in screen._info_desc.text
		and screen._info_mods.text == ""
	):
		print("OK  wexp click renders generic description and no modifier rows")
		passed += 1
	else:
		print(
			(
				"FAIL wexp click: title=%s desc=%s mods=%s"
				% [screen._info_title.text, screen._info_desc.text, screen._info_mods.text]
			)
		)
		failed += 1

	# more_info cycling: invoke the cycle directly (input simulation is
	# out of scope for this headless test). First call after a manual click
	# advances to the next registered entry.
	var before_index: int = screen._current_index
	screen._cycle_more_info()
	var advanced: bool = screen._current_index != before_index and screen._info_title.text != ""
	if advanced:
		print("OK  more_info cycle advances the side-panel selection")
		passed += 1
	else:
		print(
			(
				"FAIL more_info cycle did not advance (idx %d -> %d)"
				% [before_index, screen._current_index]
			)
		)
		failed += 1

	# Cycle should wrap around — keep cycling once per entry and confirm we
	# loop back to the first entry without crashing.
	for _i in screen._entries.size() + 1:
		screen._cycle_more_info()
	if screen._current_index >= 0 and screen._current_index < screen._entries.size():
		print("OK  more_info cycle wraps around safely")
		passed += 1
	else:
		print("FAIL more_info cycle index out of range: %d" % screen._current_index)
		failed += 1

	# V020-10: a weapon's More Info shows its full stat block, not generic text.
	var wpn_text: String = screen._weapon_info_text("iron_sword")
	var wpn_ok: bool = (
		"Iron Sword" in wpn_text
		and "Mt 6" in wpn_text
		and "Hit 85" in wpn_text
		and "Wt 7" in wpn_text
		and "Uses 45" in wpn_text
		and "Sword" in wpn_text
	)
	if wpn_ok:
		print("OK  weapon More Info renders the full stat block (V020-10)")
		passed += 1
	else:
		print("FAIL weapon info: %s" % wpn_text)
		failed += 1

	# V020-10: directional selection steps backward and marks the selected row so
	# a d-pad / keyboard user can see the highlight move.
	screen._selector.set_index(0)
	screen._move_selection(1)
	var marked: bool = false
	for lbl in screen._section_labels:
		if "▶" in lbl.text:
			marked = true
			break
	if marked and screen._info_title.text != "":
		print("OK  directional selection marks a row and previews it (V020-10)")
		passed += 1
	else:
		print("FAIL directional selection produced no highlighted row")
		failed += 1

	# V021-06: Up/Down move vertically across the stat grid; Left/Right horizontally.
	# strength (row r, col 0) and magic (same row, col 1) are one stat row; skill
	# (next row, col 0) is directly below strength.
	var _idx_of := func(cat: String, key: String) -> int:
		for i in screen._entries.size():
			if screen._entries[i].get("category") == cat and screen._entries[i].get("key") == key:
				return i
		return -1
	var str_idx: int = _idx_of.call("stat", "strength")
	var mag_idx: int = _idx_of.call("stat", "magic")
	var skl_idx: int = _idx_of.call("stat", "skill")
	# Right from strength lands on magic (same row, next column).
	screen._selector.set_index(str_idx)
	_poll_action(screen, "cursor_right")
	if screen._current_index == mag_idx:
		print("OK  V021-06 Left/Right steps within a stat row (strength -> magic)")
		passed += 1
	else:
		print(
			"FAIL V021-06 horizontal: expected magic(%d) got %d" % [mag_idx, screen._current_index]
		)
		failed += 1
	# Down from strength lands on skill (row below, same column) — not magic.
	screen._selector.set_index(str_idx)
	_poll_action(screen, "cursor_down")
	if screen._current_index == skl_idx:
		print("OK  V021-06 Down moves to the row below (strength -> skill)")
		passed += 1
	else:
		print("FAIL V021-06 vertical: expected skill(%d) got %d" % [skl_idx, screen._current_index])
		failed += 1

	# V026-02e: the selector owns the Back button too. Moving down from the last
	# content row focuses Back, and Confirm activates it without relying on a mouse.
	var back_idx: int = _idx_of.call("control", "back")
	var back_closed_seen := [false]
	screen.closed.connect(func(): back_closed_seen[0] = true, CONNECT_ONE_SHOT)
	screen._selector.set_index(back_idx - 1)
	_poll_action(screen, "cursor_down")
	var reached_back: bool = screen._current_index == back_idx and btn_back.has_focus()
	var confirm_ev := InputEventAction.new()
	confirm_ev.action = "confirm"
	confirm_ev.pressed = true
	screen._input(confirm_ev)
	if reached_back and back_closed_seen[0] and not screen.visible:
		print("OK  V026-02e selector reaches Back and Confirm closes the sheet")
		passed += 1
	else:
		print(
			(
				"FAIL V026-02e Back selector: reached=%s closed=%s visible=%s idx=%d back_idx=%d focus=%s"
				% [
					reached_back,
					back_closed_seen[0],
					screen.visible,
					screen._current_index,
					back_idx,
					btn_back.has_focus()
				]
			)
		)
		failed += 1

	# ---- B6-INPUT focus seam: input-mode subscriber overrides ----
	# This screen navigates by SelectionCursor, so a switch to gamepad seeds the
	# selector at the first entry (only when nothing is selected yet) rather than
	# grabbing a button; a switch to touch clears the highlight.
	screen.open(stub_unit)
	screen._selector.reset()
	screen._on_input_mode_changed("gamepad")
	var seeded: bool = screen._current_index == 0
	# A second gamepad switch must not clobber an existing selection.
	screen._selector.set_index(2)
	screen._on_input_mode_changed("gamepad")
	var kept_selection: bool = screen._current_index == 2
	# Switching to touch clears the selection highlight.
	screen._on_input_mode_changed("touch")
	var cleared: bool = screen._current_index == -1
	if seeded and kept_selection and cleared:
		print("OK  B6-INPUT focus seam: gamepad seeds selector, keeps selection, touch clears")
		passed += 1
	else:
		print(
			(
				"FAIL focus seam: seeded=%s kept=%s cleared=%s idx=%d"
				% [seeded, kept_selection, cleared, screen._current_index]
			)
		)
		failed += 1

	screen.open(stub_unit)

	# _close() hides the page, emits `closed`, and clears local state so the
	# next open() starts from a clean slate.
	var closed_seen := [false]
	screen.closed.connect(func(): closed_seen[0] = true)
	screen._close()
	var close_ok: bool = (
		not screen.visible
		and closed_seen[0]
		and screen._unit == null
		and screen._entries.is_empty()
		and screen._current_index == -1
	)
	if close_ok:
		print("OK  _close() hides, emits closed, and clears local state")
		passed += 1
	else:
		print(
			(
				"FAIL close state: visible=%s closed=%s unit=%s entries=%d idx=%d"
				% [
					screen.visible,
					closed_seen[0],
					screen._unit,
					screen._entries.size(),
					screen._current_index
				]
			)
		)
		failed += 1

	# open() ignores a null unit without error.
	screen.open(null)
	if not screen.visible:
		print("OK  open(null) is a safe no-op")
		passed += 1
	else:
		print("FAIL open(null) showed the page")
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
