extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_data_manager.gd
# Tests DataManager: id-based lookups for the four content catalogues (loaded by
# _ready on add_child) and the weapon-triangle resolution.

func _init() -> void:
	print("=== DataManager Test ===")
	var passed := 0
	var failed := 0

	var dm: Node = load("res://scripts/autoloads/DataManager.gd").new()
	dm.name = "DataManager"
	root.add_child(dm)   # entering the tree runs _ready → loads every catalogue
	await process_frame

	# ---- get_weapon resolves a known weapon id ----
	var sword = dm.get_weapon("iron_sword")
	if sword != null and sword.id == "iron_sword":
		print("OK  get_weapon resolves a known weapon id"); passed += 1
	else:
		print("FAIL get_weapon(iron_sword)"); failed += 1

	# ---- get_weapon returns null for an unknown id (a push_error is expected) ----
	if dm.get_weapon("no_such_weapon") == null:
		print("OK  get_weapon returns null for an unknown id"); passed += 1
	else:
		print("FAIL get_weapon(unknown)"); failed += 1

	# ---- get_item / get_skill / get_class_data resolve known ids ----
	if dm.get_item("vulnerary") != null:
		print("OK  get_item resolves a known item id"); passed += 1
	else:
		print("FAIL get_item(vulnerary)"); failed += 1
	if dm.get_skill("vantage") != null:
		print("OK  get_skill resolves a known skill id"); passed += 1
	else:
		print("FAIL get_skill(vantage)"); failed += 1
	if dm.get_class_data("mercenary") != null:
		print("OK  get_class_data resolves a known class id"); passed += 1
	else:
		print("FAIL get_class_data(mercenary)"); failed += 1

	# ---- weapon triangle: sword beats axe, loses to lance, neutral vs sword ----
	var adv: bool = dm.get_weapon_triangle_result("sword", "axe") == "advantage"
	var dis: bool = dm.get_weapon_triangle_result("sword", "lance") == "disadvantage"
	var neu: bool = dm.get_weapon_triangle_result("sword", "sword") == "neutral"
	if adv and dis and neu:
		print("OK  weapon triangle: sword vs axe / lance / sword")
		passed += 1
	else:
		print("FAIL weapon triangle sword: adv=%s dis=%s neu=%s" % [adv, dis, neu])
		failed += 1

	# ---- weapon triangle: axe beats lance; an unknown type resolves to neutral ----
	var axe_adv: bool = dm.get_weapon_triangle_result("axe", "lance") == "advantage"
	var unknown: bool = dm.get_weapon_triangle_result("frying_pan", "sword") == "neutral"
	if axe_adv and unknown:
		print("OK  weapon triangle: axe beats lance; an unknown type → neutral"); passed += 1
	else:
		print("FAIL weapon triangle: axe_adv=%s unknown=%s" % [axe_adv, unknown])
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
