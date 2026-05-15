extends Node
# [NOTE — M-1] class_name conflicts with the autoload singleton name in Godot 4.
# Loads all content resources at startup. All game systems query this singleton
# rather than loading resources on demand, so load errors surface immediately.

var _classes: Dictionary = {}
var _weapons: Dictionary = {}
var _items: Dictionary = {}
var _skills: Dictionary = {}

# Weapon triangle lives in GameConstants.WEAPON_TRIANGLE — single source of truth.


func _ready() -> void:
	_load_directory("res://data/classes/", _classes)
	_load_directory("res://data/weapons/", _weapons)
	_load_directory("res://data/items/", _items)
	_load_directory("res://data/skills/", _skills)
	for skill in _skills.values():
		skill.validate()
	_validate_cross_references()


# Validates id cross-references across all loaded catalogues.
# Called once in _ready — surfaces bad data at startup instead of mid-game.
func _validate_cross_references() -> void:
	# Class starting_skills must resolve to known skills.
	for cls in _classes.values():
		for skill_id in cls.starting_skills:
			assert(_skills.has(skill_id),
				"DataManager: class '%s' starting_skill '%s' not found" % [cls.id, skill_id])
		# promotes_to class ids are intentionally not validated — promoted classes are added in M7.
		# When promotion data lands, add: assert(_classes.has(c), ...) for c in cls.promotes_to

	# Skills: activation_chance_stat must be a known stat name if set.
	const VALID_STATS := ["strength", "magic", "skill", "speed", "luck",
						  "defense", "resistance", "hp"]
	for skill in _skills.values():
		if skill.activation_chance_stat != "":
			assert(skill.activation_chance_stat in VALID_STATS,
				"DataManager: skill '%s' activation_chance_stat '%s' is not a known stat" \
				% [skill.id, skill.activation_chance_stat])


func _load_directory(path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("DataManager: cannot open directory: " + path)
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if dir.current_is_dir():
			fname = dir.get_next()
			continue
		if fname.ends_with(".tres"):
			var res_path := path + fname
			var res := load(res_path)
			# All our content resources have a non-empty 'id' field; warn on others
			var rid: Variant = res.get("id") if res else null
			if rid != null and rid != "":
				target[rid] = res
			else:
				push_warning("DataManager: resource at %s has no 'id' field" % res_path)
		fname = dir.get_next()
	dir.list_dir_end()


# Named get_class_data (not get_class) to avoid conflict with Object.get_class() -> String
func get_class_data(id: String) -> ClassData:
	if not _classes.has(id):
		push_error("DataManager: unknown class id '%s'" % id)
		return null
	return _classes[id]


func get_weapon(id: String) -> WeaponData:
	if not _weapons.has(id):
		push_error("DataManager: unknown weapon id '%s'" % id)
		return null
	return _weapons[id]


func get_item(id: String) -> ItemData:
	if not _items.has(id):
		push_error("DataManager: unknown item id '%s'" % id)
		return null
	return _items[id]


func get_skill(id: String) -> SkillData:
	if not _skills.has(id):
		push_error("DataManager: unknown skill id '%s'" % id)
		return null
	return _skills[id]


# Returns "advantage", "disadvantage", or "neutral"
func get_weapon_triangle_result(attacker_type: String, defender_type: String) -> String:
	if GameConstants.WEAPON_TRIANGLE.has(attacker_type):
		var row: Dictionary = GameConstants.WEAPON_TRIANGLE[attacker_type]
		if row.has(defender_type):
			return row[defender_type]
	return "neutral"
