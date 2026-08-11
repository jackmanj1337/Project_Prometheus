extends "res://scripts/ui/ModalScreen.gd"
# New Game setup: pick the per-save gameplay rules (permadeath, leveling method),
# then start a fresh run. Implemented as an overlay child of MainMenu — open()/hide()
# like SettingsScreen, with Back returning to MainMenu (no scene reload).
# Extends ModalScreen (B3) for hide-on-ready and cancel-to-close.
#
# Gameplay rules are per-save state, so they are written onto GameState here rather
# than into the global settings.cfg. The save-system milestone will serialize them.
#
# Expected scene structure (see NewGameScreen.tscn):
#   NewGameScreen (Control, full-rect anchor, visible = false)
#     Panel
#       VBox
#         Label "New Game"
#         HBoxRun
#           Label "Campaign"
#           OptionButton (node name: OptRun)
#         HBoxPermadeath
#           Label "Permadeath"
#           OptionButton (node name: OptPermadeath)  # Off / On
#         HBoxAutoPromote
#           Label "Auto Promote"
#           OptionButton (node name: OptAutoPromote) # Off / On
#         HBoxLeveling
#           Label "Leveling"
#           OptionButton (node name: OptLeveling)    # Random / Fixed
#         HSeparator
#         Button (node name: BtnStart)
#         Button (node name: BtnBack)

signal back_pressed

const CampaignPackRegistryScript = preload("res://scripts/resources/CampaignPackRegistry.gd")
const CampaignStatusStoreScript = preload("res://scripts/resources/CampaignStatusStore.gd")

@onready var _opt_run: OptionButton = $Panel/Scroll/VBox/HBoxRun/OptRun
@onready var _opt_permadeath: OptionButton = $Panel/Scroll/VBox/HBoxPermadeath/OptPermadeath
@onready var _opt_auto_promote: OptionButton = $Panel/Scroll/VBox/HBoxAutoPromote/OptAutoPromote
@onready var _opt_leveling: OptionButton = $Panel/Scroll/VBox/HBoxLeveling/OptLeveling
@onready var _opt_pair_up: OptionButton = $Panel/Scroll/VBox/HBoxPairUp/OptPairUp
@onready var _opt_status: OptionButton = $Panel/Scroll/VBox/HBoxStatus/OptStatus
@onready var _btn_import_status: Button = $Panel/Scroll/VBox/BtnImportStatus
@onready var _status_feedback: Label = $Panel/Scroll/VBox/StatusFeedback
@onready var _status_dialog: FileDialog = $StatusImportDialog
@onready var _btn_start: Button = $Panel/Scroll/VBox/BtnStart
@onready var _btn_manage_campaigns: Button = $Panel/Scroll/VBox/BtnManageCampaigns
@onready var _btn_back: Button = $Panel/Scroll/VBox/BtnBack
@onready var _campaign_library: Control = $CampaignLibraryScreen

# OptLeveling index → GameState.campaign_rules.leveling_method value.
const _LEVELING_OPTIONS: Array[String] = ["growth_random", "growth_fixed"]
var _run_options: Array[Dictionary] = []
var _status_options: Array[Dictionary] = []
var _status_store := CampaignStatusStoreScript.new()


func _ready() -> void:
	_refresh_run_options()
	_opt_permadeath.clear()
	_opt_permadeath.add_item("Off")
	_opt_permadeath.add_item("On")
	_opt_auto_promote.clear()
	_opt_auto_promote.add_item("Off")
	_opt_auto_promote.add_item("On")
	_opt_leveling.clear()
	_opt_leveling.add_item("Random")
	_opt_leveling.add_item("Fixed")
	_opt_pair_up.clear()
	_opt_pair_up.add_item("Off")
	_opt_pair_up.add_item("On")
	_opt_run.item_selected.connect(_on_run_selected)
	_btn_start.pressed.connect(_on_start)
	_btn_manage_campaigns.pressed.connect(_on_manage_campaigns)
	_btn_import_status.pressed.connect(func(): _status_dialog.popup_centered_ratio(0.7))
	_status_dialog.file_selected.connect(_on_status_file_selected)
	_btn_back.pressed.connect(_on_back)
	_campaign_library.back_pressed.connect(_on_campaign_library_back)
	_campaign_library.campaigns_changed.connect(_on_campaigns_changed)
	if not _run_options.is_empty():
		_on_run_selected(_opt_run.selected)
	# Persist the rule toggles to GameState the moment they change, so closing the
	# panel WITHOUT pressing Start still remembers them on reopen (playtest v0.1.4
	# #1.2). open() seeds the controls back from these same GameState fields. These
	# are pure per-save flags; the map + roster are only configured on Start.
	# (add_item / setting `.selected` in open() do not emit item_selected, so this
	# never fires spuriously during setup.)
	_opt_permadeath.item_selected.connect(func(_i: int): _persist_rules())
	_opt_auto_promote.item_selected.connect(func(_i: int): _persist_rules())
	_opt_leveling.item_selected.connect(func(_i: int): _persist_rules())
	_opt_pair_up.item_selected.connect(func(_i: int): _persist_rules())
	super._ready()


