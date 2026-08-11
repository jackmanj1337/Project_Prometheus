extends "res://scripts/ui/ModalScreen.gd"
# Player-facing bridge over the inert campaign archive services. Choosing a file
# never activates content; NewGameScreen refreshes discovery only after install.

signal back_pressed
signal campaigns_changed

const Preflight = preload("res://scripts/resources/CampaignArchivePreflight.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const Exporter = preload("res://scripts/resources/CampaignPackExporter.gd")
const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const ImportBudgetConfig = preload("res://scripts/resources/ImportBudgets.gd")
const Transfer = preload("res://scripts/resources/TransferFileService.gd")

@onready var _package: OptionButton = $Panel/VBox/HBoxPackage/OptPackage
@onready var _import_button: Button = $Panel/VBox/BtnImport
@onready var _export_button: Button = $Panel/VBox/BtnExport
@onready var _back_button: Button = $Panel/VBox/BtnBack
@onready var _import_dialog: FileDialog = $ImportDialog
@onready var _export_dialog: FileDialog = $ExportDialog
@onready var _result_dialog: AcceptDialog = $ResultDialog

var _summaries: Array[Dictionary] = []


func _ready() -> void:
	_import_button.pressed.connect(_on_import_pressed)
	_export_button.pressed.connect(_on_export_pressed)
	_back_button.pressed.connect(_close)
	_import_dialog.file_selected.connect(_on_import_file_selected)
	_export_dialog.file_selected.connect(_on_export_file_selected)
	super._ready()


func open() -> void:
	_refresh_packages()
	show()
	_import_button.grab_focus()


func _close() -> void:
	back_pressed.emit()
	super._close()


func _refresh_packages() -> void:
	var registry := Registry.new(Registry.DEFAULT_STORAGE_ROOT)
	_summaries = registry.refresh()
	_package.clear()
	for summary in _summaries:
		_package.add_item("%s %s" % [summary["package_id"], summary["package_version"]])
	_export_button.disabled = _summaries.is_empty()
	_package.disabled = _summaries.is_empty()


func _on_import_pressed() -> void:
	Transfer.request_open(
		_import_dialog,
		".zip,application/zip",
		ImportBudgetConfig.CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES,
		_on_import_file_selected,
		_on_import_file_failed
	)


func _on_export_pressed() -> void:
	if _summaries.is_empty() or _package.selected < 0:
		_show_result("No installed campaign package is available to export.")
		return
	var summary := _summaries[_package.selected]
	var suggested := "%s-%s.zip" % [summary["package_id"], summary["package_version"]]
	Transfer.request_save(_export_dialog, suggested, _on_export_file_selected)


func _on_import_file_selected(path: String) -> void:
	var preflight = Preflight.inspect_zip(path, _limits())
	if not preflight.valid:
		Transfer.discard_import(path)
		_show_result(_failure_text("Import failed", preflight.errors))
		return
	var installer := Installer.new(Registry.DEFAULT_STORAGE_ROOT)
	var result = installer.install_zip(path, preflight)
	Transfer.discard_import(path)
	if not result.installed:
		_show_result(_failure_text("Import failed", result.errors))
		return
	_refresh_packages()
	_record_import_preference(result.package_id, result.package_version)
	campaigns_changed.emit()
	var message := "Imported %s %s." % [result.package_id, result.package_version]
	if not result.repair_report.is_empty():
		message += "\n\nLoaded with %d optional-asset repair(s)." % result.repair_report.size()
	_show_result(message)


func _on_import_file_failed(message: String, cancelled: bool) -> void:
	# Cancelling a browser picker is not an import defect, but it still gets a
	# distinct, truthful result instead of looking like a read failure.
	_show_result(message if not cancelled else "Import cancelled.")


func _on_export_file_selected(path: String) -> void:
	if _summaries.is_empty() or _package.selected < 0:
		_show_result("Export failed: the selected package is no longer installed.")
		return
	var summary := _summaries[_package.selected]
	var result = Exporter.new().export_zip(summary["path"], path, _limits())
	if not result.exported:
		_show_result(_failure_text("Export failed", result.errors))
		return
	# On web the archive was written to a staging path, not somewhere the player
	# can reach; deliver() hands it to the browser. No-op on desktop.
	var delivery := Transfer.deliver(path)
	if not delivery["ok"]:
		_show_result(_failure_text("Export failed", delivery["errors"]))
		return
	var message := "Exported %s %s." % [result.package_id, result.package_version]
	if not result.repair_report.is_empty():
		message += "\n\nArchive includes %d optional-asset repair(s)." % result.repair_report.size()
	_show_result(message)


func _show_result(message: String) -> void:
	_result_dialog.dialog_text = message
	_result_dialog.popup_centered()
	_result_dialog.get_ok_button().grab_focus()


func _record_import_preference(package_id: String, package_version: String) -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null or not manager.has_method("record_campaign_imported"):
		return
	for summary in _summaries:
		if summary["package_id"] != package_id or summary["package_version"] != package_version:
			continue
		for campaign in summary["campaigns"]:
			if bool(campaign.get("is_dev_only", false)):
				continue
			(
				manager
				. call(
					"record_campaign_imported",
					{
						"campaign_id": campaign["campaign_id"],
						"package_id": package_id,
						"package_version": package_version,
					}
				)
			)
			return


static func _failure_text(prefix: String, errors: Array[String]) -> String:
	if errors.is_empty():
		return prefix + "."
	return "%s:\n%s" % [prefix, "\n".join(errors)]


static func _limits():
	return Preflight.Limits.new(
		ImportBudgetConfig.CAMPAIGN_ARCHIVE_MAX_ENTRIES,
		ImportBudgetConfig.CAMPAIGN_ARCHIVE_MAX_ENTRY_COMPRESSED_BYTES,
		ImportBudgetConfig.CAMPAIGN_ARCHIVE_MAX_ENTRY_UNCOMPRESSED_BYTES,
		ImportBudgetConfig.CAMPAIGN_ARCHIVE_MAX_TOTAL_COMPRESSED_BYTES,
		ImportBudgetConfig.CAMPAIGN_ARCHIVE_MAX_TOTAL_UNCOMPRESSED_BYTES
	)
