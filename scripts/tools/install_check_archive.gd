extends SceneTree
# Install-check an existing campaign pack archive, without exporting it.
#
#   godot --headless --script res://scripts/tools/install_check_archive.gd -- <archive.zip>...
#
# `export_pack_archive.gd` checks what it just wrote. This checks what a bundle actually
# SHIPS, which is the artifact that matters: it runs the same preflight and installer the
# Campaign Library screen uses, against the player's own import budgets, and exits
# non-zero if any archive would be refused.

const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Budgets = preload("res://scripts/resources/ImportBudgets.gd")


func _init() -> void:
	var archives := OS.get_cmdline_user_args()
	if archives.is_empty():
		printerr("usage: install_check_archive.gd -- <archive.zip>...")
		quit(2)
		return

	var limits: Preflight.Limits = Preflight.Limits.new(
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRIES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES
	)

	var failures := 0
	for raw in archives:
		var archive := String(raw)
		var preflight = Preflight.inspect_zip(archive, limits)
		if not preflight.valid:
			printerr("REFUSED (preflight): %s" % archive)
			for error in preflight.errors:
				printerr("    %s" % error)
			failures += 1
			continue
		var storage_root := "user://_install_check_%d" % Time.get_ticks_usec()
		var installer = Installer.new(storage_root)
		var result = installer.install_zip(archive, preflight)
		if result.errors.is_empty():
			print(
				(
					"INSTALLABLE: %s -> %s %s (root %s/, %d entries)"
					% [
						archive.get_file(),
						result.package_id,
						result.package_version,
						preflight.package_root,
						preflight.entries.size()
					]
				)
			)
		else:
			printerr("REFUSED (install): %s" % archive)
			for error in result.errors:
				printerr("    %s" % error)
			failures += 1
		_remove_tree(ProjectSettings.globalize_path(storage_root))

	if failures > 0:
		printerr("%d archive(s) would be refused at import" % failures)
		quit(1)
		return
	print("all %d archive(s) install" % archives.size())
	quit(0)


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
