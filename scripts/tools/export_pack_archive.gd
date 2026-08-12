extends SceneTree
# Export a campaign pack directory to the ONE archive shape the game can install,
# and prove it installs before claiming success.
#
#   godot --headless --script res://scripts/tools/export_pack_archive.gd -- \
#       --pack <pack directory> --out <archive.zip> [--skip-install-check]
#
# WHY THIS EXISTS. A pack directory is not installable. `CampaignPackInstaller` has
# exactly one entry point, `install_zip()`, driven by `ZIPReader`; the Campaign Library's
# import dialog filters `*.zip` and cannot select a folder at all. The archive must also
# carry every entry under a single root directory named EXACTLY the manifest id
# (`CampaignArchivePreflight` rejects `manifest.id != package_root`), which is not the
# directory name a pack happens to be checked out under.
#
# The v0.7.0 tester bundle shipped its packs as loose directories named
# `proving_grounds_public` / `_internal` / `_invalid` while their manifest ids are
# `prometheus-proving-grounds` and friends, so neither the folder nor a hand-made zip of
# it could have been installed. Nothing caught it because every automated path validates a
# pack ROOT (`validate_pack.gd`, `Tier2Catalogue.load_campaign_pack`) and never the
# artifact a player is handed.
#
# So this tool does not stop at writing bytes: it runs the real preflight and, unless
# told otherwise, performs an actual install into a throwaway storage root. "Exported"
# and "installable" are different claims, and only the second one is worth shipping.

const Exporter = preload("res://scripts/resources/CampaignPackExporter.gd")
const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Budgets = preload("res://scripts/resources/ImportBudgets.gd")


func _init() -> void:
	var args := _parse_args()
	if args.is_empty():
		quit(2)
		return
	var pack_root: String = args.get("pack", "")
	var out_path: String = args.get("out", "")
	if pack_root.is_empty() or out_path.is_empty():
		printerr("usage: --pack <directory> --out <archive.zip> [--skip-install-check]")
		quit(2)
		return
	if not DirAccess.dir_exists_absolute(pack_root):
		printerr("pack directory does not exist: %s" % pack_root)
		quit(1)
		return

	# The player's own budgets, not a permissive build-tool set: an archive that only
	# passes because the tool was generous is not evidence about the shipped path.
	var limits: Preflight.Limits = _player_limits()

	var exporter := Exporter.new()
	var result = exporter.export_zip(pack_root, out_path, limits)
	if not result.exported:
		printerr("export failed for %s" % pack_root)
		for error in result.errors:
			printerr("  %s" % error)
		quit(1)
		return

	print("exported %s" % out_path)
	print("  package id      : %s" % result.package_id)
	print("  package version : %s" % result.package_version)
	print("  archive root    : %s/" % result.package_id)
	print("  entries         : %d" % result.preflight.entries.size())
	for repair in result.repair_report:
		print("  repaired media  : %s" % repair)

	if args.has("skip-install-check"):
		print("install check SKIPPED by request")
		quit(0)
		return

	if not _install_check(out_path, limits):
		quit(1)
		return
	print("INSTALLABLE: %s" % out_path)
	quit(0)


# Install into a throwaway storage root through the same preflight + installer pair the
# Campaign Library screen uses, then delete it. This is the only step that distinguishes
# "a zip was written" from "the game accepts it".
func _install_check(archive_path: String, limits: Preflight.Limits) -> bool:
	var preflight = Preflight.inspect_zip(archive_path, limits)
	if not preflight.valid:
		printerr("preflight rejected the exported archive:")
		for error in preflight.errors:
			printerr("  %s" % error)
		return false

	var storage_root := "user://_pack_install_check_%d" % Time.get_ticks_usec()
	var installer = Installer.new(storage_root)
	var result = installer.install_zip(archive_path, preflight)
	var installed: bool = result.errors.is_empty()
	if not installed:
		printerr("install rejected the exported archive:")
		for error in result.errors:
			printerr("  %s" % error)
	else:
		print("  installed as   : %s %s" % [result.package_id, result.package_version])
	_remove_tree(ProjectSettings.globalize_path(storage_root))
	return installed


func _player_limits() -> Preflight.Limits:
	return Preflight.Limits.new(
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRIES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES
	)


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
	var parsed := {}
	var argv := OS.get_cmdline_user_args()
	var index := 0
	while index < argv.size():
		var token := String(argv[index])
		match token:
			"--pack", "--out":
				if index + 1 >= argv.size():
					printerr("%s requires a value" % token)
					return {}
				parsed[token.trim_prefix("--")] = String(argv[index + 1])
				index += 2
			"--skip-install-check":
				parsed["skip-install-check"] = true
				index += 1
			_:
				printerr("unknown argument: %s" % token)
				return {}
	return parsed
