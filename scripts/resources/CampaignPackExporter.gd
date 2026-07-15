class_name CampaignPackExporter extends RefCounted
# Deterministic pack export. The admitted set is derived from validated package
# data, never from an unrestricted recursive copy of the source directory.

const MANIFEST_PATH := "manifest.json"
const APPROVED_MEDIA_EXTENSIONS := ["png", "ogg", "wav", "ttf", "otf"]


class Result extends RefCounted:
	var exported := false
	var errors: Array[String] = []
	var repair_report: Array[Dictionary] = []
	var package_id := ""
	var package_version := ""
	var archive_path := ""
	var admitted_paths: Array[String] = []
	var preflight: CampaignArchivePreflight.Result


func export_zip(pack_root: String, archive_path: String,
		limits: CampaignArchivePreflight.Limits) -> Result:
	var result := Result.new()
	result.archive_path = archive_path
	if limits == null:
		result.errors.append("Campaign pack export requires explicit security limits")
		return result
	var root := pack_root.trim_suffix("/")
	var manifest_raw: Variant = _read_json(root.path_join(MANIFEST_PATH), result.errors)
	if manifest_raw == null:
		return result
	var manifest_errors: Array[String] = []
	var manifest: PackManifest = PackManifest.parse(manifest_raw, MANIFEST_PATH, manifest_errors)
	result.errors.append_array(manifest_errors)
	if manifest == null:
		return result
	result.package_id = manifest.id
	result.package_version = manifest.version

	var catalogue_errors: Array[String] = []
	var catalogue := Tier2Catalogue.load_campaign_pack(root, catalogue_errors)
	result.errors.append_array(catalogue_errors)
	if catalogue == null:
		return result

	var admitted: Array[String] = [MANIFEST_PATH, Tier2Catalogue.CATALOGUE_PATH]
	for entry in catalogue.entries:
		admitted.append(String(entry["path"]))
	_collect_approved_media(root.path_join("assets"), root, admitted, result.errors)
	if not result.errors.is_empty():
		return result
	admitted.sort()
	result.admitted_paths = admitted.duplicate()
	result.repair_report = _media_repair_report(root, admitted)

	var temporary := "%s.tmp-%d-%d" % [
		archive_path, Time.get_ticks_usec(), OS.get_process_id()]
	if DirAccess.make_dir_recursive_absolute(archive_path.get_base_dir()) != OK:
		result.errors.append("Cannot create campaign-pack export directory")
		return result
	if not _write_archive(root, manifest.id, admitted, temporary, result.errors):
		DirAccess.remove_absolute(temporary)
		return result
	result.preflight = CampaignArchivePreflight.inspect_zip(temporary, limits)
	if not result.preflight.valid:
		result.errors.append("Exported archive failed preflight")
		result.errors.append_array(result.preflight.errors)
		DirAccess.remove_absolute(temporary)
		return result
	if FileAccess.file_exists(archive_path):
		var remove_error := DirAccess.remove_absolute(archive_path)
		if remove_error != OK:
			result.errors.append("Cannot replace export destination: %s" % error_string(remove_error))
			DirAccess.remove_absolute(temporary)
			return result
	var rename_error := DirAccess.rename_absolute(temporary, archive_path)
	if rename_error != OK:
		result.errors.append("Cannot finalize campaign-pack export: %s" % error_string(rename_error))
		DirAccess.remove_absolute(temporary)
		return result
	result.exported = true
	return result


func _write_archive(root: String, package_id: String, admitted: Array[String],
		output: String, errors: Array[String]) -> bool:
	var packer := ZIPPacker.new()
	var open_error := packer.open(output, ZIPPacker.APPEND_CREATE)
	if open_error != OK:
		errors.append("Cannot create campaign-pack archive: %s" % error_string(open_error))
		return false
	for relative in admitted:
		var file := FileAccess.open(root.path_join(relative), FileAccess.READ)
		if file == null:
			errors.append("Cannot read admitted export file '%s'" % relative)
			break
		var entry_path := package_id + "/" + relative.replace("\\", "/")
		var start_error := packer.start_file(entry_path)
		if start_error != OK:
			errors.append("Cannot add export entry '%s': %s" % [relative, error_string(start_error)])
			break
		packer.write_file(file.get_buffer(file.get_length()))
		packer.close_file()
	packer.close()
	return errors.is_empty()


func _collect_approved_media(path: String, root: String,
		admitted: Array[String], errors: Array[String]) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		errors.append("Cannot inspect campaign-pack media directory")
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while not name.is_empty():
		var child := path.path_join(name)
		if directory.current_is_dir():
			_collect_approved_media(child, root, admitted, errors)
		else:
			var relative := child.trim_prefix(root + "/").replace("\\", "/")
			if relative.get_extension().to_lower() in APPROVED_MEDIA_EXTENSIONS:
				admitted.append(relative)
		name = directory.get_next()
	directory.list_dir_end()


func _media_repair_report(root: String,
		admitted: Array[String]) -> Array[Dictionary]:
	var resolver := AssetResolver.new(root)
	var groups := {
		"png": AssetResolver.HANDLER_TEXTURE,
		"ttf": AssetResolver.HANDLER_FONT,
		"otf": AssetResolver.HANDLER_FONT,
		"ogg": AssetResolver.HANDLER_OGG,
		"wav": AssetResolver.HANDLER_WAV,
	}
	for extension in groups:
		resolver.register_group(extension, groups[extension])
	for relative in admitted:
		var extension := relative.get_extension().to_lower()
		if relative.begins_with("assets/") and groups.has(extension):
			resolver.resolve(extension, relative)
	return resolver.repair_report()


static func _read_json(path: String, errors: Array[String]) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Cannot open required export JSON '%s'" % path)
		return null
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		errors.append("Invalid export JSON '%s': %s" % [path, json.get_error_message()])
		return null
	return json.data
