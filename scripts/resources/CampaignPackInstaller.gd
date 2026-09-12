class_name CampaignPackInstaller extends RefCounted
# Transactional campaign-pack storage. Installation is deliberately inert: it
# only moves validated bytes and never selects content or writes campaign state.
#
# A release is promoted to installed/<id>/<version>/<fingerprint>/, so two builds
# published under one version number coexist and are told apart by their content —
# see the layout note in CampaignPackRegistry.gd. "Already installed" therefore means
# the same CONTENT is already there, not merely the same version number; installing a
# different build beside an existing one is the supported case, and it is the thing
# whose absence made a v0.7.17 backup unrestorable.

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
	var content_fingerprint := ""
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
		_record_install(result)
		return result
	if _storage_root.is_empty():
		result.errors.append("Campaign pack storage root cannot be empty")
		_record_install(result)
		return result

	var staging_parent := _unique_staging_path()
	var staged_pack := staging_parent.path_join(preflight.package_root)
	if DirAccess.make_dir_recursive_absolute(staged_pack) != OK:
		result.errors.append("Cannot create campaign-pack staging directory")
		_record_install(result)
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
		_cleanup_empty_storage_parents(result.package_id, result.package_version)
	_record_install(result)
	return result


func _record_install(result: Result) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var diagnostics := tree.root.get_node_or_null("DiagnosticsLog") if tree != null else null
	if diagnostics == null or not diagnostics.has_method("record"):
		return
	var fields := {
		"outcome": "completed" if result.installed else "refused",
		"package":
		{
			"package_id": result.package_id,
			"package_version": result.package_version,
			# Part of the identity, so it belongs in the record. Without it a reader
			# following one package through install and activate cannot tell two builds
			# of a version apart — which is exactly the read V0717-01 needed and could
			# not make.
			"content_fingerprint": result.content_fingerprint,
		},
		"installed_path": result.installed_path,
	}
	# The fingerprint is in the dedupe key, not only in the fields. Consecutive records
	# sharing a key collapse into one line with a repeat count, so two builds of one
	# version installed back to back — which is precisely the restore this identity
	# exists to allow — would otherwise be written once, under the FIRST build's
	# fingerprint. That is the read V0717-08 was opened to make possible.
	var key := (
		"install:%s:%s:%s" % [result.package_id, result.package_version, result.content_fingerprint]
	)
	if not result.errors.is_empty():
		fields["reason_code"] = result.errors[0]
	diagnostics.record(&"pack", &"install", fields, key)


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
	var catalogue := Tier2Catalogue.load_campaign_pack(staged_pack, catalogue_errors)
	result.errors.append_array(catalogue_errors)
	if not result.errors.is_empty():
		return
	# Taken from the STAGED catalogue rather than from the preflight result: the bytes
	# about to be promoted are what the installed identity has to describe, and they are
	# the ones in hand here.
	result.content_fingerprint = catalogue.content_fingerprint()
	var documents := {}
	for entry in catalogue.entries:
		var path := String(entry["path"])
		var document_errors: Array[String] = []
		var document: Variant = _read_json(staged_pack.path_join(path), document_errors)
		result.errors.append_array(document_errors)
		if document != null:
			documents[path] = document
	if not result.errors.is_empty():
		return
	if not CampaignArchivePreflight.has_playable_campaign(catalogue, documents):
		result.errors.append("no_playable_campaign")
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
	var version_root := CampaignPackRegistry.installed_path(
		_storage_root, result.package_id, result.package_version
	)
	var final_path := CampaignPackRegistry.build_path(
		_storage_root, result.package_id, result.package_version, result.content_fingerprint
	)
	if final_path.is_empty():
		result.errors.append("Campaign pack content fingerprint cannot name an installed identity")
		return false
	result.installed_path = final_path

	# "Already installed" now means the same CONTENT is already there. It is asked
	# before anything moves, and it is asked of BOTH layouts, so a refusal leaves the
	# library exactly as it was — the byte-preservation guarantee a duplicate install
	# has always carried.
	var unversioned := version_root.path_join(MANIFEST_PATH)
	var unversioned_installed := FileAccess.file_exists(unversioned)
	var unversioned_fingerprint := (
		_installed_fingerprint(version_root) if unversioned_installed else ""
	)
	if (
		(unversioned_installed and unversioned_fingerprint == result.content_fingerprint)
		or DirAccess.dir_exists_absolute(final_path)
		or FileAccess.file_exists(final_path)
	):
		result.errors.append(
			(
				"Campaign pack '%s' version '%s' is already installed"
				% [result.package_id, result.package_version]
			)
		)
		return false

	if unversioned_installed:
		if not _relocate_unversioned_install(
			version_root, unversioned_fingerprint, staging_parent, result
		):
			return false
	if DirAccess.make_dir_recursive_absolute(version_root) != OK:
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


