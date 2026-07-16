class_name AssetResolver extends RefCounted
# Pack-scoped Tier-1 asset resolution. Loader handlers are engine primitives;
# asset groups and ids are authored registrations layered on top. Adding a new
# group that reuses an existing primitive therefore needs data, not a new match.

const HANDLER_TEXTURE := "raw_texture"
const HANDLER_FONT := "raw_font"
const HANDLER_OGG := "raw_ogg"
const HANDLER_WAV := "raw_wav"

var _pack_root: String
var _loaders: Dictionary = {}
var _groups: Dictionary = {}
var _assets: Dictionary = {}
var _report: Array[Dictionary] = []


func _init(pack_root: String = "") -> void:
	_pack_root = pack_root.trim_suffix("/")
	register_loader(HANDLER_TEXTURE, Callable(self, "_load_texture"))
	register_loader(HANDLER_FONT, Callable(self, "_load_font"))
	register_loader(HANDLER_OGG, Callable(self, "_load_ogg"))
	register_loader(HANDLER_WAV, Callable(self, "_load_wav"))


# Loader handlers are the small engine-facing boundary. Duplicate ids are
# rejected so one feature cannot silently replace another feature's primitive.
func register_loader(handler_id: String, loader: Callable) -> String:
	if handler_id.is_empty():
		return "AssetResolver: loader id cannot be empty"
	if not loader.is_valid():
		return "AssetResolver: loader '%s' is not callable" % handler_id
	if _loaders.has(handler_id):
		return "AssetResolver: duplicate loader '%s'" % handler_id
	_loaders[handler_id] = loader
	return ""


# A group registration is plain data: {loader, fallbacks}. Fallback entries are
# {group, id} references, so chains compose without a type switch in resolve().
func register_group(group_id: String, loader_id: String, fallbacks: Array = []) -> Array[String]:
	var errors: Array[String] = []
	if group_id.is_empty():
		errors.append("AssetResolver: group id cannot be empty")
	elif _groups.has(group_id):
		errors.append("AssetResolver: duplicate group '%s'" % group_id)
	if not _loaders.has(loader_id):
		errors.append("AssetResolver: group '%s' names unknown loader '%s'" % [group_id, loader_id])
	for fallback in fallbacks:
		if (
			not fallback is Dictionary
			or String(fallback.get("group", "")).is_empty()
			or String(fallback.get("id", "")).is_empty()
		):
			errors.append("AssetResolver: group '%s' has malformed fallback" % group_id)
	if errors.is_empty():
		_groups[group_id] = {
			"loader": loader_id,
			"fallbacks": fallbacks.duplicate(true),
		}
	return errors


func register_asset(group_id: String, asset_id: String, relative_path: String) -> String:
	if not _groups.has(group_id):
		return "AssetResolver: asset '%s' names unknown group '%s'" % [asset_id, group_id]
	if asset_id.is_empty() or relative_path.is_empty():
		return "AssetResolver: asset id and path cannot be empty"
	var key := _asset_key(group_id, asset_id)
	if _assets.has(key):
		return "AssetResolver: duplicate asset '%s/%s'" % [group_id, asset_id]
	if not _safe_relative_path(relative_path):
		return "AssetResolver: asset '%s/%s' escapes its campaign pack" % [group_id, asset_id]
	_assets[key] = relative_path
	return ""


# Resolves an authored id, or a safe pack-relative path escape hatch. Missing
# optional assets return null and append a structured repair-report entry.
func resolve(group_id: String, id_or_path: String) -> Resource:
	return _resolve(group_id, id_or_path, {})


func repair_report() -> Array[Dictionary]:
	return _report.duplicate(true)


func clear_report() -> void:
	_report.clear()


func _resolve(group_id: String, id_or_path: String, visited: Dictionary) -> Resource:
	if not _groups.has(group_id):
		_record(group_id, id_or_path, "unknown_group")
		return null
	var visit_key := _asset_key(group_id, id_or_path)
	if visited.has(visit_key):
		_record(group_id, id_or_path, "fallback_cycle")
		return null
	visited[visit_key] = true

	var relative_path: String = String(_assets.get(visit_key, id_or_path))
	if _safe_relative_path(relative_path):
		var group: Dictionary = _groups[group_id]
		var loader: Callable = _loaders[String(group["loader"])]
		var loaded: Variant = loader.call(_pack_root.path_join(relative_path))
		if loaded is Resource:
			return loaded
	else:
		_record(group_id, id_or_path, "path_outside_pack")

	_record(group_id, id_or_path, "missing_or_invalid")
	for fallback in _groups[group_id]["fallbacks"]:
		var resolved := _resolve(String(fallback["group"]), String(fallback["id"]), visited)
		if resolved != null:
			return resolved
	return null


func _record(group_id: String, asset_id: String, reason: String) -> void:
	_report.append({"group": group_id, "id": asset_id, "reason": reason})


static func _asset_key(group_id: String, asset_id: String) -> String:
	return "%s\n%s" % [group_id, asset_id]


static func _safe_relative_path(path: String) -> bool:
	if (
		path.is_empty()
		or path.is_absolute_path()
		or path.begins_with("user://")
		or path.begins_with("res://")
	):
		return false
	for part in path.replace("\\", "/").split("/"):
		if part == "..":
			return false
	return true


func _load_texture(path: String) -> Resource:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _load_font(path: String) -> Resource:
	if not FileAccess.file_exists(path):
		return null
	var font := FontFile.new()
	return font if font.load_dynamic_font(path) == OK else null


func _load_ogg(path: String) -> Resource:
	if not FileAccess.file_exists(path):
		return null
	return AudioStreamOggVorbis.load_from_file(path)


func _load_wav(path: String) -> Resource:
	if not FileAccess.file_exists(path):
		return null
	return AudioStreamWAV.load_from_file(path)
