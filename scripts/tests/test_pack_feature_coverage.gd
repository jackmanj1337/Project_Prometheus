extends SceneTree

const Adapter = preload("res://scripts/resources/CampaignTier2RuntimeAdapter.gd")
const Coverage = preload("res://scripts/tools/PackFeatureCoverage.gd")


func _init() -> void:
	print("=== Pack Feature Coverage Test ===")
	var adapted = Adapter.Result.new()
	var mage := ClassData.new()
	mage.id = "mage"
	mage.allowed_weapon_families = ["fire"]
	adapted.classes[mage.id] = mage
	var tome := WeaponData.new()
	tome.id = "tome"
	tome.wexp_track = "elemental_magic"
	adapted.weapons[tome.id] = tome
	var unit := UnitData.new()
	unit.unit_id = "hero"
	unit.skills = ["vantage"]
	adapted.rosters["heroes"] = [unit]
	adapted.terrain["plain"] = {"id": "plain"}
	var map := MapData.new()
	map.id = "map_01"
	adapted.maps[map.id] = map

	var complete := Coverage.warnings("complete", adapted)
	var draft := Coverage.warnings("draft", adapted)
	var joined := "\n".join(complete)
	var expected_fragments := ["uses_mag=true", "vantage", "terrain variants", "enemy encounter"]
	var all_present := true
	for fragment in expected_fragments:
		all_present = all_present and fragment in joined
	if complete.size() == 4 and all_present and draft.is_empty():
		print("OK  complete contradictions warn while draft packs remain advisory-free")
	else:
		print("FAIL warning gate: complete=%s draft=%s" % [complete, draft])
		quit(1)
		return

	tome.uses_mag = true
	adapted.skills["vantage"] = SkillData.new()
	adapted.terrain_variants["plain_a"] = {"id": "plain_a"}
	var enemy := UnitData.new()
	enemy.unit_id = "enemy"
	map.enemy_placements = [{"unit_data": enemy}]
	var resolved := Coverage.warnings("complete", adapted)
	if resolved.is_empty():
		print("OK  exercising every implied feature clears all warnings")
		print("=== Results: 2 passed, 0 failed ===")
		quit(0)
	else:
		print("FAIL resolved feature coverage: %s" % [resolved])
		quit(1)