func open() -> void:
	_refresh_run_options()
	# Seed the controls from GameState so reopening shows the current choices.
	var gs := get_node_or_null("/root/GameState")
	if gs:
		var rules: CampaignRules = gs.get("campaign_rules") as CampaignRules
		_opt_run.selected = 0
		if rules != null:
			_opt_permadeath.selected = int(rules.permadeath_enabled)  # 0=Off, 1=On
			_opt_auto_promote.selected = int(rules.auto_promote_at_max_level)  # 0=Off, 1=On
			_opt_leveling.selected = maxi(0, _LEVELING_OPTIONS.find(rules.leveling_method))
			_opt_pair_up.selected = int(rules.pair_up_enabled)  # 0=Off, 1=On
	else:
		_opt_run.selected = 0
	_select_preferred_run()
	_on_run_selected(_opt_run.selected)
	show()
	_btn_start.grab_focus()


func _close() -> void:
	# Subclass override: emit back_pressed (consumed by MainMenu) in addition
	# to ModalScreen.closed.
	back_pressed.emit()
	super._close()


# Writes the current rule-toggle selections onto GameState. Shared by the
# on-change handlers (so a close/reopen without Start remembers them) and by
# _on_start (which additionally configures the map + roster). Pure per-save
# flags — no map or roster side effects.
func _persist_rules() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var rules: CampaignRules = gs.get("campaign_rules") as CampaignRules
	if rules == null:
		push_error("NewGameScreen: GameState.campaign_rules missing — cannot apply rules.")
		return
	if not _opt_permadeath.disabled:
		rules.permadeath_enabled = bool(_opt_permadeath.selected)  # 0=Off, 1=On
	if not _opt_auto_promote.disabled:
		rules.auto_promote_at_max_level = bool(_opt_auto_promote.selected)  # 0=Off, 1=On
	if not _opt_leveling.disabled:
		rules.leveling_method = _LEVELING_OPTIONS[_opt_leveling.selected]
	if not _opt_pair_up.disabled:
		rules.pair_up_enabled = bool(_opt_pair_up.selected)  # 0=Off, 1=On
	if gs.has_method("commit_current_campaign_rules_as_defaults"):
		gs.call("commit_current_campaign_rules_as_defaults")


func _on_start() -> void:
	# Commit the chosen rules onto GameState, then load the roster and the first map.
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		push_error(
			"NewGameScreen: GameState autoload missing — cannot apply rules or start the map."
		)
		return
	var run: Dictionary = _run_options[_opt_run.selected]
	if not _activate_run_source(run):
		# [V070-05] The refusal itself is correct — activation fails closed, the
		# previously active pack survives, and DataManager keeps the reason. What was
		# missing is saying so: this used to be a bare `return`, so the deliberately
		# invalid pack "loads and can be selected, but when you click start nothing
		# happens" while the log carried the naming message 18 times into push_error.
		_report_activation_failure()
		return
	var campaign_id: String = String(run["campaign_id"])
	var cm := get_node_or_null("/root/CampaignManager")
	if cm == null:
		push_error("NewGameScreen: CampaignManager autoload missing — cannot start campaign.")
		return
	if not bool(cm.call("start_campaign", campaign_id)):
		return
	if not _apply_selected_status_record(cm, gs, run):
		cm.call("end_campaign")
		return
	_record_started_run(run)
	# Campaign defaults seed the controls; only editable defaults write back.
	# Mandates remain locked at the value CampaignManager just applied.
	_persist_rules()
	if not bool(cm.call("launch_current_node")):
		cm.call("end_campaign")


func _on_run_selected(index: int) -> void:
	_apply_rule_authority(_run_options[index])
	_refresh_status_options(_run_options[index])


