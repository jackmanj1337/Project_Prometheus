extends SceneTree
# Stage the v0.7.6 save-migration fixture pair from the tracked two-map skirmish
# pack, with their migration identity COMPUTED from the staged catalogues.
#
#   godot --headless --script res://scripts/tools/build_migration_fixtures.gd -- \
#       --out builds/v0.7.6-fixtures \
#       --archives-out builds/packs
#
# WHY THIS EXISTS. The v1/v2 fixtures the tester bundle ships were hand-built and
# lived only under the gitignored builds/ tree, so nothing in the repository could
# rebuild them and nothing checked them. Their v2 manifest was written before
# save_migrations grew its full identity contract and never caught up: it declared
# a source version and a destination version and none of the six identity fields
# that make an edge verifiable. `CampaignPackRegistry` then rejected the pack, and
# the v0.7.13 round lost its entire migration section to a fixture defect.
#
# Identity is derived here rather than typed: the content fingerprint is read back
# from the staged catalogue through the same `Tier2Catalogue.content_fingerprint()`
# the registry compares against, so a fixture whose content changes cannot keep a
# stale declaration.
#
# With --archives-out, this tool invokes export_pack_archive.gd for each staged
# directory. That exporter continues to own preflight and the real install check;
# this tool only makes rebuilding the exact tester-facing pair one command instead
# of leaving hand-built ZIPs under gitignored builds/.

const SOURCE_PACK := "res://test_fixtures/campaign_packs/two_map_skirmish"
const FIXTURE_ID := "v076_migration_fixture"
const SOURCE_VERSION := "1.0.0"
const DESTINATION_VERSION := "2.0.0"
const ALIAS_KINDS: Array[String] = [
	"campaign", "campaign_node", "map", "unit", "item", "class", "skill"
]


func _init() -> void:
	var args := _parse_args()
	var out_root: String = args.get("out", "")
	if out_root.is_empty():
		printerr("usage: --out <directory> [--archives-out <directory>]")
		quit(2)
		return

	var staged := {}
	for version: String in [SOURCE_VERSION, DESTINATION_VERSION]:
		var directory := out_root.path_join("src-v%s" % version.left(1)).path_join(FIXTURE_ID)
		if not _stage(directory, version):
			quit(1)
			return
		staged[version] = directory

	var source_identity := _catalogue_identity(staged[SOURCE_VERSION])
	var destination_identity := _catalogue_identity(staged[DESTINATION_VERSION])
	if source_identity.is_empty() or destination_identity.is_empty():
		quit(1)
		return

	var aliases := {}
	for kind in ALIAS_KINDS:
		aliases[kind] = {}
	var declaration := {
		"source_package_id": FIXTURE_ID,
		"source_package_version": SOURCE_VERSION,
		"source_content_schema_version": source_identity["schema"],
		"source_content_fingerprint": source_identity["fingerprint"],
		"destination_package_id": FIXTURE_ID,
		"destination_package_version": DESTINATION_VERSION,
		"destination_content_schema_version": destination_identity["schema"],
		"destination_content_fingerprint": destination_identity["fingerprint"],
		"aliases": aliases,
	}
	var manifest := _read_json(String(staged[DESTINATION_VERSION]).path_join("manifest.json"))
	manifest["save_migrations"] = [declaration]
	if not _write_json(String(staged[DESTINATION_VERSION]).path_join("manifest.json"), manifest):
		quit(1)
		return

	# Prove the declaration the registry will read, not the one just written: a
	# manifest that parses is not the same claim as an edge whose endpoints match
	# the installed catalogue.
	var manifest_errors: Array[String] = []
	var parsed := PackManifest.parse(manifest, "manifest.json", manifest_errors)
	if parsed == null or not manifest_errors.is_empty():
		printerr("staged v%s manifest does not validate:" % DESTINATION_VERSION)
		for error in manifest_errors:
			printerr("  %s" % error)
		quit(1)
		return

	for version: String in [SOURCE_VERSION, DESTINATION_VERSION]:
		print("staged %s %s -> %s" % [FIXTURE_ID, version, staged[version]])
	print(
		"  source      : schema %d %s" % [source_identity["schema"], source_identity["fingerprint"]]
	)
	print(
		(
			"  destination : schema %d %s"
			% [destination_identity["schema"], destination_identity["fingerprint"]]
		)
	)
	var archives_out: String = args.get("archives-out", "")
	if not archives_out.is_empty():
		if not _export_archives(staged, archives_out):
			quit(1)
			return
	else:
		print(
			(
				"next: rerun with --archives-out <directory>, or invoke "
				+ "scripts/tools/export_pack_archive.gd for each staged directory"
			)
		)
	quit(0)


