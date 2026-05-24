extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_unit_details_screen.gd
# Verifies UnitDetailsScreen.tscn instantiates, the nodes its script's @onready
# vars expect resolve, the opaque Dimmer exists, and open()/close drive
# visibility and populate the panel from a unit's data (#1).

func _init() -> void:
	print("=== UnitDetailsScreen Test ===")
	var passed := 0
	var failed := 0

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

	# Every node the script's @onready vars depend on must exist.
	var expected := [
		"Panel/VBox/TitleLabel",
		"Panel/VBox/StatsLabel",
		"Panel/VBox/InventoryLabel",
		"Panel/VBox/SkillsLabel",
		"Panel/VBox/WexpLabel",
		"Panel/VBox/BtnBack",
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
	d.weapon_wexp = {"lance": 130, "axe": 50}
	d.active_modifiers = [
		{"stat": "strength", "delta": 2, "source": "tonic", "duration": 1, "duration_type": "turn"},
		{"stat": "movement", "delta": 1, "source": "pair_up", "duration": -1, "duration_type": "combat"},
	]
	var stub_script := GDScript.new()
	stub_script.source_code = """
extends Node
const GameConstants = preload("res://scripts/shared/GameConstants.gd")
var data = null
func get_effective_stat(stat_name: String) -> int:
	var base = data.get(stat_name)
	var total: int = int(base) if base != null else 0
	for mod in data.active_modifiers:
		if String(mod.get("stat", "")) == stat_name:
			total += int(mod.get("delta", 0))
	return max(0, total)
func get_stored_weapon_rank(track: String) -> String:
	return GameConstants.weapon_rank_for_wexp(int(data.weapon_wexp.get(track, 0)))
func is_weapon_track_available(track: String) -> bool:
	return track == "lance"
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

	# Stats line reflects effective values and the breakdown includes base + mods.
	if "Str  11" in screen._stats.text and "Str  base 9; mods: tonic +2; total 11" in screen._stats.text \
			and "Mov  base 6; mods: pair_up +1; total 7" in screen._stats.text:
		print("OK  stats panel shows effective values plus base/modifier breakdown"); passed += 1
	else:
		print("FAIL stats panel: %s" % screen._stats.text); failed += 1

	if "Int  7" in screen._stats.text and "Weapon Ranks:" in screen._wexp.text \
			and "Lance  D  130 / 200 to C" in screen._wexp.text \
			and "Axe  E  50 / 100 to D" in screen._wexp.text \
			and "Unavailable" in screen._wexp.text:
		print("OK  WEXP panel shows rank progress and dims unavailable tracks")
		passed += 1
	else:
		print("FAIL WEXP panel: %s" % screen._wexp.text); failed += 1

	# _close() hides the page and emits `closed`.
	var closed_seen := [false]
	screen.closed.connect(func(): closed_seen[0] = true)
	screen._close()
	if not screen.visible and closed_seen[0]:
		print("OK  _close() hides the page and emits closed"); passed += 1
	else:
		print("FAIL close: visible=%s closed=%s" % [screen.visible, closed_seen[0]])
		failed += 1

	# open() ignores a null unit without error.
	screen.open(null)
	if not screen.visible:
		print("OK  open(null) is a safe no-op"); passed += 1
	else:
		print("FAIL open(null) showed the page"); failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