# A library written before the identity carried a fingerprint keeps its release
# directly at installed/<id>/<version>. That directory is now the CONTAINER for the
# builds published under that version number, so the release in it has to move down
# one level into its own fingerprint directory before anything can be installed
# beside it.
#
# This runs only when something is actually being installed here. Discovery reads the
# old shape unchanged, so a library that is merely being read is never rewritten.
func _relocate_unversioned_install(
	version_root: String, content_fingerprint: String, staging_parent: String, result: Result
) -> bool:
	var directory := CampaignPackRegistry.fingerprint_dir(content_fingerprint)
	if directory.is_empty():
		# Nothing here can say what is already installed, so nothing here can say the
		# move is safe. Refusing keeps the bytes where they are; moving them blind could
		# strand them under an identity that does not describe them.
		result.errors.append(
			(
				(
					"A campaign package is already installed at '%s' but could not be read, "
					+ "so a second build cannot be installed beside it"
				)
				% version_root
			)
		)
		return false
	# Parked inside this install's own staging directory, which the registry never
	# scans, so a half-finished move can never be discovered as a release. If the
	# process dies between the renames the bytes survive there and the library is
	# missing that build until they are put back by hand — losing them would be worse.
	var parked := staging_parent.path_join(".relocating")
	if DirAccess.dir_exists_absolute(parked):
		result.errors.append("Cannot prepare the installed campaign-pack identity directory")
		return false
	if DirAccess.rename_absolute(version_root, parked) != OK:
		result.errors.append("Cannot relocate the installed campaign pack to its own identity")
		return false
	if DirAccess.make_dir_recursive_absolute(version_root) != OK:
		DirAccess.rename_absolute(parked, version_root)
		result.errors.append("Cannot create installed campaign-pack identity directory")
		return false
	if DirAccess.rename_absolute(parked, version_root.path_join(directory)) != OK:
		DirAccess.remove_absolute(version_root)
		DirAccess.rename_absolute(parked, version_root)
		result.errors.append("Cannot relocate the installed campaign pack to its own identity")
		return false
	return true


# The content fingerprint of an installed tree, or "" when it cannot be read. Reading
# it costs a catalogue parse, so it is only asked for on the two paths that compare
# identities: refusing a duplicate, and relocating a pre-fingerprint release.
func _installed_fingerprint(pack_root: String) -> String:
	var errors: Array[String] = []
	var catalogue := Tier2Catalogue.load_campaign_pack(pack_root, errors)
	return "" if catalogue == null else catalogue.content_fingerprint()


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


# Only ever removes directories that are already empty — DirAccess.remove_absolute
# fails on a non-empty one — so a failed install cannot take a sibling build with it.
# The version level joined this walk when it became a container rather than a release.
func _cleanup_empty_storage_parents(package_id: String, package_version: String = "") -> void:
	if not package_id.is_empty() and not package_version.is_empty():
		DirAccess.remove_absolute(
			CampaignPackRegistry.installed_path(_storage_root, package_id, package_version)
		)
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
