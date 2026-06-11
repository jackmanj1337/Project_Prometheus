extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_attack_preview_selector.gd
# Verifies the AttackPreview Phase 1 More Info selector (step 6 of the
# build order in AGENT/Docs/more_info_mode_plan_2026-05-24.md):
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


# Tiny resolver stub so show_preview can pull a Dictionary without booting
# the real CombatResolver autoload.
class StubResolver extends Node:
	var preview_data: Dictionary = {}

	func preview_combat(_a: Node, _d: Node) -> Dictionary:
		return preview_data.duplicate(true)


# Minimal Node2D-shaped unit so AttackPreview's .data and (skipped) screen-
# position reads succeed without needing the real Unit class.
class StubUnit extends Node2D:
	var data = null


func _init() -> void:
	print("=== AttackPreview Selector Test ===")
	var passed := 0
	var failed := 0

	# Install the CombatResolver stub before instantiating the preview so
	# show_preview's get_node_or_null("/root/CombatResolver") resolves it.
	var resolver := StubResolver.new()
	resolver.name = "CombatResolver"
	resolver.preview_data = _make_preview_data()
	root.add_child(resolver)

	var packed := load("res://scenes/ui/AttackPreview.tscn")
	if packed == null:
		print("FAIL could not load AttackPreview.tscn"); quit(1); return
	var preview: Control = packed.instantiate()
	root.add_child(preview)
	await process_frame  # let @onready vars resolve and signals wire

	var attacker := StubUnit.new()
	attacker.data = _make_unit_data("Hero", 24, 30)
	root.add_child(attacker)

	var defender := StubUnit.new()
	defender.data = _make_unit_data("Brigand", 18, 28)
	root.add_child(defender)

	preview.show_preview(attacker, defender)
	await process_frame
	var panel_size_ok: bool = preview._panel.size.x >= 560.0 \
		and preview._panel.size.x < root.get_visible_rect().size.x \
		and preview._panel.size.y >= 110.0 \
		and preview._panel.size.y < 400.0
	if panel_size_ok:
		print("OK  preview panel sizes to its content instead of stretching across the screen")
		passed += 1
	else:
		print("FAIL preview panel size: %s" % str(preview._panel.size))
		failed += 1

	# ---- Rendered forecast rows must receive visible height -------------
	var forecast_rows: Array[RichTextLabel] = [
		preview._atk_name, preview._atk_hp, preview._atk_dmg, preview._atk_hit,
		preview._atk_crit, preview._atk_triangle, preview._atk_effective,
		preview._def_name, preview._def_hp, preview._def_dmg, preview._def_hit,
		preview._def_crit, preview._def_triangle,
	]
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
		and preview._attacker_box.position.x + preview._attacker_box.size.x <= preview._defender_box.position.x
		and preview._defender_box.position.x + preview._defender_box.size.x <= preview._info_box.position.x
		and preview._info_box.position.x + preview._info_box.size.x <= preview._panel.size.x
	)
	if columns_ok:
		print("OK  attacker, defender, and info columns stay separated inside the panel")
		passed += 1
	else:
		print("FAIL column layout: atk=%s/%s def=%s/%s info=%s/%s panel=%s" % [
			str(preview._attacker_box.position), str(preview._attacker_box.size),
			str(preview._defender_box.position), str(preview._defender_box.size),
			str(preview._info_box.position), str(preview._info_box.size),
			str(preview._panel.size),
		])
		failed += 1

	# ---- Each visible field is wrapped in a [url=combat_field:...] link ----
	var atk_dmg_text: String = preview._atk_dmg.text
	var def_hit_text: String = preview._def_hit.text
	var atk_tri_text: String = preview._atk_triangle.text
	var atk_eff_text: String = preview._atk_effective.text
	var links_ok: bool = (
		"[url=combat_field:atk:damage]Dmg  10×2[/url]" in atk_dmg_text
		and "[url=combat_field:def:hit]Hit  40%[/url]" in def_hit_text
		and "[url=combat_field:atk:triangle]" in atk_tri_text
		and "▲ Advantage" in atk_tri_text
		and "[url=combat_field:atk:effectiveness]" in atk_eff_text
		and "Effective ×3" in atk_eff_text
	)
	if links_ok:
		print("OK  every field renders as a clickable [url=combat_field:...] link"); passed += 1
	else:
		print("FAIL field link rendering: atk_dmg=%s def_hit=%s atk_tri=%s atk_eff=%s" \
			% [atk_dmg_text, def_hit_text, atk_tri_text, atk_eff_text])
		failed += 1

	# ---- InfoBox starts in the hint state -------------------------------
	if preview._info_hint.visible and preview._info_desc.text == "":
		print("OK  InfoBox starts in the hint state"); passed += 1
	else:
		print("FAIL InfoBox initial state"); failed += 1

	# ---- Clicking a field populates the description -----------------------
	preview._on_entry_clicked("combat_field:atk:hit")
	var hit_ok: bool = (
		preview._info_title.text == "Hit Rate"
		and not preview._info_hint.visible
		and "land a single hit" in preview._info_desc.text
	)
	if hit_ok:
		print("OK  clicking atk:hit populates title + description"); passed += 1
	else:
		print("FAIL atk:hit click: title=%s desc=%s" \
			% [preview._info_title.text, preview._info_desc.text])
		failed += 1

	# ---- Clicking the triangle marker resolves to the triangle copy -----
	preview._on_entry_clicked("combat_field:atk:triangle")
	if preview._info_title.text == "Weapon Triangle" \
			and "Weapon Triangle" in preview._info_desc.text:
		print("OK  triangle click pulls the weapon-triangle description"); passed += 1
	else:
		print("FAIL triangle click: title=%s desc=%s" \
			% [preview._info_title.text, preview._info_desc.text])
		failed += 1

	# ---- Cycle: first press goes to the first entry (atk:name) ---------
	# Reset by re-rendering — show_preview clears _current_index back to -1.
	preview.show_preview(attacker, defender)
	await process_frame
	preview._cycle_more_info()
	if preview._current_index == 0 \
			and preview._info_title.text == "Attacker":
		print("OK  more_info cycle starts at the first entry"); passed += 1
	else:
		print("FAIL cycle start: idx=%d title=%s" \
			% [preview._current_index, preview._info_title.text])
		failed += 1

	# ---- Cycle: advancing past the last entry wraps to the first --------
	var total: int = preview._entries.size()
	for _i in total:
		preview._cycle_more_info()
	if preview._current_index == 0:
		print("OK  cycling one full loop returns to the first entry"); passed += 1
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
		print("FAIL cycle visited %d unique entries, expected %d" \
			% [seen.size(), preview._entries.size()])
		failed += 1

	# ---- No-counter layout keeps the visible defender row readable ------
	resolver.preview_data = _make_preview_data(false, true)
	preview.show_preview(attacker, defender)
	await process_frame
	var no_counter_ok: bool = (
		preview._def_dmg.text == "[url=combat_field:def:damage]No counter[/url]"
		and preview._def_dmg.size.y > 0.0
		and preview._def_hit.text == ""
		and preview._def_hit.size.y <= 0.0
		and preview._def_crit.text == ""
		and preview._def_crit.size.y <= 0.0
		and preview._def_name.text.ends_with("  [Vantage]")
	)
	if no_counter_ok:
		print("OK  no-counter preview keeps the visible defender row readable")
		passed += 1
	else:
		print("FAIL no-counter layout: dmg=%s/%s hit=%s/%s crit=%s/%s name=%s" % [
			preview._def_dmg.text, str(preview._def_dmg.size),
			preview._def_hit.text, str(preview._def_hit.size),
			preview._def_crit.text, str(preview._def_crit.size),
			preview._def_name.text,
		])
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
		print("OK  show_preview is safe without camera injection"); passed += 1
	else:
		print("FAIL show_preview without camera left preview hidden")
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _make_unit_data(unit_name: String, hp: int, max_hp: int):
	var d := UnitData.new()
	d.unit_name = unit_name
	d.hp = hp
	d.max_hp = max_hp
	return d


func _make_preview_data(can_counter: bool = true, defender_vantage: bool = false) -> Dictionary:
	return {
		"attacker_hit": 90, "attacker_damage": 10, "attacker_crit": 5,
		"attacker_attacks": 2,
		"can_counter": can_counter,
		"defender_hit": 40, "defender_damage": 6, "defender_crit": 0,
		"defender_attacks": 1,
		"attacker_weapon": null, "defender_weapon": null,
		"defender_vantage": defender_vantage,
		"attacker_triangle": "advantage",
		"defender_triangle": "disadvantage",
		"attacker_effective": true,
		"defender_effective": false,
		"attacker_effectiveness_mult": 3.0,
		"defender_effectiveness_mult": 1.0,
	}
