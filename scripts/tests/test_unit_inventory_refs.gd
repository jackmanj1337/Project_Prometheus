extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_unit_inventory_refs.gd
#
# Regression guard for the v0.1.4 "unknown weapon id 'iron_axe'" defect: four
# Fighter units referenced a weapon id that had no WeaponData on disk, so
# DataManager.get_weapon() push_error'd at runtime (11,829 times in one pass)
# rather than at load. This test walks every UnitData resource shipped under
# data/maps and data/roster and asserts each inventory weapon_id / item_id
# resolves in DataManager — catching this whole class of dangling reference
# before it reaches a build.

# Directories whose UnitData resources must reference only loaded content.
const SCAN_ROOTS := ["res://data/maps", "res://data/roster"]


func _init() -> void:
	print("=== Unit Inventory Refs Test ===")
	var passed := 0
	var failed := 0

	# Boot DataManager exactly like test_data_manager.gd: entering the tree runs
	# _ready, which loads every content catalogue from its manifest.
	var dm: Node = load("res://scripts/autoloads/DataManager.gd").new()
	dm.name = "DataManager"
	root.add_child(dm)
	await process_frame

	# Collect every .tres under the scan roots, then keep only UnitData ones.
	var unit_paths: Array[String] = []
	for r in SCAN_ROOTS:
		_collect_tres(r, unit_paths)
	unit_paths.sort()

	var checked_units := 0
	var dangling: Array[String] = []
	for path in unit_paths:
		var res = load(path)
		if not (res is UnitData):
			continue  # map data, faction defs, etc. — not a unit roster entry
		checked_units += 1
		for entry in res.inventory:
			if entry == null:
				continue
			if entry.is_weapon() and dm.get_weapon(entry.weapon_id) == null:
				dangling.append("%s -> weapon '%s'" % [path, entry.weapon_id])
			elif entry.is_item() and dm.get_item(entry.item_id) == null:
				dangling.append("%s -> item '%s'" % [path, entry.item_id])

	# Sanity: the scan must actually find units, or the test silently passes on
	# an empty set (e.g. a moved data dir) and stops guarding anything.
	if checked_units > 0:
		print("OK  scanned %d UnitData resources under %s" % [checked_units, SCAN_ROOTS]); passed += 1
	else:
		print("FAIL scan found 0 UnitData resources — scan roots wrong?"); failed += 1

	if dangling.is_empty():
		print("OK  every inventory weapon_id / item_id resolves in DataManager"); passed += 1
	else:
		print("FAIL %d dangling inventory reference(s):" % dangling.size())
		for d in dangling:
			print("       %s" % d)
		failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


# Depth-first walk collecting every .tres path. DirAccess is used directly (not
# the export manifests) because this is a dev-time test reading the source tree.
func _collect_tres(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name == "." or name == "..":
			name = dir.get_next()
			continue
		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			_collect_tres(full, out)
		elif name.ends_with(".tres"):
			out.append(full)
		name = dir.get_next()
	dir.list_dir_end()
