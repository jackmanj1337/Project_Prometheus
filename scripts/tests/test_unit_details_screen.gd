extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_unit_details_screen.gd
# Verifies UnitDetailsScreen.tscn instantiates, the new HBox-based layout's
# @onready vars resolve, the opaque Dimmer exists, open()/_close drive
# visibility, and the More Info side panel responds to clicks and the
# `more_info` cycle. Tracks the Phase 1 More Info migration from
# AGENT/Docs/more_info_mode_plan_2026-05-24.md.

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
		print("FAIL could not load UnitDetailsScreen.tscn"); quit(1); return
	var screen: Control = packed.instantiate()
	root.add_child(screen)
	await process_frame

	# Opaque Dimmer makes the page modal.
	if screen.get_node_or_null("Dimmer") != null:
		print("OK  Dimmer node present (#1)"); passed += 1
	else:
		print("FAIL no Dimmer node (#1)"); failed += 1

	# Every node the script's @onready vars depend on must exist after the
	# More Info layout switch to Panel/HBox/{VBox, InfoVBox}.
	var expected := [
		"Panel/HBox/VBox/TitleLabel",
		"Panel/HBox/VBox/StatsLabel",
		"Panel/HBox/VBox/InventoryLabel",
		"Panel/HBox/VBox/SkillsLabel",
		"Panel/HBox/VBox/WexpLabel",
		"Panel/HBox/VBox/BtnPair",
		"Panel/HBox/VBox/BtnBack",
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
		print("OK  all @onready-referenced nodes resolve"); passed += 1

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
		{"stat": "movement", "delta": 1, "source": "pair_up", "duration": -1, "duration_type": "combat"},
		# A net debuff on defense (8 -> 5) must render red.
		{"stat": "defense", "delta": -3, "source": "poison", "duration": -1, "duration_type": "permanent"},
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
	var title_ok: bool = screen.visible and "Test Knight" in screen._title.text \
		and "7" in screen._title.text
	if title_ok:
		print("OK  open() shows the page and fills the title (#1)"); passed += 1
	else:
		print("FAIL open(): visible=%s title=%s" % [screen.visible, screen._title.text])
		failed += 1

	# Stats panel: each stat is now a [url=stat:...] link with the colored
	# current value. Boosted Strength shows green and the link is intact.
	var stats_text: String = screen._stats.text
	var stats_ok: bool = (
		"[url=stat:strength]Str  [color=#61c454]11 [/color][/url]" in stats_text
		and "[url=stat:movement]Mov  [color=#61c454]7  [/color][/url]" in stats_text
		and "[url=stat:hp]HP" in stats_text
		# V020-15: CON and LoS appear on the sheet as selectable utility-stat rows.
		and "[url=stat:constitution]Con" in stats_text
		and "[url=stat:line_of_sight]LoS" in stats_text
	)
	if stats_ok:
		print("OK  stats panel renders selectable [url=...] rows with coloured current values")
		passed += 1
	else:
		print("FAIL stats panel: %s" % stats_text); failed += 1

	# V020-11: class summary section renders a selectable class row.
	var class_text: String = screen._class_lbl.text
	var class_ok: bool = "[url=class:soldier]" in class_text and "Class:" in class_text
	if class_ok:
		print("OK  class summary renders a selectable class row (V020-11)"); passed += 1
	else:
		print("FAIL class summary: %s" % class_text); failed += 1

	# Compact stats use the same effective-display total as More Info, including
	# combat-only Pair Up bonuses. The paired-unit button opens the hidden support
	# sheet and then lets the player return to the lead.
	var gs_pair := root.get_node_or_null("GameState")
	var reg_pair := root.get_node_or_null("PairUpRegistry")
	var res_pair := root.get_node_or_null("PairUpBonusResolver")
	if gs_pair != null and reg_pair != null and res_pair != null:
		gs_pair.call("reset_map_state")
		reg_pair.call("clear")
		gs_pair.set("pair_up_enabled", true)
		var support_data := UnitData.new()
		support_data.unit_id = "details_support"
		support_data.unit_name = "Support Cavalier"
		support_data.class_id = "cavalier"
		support_data.hp = 20; support_data.max_hp = 20
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
		var compact_expected := "Str  [color=#61c454]%s[/color]" % ("%-3d" % expected_str)
		var compact_uses_pair: bool = compact_expected in screen._stats.text
		var pair_button_visible: bool = screen._btn_pair.visible \
			and screen._btn_pair.text == "View Support"
		screen._on_pair_button_pressed()
		var opened_support: bool = "Support Cavalier" in screen._title.text \
			and screen._btn_pair.visible and screen._btn_pair.text == "View Lead"
		screen._on_pair_button_pressed()
		var returned_to_lead: bool = "Test Knight" in screen._title.text
		if compact_uses_pair and pair_button_visible and opened_support and returned_to_lead:
			print("OK  compact stats include Pair Up effective values and paired-unit button swaps sheets")
			passed += 1
		else:
			print("FAIL pair sheet: compact=%s button=%s support=%s return=%s stats=%s title=%s" % [
				compact_uses_pair, pair_button_visible, opened_support, returned_to_lead,
				screen._stats.text, screen._title.text])
			failed += 1
		reg_pair.call("clear")
		gs_pair.call("reset_map_state")
		support_unit.queue_free()
	else:
		print("SKIP compact Pair Up stat / paired-unit button test (autoload missing)")

	# WEXP panel: track rows are also [url=wexp:...] links so they open
	# More Info; unavailable tracks stay dimmed but selectable.
	var wexp_text: String = screen._wexp.text
	if "[url=wexp:lance]Lance  D  130 / 200 to C[/url]" in wexp_text \
			and "[url=wexp:axe][color=#9a9aa6]Axe  E  50 / 100 to D (Unavailable)[/color][/url]" in wexp_text:
		print("OK  WEXP panel rows are selectable, unavailable tracks dimmed"); passed += 1
	else:
		print("FAIL WEXP panel: %s" % wexp_text); failed += 1

	# Side panel starts in the hint state — nothing selected yet.
	if screen._info_hint.visible and screen._info_desc.text == "" \
			and screen._info_mods.text == "":
		print("OK  side panel starts in the hint state"); passed += 1
	else:
		print("FAIL side panel initial state"); failed += 1

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
		and "Class base" in mods_text and "Soldier" in mods_text
		and "Class cap" in mods_text
		# Effective is shown and rendered green because the +2 tonic raises it.
		and "Effective" in mods_text and "11" in mods_text
		and "#5fd35f" in mods_text
		and "Growth 70%" in mods_text
		and "Fixed 35 / 100" in mods_text
		# The bonus row lists the source + signed delta.
		and "Bonuses:" in mods_text
		and "Tonic" in mods_text
		and "+2" in mods_text
	)
	if click_ok:
		print("OK  clicking a stat populates description + breakdown rows (green when boosted)"); passed += 1
	else:
		print("FAIL stat click: title=%s desc=%s mods=%s" % [screen._info_title.text, desc_text, mods_text])
		failed += 1

	# Click a debuffed stat -> effective renders red (net-negative), not green.
	screen._on_entry_clicked("stat:defense")
	var def_text: String = screen._info_mods.text
	if "#ff6b6b" in def_text and not ("#5fd35f" in def_text) and "poison" in def_text:
		print("OK  a net-debuffed stat renders the effective value red"); passed += 1
	else:
		print("FAIL debuff render: %s" % def_text); failed += 1

	# Click a stat with no active bonuses -> block shows the "none" notice plus
	# the decomposition, not an empty block, and is NOT green.
	screen._on_entry_clicked("stat:luck")
	var luck_text: String = screen._info_mods.text
	if "No active bonuses" in luck_text and "Class cap" in luck_text and not ("#5fd35f" in luck_text):
		print("OK  zero-bonus stats render the decomposition + 'none' notice, no green"); passed += 1
	else:
		print("FAIL zero-bonus render: %s" % luck_text); failed += 1

	# Non-stat entries (wexp here) get a description but no modifier rows.
	screen._on_entry_clicked("wexp:lance")
	if screen._info_title.text == "Lance" \
			and "Weapon experience" in screen._info_desc.text \
			and screen._info_mods.text == "":
		print("OK  wexp click renders generic description and no modifier rows")
		passed += 1
	else:
		print("FAIL wexp click: title=%s desc=%s mods=%s" % [screen._info_title.text, screen._info_desc.text, screen._info_mods.text])
		failed += 1

	# more_info cycling: invoke the cycle directly (input simulation is
	# out of scope for this headless test). First call after a manual click
	# advances to the next registered entry.
	var before_index: int = screen._current_index
	screen._cycle_more_info()
	var advanced: bool = screen._current_index != before_index \
		and screen._info_title.text != ""
	if advanced:
		print("OK  more_info cycle advances the side-panel selection"); passed += 1
	else:
		print("FAIL more_info cycle did not advance (idx %d -> %d)" % [before_index, screen._current_index])
		failed += 1

	# Cycle should wrap around — keep cycling once per entry and confirm we
	# loop back to the first entry without crashing.
	for _i in screen._entries.size() + 1:
		screen._cycle_more_info()
	if screen._current_index >= 0 and screen._current_index < screen._entries.size():
		print("OK  more_info cycle wraps around safely"); passed += 1
	else:
		print("FAIL more_info cycle index out of range: %d" % screen._current_index)
		failed += 1

	# V020-10: a weapon's More Info shows its full stat block, not generic text.
	var wpn_text: String = screen._weapon_info_text("iron_sword")
	var wpn_ok: bool = "Iron Sword" in wpn_text and "Mt 6" in wpn_text \
		and "Hit 85" in wpn_text and "Wt 7" in wpn_text \
		and "Uses 45" in wpn_text and "Sword" in wpn_text
	if wpn_ok:
		print("OK  weapon More Info renders the full stat block (V020-10)"); passed += 1
	else:
		print("FAIL weapon info: %s" % wpn_text); failed += 1

	# V020-10: directional selection steps backward and marks the selected row so
	# a d-pad / keyboard user can see the highlight move.
	screen._move_selection(-1)
	var marked: bool = false
	for lbl in screen._section_labels:
		if "▶" in lbl.text:
			marked = true
			break
	if marked and screen._info_title.text != "":
		print("OK  directional selection marks a row and previews it (V020-10)"); passed += 1
	else:
		print("FAIL directional selection produced no highlighted row"); failed += 1

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
		print("OK  _close() hides, emits closed, and clears local state"); passed += 1
	else:
		print("FAIL close state: visible=%s closed=%s unit=%s entries=%d idx=%d" \
			% [screen.visible, closed_seen[0], screen._unit, screen._entries.size(), screen._current_index])
		failed += 1

	# open() ignores a null unit without error.
	screen.open(null)
	if not screen.visible:
		print("OK  open(null) is a safe no-op"); passed += 1
	else:
		print("FAIL open(null) showed the page"); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