func _refresh_run_options() -> void:
	var previous := (
		_run_options[_opt_run.selected].duplicate(true)
		if (
			not _run_options.is_empty()
			and _opt_run.selected >= 0
			and _opt_run.selected < _run_options.size()
		)
		else {}
	)
	_run_options = []
	var dm := get_node_or_null("/root/DataManager")
	if dm != null and dm.has_method("get_shipped_campaigns"):
		for campaign: CampaignData in dm.call("get_shipped_campaigns").values():
			if campaign == null or campaign.is_dev_only and not OS.is_debug_build():
				continue
			(
				_run_options
				. append(
					{
						"label": campaign.label,
						"campaign_id": campaign.campaign_id,
						"author_id": campaign.author_id,
						"campaign_version": campaign.campaign_version,
						"compatible_status_sources":
						campaign.compatible_status_sources.duplicate(true),
						"rules":
						_authored_rule_rows(campaign.rule_overrides, campaign.mandated_rule_ids),
					}
				)
			)
	_run_options.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return (
				"%s\n%s" % [a["label"], a["campaign_id"]]
				< "%s\n%s" % [b["label"], b["campaign_id"]]
			)
	)
	var registry := CampaignPackRegistryScript.new(CampaignPackRegistryScript.DEFAULT_STORAGE_ROOT)
	for summary in registry.refresh():
		for campaign in summary["campaigns"]:
			if bool(campaign.get("is_dev_only", false)) and not OS.is_debug_build():
				continue
			(
				_run_options
				. append(
					{
						"label":
						(
							"%s — %s %s"
							% [campaign["label"], summary["package_id"], summary["package_version"]]
						),
						"campaign_id": campaign["campaign_id"],
						"author_id": campaign.get("author_id", summary["package_id"]),
						"campaign_version": campaign.get("campaign_version", "1.0.0"),
						"compatible_status_sources":
						campaign.get("compatible_status_sources", []).duplicate(true),
						"package_id": summary["package_id"],
						"package_version": summary["package_version"],
						"package_path": summary["path"],
						"rules": campaign.get("rules", {}).duplicate(true),
					}
				)
			)
	_opt_run.clear()
	for entry in _run_options:
		_opt_run.add_item(entry["label"])
	_opt_run.selected = 0
	if not previous.is_empty():
		for index in _run_options.size():
			if _same_run_identity(_run_options[index], previous):
				_opt_run.selected = index
				break
	_select_preferred_run()


func _status_target(run: Dictionary) -> Dictionary:
	return {
		"author_id": String(run.get("author_id", run.get("package_id", "project_prometheus"))),
		"campaign_id": String(run.get("campaign_id", "")),
		"campaign_version": String(run.get("campaign_version", "1.0.0")),
		"compatible_status_sources": run.get("compatible_status_sources", []).duplicate(true),
	}


func _refresh_status_options(run: Dictionary) -> void:
	_status_options = [{"label": "None — start clean"}]
	for loaded in _status_store.scan_compatible(_status_target(run)):
		var record: Dictionary = loaded.get("record", {})
		(
			_status_options
			. append(
				{
					"label":
					(
						"%s %s — %s"
						% [
							record.get("campaign_id", "Campaign"),
							record.get("campaign_version", ""),
							record.get("created_at_utc", "")
						]
					),
					"record": record.duplicate(true),
					"manual_foreign": false,
				}
			)
		)
	_opt_status.clear()
	for option in _status_options:
		_opt_status.add_item(String(option["label"]))
	_opt_status.selected = 0
	_status_feedback.text = "%d compatible record(s) found" % (_status_options.size() - 1)


func _on_status_file_selected(path: String) -> void:
	var loaded := _status_store.load_record(path)
	if loaded.is_empty():
		_status_feedback.text = "Import failed: %s" % "; ".join(_status_store.last_errors)
		return
	var record: Dictionary = loaded["record"]
	(
		_status_options
		. append(
			{
				"label":
				(
					"Manual: %s %s"
					% [record.get("campaign_id", "Campaign"), record.get("campaign_version", "")]
				),
				"record": record.duplicate(true),
				"manual_foreign": true,
			}
		)
	)
	_opt_status.add_item(_status_options[-1]["label"])
	_opt_status.selected = _status_options.size() - 1
	_status_feedback.text = "Manual record ready; its source will be recorded in this run"


func _apply_selected_status_record(cm: Node, gs: Node, run: Dictionary) -> bool:
	if _opt_status.selected <= 0 or _opt_status.selected >= _status_options.size():
		return true
	var option: Dictionary = _status_options[_opt_status.selected]
	var state: MutableCampaignState = gs.get("mutable_campaign_state") as MutableCampaignState
	if (
		state == null
		or not _status_store.import_into(
			option["record"], _status_target(run), state, bool(option.get("manual_foreign", false))
		)
	):
		_status_feedback.text = "Import failed: %s" % "; ".join(_status_store.last_errors)
		return false
	if not bool(cm.call("import_carry_forward_facts", state.carry_forward_facts)):
		_status_feedback.text = "Import failed: campaign facts were rejected"
		return false
	if not bool(cm.call("stage_status_import_benefits", option["record"])):
		_status_feedback.text = "Import failed: campaign benefits were rejected"
		return false
	return true


