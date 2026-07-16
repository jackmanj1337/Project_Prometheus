class_name CampaignStatusStore extends RefCounted
# Filesystem owner for portable status records. Package import remains separate:
# records are player state, never campaign-pack content.

const RecordScript = preload("res://scripts/resources/CampaignStatusRecord.gd")
const DEFAULT_ROOT := "user://campaign_status"

var storage_root: String
var last_errors: Array[String] = []


func _init(root_path: String = DEFAULT_ROOT) -> void:
	storage_root = root_path


func export_completion(
	target: Dictionary,
	mutable_state: MutableCampaignState,
	completion: Dictionary,
	counters: Dictionary,
	record_id: String = ""
) -> Dictionary:
	last_errors.clear()
	var record := RecordScript.new()
	record.author_id = String(target.get("author_id", ""))
	record.campaign_id = String(target.get("campaign_id", ""))
	record.campaign_version = String(target.get("campaign_version", "1.0.0"))
	record.created_at_utc = Time.get_datetime_string_from_system(true)
	record.completion = completion.duplicate(true)
	record.facts = mutable_state.carry_forward_facts.duplicate(true)
	record.counters = counters.duplicate(true)
	if record.author_id == "" or record.campaign_id == "":
		last_errors.append("Campaign status export requires author_id and campaign_id")
		return {}
	var seed := (
		"%s|%s|%s|%s"
		% [record.author_id, record.campaign_id, record.campaign_version, record.created_at_utc]
	)
	record.record_id = record_id if record_id != "" else _sha256(seed).substr(0, 24)
	var err := DirAccess.make_dir_recursive_absolute(storage_root)
	if err != OK and err != ERR_ALREADY_EXISTS:
		last_errors.append("Could not create campaign status directory")
		return {}
	var path := storage_root.path_join("%s.json" % _safe_id(record.record_id))
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		last_errors.append("Could not write campaign status record")
		return {}
	file.store_string(JSON.stringify(record.to_dict(), "  ", false) + "\n")
	file.close()
	if not _promote_with_rollback(temp, path):
		last_errors.append("Could not finalize campaign status record")
		return {}
	return {"path": path, "record": record.to_dict()}


static func _promote_with_rollback(temp: String, path: String) -> bool:
	var backup := path + ".bak"
	DirAccess.remove_absolute(backup)
	if FileAccess.file_exists(path) and DirAccess.rename_absolute(path, backup) != OK:
		DirAccess.remove_absolute(temp)
		return false
	if DirAccess.rename_absolute(temp, path) == OK:
		DirAccess.remove_absolute(backup)
		return true
	if FileAccess.file_exists(backup):
		DirAccess.rename_absolute(backup, path)
	DirAccess.remove_absolute(temp)
	return false


func scan_compatible(target: Dictionary) -> Array[Dictionary]:
	last_errors.clear()
	var matches: Array[Dictionary] = []
	var dir := DirAccess.open(storage_root)
	if dir == null:
		return matches
	var names := dir.get_files()
	names.sort()
	for name in names:
		if not name.ends_with(".json"):
			continue
		var loaded := load_record(storage_root.path_join(name))
		if not loaded.is_empty() and is_compatible(loaded["record"], target):
			matches.append(loaded)
	return matches


func load_record(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_errors.append("Could not open status record '%s'" % path)
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		last_errors.append("Status record is not valid JSON: %s" % json.get_error_message())
		return {}
	var errors: Array[String] = []
	var record := RecordScript.from_dict(json.data, errors)
	if record == null:
		last_errors.append_array(errors)
		return {}
	return {"path": path, "record": record.to_dict()}


func import_into(
	record_dict: Dictionary,
	target: Dictionary,
	state: MutableCampaignState,
	allow_manual_foreign: bool = false
) -> bool:
	var errors: Array[String] = []
	var record := RecordScript.from_dict(record_dict, errors)
	if record == null:
		last_errors.append_array(errors)
		return false
	if not allow_manual_foreign and not is_compatible(record.to_dict(), target):
		last_errors.append("Status record is not compatible with this campaign")
		return false
	state.carry_forward_facts = record.facts.duplicate(true)
	state.imported_record_ref = {
		"record_id": record.record_id,
		"author_id": record.author_id,
		"campaign_id": record.campaign_id,
		"campaign_version": record.campaign_version,
		"checksum": record.checksum,
	}
	return true


static func is_compatible(record: Dictionary, target: Dictionary) -> bool:
	if (
		String(record.get("author_id", "")) == String(target.get("author_id", ""))
		and String(record.get("campaign_id", "")) == String(target.get("campaign_id", ""))
	):
		return true  # same-campaign NG+
	var sources: Variant = target.get("compatible_status_sources", [])
	if not (sources is Array):
		return false
	for source in sources:
		if not (source is Dictionary):
			continue
		if (
			source.has("author_id")
			and String(source["author_id"]) != String(record.get("author_id", ""))
		):
			continue
		if (
			source.has("campaign_id")
			and String(source["campaign_id"]) != String(record.get("campaign_id", ""))
		):
			continue
		var versions: Variant = source.get("campaign_versions", [])
		if (
			versions is Array
			and not versions.is_empty()
			and not String(record.get("campaign_version", "")) in versions
		):
			continue
		return true
	return false


static func _safe_id(value: String) -> String:
	var out := ""
	for character in value:
		out += character if character.is_valid_identifier() or character.is_valid_int() else "_"
	return out


static func _sha256(text: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(text.to_utf8_buffer())
	return context.finish().hex_encode()
