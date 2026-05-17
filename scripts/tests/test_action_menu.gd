extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_action_menu.gd
# Tests ActionMenu.show_for — the Attack / Staff / Item / Wait button-availability
# logic. Uses a stub grid (so the enemy / heal-target lists are fully controlled)
# and real weapon resources for the is_healing_staff() check.

var _unit_stub: GDScript
var _grid_stub: GDScript


# Builds a stub unit: get_equipped_weapon() returns `weapon`; data.inventory = `entries`.
func _mk_unit(weapon: Variant, entries: Array) -> Node:
	var d := UnitData.new()
	var inv: Array[InventoryEntry] = []
	for e in entries:
		inv.append(e)
	d.inventory = inv
	var u: Node = _unit_stub.new()
	u.set("data", d)
	u.set("_weapon", weapon)
	root.add_child(u)
	return u


# Builds a stub grid whose two query methods return exactly the given lists.
func _mk_grid(enemies: Array, heal_targets: Array) -> Node:
	var g: Node = _grid_stub.new()
	g.set("enemies", enemies)
	g.set("heal_targets", heal_targets)
	root.add_child(g)
	return g


# An InventoryEntry that is_item() and has_uses() → makes the Item button eligible.
func _usable_item() -> InventoryEntry:
	var e := InventoryEntry.new()
	e.entry_type = "item"
	e.item_id = "vulnerary"
	e.uses_remaining = 3
	return e


func _init() -> void:
	print("=== ActionMenu Test ===")
	var passed := 0
	var failed := 0

	_unit_stub = GDScript.new()
	_unit_stub.source_code = "extends Node\nvar data = null\nvar _weapon = null\nvar tile_position: Vector2i = Vector2i.ZERO\nfunc get_equipped_weapon(): return _weapon\n"
	_unit_stub.reload()
	_grid_stub = GDScript.new()
	_grid_stub.source_code = "extends Node\nvar enemies: Array = []\nvar heal_targets: Array = []\nfunc get_attackable_enemies_from_tile(_u, _t) -> Array: return enemies\nfunc get_healable_allies(_u) -> Array: return heal_targets\n"
	_grid_stub.reload()

	var sword = load("res://data/weapons/iron_sword.tres")
	var staff = load("res://data/weapons/heal_staff.tres")
	var dummy: Array = [null]   # a non-empty list — ActionMenu only checks .size()

	# Typed Node, not ActionMenu — the ActionMenu class_name is not in the headless
	# class cache (the project types its menu refs as Node for the same reason).
	var am: Node = load("res://scenes/ui/ActionMenu.tscn").instantiate()
	root.add_child(am)
	await process_frame

	# ---- Attack enabled: a weapon equipped + an enemy in range ----
	am.show_for(_mk_unit(sword, []), _mk_grid(dummy, []))
	if not am._btn_attack.disabled and am._focused_idx == 0:
		print("OK  Attack enabled (weapon + enemy in range); focus on Attack"); passed += 1
	else:
		print("FAIL Attack should be enabled and focused"); failed += 1

	# ---- Attack disabled: a weapon but no enemy in range ----
	am.show_for(_mk_unit(sword, []), _mk_grid([], []))
	if am._btn_attack.disabled:
		print("OK  Attack disabled when no enemy is in range"); passed += 1
	else:
		print("FAIL Attack should be disabled (no enemies)"); failed += 1

	# ---- Attack disabled: no weapon equipped, even with enemies present ----
	am.show_for(_mk_unit(null, []), _mk_grid(dummy, []))
	if am._btn_attack.disabled:
		print("OK  Attack disabled with no weapon equipped"); passed += 1
	else:
		print("FAIL Attack should be disabled (no weapon)"); failed += 1

	# ---- Staff enabled: a healing staff + a heal target in range ----
	am.show_for(_mk_unit(staff, []), _mk_grid([], dummy))
	if not am._btn_staff.disabled:
		print("OK  Staff enabled with a healing staff and a target in range"); passed += 1
	else:
		print("FAIL Staff should be enabled"); failed += 1

	# ---- Staff disabled: a non-staff weapon never offers Staff ----
	am.show_for(_mk_unit(sword, []), _mk_grid([], dummy))
	if am._btn_staff.disabled:
		print("OK  Staff disabled with a non-staff weapon"); passed += 1
	else:
		print("FAIL Staff should be disabled (sword)"); failed += 1

	# ---- Item enabled: inventory holds a usable item ----
	am.show_for(_mk_unit(sword, [_usable_item()]), _mk_grid([], []))
	if not am._btn_item.disabled:
		print("OK  Item enabled when the inventory holds a usable item"); passed += 1
	else:
		print("FAIL Item should be enabled"); failed += 1

	# ---- All else disabled: Item off, Wait still on, focus falls to Wait ----
	am.show_for(_mk_unit(null, []), _mk_grid([], []))
	if am._btn_item.disabled and not am._btn_wait.disabled and am._focused_idx == 3:
		print("OK  Item disabled / Wait always enabled / focus falls to Wait"); passed += 1
	else:
		print("FAIL Wait fallback: item=%s wait=%s focus=%d" % [
			am._btn_item.disabled, am._btn_wait.disabled, am._focused_idx])
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
