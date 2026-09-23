extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_attack_preview_selector.gd
# Verifies the AttackPreview Phase 1 More Info selector (step 6 of the
# build order in [GDD-07-SCREENS-PANELS]):
#   - show_preview wraps each field in a [url=combat_field:side:key] link
#   - clicking an entry populates InfoTitle + InfoDescription from
#     MoreInfoContent.describe()
#   - the more_info cycle advances through entries in declaration order
#     (attacker first, defender second) and wraps around safely
#   - non-stat fields (name, hp, damage, hit, crit) all open a description
#     even when their authored copy is generic
#
# Screen-space repositioning is exercised by test_attack_preview_position.gd
# — this file focuses on selector state only.


# Tiny resolver stub used by the real ProjectionService so show_preview can pull
# a Dictionary without booting the real CombatResolver autoload.
class StubResolver:
	extends Node
	var preview_data: Dictionary = {}

	func preview_combat(_a: Node, _d: Node) -> Dictionary:
		return preview_data.duplicate(true)


# Minimal Node2D-shaped unit so AttackPreview's .data and (skipped) screen-
# position reads succeed without needing the real Unit class.
class StubUnit:
	extends Node2D
	var data = null
	var _weapon = null

	func get_equipped_weapon():
		return _weapon


func _init() -> void:
	print("=== AttackPreview Selector Test ===")
	var passed := 0
	var failed := 0

	# Install the CombatResolver stub before autoload registration completes so
	# ProjectionService's resolver lookup reaches this deterministic fixture.
	var resolver := StubResolver.new()
	resolver.name = "CombatResolver"
	resolver.preview_data = _make_preview_data()
	root.add_child(resolver)

	var packed := load("res://scenes/ui/AttackPreview.tscn")
	if packed == null:
		print("FAIL could not load AttackPreview.tscn")
		quit(1)
		return
	var preview: Control = packed.instantiate()
	root.add_child(preview)
	await process_frame  # let @onready vars resolve and signals wire

	var attacker := StubUnit.new()
	attacker.data = _make_unit_data("Hero", 24, 30)
	attacker._weapon = load("res://data/weapons/iron_sword.tres")
	root.add_child(attacker)

	var defender := StubUnit.new()
	defender.data = _make_unit_data("Brigand", 18, 28)  # no weapon → Unarmed
	root.add_child(defender)

	preview.show_preview(attacker, defender)
	await process_frame

	# ---- V021-14: forecast names each combatant's equipped weapon -------
	var weapon_ok: bool = (
		"Iron Sword" in preview._atk_weapon.text
		and preview._atk_weapon.size.y > 0.0
		and preview._def_weapon.text == "Unarmed"
		and preview._def_weapon.size.y > 0.0
	)
	if weapon_ok:
		print("OK  forecast names the equipped weapon with visible row height (V021-14/V023-04)")
		passed += 1
	else:
		print(
			(
				"FAIL V021-14 weapon names: atk=%s def=%s"
				% [preview._atk_weapon.text, preview._def_weapon.text]
			)
		)
		failed += 1
	var panel_size_ok: bool = (
		preview._panel.size.x >= 560.0
		and preview._panel.size.x < root.get_visible_rect().size.x
		and preview._panel.size.y >= 110.0
		and preview._panel.size.y < 400.0
	)
	if panel_size_ok:
		print("OK  preview panel sizes to its content instead of stretching across the screen")
		passed += 1
	else:
		print("FAIL preview panel size: %s" % str(preview._panel.size))
		failed += 1

	# ---- Rendered forecast rows must receive visible height -------------
	# Asked of the PANEL rather than listed here, because the interaction rows do not exist
	# until a forecast says how many there are — a hand-written list would silently stop
	# covering exactly the rows this check was added for.
	var forecast_rows: Array[RichTextLabel] = preview._all_forecast_rows()
	var visible_height_failures: Array[String] = []
	for label in forecast_rows:
		if label.text == "":
			continue
		if label.size.y <= 0.0:
			visible_height_failures.append("%s=%s" % [label.name, str(label.size)])
	if visible_height_failures.is_empty():
		print("OK  every non-empty forecast row receives visible height")
		passed += 1
	else:
		print("FAIL zero-height forecast rows: %s" % ", ".join(visible_height_failures))
		failed += 1

	# ---- Forecast columns must stay distinct and inside the panel -------
	var columns_ok: bool = (
		preview._attacker_box.size.x > 0.0
		and preview._defender_box.size.x > 0.0
		and preview._info_box.size.x > 0.0
		and (
			preview._attacker_box.position.x + preview._attacker_box.size.x
			<= preview._defender_box.position.x
		)
		and (
			preview._defender_box.position.x + preview._defender_box.size.x
			<= preview._info_box.position.x
		)
		and preview._info_box.position.x + preview._info_box.size.x <= preview._panel.size.x
	)
	if columns_ok:
		print("OK  attacker, defender, and info columns stay separated inside the panel")
		passed += 1
	else:
		print(
			(
				"FAIL column layout: atk=%s/%s def=%s/%s info=%s/%s panel=%s"
				% [
					str(preview._attacker_box.position),
					str(preview._attacker_box.size),
					str(preview._defender_box.position),
					str(preview._defender_box.size),
					str(preview._info_box.position),
					str(preview._info_box.size),
					str(preview._panel.size),
				]
			)
		)
		failed += 1

	# ---- Each visible field is wrapped in a [url=combat_field:...] link ----
	var atk_dmg_text: String = preview._atk_dmg.text
	var def_hit_text: String = preview._def_hit.text
	var atk_rows: Array = preview._interaction_rows(preview._atk_interactions)
	var atk_row_0: String = atk_rows[0].text if atk_rows.size() > 0 else ""
	var atk_row_1: String = atk_rows[1].text if atk_rows.size() > 1 else ""
	var links_ok: bool = (
		"[url=combat_field:atk:damage]Dmg  10×2[/url]" in atk_dmg_text
		and "[url=combat_field:def:hit]Hit  40%[/url]" in def_hit_text
		# ONE ROW PER AUTHORED RELATIONSHIP, each naming itself and carrying its numbers.
		and atk_rows.size() == 2
		and "[url=combat_field:atk:interaction.0]" in atk_row_0
		and "▲ Weapon Triangle" in atk_row_0
		and "+10 Hit, +2 Dmg" in atk_row_0
		and "[url=combat_field:atk:interaction.1]" in atk_row_1
		and "Effective" in atk_row_1
		# The author declared a colour on the second row and none on the first, so the first
		# takes the surface's mapping of `direction` and the second takes the author's.
		and ("[color=%s]" % preview.COLOR_ADVANTAGE) in atk_row_0
		and "[color=#eec84c]" in atk_row_1
	)
	if links_ok:
		print("OK  every field renders as a clickable [url=combat_field:...] link")
		passed += 1
	else:
		print(
			(
				"FAIL field link rendering: atk_dmg=%s def_hit=%s rows=%d row0=%s row1=%s"
				% [atk_dmg_text, def_hit_text, atk_rows.size(), atk_row_0, atk_row_1]
			)
		)
		failed += 1

	# A CAMPAIGN THAT AUTHORS NO INTERACTIONS SHOWS NO ROWS. The old panel had two fixed slots
	# and rendered "■ Neutral" in each, which was defensible while the engine owned the
	# triangle and is a fabrication now: there is no relationship to report as neutral. The
	# rows must also be GONE from the cycle, not merely blank — an entry a player can select
	# and read nothing from is worse than an absent one.
	var empty_data := _make_preview_data()
	empty_data["attacker_interactions"] = []
	empty_data["defender_interactions"] = []
	resolver.preview_data = empty_data
	preview.show_preview(attacker, defender)
	await process_frame
	var empty_keys: Array[String] = []
	for entry in preview._entries:
		empty_keys.append(String((entry as Dictionary)["key"]))
	var empty_ok: bool = (
		preview._interaction_rows(preview._atk_interactions).is_empty()
		and preview._interaction_rows(preview._def_interactions).is_empty()
		and not ("interaction.0" in empty_keys)
	)
	if empty_ok:
		print("OK  a pack authoring no interactions renders no rows and no cycle entries")
		passed += 1
	else:
		print(
			(
				"FAIL unauthored rows: atk=%d def=%d keys=%s"
				% [
					preview._interaction_rows(preview._atk_interactions).size(),
					preview._interaction_rows(preview._def_interactions).size(),
					str(empty_keys)
				]
			)
		)
		failed += 1

	# A row whose profile declared NO presentation renders from the generic fallback: the
	# glyph and colour the surface maps from `direction`, and a label the readout humanised.
	# This is the other half of "authored presentation OVER a generic fallback" — the fallback
	# has to be renderable, not just permitted.
	var generic_data := _make_preview_data()
	var generic_row := _make_row(
		"armour_bane", "Armour Bane", "vs_armour", "disadvantage", "-5 Hit", "", "", 0
	)
	generic_row["authored"] = false
	generic_data["attacker_interactions"] = [generic_row]
	resolver.preview_data = generic_data
	preview.show_preview(attacker, defender)
	await process_frame
	var generic_rows: Array = preview._interaction_rows(preview._atk_interactions)
	var generic_text: String = generic_rows[0].text if generic_rows.size() == 1 else ""
	var generic_ok: bool = (
		generic_rows.size() == 1
		and "Armour Bane" in generic_text
		and ("[color=%s]" % preview.COLOR_DISADVANTAGE) in generic_text
		and generic_rows[0].size.y > 0.0
	)
	if generic_ok:
		print("OK  an unauthored row renders from the generic direction fallback")
		passed += 1
	else:
		print("FAIL generic row: rows=%d text=%s" % [generic_rows.size(), generic_text])
		failed += 1

	# A LONG AUTHORED LABEL MUST NOT LOSE EITHER HALF OF THE ROW. A pack's label is text of any
	# length, unlike the fixed "▲ Advantage" this replaced, so the row wraps and takes its
	# height from its content instead of being pinned to one line. Clipping or ellipsising
	# would drop either the relationship's name or the numbers the player is comparing.
	var long_data := _make_preview_data()
	var long_row := _make_row(
		"ancient_enmity",
		"Ancient Enmity of the Sundered Houses",
		"vs_house",
		"advantage",
		"+10 Hit, +2 Dmg, ×3 Might",
		"▲",
		"",
		0
	)
	long_data["attacker_interactions"] = [long_row]
	resolver.preview_data = long_data
	preview.show_preview(attacker, defender)
	await process_frame
	var long_rows: Array = preview._interaction_rows(preview._atk_interactions)
	var long_label: RichTextLabel = long_rows[0] if long_rows.size() == 1 else null
	var long_ok: bool = (
		long_label != null
		and "Ancient Enmity of the Sundered Houses" in long_label.text
		and "×3 Might" in long_label.text
		and long_label.get_line_count() > 1
		and long_label.size.y >= long_label.get_content_height() - 0.5
		and preview._panel.size.y >= preview._panel.get_combined_minimum_size().y - 0.5
	)
	if long_ok:
		print("OK  a long authored label wraps to full height instead of clipping the row")
		passed += 1
	else:
		print(
			(
				"FAIL long label: rows=%d lines=%s size=%s content=%s panel=%s min=%s"
				% [
					long_rows.size(),
					str(long_label.get_line_count()) if long_label else "-",
					str(long_label.size) if long_label else "-",
					str(long_label.get_content_height()) if long_label else "-",
					str(preview._panel.size),
					str(preview._panel.get_combined_minimum_size()),
				]
			)
		)
		failed += 1

	resolver.preview_data = _make_preview_data()
	preview.show_preview(attacker, defender)
	await process_frame

	# ---- InfoBox starts in the hint state -------------------------------
	if (
		preview._info_hint.visible
		and preview._info_desc.text == ""
		and "Enter attacks." in preview._info_hint.text
	):
		print("OK  InfoBox starts in the hint state and labels Enter as attack")
		passed += 1
	else:
		print("FAIL InfoBox initial state")
		failed += 1

	# ---- Clicking a field populates the description -----------------------
	preview._on_entry_clicked("combat_field:atk:hit")
	var hit_ok: bool = (
		preview._info_title.text == "Hit Rate"
		and not preview._info_hint.visible
		and "land a single hit" in preview._info_desc.text
	)
	if hit_ok:
		print("OK  clicking atk:hit populates title + description")
		passed += 1
	else:
		print(
			(
				"FAIL atk:hit click: title=%s desc=%s"
				% [preview._info_title.text, preview._info_desc.text]
			)
		)
		failed += 1

	# ---- Clicking an interaction row shows the GENERATED description ----
	# The row's own detail, not a MoreInfoContent lookup: MoreInfoContent has no entry for an
	# authored relationship and must not grow one (`[ITR-6]`). The title is the profile's
	# label, so a pack renaming its relationship renames the panel heading with no code change.
	preview._on_entry_clicked("combat_field:atk:interaction.0")
	if (
		preview._info_title.text == "Weapon Triangle"
		and "matched: sword_vs_axe" in preview._info_desc.text
	):
		print("OK  an interaction row shows the description generated from its resolution")
		passed += 1
	else:
		print(
			(
				"FAIL interaction click: title=%s desc=%s"
				% [preview._info_title.text, preview._info_desc.text]
			)
		)
		failed += 1

	# ---- Cycle: first press goes to the first entry (atk:name) ---------
	# Reset by re-rendering — show_preview clears _current_index back to -1.
	preview.show_preview(attacker, defender)
	await process_frame
	preview._cycle_more_info()
	if preview._current_index == 0 and preview._info_title.text == "Attacker":
		print("OK  more_info cycle starts at the first entry")
		passed += 1
	else:
		print(
			"FAIL cycle start: idx=%d title=%s" % [preview._current_index, preview._info_title.text]
		)
		failed += 1

	# ---- Cycle: advancing past the last entry wraps to the first --------
	var total: int = preview._entries.size()
	for _i in total:
		preview._cycle_more_info()
	if preview._current_index == 0:
		print("OK  cycling one full loop returns to the first entry")
		passed += 1
	else:
		print("FAIL wrap: total=%d ended at idx=%d" % [total, preview._current_index])
		failed += 1

	# ---- Cycle visits every entry exactly once per loop -----------------
	preview.show_preview(attacker, defender)  # reset to -1
	await process_frame
	var seen := {}
	for _i in preview._entries.size():
		preview._cycle_more_info()
		var entry: Dictionary = preview._entries[preview._current_index]
		var sk := "%s:%s" % [entry["side"], entry["key"]]
		seen[sk] = int(seen.get(sk, 0)) + 1
	var visited_uniquely: bool = seen.size() == preview._entries.size()
	if visited_uniquely:
		print("OK  one full cycle visits every entry exactly once (%d entries)" % seen.size())
		passed += 1
	else:
		print(
			(
				"FAIL cycle visited %d unique entries, expected %d"
				% [seen.size(), preview._entries.size()]
			)
		)
		failed += 1

	# ---- The shared SelectionCursor drives selection (B6-INPUT adoption) -
	# _current_index is a mirror of _selector.index; clicking, cycling, and the
	# reset-on-show all flow through the cursor. Locks the refactor so a future
	# edit can't quietly reintroduce a private index.
	preview.show_preview(attacker, defender)
	await process_frame
	var cursor_start_ok: bool = preview._selector.index == -1 and preview._current_index == -1
	preview._cycle_more_info()
	var cursor_step_ok: bool = preview._selector.index == 0 and preview._current_index == 0
	preview._on_entry_clicked("combat_field:def:hp")
	var def_hp_idx: int = -1
	for i in preview._entries.size():
		var entry: Dictionary = preview._entries[i]
		if entry["side"] == "def" and entry["key"] == "hp":
			def_hp_idx = i
			break
	var cursor_click_ok: bool = (
		preview._selector.index == def_hp_idx and preview._current_index == def_hp_idx
	)
	if cursor_start_ok and cursor_step_ok and cursor_click_ok:
		print("OK  selection flows through the shared SelectionCursor")
		passed += 1
	else:
		print(
			(
				"FAIL cursor adoption: start=%s step=%s click=%s (sel=%d cur=%d def_hp=%d)"
				% [
					cursor_start_ok,
					cursor_step_ok,
					cursor_click_ok,
					preview._selector.index,
					preview._current_index,
					def_hp_idx
				]
			)
		)
		failed += 1

	# ---- No-counter layout keeps the visible defender row readable ------
	resolver.preview_data = _make_preview_data(false, true)
	preview.show_preview(attacker, defender)
	await process_frame
	# V026-04b: Hit/Crit render as plain dash rows (not blanks) when there is no
	# counter, so the two columns stay aligned. Plain text (no [url]) so the selector
	# cycle never lands on a rate that doesn't exist.
	var no_counter_ok: bool = (
		preview._def_dmg.text == "[url=combat_field:def:damage]No counter[/url]"
		and preview._def_dmg.size.y > 0.0
		and preview._def_hit.text == "Hit  —"
		and preview._def_hit.size.y > 0.0
		and not ("[url=" in preview._def_hit.text)
		and preview._def_crit.text == "Crit —"
		and preview._def_crit.size.y > 0.0
		and not ("[url=" in preview._def_crit.text)
		and preview._def_name.text.ends_with("  [Vantage]")
	)
	if no_counter_ok:
		print("OK  no-counter preview keeps the visible defender row readable")
		passed += 1
	else:
		print(
			(
				"FAIL no-counter layout: dmg=%s/%s hit=%s/%s crit=%s/%s name=%s"
				% [
					preview._def_dmg.text,
					str(preview._def_dmg.size),
					preview._def_hit.text,
					str(preview._def_hit.size),
					preview._def_crit.text,
					str(preview._def_crit.size),
					preview._def_name.text,
				]
			)
		)
		failed += 1

	# ---- Tallest preview renders every row and fits the panel -----------
	# Two authored relationships per side is the maximal layout this fixture builds, and the
	# row count is no longer fixed by the scene — it is however many the forecast returns.
	# Guards the fit_content=false + row-height refresh path for that case: every interaction
	# row must render with height, and the panel must be at least its own combined minimum so
	# no row is clipped. A dynamically created row left out of _all_forecast_rows is exactly
	# what this catches.
	# ---- No-counter Battle Speed note still shows the defender's speed --
	# Playtest v0.1.5.0 #8.3: the defender's Battle Speed must appear even when
	# it cannot counter (it was previously hidden with a bare "(no counter)").
	resolver.preview_data = _make_preview_data(false)
	preview.show_preview(attacker, defender)
	await process_frame
	var bs_note: String = preview._battle_speed_note()
	var bs_note_ok: bool = (
		"Attacker 9 vs Defender 3" in bs_note and "defender cannot counter" in bs_note
	)
	if bs_note_ok:
		print("OK  no-counter Battle Speed note still shows the defender's speed (#8.3)")
		passed += 1
	else:
		print("FAIL no-counter battle-speed note: %s" % bs_note)
		failed += 1

	resolver.preview_data = _make_preview_data(true, false, true)
	preview.show_preview(attacker, defender)
	await process_frame
	var tall_min: Vector2 = preview._panel.get_combined_minimum_size()
	var tall_atk: Array = preview._interaction_rows(preview._atk_interactions)
	var tall_def: Array = preview._interaction_rows(preview._def_interactions)
	var tall_ok: bool = tall_atk.size() == 2 and tall_def.size() == 2
	for row in tall_atk + tall_def:
		tall_ok = tall_ok and row.size.y > 0.0
	# The shipping v0.8.1 two-row case wrapped "Weapon Effectiveness  ×3 Might" over
	# three lines in a 150px column. The wider authored column keeps that exact row to one
	# line at the default UI scale, so the panel does not grow into the terrain card.
	for row in tall_def:
		tall_ok = tall_ok and row.get_line_count() == 1
	tall_ok = tall_ok and preview._panel.size.y >= tall_min.y - 0.5
	if tall_ok:
		print("OK  tallest preview renders every row and fits the panel")
		passed += 1
	else:
		var heights: Array[String] = []
		for row in tall_atk + tall_def:
			heights.append(str(row.size.y))
		print(
			(
				"FAIL tall preview clipped: panel=%s combined_min=%s atk=%d def=%d heights=%s"
				% [
					str(preview._panel.size),
					str(tall_min),
					tall_atk.size(),
					tall_def.size(),
					str(heights),
				]
			)
		)
		failed += 1

	# ---- Long names truncate to one line but stay full in More Info -----
	# A name wider than the forecast column must collapse to a single
	# ellipsised line in the row (no wrap, no silent clip), while the full
	# name remains readable by selecting the name entry.
	var long_name := "Sir Reginald the Unfathomably Verbose, Keeper of the Impossibly Long Title"
	attacker.data.unit_name = long_name
	resolver.preview_data = _make_preview_data()
	preview.show_preview(attacker, defender)
	await process_frame
	var row_text: String = preview._atk_name.text
	var trunc_ok: bool = (
		preview._atk_name.autowrap_mode == TextServer.AUTOWRAP_OFF
		and "…" in row_text
		and not ("Impossibly" in row_text)  # the overflowing tail is dropped
		and preview._atk_name.get_line_count() == 1
	)
	preview._on_entry_clicked("combat_field:atk:name")
	var info_ok: bool = long_name in preview._info_desc.text
	# A short name must pass through untouched — no spurious ellipsis.
	attacker.data.unit_name = "Hero"
	preview.show_preview(attacker, defender)
	await process_frame
	var short_ok: bool = not ("…" in preview._atk_name.text)
	if trunc_ok and info_ok and short_ok:
		print("OK  long names ellipsise in the row but show in full in More Info")
		passed += 1
	else:
		print(
			(
				"FAIL name truncation: trunc_ok=%s info_ok=%s short_ok=%s row=%s desc=%s"
				% [trunc_ok, info_ok, short_ok, row_text, preview._info_desc.text]
			)
		)
		failed += 1

	# ---- show_preview without setup() is a safe no-op for positioning ---
	# Re-render with no camera/grid injected; _reposition_for early-returns
	# and the panel stays visible without crashing.
	resolver.preview_data = _make_preview_data()
	preview._camera = null
	preview._grid = null
	preview._camera_ctrl = null
	preview.show_preview(attacker, defender)
	await process_frame
	if preview.visible:
		print("OK  show_preview is safe without camera injection")
		passed += 1
	else:
		print("FAIL show_preview without camera left preview hidden")
		failed += 1

	# A failed projection must invalidate the previous selector state instead of
	# leaving stale rows available through More Info navigation.
	resolver.free()
	preview.show_preview(attacker, defender)
	if preview._entries.is_empty() and preview._current_index == -1:
		print("OK  failed projection clears stale selector entries")
		passed += 1
	else:
		print(
			(
				"FAIL failed projection retained %d selector entries at index %d"
				% [preview._entries.size(), preview._current_index]
			)
		)
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _make_unit_data(unit_name: String, hp: int, max_hp: int):
	var d := UnitData.new()
	d.unit_name = unit_name
	d.hp = hp
	d.max_hp = max_hp
	return d