# Renders why activation refused, using the errors DataManager already retains.
# Bounded: one validator complaint repeats per offending map entry, so the invalid
# fixture returns the same sentence eighteen times. The player gets the first few and
# a count; the full set still goes to the log for triage.
func _report_activation_failure() -> void:
	const MAX_SHOWN := 3
	var dm := get_node_or_null("/root/DataManager")
	var errors: Array = []
	if dm != null and dm.has_method("content_status"):
		var status: Dictionary = dm.call("content_status")
		if status.get("errors") is Array:
			errors = status["errors"]
	if errors.is_empty():
		_status_feedback.text = "Could not start: this campaign package failed to activate"
		return
	var unique: Array[String] = []
	for error in errors:
		var text := String(error)
		if text not in unique:
			unique.append(text)
	var shown := unique.slice(0, MAX_SHOWN)
	var suffix := ""
	if unique.size() > shown.size():
		suffix = " (+%d more; see the log)" % (unique.size() - shown.size())
	_status_feedback.text = "Could not start: %s%s" % ["; ".join(shown), suffix]
	push_warning("NewGameScreen: campaign activation refused — %s" % "; ".join(unique))


func _activate_run_source(run: Dictionary) -> bool:
	var dm := get_node_or_null("/root/DataManager")
	if dm == null:
		push_error("NewGameScreen: DataManager unavailable — cannot select campaign content")
		return false
	var package_id := String(run.get("package_id", ""))
	if package_id.is_empty():
		push_error("NewGameScreen: campaign run has no package identity")
		return false
	return bool(
		dm.call(
			"select_tier2_campaign_source",
			String(run["package_path"]),
			package_id,
			String(run["package_version"])
		)
	)


static func _same_run_identity(a: Dictionary, b: Dictionary) -> bool:
	return (
		a.get("campaign_id", "") == b.get("campaign_id", "")
		and a.get("package_id", "") == b.get("package_id", "")
		and a.get("package_version", "") == b.get("package_version", "")
	)


func _select_preferred_run() -> void:
	if _run_options.is_empty():
		return
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager == null or not save_manager.has_method("campaign_preference_candidates"):
		return
	for preferred in save_manager.call("campaign_preference_candidates"):
		for index in _run_options.size():
			if _same_run_identity(_run_options[index], preferred):
				_opt_run.selected = index
				return


func _record_started_run(run: Dictionary) -> void:
	var save_manager := get_node_or_null("/root/SaveManager")
	if save_manager != null and save_manager.has_method("record_campaign_started"):
		save_manager.call("record_campaign_started", run)


func _on_back() -> void:
	# Back button and cancel key share the _close path so teardown stays in
	# one place (B3).
	_close()


func _on_manage_campaigns() -> void:
	_campaign_library.open()


func _on_campaign_library_back() -> void:
	_btn_manage_campaigns.grab_focus()


func _on_campaigns_changed() -> void:
	_refresh_run_options()
	_on_run_selected(_opt_run.selected)


func _apply_rule_authority(run: Dictionary) -> void:
	for control in [_opt_permadeath, _opt_auto_promote, _opt_leveling, _opt_pair_up]:
		(control as OptionButton).disabled = false
	var rows: Dictionary = run.get("rules", {}) if run.get("rules", {}) is Dictionary else {}
	_apply_authored_option(
		rows,
		"death_mode",
		_opt_permadeath,
		func(value: Variant) -> int: return 1 if String(value) == "classic" else 0
	)
	_apply_authored_option(
		rows,
		"auto_promote_at_max_level",
		_opt_auto_promote,
		func(value: Variant) -> int: return int(bool(value))
	)
	_apply_authored_option(
		rows,
		"leveling_method",
		_opt_leveling,
		func(value: Variant) -> int: return maxi(0, _LEVELING_OPTIONS.find(String(value)))
	)
	_apply_authored_option(
		rows, "pair_up_enabled", _opt_pair_up, func(value: Variant) -> int: return int(bool(value))
	)


func _apply_authored_option(
	rows: Dictionary, rule_id: String, control: OptionButton, index_for_value: Callable
) -> void:
	if not rows.has(rule_id):
		return
	var authored: Variant = rows[rule_id]
	var value: Variant = (
		authored.get("value") if authored is Dictionary and authored.has("value") else authored
	)
	control.selected = int(index_for_value.call(value))
	control.disabled = (
		authored is Dictionary and String(authored.get("authority", "default")) == "mandate"
	)


static func _authored_rule_rows(overrides: Dictionary, mandated: Array[String]) -> Dictionary:
	var rows := {}
	for rule_id in overrides:
		rows[rule_id] = {
			"value": overrides[rule_id],
			"authority": "mandate" if String(rule_id) in mandated else "default"
		}
	return rows
