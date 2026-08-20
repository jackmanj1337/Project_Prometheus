extends Node

## Stable text-key table used by authoring systems before full localization lands.
## Tables are plain JSON dictionaries, so packs can add text without engine edits.
##
## Registered as the `TextDB` autoload so every availability surface can reach the
## shared table without threading one through each call site. That is deliberate: a
## reason string that no consumer can obtain renders as its own key, which is what
## every unmet reason did before this autoload existed. There is no `class_name` here
## precisely because the autoload owns that global name — construct the table
## directly with `preload("res://scripts/text/TextDB.gd").new()` in tests and tools,
## where autoloads are not live.

const MISSING_PREFIX := "#missing:"

## Engine-shipped fallback sentences for the built-in predicate vocabulary. Packs
## may add their own tables on top; authors override a single entry's wording with
## `presentation.override_text_key` rather than editing this file.
const ENGINE_TABLE := "res://engine_data/text/en/core.json"

var _entries: Dictionary = {}
var _warnings: Array[String] = []


func _ready() -> void:
	reload_engine_table()


# Idempotent on purpose: it clears first, so calling it twice reports no duplicate keys.
# Loading is not a one-shot event — a pack swap will want to rebuild the table, and a
# table that errors on its own reload would report the reload as corrupt data.
func reload_engine_table() -> void:
	clear()
	for error in load_json_table(ENGINE_TABLE):
		push_error(error)


func clear() -> void:
	_entries.clear()
	_warnings.clear()


func load_json_table(path: String) -> Array[String]:
	var errors: Array[String] = []
	if not FileAccess.file_exists(path):
		errors.append("TextDB: table does not exist: %s" % path)
		return errors
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		errors.append("TextDB: table must be a JSON object: %s" % path)
		return errors
	return add_table(parsed, path)


func add_table(table: Dictionary, source: String = "<memory>") -> Array[String]:
	var errors: Array[String] = []
	for raw_key in table:
		var key := String(raw_key).strip_edges()
		var value: Variant = table[raw_key]
		if key.is_empty():
			errors.append("TextDB: empty key in %s" % source)
		elif not value is String:
			errors.append("TextDB: '%s' in %s must be a string" % [key, source])
		elif _entries.has(key):
			errors.append("TextDB: duplicate key '%s' in %s" % [key, source])
		else:
			_entries[key] = value
	return errors


func has_key(key: String) -> bool:
	return _entries.has(key)


# Only ever place a `{placeholder}` for a param known to be a SCALAR. Substitution is
# str(), so a Dictionary or Array param stringifies as a GDScript literal and the player
# reads raw JSON on screen — the same defect as the prep rules summary (V070-10). This is
# why `req.compare` carries no placeholders: its params are nested formula objects.
func tr_key(key: String, params: Dictionary = {}) -> String:
	if not _entries.has(key):
		var warning := "TextDB: missing text key '%s'" % key
		if warning not in _warnings:
			_warnings.append(warning)
		return MISSING_PREFIX + key
	var rendered := String(_entries[key])
	for raw_name in params:
		rendered = rendered.replace("{%s}" % String(raw_name), str(params[raw_name]))
	return rendered


func validation_warnings() -> Array[String]:
	return _warnings.duplicate()
