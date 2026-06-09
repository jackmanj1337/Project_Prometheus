extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_snapshot_coverage.gd
# Verifies that _snapshot_unit_data covers all UnitData fields that can change during a map,
# and that _restore_unit_data correctly round-trips them.

# Fields intentionally excluded from the snapshot — either static identity fields that never
# change during a map, or fields not in scope until a later milestone.
const STATIC_FIELDS := [
	# Identity / config — set at unit creation, never written at runtime
	"unit_id", "unit_name", "ai_profile", "is_default_roster",
	# Not individually tracked in snapshot (not mutable in MVP maps)
	"movement", "constitution", "line_of_sight", "gold",
	# Personal growth rates — set at unit creation, never written at runtime
	"growth_rates", "reclass_options",
	"can_seize",
	# Laguz identity field — static in MVP
	"shift_profile_id",
]


func _init() -> void:
	print("=== Snapshot Coverage Test ===")
	var passed := 0
	var failed := 0

	# Access GameState via a scene-tree node so the absolute path resolves correctly.
	# Direct root.get_node_or_null("GameState") doesn't work from --script SceneTree context.
	var relay := Node.new()
	root.add_child(relay)
	await process_frame
	var gs := relay.get_node_or_null("/root/GameState")
	relay.queue_free()
	if gs == null:
		print("BAIL: GameState autoload missing — cannot run snapshot coverage test")
		quit(1)
		return

	var template := UnitData.new()
	var snap: Dictionary = gs.call("_snapshot_unit_data", template)
	var snap_keys: Array = snap.keys()

	# Walk script-defined properties (PROPERTY_USAGE_SCRIPT_VARIABLE filters out Godot internals)
	for prop in template.get_property_list():
		var pname: String = prop["name"]
		var pusage: int = prop.get("usage", 0)
		if not (pusage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if pname in STATIC_FIELDS:
			continue
		if pname in snap_keys:
			print("OK  covered: %s" % pname)
			passed += 1
		else:
			print("FAIL not in snapshot: %s" % pname)
			failed += 1

	# Verify no stale keys in the snapshot (would indicate a removed UnitData field)
	var all_prop_names: Array[String] = []
	for prop in template.get_property_list():
		all_prop_names.append(prop["name"])
	for key in snap_keys:
		if not (key in all_prop_names):
			print("FAIL snapshot has stale key missing from UnitData: %s" % key)
			failed += 1

	# Round-trip test: modified fields survive snapshot → restore intact
	var d_before := UnitData.new()
	d_before.class_id = "cavalier"
	d_before.hp = 13
	d_before.exp = 55
	d_before.internal_level = 24
	d_before.is_promoted = true
	d_before.class_line_id = "cavalier"
	d_before.weapon_wexp = {"lance": 130}
	d_before.is_incapacitated = true
	d_before.earned_skills = ["discipline", "outdoor_fighter"]
	d_before.active_modifiers = [{"stat": "strength", "delta": 2, "source": "test",
		"duration": 2, "duration_type": "turn"}]
	var snap2: Dictionary = gs.call("_snapshot_unit_data", d_before)
	var d_after := UnitData.new()
	gs.call("_restore_unit_data", d_after, snap2)
	if d_after.class_id == "cavalier" and d_after.hp == 13 and d_after.exp == 55 \
			and d_after.internal_level == 24 \
			and d_after.is_promoted == true and d_after.class_line_id == "cavalier" \
			and d_after.weapon_wexp == {"lance": 130} \
			and d_after.is_incapacitated == true \
			and d_after.active_modifiers.size() == 1 \
			and d_after.earned_skills == ["discipline", "outdoor_fighter"]:
		print("OK  restore round-trip: class, promotion, hp, exp, internal_level, weapon_wexp, earned_skills, incap, active_modifiers")
		passed += 1
	else:
		print("FAIL restore round-trip: class=%s promoted=%s line=%s hp=%d exp=%d internal=%d weapon_wexp=%s earned=%s incap=%s mods=%s" \
			% [d_after.class_id, d_after.is_promoted, d_after.class_line_id, d_after.hp,
			d_after.exp, d_after.internal_level, d_after.weapon_wexp, d_after.earned_skills, d_after.is_incapacitated,
			d_after.active_modifiers])
		failed += 1

	# A2: snapshot must deep-copy InventoryEntry resources, not share references.
	# Mutating an entry after snapshotting must not leak into the snapshot, and a
	# restore must hand back the original uses regardless of post-snapshot edits.
	var d_inv := UnitData.new()
	var lance_entry := InventoryEntry.make_weapon("iron_lance", 20)
	var vuln_entry := InventoryEntry.make_item("vulnerary", 3)
	d_inv.inventory = [lance_entry, vuln_entry]
	var snap3: Dictionary = gs.call("_snapshot_unit_data", d_inv)
	# Mutate the live entries the way combat / item use would.
	lance_entry.uses_remaining = 5
	d_inv.inventory.erase(vuln_entry)
	# The snapshot's entries must be untouched by those mutations.
	var snap_inv: Array = snap3["inventory"]
	if snap_inv.size() == 2 and snap_inv[0].uses_remaining == 20 \
			and snap_inv[1].uses_remaining == 3:
		print("OK  A2: snapshot deep-copies InventoryEntry (immune to live mutation)")
		passed += 1
	else:
		print("FAIL A2: snapshot leaked — size=%d uses=%s" \
			% [snap_inv.size(), str(snap_inv.map(func(e): return e.uses_remaining))])
		failed += 1
	# Restore must repopulate the live inventory with the original uses.
	gs.call("_restore_unit_data", d_inv, snap3)
	if d_inv.inventory.size() == 2 and d_inv.inventory[0].uses_remaining == 20 \
			and d_inv.inventory[1].uses_remaining == 3:
		print("OK  A2: restore reinstates original InventoryEntry uses")
		passed += 1
	else:
		print("FAIL A2: restore wrong — size=%d uses=%s" \
			% [d_inv.inventory.size(), str(d_inv.inventory.map(func(e): return e.uses_remaining))])
		failed += 1
	# A second restore from the same snapshot must be isolated from the first.
	d_inv.inventory[0].uses_remaining = 1
	gs.call("_restore_unit_data", d_inv, snap3)
	if d_inv.inventory[0].uses_remaining == 20:
		print("OK  A2: repeated restores stay isolated from each other")
		passed += 1
	else:
		print("FAIL A2: repeated restore aliased — uses=%d" % d_inv.inventory[0].uses_remaining)
		failed += 1

	# W3e: Retry after an in-map reclass must revert class_id, class_line_id,
	# is_promoted, level, internal_level, stats, equipped skills, and weapon_wexp.
	# Snapshot a level-5 Cavalier, mutate it as a tier-1→tier-1 reclass would,
	# then restore and verify every reclass-touched field is back to the original.
	var pre := UnitData.new()
	pre.class_id = "cavalier"
	pre.class_line_id = "cavalier"
	pre.level = 5
	pre.exp = 30
	pre.is_promoted = false
	pre.internal_level = 5
	pre.max_hp = 24
	pre.hp = 24
	pre.strength = 9
	pre.defense = 7
	pre.speed = 8
	pre.skill = 8
	pre.weapon_wexp = {"lance": 130, "sword": 0}
	pre.skills = ["discipline"]
	pre.earned_skills = ["discipline"]
	var pre_snap: Dictionary = gs.call("_snapshot_unit_data", pre)
	# Simulate a Second Seal reclass mid-map.
	pre.class_id = "mercenary"
	pre.class_line_id = "mercenary"
	pre.level = 1
	pre.exp = 0
	pre.internal_level = 5
	pre.strength = 6
	pre.defense = 5
	pre.speed = 9
	pre.skill = 11
	pre.weapon_wexp = {"lance": 130, "sword": 100}
	pre.skills = ["armsthrift"]
	pre.earned_skills = ["discipline", "armsthrift"]
	gs.call("_restore_unit_data", pre, pre_snap)
	if pre.class_id == "cavalier" and pre.class_line_id == "cavalier" \
			and not pre.is_promoted and pre.level == 5 and pre.internal_level == 5 \
			and pre.exp == 30 and pre.strength == 9 and pre.defense == 7 \
			and pre.speed == 8 and pre.skill == 8 \
			and pre.weapon_wexp == {"lance": 130, "sword": 0} \
			and pre.skills == ["discipline"] \
			and pre.earned_skills == ["discipline"]:
		print("OK  W3e: Retry after a mid-map reclass restores class, level, stats, weapon_wexp, and equipped skills")
		passed += 1
	else:
		print("FAIL W3e reclass-restore: class=%s line=%s lvl=%d il=%d str=%d def=%d spd=%d skl=%d wexp=%s skills=%s earned=%s" % [
			pre.class_id, pre.class_line_id, pre.level, pre.internal_level,
			pre.strength, pre.defense, pre.speed, pre.skill,
			pre.weapon_wexp, pre.skills, pre.earned_skills])
		failed += 1

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
