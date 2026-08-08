class_name PackFeatureCoverage extends RefCounted
# Advisory checks for contradictions in a pack that declares authoring complete.
# These are implication checks, not quotas: omitting an optional feature is legal.

const MAGIC_TRACKS: Array[String] = ["elemental_magic", "light", "dark"]
const Constants = preload("res://scripts/shared/GameConstants.gd")


static func warnings(authoring_status: String, adapted) -> Array[String]:
	var result: Array[String] = []
	if authoring_status != "complete":
		return result
	_check_magic_projection(adapted, result)
	_check_skill_documents(adapted, result)
	_check_terrain_projection(adapted, result)
	_check_encounters(adapted, result)
	return result


static func _check_magic_projection(adapted, result: Array[String]) -> void:
	var implies_magic := false
	var has_magic_weapon := false
	for weapon in adapted.weapons.values():
		if weapon is WeaponData and weapon.wexp_track in MAGIC_TRACKS:
			implies_magic = true
			has_magic_weapon = has_magic_weapon or weapon.uses_mag
	for class_data in adapted.classes.values():
		if not class_data is ClassData:
			continue
		for family in class_data.allowed_weapon_families:
			if Constants.combat_family_to_wexp_track(family) in MAGIC_TRACKS:
				implies_magic = true
	if implies_magic and not has_magic_weapon:
		result.append("complete pack implies magic combat but has no weapon with uses_mag=true")


static func _check_skill_documents(adapted, result: Array[String]) -> void:
	var referenced: Dictionary = {}
	for roster in adapted.rosters.values():
		_collect_unit_skills(roster, referenced)
	for map in adapted.maps.values():
		if not map is MapData:
			continue
		var units: Array = []
		for placement in map.enemy_placements:
			if placement is Dictionary and placement.get("unit_data") is UnitData:
				units.append(placement["unit_data"])
		_collect_unit_skills(units, referenced)
	var missing: Array[String] = []
	for skill_id in referenced:
		if not adapted.skills.has(skill_id):
			missing.append(String(skill_id))
	missing.sort()
	if not missing.is_empty():
		result.append(
			"complete pack has unit skill references without documents: %s" % ", ".join(missing)
		)


static func _collect_unit_skills(units: Array, referenced: Dictionary) -> void:
	for unit in units:
		if not unit is UnitData:
			continue
		for skill_id in unit.skills + unit.earned_skills + unit.mastery_skills:
			if not skill_id.is_empty():
				referenced[skill_id] = true


static func _check_terrain_projection(adapted, result: Array[String]) -> void:
	if (
		not adapted.terrain.is_empty()
		and adapted.terrain_variants.is_empty()
		and adapted.assets.is_empty()
	):
		result.append(
			"complete pack defines terrain but has no terrain variants and no packaged assets"
		)


static func _check_encounters(adapted, result: Array[String]) -> void:
	if adapted.maps.is_empty():
		return
	var maps_without_enemies: Array[String] = []
	for map_id in adapted.maps:
		var map = adapted.maps[map_id]
		if map is MapData and map.enemy_placements.is_empty():
			maps_without_enemies.append(String(map_id))
	maps_without_enemies.sort()
	if not maps_without_enemies.is_empty():
		result.append(
			(
				"complete pack has map documents without enemy encounters: %s"
				% ", ".join(maps_without_enemies)
			)
		)
