extends SceneTree
# Runs from both a source checkout and an exported PCK. The surrounding shell gate
# compares the two reports, then asks this same exported runtime to install the exact
# release fixture. Keep this script under scripts/shared so the release preset includes
# the verifier while excluding authoring/test tools.

const RegistryManagerScript = preload("res://scripts/autoloads/RegistryManager.gd")
const RegistryCatalogScript = preload("res://scripts/registries/RegistryCatalog.gd")
const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Budgets = preload("res://scripts/resources/ImportBudgets.gd")

const FORBIDDEN_CAMPAIGN_RESOURCES: Array[String] = [
	"res://data/campaigns/resource_manifest.json",
	"res://data/classes/resource_manifest.json",
	"res://data/items/resource_manifest.json",
	"res://data/maps/map_registry.json",
	"res://data/skills/resource_manifest.json",
	"res://data/weapons/resource_manifest.json",
]
const REPORT_PREFIX := "EXPORTED_REGISTRY_GATE_JSON:"


func _init() -> void:
	var report := _registry_report()
	var failures: Array[String] = report.pop_back()
	var arguments := OS.get_cmdline_user_args()
	var source_mode := arguments.has("--source-mode")
	arguments.erase("--source-mode")
	if not source_mode:
		for path in FORBIDDEN_CAMPAIGN_RESOURCES:
			if FileAccess.file_exists(path):
				failures.append("forbidden campaign resource shipped: %s" % path)
	print(REPORT_PREFIX + JSON.stringify(report))
	for archive in arguments:
		failures.append_array(_check_archive(String(archive)))
	if not failures.is_empty():
		for failure in failures:
			printerr("EXPORTED REGISTRY GATE: %s" % failure)
		quit(1)
		return
	print("EXPORTED REGISTRY GATE: PASS")
	quit(0)


# The last element carries diagnostics so the JSON report itself stays stable and can
# be compared byte-for-byte between source and exported runtimes.
func _registry_report() -> Array:
	var manager := RegistryManagerScript.new()
	var errors: Array[String] = manager.reload_presets()
	var report: Dictionary = {}
	for family in RegistryCatalogScript.REQUIRED_FAMILIES:
		var ids: Array[String] = manager.ids(family)
		report[family] = ids
		if ids.is_empty():
			errors.append("required engine registry family is empty: %s" % family)
	manager.free()
	return [report, errors]


func _check_archive(archive: String) -> Array[String]:
	var failures: Array[String] = []
	var limits: Preflight.Limits = Preflight.Limits.new(
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRIES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES,
		Budgets.CAMPAIGN_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES
	)
	var preflight = Preflight.inspect_zip(archive, limits)
	if not preflight.valid:
		for error in preflight.errors:
			failures.append("archive preflight: %s" % error)
		return failures
	var storage_root := "user://_exported_registry_gate_%d" % Time.get_ticks_usec()
	var installer = Installer.new(storage_root)
	var result = installer.install_zip(archive, preflight)
	for error in result.errors:
		failures.append("archive install: %s" % error)
	_remove_tree(ProjectSettings.globalize_path(storage_root))
	return failures


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
