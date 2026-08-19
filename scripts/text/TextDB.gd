class_name TextDB
extends Node

## Stable text-key table used by authoring systems before full localization lands.
## Tables are plain JSON dictionaries, so packs can add text without engine edits.

const MISSING_PREFIX := "#missing:"

var _entries: Dictionary = {}
var _warnings: Array[String] = []


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
