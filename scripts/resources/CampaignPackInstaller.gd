class_name CampaignPackInstaller extends RefCounted
# Transactional campaign-pack storage. Installation is deliberately inert: it
# only moves validated bytes and never selects content or writes campaign state.

const MANIFEST_PATH := "manifest.json"
const STAGING_DIR := ".staging"
const INSTALLED_DIR := "installed"


class Result:
	extends RefCounted
	var installed := false
	var errors: Array[String] = []
	var repair_report: Array[Dictionary] = []
	var package_id := ""
	var package_version := ""
	var installed_path := ""


var _storage_root: String
var _fault_injector: Callable


func _init(storage_root: String, fault_injector: Callable = Callable()) -> void:
	_storage_root = storage_root.trim_suffix("/")
	_fault_injector = fault_injector


func install_zip(archive_path: String, preflight: CampaignArchivePreflight.Result) -> Result:
	var result := Result.new()
	if preflight == null or not preflight.valid:
		result.errors.append("Campaign pack installation requires a successful preflight")
		return result
	if _storage_root.is_empty():
		result.errors.append("Campaign pack storage root cannot be empty")
		return result

	var staging_parent := _unique_staging_path()
	var staged_pack := staging_parent.path_join(preflight.package_root)
	if DirAccess.make_dir_recursive_absolute(staged_pack) != OK:
		result.errors.append("Cannot create campaign-pack staging directory")
		return result

	var succeeded := false
	if _fault("extraction"):
		result.errors.append("Simulated campaign-pack extraction failure")
	elif not _extract_admitted(archive_path, preflight, staged_pack, result.errors):
		pass
	elif _fault("validation"):
		result.errors.append("Simulated campaign-pack validation failure")
	else:
		_validate_staged_tree(staged_pack, preflight, result)
		if result.errors.is_empty():
			succeeded = _promote(staging_parent, staged_pack, result)

	if not succeeded:
		_remove_tree(staging_parent)
		_cleanup_empty_storage_parents(result.package_id)
	return result


func _extract_admitted(
	archive_path: String,
	preflight: CampaignArchivePreflight.Result,
	staged_pack: String,
	errors: Array[String]
) -> bool:
	var reader := ZIPReader.new()
	var open_error := reader.open(archive_path)
	if open_error != OK:
		errors.append("Cannot reopen preflighted archive: %s" % error_string(open_error))
		return false
	var prefix := preflight.package_root + "/"
	for entry in preflight.entries:
		if entry.get("is_directory", false):
			continue
		var archive_path_entry := String(entry.get("path", ""))
		if not archive_path_entry.begins_with(prefix):
			errors.append("Preflight entry escaped the validated package root")
			break
		var relative := archive_path_entry.trim_prefix(prefix)
		var destination := staged_pack.path_join(relative)
		if DirAccess.make_dir_recursive_absolute(destination.get_base_dir()) != OK:
			errors.append("Cannot create staging parent for '%s'" % relative)
			break
		var payload := reader.read_file(archive_path_entry)
		if payload.size() != int(entry.get("uncompressed_size", -1)):
			errors.append("Archive entry changed or could not be extracted: '%s'" % relative)
			break
		var file := FileAccess.open(destination, FileAccess.WRITE)
		if file == null:
			errors.append("Cannot write staged archive entry '%s'" % relative)
			break
		file.store_buffer(payload)
	reader.close()
	return errors.is_empty()


func _validate_staged_tree(
	staged_pack: String, preflight: CampaignArchivePreflight.Result, result: Result
) -> void:
	var manifest_raw: Variant = _read_json(staged_pack.path_join(MANIFEST_PATH), result.errors)
	if manifest_raw == null:
		return
	var manifest_errors: Array[String] = []
	var manifest: PackManifest = PackManifest.parse(manifest_raw, MANIFEST_PATH, manifest_errors)
	result.errors.append_array(manifest_errors)
	if manifest == null:
		return
	result.package_id = manifest.id
	result.package_version = manifest.version
	if manifest.id != preflight.package_id or manifest.id != preflight.package_root:
		result.errors.append("Staged manifest identity differs from archive preflight")
	if not _safe_identity_component(manifest.version):
		result.errors.append(
			"PackManifest(%s): version is not safe for installed identity" % MANIFEST_PATH
		)

	var catalogue_errors: Array[String] = []
	Tier2Catalogue.load_campaign_pack(staged_pack, catalogue_errors)
	result.errors.append_array(catalogue_errors)
	if not result.errors.is_empty():
		return
	_validate_optional_media(staged_pack, preflight, result.repair_report)