func _make_preview_data(
	can_counter: bool = true, defender_vantage: bool = false, defender_effective: bool = false
) -> Dictionary:
	return {
		"attacker_hit": 90,
		"attacker_damage": 10,
		"attacker_crit": 5,
		"attacker_attacks": 2,
		"attacker_battle_speed": 9,
		"defender_battle_speed": 3,
		"follow_up_threshold": 5,
		"can_counter": can_counter,
		"defender_hit": 40,
		"defender_damage": 6,
		"defender_crit": 0,
		"defender_attacks": 1,
		"attacker_weapon": null,
		"defender_weapon": null,
		"defender_vantage": defender_vantage,
		# The authored-interaction readout `[ITR-6]`. The attacker always carries TWO rows,
		# which is the case the two old fixed marker slots could just represent and the third
		# row is the case they could not; `defender_effective` adds a second defender row so
		# the tall-panel check still has a maximal layout to measure. A no-counter defender
		# gets NO rows, which is what the engine returns for a strike that never happens.
		"attacker_interactions":
		[
			_make_row(
				"weapon_triangle",
				"Weapon Triangle",
				"sword_vs_axe",
				"advantage",
				"+10 Hit, +2 Dmg",
				"\u25b2",
				"",
				10
			),
			_make_row(
				"weapon_effectiveness",
				"Effective",
				"effective_weapon",
				"advantage",
				"\u00d73 Might",
				"",
				"#eec84c",
				20
			),
		],
		"defender_interactions":
		(
			[]
			if not can_counter
			else (
				[
					_make_row(
						"weapon_triangle",
						"Weapon Triangle",
						"axe_vs_sword",
						"disadvantage",
						"-10 Hit, -2 Dmg",
						"\u25bc",
						"",
						10
					),
				]
				+ (
					[
						_make_row(
							"armour_bane",
							"Armour Bane",
							"vs_armour",
							"mixed",
							"\u00d72 Might, +5 Avoid (opponent)",
							"",
							"",
							20
						),
					]
					if defender_effective
					else []
				)
			)
		),
		"interaction_diagnostics": [],
	}


# One readout row in the shape CombatInteractionReadout.build returns. Written out here rather
# than built by the real module because this suite tests the PANEL: a stubbed resolver that
# shared the producer's code could not catch the panel reading a key the producer renamed.
func _make_row(
	profile_id: String,
	label: String,
	rule_id: String,
	direction: String,
	summary: String,
	glyph: String,
	color: String,
	display_order: int
) -> Dictionary:
	return {
		"profile_id": profile_id,
		"rule_ids": [rule_id],
		"label": label,
		"glyph": glyph,
		"color": color,
		"display_order": display_order,
		"authored": true,
		"terms": [],
		"summary": summary,
		"direction": direction,
		"detail": "%s \u2014 matched: %s." % [label, rule_id],
	}
