extends Node
# [NOTE — M-1] class_name conflicts with the autoload singleton name in Godot 4.
# Loads all content resources at startup. All game systems query this singleton
# rather than loading resources on demand, so load errors surface immediately.

# Preloaded (not autoload-referenced) so _validate_cross_references can read the
# canonical IMPLEMENTED_EFFECT_IDS list even though ItemHandler is registered as
# an autoload AFTER DataManager in project.godot (so /root/ItemHandler doesn't
# exist yet during DataManager._ready). Const access only — no instance needed.
const ItemHandlerScript = preload("res://scripts/items/ItemHandler.gd")

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
	for err in collect_validation_errors(_classes, _weapons, _items, _skills):
		push_error(err)


# Pure validator: returns the list of cross-reference errors as strings.
# Split out from _ready (B6) so tests can drive it with fixture data without
# capturing push_error. _ready loops over the result and emits each via
# push_error so bad data still surfaces in release builds (assert is stripped).
static func collect_validation_errors(classes: Dictionary, weapons: Dictionary,
		items: Dictionary, skills: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	_check_class_refs(classes, skills, errors)
	_check_skill_refs(skills, errors)
	_check_weapon_refs(weapons, errors)
	_check_item_refs(items, classes, errors)
	return errors


static func _check_class_refs(classes: Dictionary, skills: Dictionary, errors: Array[String]) -> void:
	for cls in classes.values():
		# Every skill a class auto-grants at level-up must reference a real skill.
		for level in cls.skill_unlocks:
			var skill_id: String = String(cls.skill_unlocks[level])
			if not skills.has(skill_id):
				errors.append("DataManager: class '%s' skill_unlocks[%s] '%s' not found" \
					% [cls.id, str(level), skill_id])
		# Growth tables and caps must carry every expected stat key so a missing
		# entry can't silently zero a stat at level-up.
		_check_stat_dict(cls, "player_growth_rates", cls.player_growth_rates, errors)
		_check_stat_dict(cls, "enemy_growth_rates", cls.enemy_growth_rates, errors)
		_check_stat_dict(cls, "stat_caps", cls.stat_caps, errors)
		for target_id in cls.promotes_to:
			if not classes.has(String(target_id)):
				errors.append("DataManager: class '%s' promotes_to '%s' not found" % [cls.id, String(target_id)])
		for source_id in cls.promotes_from:
			if not classes.has(String(source_id)):
				errors.append("DataManager: class '%s' promotes_from '%s' not found" % [cls.id, String(source_id)])


# Warns if a class stat dictionary is non-empty but missing expected stat keys.
# Empty {} is allowed (e.g. a class with no enemy variant) and skipped.
static func _check_stat_dict(cls, field: String, dict: Dictionary, errors: Array[String]) -> void:
	if dict.is_empty():
		return
	for key in ClassData.STAT_KEYS:
		if not dict.has(key):
			errors.append("DataManager: class '%s' %s missing stat key '%s'" % [cls.id, field, key])


# Valid stat names skills may name in activation_chance_stat. Hoisted to module
# scope so it can be a static const (consts inside a static func can't capture
# instance state; this is pure data, so module scope is the right home).
const _VALID_STATS: Array[String] = ["strength", "magic", "skill", "speed", "luck",
									 "defense", "resistance", "hp"]


static func _check_skill_refs(skills: Dictionary, errors: Array[String]) -> void:
	for skill in skills.values():
		if skill.activation_chance_stat != "":
			if not (skill.activation_chance_stat in _VALID_STATS):
				errors.append("DataManager: skill '%s' activation_chance_stat '%s' is not a known stat" \
					% [skill.id, skill.activation_chance_stat])
		# Skills whose effect_params name a weapon_type (faires, breakers) must
		# reference a real weapon type so a typo like 'sord' fails loud.
		if skill.effect_params.has("weapon_type"):
			var skl_wt: String = String(skill.effect_params["weapon_type"])
			if not (skl_wt in GameConstants.VALID_WEAPON_TYPES):
				errors.append("DataManager: skill '%s' effect_params.weapon_type '%s' is not a known weapon type" \
					% [skill.id, skl_wt])


static func _check_weapon_refs(weapons: Dictionary, errors: Array[String]) -> void:
	# Catches typos like effective_armored vs effective_armoured (the literal-string
	# match in CombatResolver._is_effective would silently never fire on a typo).
	for weapon in weapons.values():
		if not (weapon.weapon_type in GameConstants.VALID_WEAPON_TYPES):
			errors.append("DataManager: weapon '%s' weapon_type '%s' is not a known weapon type" \
				% [weapon.id, weapon.weapon_type])
		for tag in weapon.effect_tags:
			if not (tag in GameConstants.VALID_EFFECT_TAGS):
				errors.append("DataManager: weapon '%s' effect_tag '%s' is not a known tag" \
					% [weapon.id, tag])


static func _check_item_refs(items: Dictionary, classes: Dictionary, errors: Array[String]) -> void:
	# apply_item already push_warns and refuses to consume unknown effects at
	# runtime, but failing loud at boot beats discovering it the first time the
	# player drinks the item.
	var known_class_groups := _collect_class_groups(classes)
	for item in items.values():
		if not (item.effect_id in ItemHandlerScript.IMPLEMENTED_EFFECT_IDS):
			errors.append("DataManager: item '%s' effect_id '%s' is not implemented by ItemHandler" \
				% [item.id, item.effect_id])
		if item.effect_params.has("allowed_classes"):
			for class_id in item.effect_params["allowed_classes"]:
				if not classes.has(String(class_id)):
					errors.append("DataManager: item '%s' allowed_classes '%s' not found" % [
						item.id, String(class_id)])
		if item.effect_params.has("allowed_class_groups"):
			for group_id in item.effect_params["allowed_class_groups"]:
				if not known_class_groups.has(String(group_id)):
					errors.append("DataManager: item '%s' allowed_class_groups '%s' not found" % [
						item.id, String(group_id)])


static func _collect_class_groups(classes: Dictionary) -> Dictionary:
	var groups := {}
	for cls in classes.values():
		for group_id in cls.class_groups:
			groups[String(group_id)] = true
	return groups


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


func get_all_classes() -> Dictionary:
	return _classes


func validate_unit_data(unit: UnitData) -> Array[String]:
	return collect_unit_validation_errors([unit], _classes)


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


static func collect_unit_validation_errors(units: Array, classes: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for unit in units:
		if unit == null:
			continue
		if unit.class_id != "" and not classes.has(unit.class_id):
			errors.append("DataManager: unit '%s' class_id '%s' not found" % [
				unit.unit_id, unit.class_id])
		if unit.class_line_id != "":
			if not classes.has(unit.class_line_id):
				errors.append("DataManager: unit '%s' class_line_id '%s' not found" % [
					unit.unit_id, unit.class_line_id])
			else:
				var line_class: ClassData = classes[unit.class_line_id]
				if line_class.tier != 1:
					errors.append("DataManager: unit '%s' class_line_id '%s' must point to a tier-1 class" % [
						unit.unit_id, unit.class_line_id])
		for option_id in unit.reclass_options:
			if not classes.has(String(option_id)):
				errors.append("DataManager: unit '%s' reclass_options '%s' not found" % [
					unit.unit_id, String(option_id)])
				continue
			var option_class: ClassData = classes[String(option_id)]
			if option_class.tier != 1:
				errors.append("DataManager: unit '%s' reclass_options '%s' must point to a tier-1 class" % [
					unit.unit_id, String(option_id)])
	return errors