func _export_archives(staged: Dictionary, archives_out: String) -> bool:
	var absolute_out := ProjectSettings.globalize_path(archives_out)
	if DirAccess.make_dir_recursive_absolute(absolute_out) != OK:
		printerr("cannot create archive output directory: %s" % absolute_out)
		return false
	var project_root := ProjectSettings.globalize_path("res://")
	for version: String in [SOURCE_VERSION, DESTINATION_VERSION]:
		var archive := absolute_out.path_join("v076-migration-%s.zip" % version)
		var output: Array = []
		var exit_code := (
			OS
			. execute(
				OS.get_executable_path(),
				PackedStringArray(
					[
						"--headless",
						"--path",
						project_root,
						"--script",
						"res://scripts/tools/export_pack_archive.gd",
						"--",
						"--pack",
						ProjectSettings.globalize_path(String(staged[version])),
						"--out",
						archive,
					]
				),
				output,
				true
			)
		)
		for line: String in output:
			print(line.trim_suffix("\n"))
		if exit_code != 0:
			printerr("archive export failed for v%s (exit %d)" % [version, exit_code])
			return false
		print("fixture archive -> %s" % archive)
	return true


func _stage(directory: String, version: String) -> bool:
	var absolute := ProjectSettings.globalize_path(directory)
	_remove_tree(absolute)
	if DirAccess.make_dir_recursive_absolute(absolute.path_join("data")) != OK:
		printerr("cannot create staging directory: %s" % absolute)
		return false
	var source := DirAccess.open(SOURCE_PACK.path_join("data"))
	if source == null:
		printerr("cannot read fixture source: %s" % SOURCE_PACK)
		return false
	for name in source.get_files():
		if not name.ends_with(".json"):
			continue
		var from := SOURCE_PACK.path_join("data").path_join(name)
		if DirAccess.copy_absolute(from, absolute.path_join("data").path_join(name)) != OK:
			printerr("cannot copy %s" % from)
			return false
	var manifest := _read_json(SOURCE_PACK.path_join("manifest.json"))
	if manifest.is_empty():
		return false
	manifest["id"] = FIXTURE_ID
	manifest["version"] = version
	manifest.erase("save_migrations")
	return _write_json(absolute.path_join("manifest.json"), manifest)


func _catalogue_identity(directory: String) -> Dictionary:
	var errors: Array[String] = []
	var catalogue := Tier2Catalogue.load_campaign_pack(directory, errors)
	if catalogue == null:
		printerr("staged pack does not load as a catalogue: %s" % directory)
		for error in errors:
			printerr("  %s" % error)
		return {}
	return {"schema": catalogue.format_version, "fingerprint": catalogue.content_fingerprint()}


func _read_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		printerr("cannot read %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		printerr("%s is not a JSON object" % path)
		return {}
	return parsed


func _write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("cannot write %s" % path)
		return false
	file.store_string(JSON.stringify(data, "  ", false) + "\n")
	file.close()
	return true


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var name := directory.get_next()
	while name != "":
		var child := path.path_join(name)
		if directory.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		name = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)


func _parse_args() -> Dictionary:
	var argv := OS.get_cmdline_user_args()
	var parsed := {}
	var index := 0
	while index < argv.size():
		var token := String(argv[index])
		if token in ["--out", "--archives-out"]:
			if index + 1 >= argv.size():
				printerr("%s requires a value" % token)
				return {}
			parsed[token.trim_prefix("--")] = String(argv[index + 1])
			index += 2
			continue
		printerr("unknown argument: %s" % token)
		return {}
	return parsed