func _validate_optional_media(
	staged_pack: String,
	preflight: CampaignArchivePreflight.Result,
	repair_report: Array[Dictionary]
) -> void:
	var resolver := AssetResolver.new(staged_pack)
	var groups := {
		"png": AssetResolver.HANDLER_TEXTURE,
		"ttf": AssetResolver.HANDLER_FONT,
		"otf": AssetResolver.HANDLER_FONT,
		"ogg": AssetResolver.HANDLER_OGG,
		"wav": AssetResolver.HANDLER_WAV,
	}
	for extension in groups:
		resolver.register_group(extension, groups[extension])
	var prefix := preflight.package_root + "/"
	for entry in preflight.entries:
		var archive_entry := String(entry.get("path", ""))
		if entry.get("is_directory", false) or not archive_entry.begins_with(prefix):
			continue
		var relative := archive_entry.trim_prefix(prefix)
		var extension := relative.get_extension().to_lower()
		if relative.begins_with("assets/") and groups.has(extension):
			resolver.resolve(extension, relative)
	repair_report.append_array(resolver.repair_report())


func _promote(staging_parent: String, staged_pack: String, result: Result) -> bool:
	var final_parent := _storage_root.path_join(INSTALLED_DIR).path_join(result.package_id)
	var final_path := final_parent.path_join(result.package_version)
	result.installed_path = final_path
	if DirAccess.dir_exists_absolute(final_path) or FileAccess.file_exists(final_path):
		result.errors.append(
			(
				"Campaign pack '%s' version '%s' is already installed"
				% [result.package_id, result.package_version]
			)
		)
		return false
	if DirAccess.make_dir_recursive_absolute(final_parent) != OK:
		result.errors.append("Cannot create installed campaign-pack identity directory")
		return false
	if _fault("promotion"):
		result.errors.append("Simulated campaign-pack promotion failure")
		return false
	var rename_error := DirAccess.rename_absolute(staged_pack, final_path)
	if rename_error != OK:
		result.errors.append(
			"Cannot atomically promote staged campaign pack: %s" % error_string(rename_error)
		)
		return false
	_remove_tree(staging_parent)
	result.installed = true
	return true


func _unique_staging_path() -> String:
	var root := _storage_root.path_join(STAGING_DIR)
	var nonce := "%d-%d" % [Time.get_ticks_usec(), OS.get_process_id()]
	var candidate := root.path_join(nonce)
	var suffix := 0
	while DirAccess.dir_exists_absolute(candidate) or FileAccess.file_exists(candidate):
		suffix += 1
		candidate = root.path_join("%s-%d" % [nonce, suffix])
	return candidate


func _fault(stage: String) -> bool:
	return _fault_injector.is_valid() and bool(_fault_injector.call(stage))


func _cleanup_empty_storage_parents(package_id: String) -> void:
	if not package_id.is_empty():
		DirAccess.remove_absolute(_storage_root.path_join(INSTALLED_DIR).path_join(package_id))
	DirAccess.remove_absolute(_storage_root.path_join(INSTALLED_DIR))
	DirAccess.remove_absolute(_storage_root.path_join(STAGING_DIR))


static func _safe_identity_component(value: String) -> bool:
	if value.is_empty():
		return false
	for character in value:
		if not character in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-":
			return false
	return value != "." and value != ".."


static func _read_json(path: String, errors: Array[String]) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Cannot open staged JSON '%s'" % path)
		return null
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		errors.append("Invalid staged JSON '%s': %s" % [path, json.get_error_message()])
		return null
	return json.data


static func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := path.path_join(name)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		name = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)
