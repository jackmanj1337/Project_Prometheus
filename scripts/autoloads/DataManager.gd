extends Node
# Loads all content resources at startup. All game systems query this singleton
# rather than loading resources on demand, so load errors surface immediately.

var _classes: Dictionary = {}
var _weapons: Dictionary = {}
var _items: Dictionary = {}
var _skills: Dictionary = {}

# Weapon triangle: [attacker_type][defender_type] -> "advantage"|"disadvantage"|"neutral"
# Only advantage/disadvantage pairs are listed; everything else is "neutral".
const _weapon_triangle: Dictionary = {
	"sword":   { "axe": "advantage",    "lance": "disadvantage" },
	"axe":     { "lance": "advantage",  "sword": "disadvantage" },
	"lance":   { "sword": "advantage",  "axe":   "disadvantage" },
	"dark":    { "fire":  "advantage",  "thunder": "advantage",  "wind": "advantage",  "light": "disadvantage" },
	"light":   { "dark":  "advantage",  "fire": "disadvantage",  "thunder": "disadvantage", "wind": "disadvantage" },
	"fire":    { "light": "advantage",  "dark": "disadvantage" },
	"thunder": { "light": "advantage",  "dark": "disadvantage" },
	"wind":    { "light": "advantage",  "dark": "disadvantage" },
}


func _ready() -> void:
	_load_directory("res://data/classes/", _classes)
	_load_directory("res://data/weapons/", _weapons)
	_load_directory("res://data/items/", _items)
	_load_directory("res://data/skills/", _skills)


func _load_directory(path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("DataManager: cannot open directory: " + path)
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
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
	if _weapon_triangle.has(attacker_type):
		var row: Dictionary = _weapon_triangle[attacker_type]
		if row.has(defender_type):
			return row[defender_type]
	return "neutral"
