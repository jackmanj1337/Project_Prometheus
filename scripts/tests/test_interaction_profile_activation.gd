extends SceneTree
# Slice 4 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: THE ACTIVATION GATE.
#
# `InteractionProfileSchema` has enforced the authored-interaction contract since slice 1
# and nothing in production called it, so the contract was upheld by its own suite alone.
# This one drives the REAL activation path with a real pack on disk, because the claim
# being made is not "validate() returns errors" — slice 1 proved that — but "a pack whose
# profiles do not validate does not become the live content".
#
# Every failing case therefore asserts the refusal AND that nothing changed: activation
# returned false, the errors are on the activation channel, and the registry catalogue
# still holds what it held before the attempt. `[ITR-1..7]`

const Registry = preload("res://scripts/resources/CampaignPackRegistry.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")

const PACK_ID := "interaction-profile-pack"
const VERSION := "1.0"

var _passed := 0
var _failed := 0
var _dm: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Interaction Profile Activation Test ===")
	_dm = root.get_node_or_null("DataManager")
	var registry_manager := root.get_node_or_null("RegistryManager")
	if _dm == null or registry_manager == null:
		_check(false, "required autoloads unavailable")
		_finish()
		return

	# A profile naming a composition the ENGINE registers, so the fixture needs no
	# registry entries of its own and the case under test stays the profile.
	var valid_profile := {
		"profile_id": "fixture_profile",
		"context": "combat",
		"subjects": ["source", "target"],
		"priority": 10,
		"stack_group": "fixture_group",
		"stack_policy": "highest",
		"stops_below": false,
		"rules":
		[
			{
				"rule_id": "r1",
				"when":
				{
					"predicate_id": "has_trait",
					"subject": {"kind": "source"},
					"params": {"id": "sword"},
				},
				"effects": [{"composition_id": "fog_reveal", "target": "target"}],
			}
		],
	}

	# --- the pack that validates -----------------------------------------------
	_install([valid_profile])
	var accepted: bool = _dm.call("select_tier2_campaign_source", _pack_path(), PACK_ID, VERSION)
	_check(accepted, "a pack whose interaction profiles validate still activates")
	var baseline: int = _catalogue_size(registry_manager)
	_check(baseline > 0, "...and its registry catalogue is live")

	# --- an unknown context ----------------------------------------------------
	var bad_context: Dictionary = valid_profile.duplicate(true)
	bad_context["context"] = "not_a_context"
	_check_refused(
		registry_manager,
		baseline,
		[bad_context],
		"declares unknown context",
		"a profile naming a context the engine does not declare refuses the pack"
	)

	# --- a composition id nothing installs -------------------------------------
	var bad_composition: Dictionary = valid_profile.duplicate(true)
	(((bad_composition["rules"] as Array)[0] as Dictionary)["effects"] as Array)[0]["composition_id"] = "no_such_composition"
	_check_refused(
		registry_manager,
		baseline,
		[bad_composition],
		"unknown effect composition",
		(
			"a profile naming a composition NO pack installs refuses the pack — the check "
			+ "that needs the candidate catalogue"
		)
	)

	# --- an unbound subject ----------------------------------------------------
	var bad_subject: Dictionary = valid_profile.duplicate(true)
	(((bad_subject["rules"] as Array)[0] as Dictionary)["effects"] as Array)[0]["target"] = ("equipped_target")
	_check_refused(
		registry_manager,
		baseline,
		[bad_subject],
		"unbound subject",
		"a profile targeting a subject it never bound refuses the pack"
	)

	_teardown()
	_finish()


# The shape every refusal must have: false, a reason on the activation channel, and a
# registry catalogue that is exactly what it was. A pack that fails validation but leaves
# its vocabulary installed is the failure the pre-commit ordering exists to prevent.
func _check_refused(
	registry_manager: Node, baseline: int, profiles: Array, fragment: String, label: String
) -> void:
	_install(profiles)
	var accepted: bool = _dm.call("select_tier2_campaign_source", _pack_path(), PACK_ID, VERSION)
	_check(not accepted, label)
	var status: Dictionary = _dm.call("content_status")
	_check(
		_has_error(status["errors"], fragment),
		"...and says why, naming the campaign: %s" % fragment,
		str(status["errors"])
	)
	_check(
		_catalogue_size(registry_manager) == baseline,
		"...and the registry catalogue is untouched: the candidate was never committed"
	)
	var report = _dm.call("content_report")
	_check(report.blocks("activation"), "...and the refusal BLOCKS at the activation gate")


# The manager answers `ids()` directly; there is no catalogue accessor to reach through.
func _catalogue_size(registry_manager: Node) -> int:
	return (registry_manager.call("ids", "effect_compositions") as Array).size()


func _has_error(errors: Array, fragment: String) -> bool:
	for message in errors:
		if String(message).contains(fragment) and String(message).contains("campaign 'fixture'"):
			return true
	return false


func _pack_path() -> String:
	return Registry.installed_path(Registry.DEFAULT_STORAGE_ROOT, PACK_ID, VERSION)


func _teardown() -> void:
	_dm.call("select_campaign_source", "res://data")
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)


func _finish() -> void:
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(ok: bool, label: String, detail: String = "") -> void:
	if ok:
		print("OK  %s" % label)
		_passed += 1
	else:
		print("FAIL %s%s" % [label, "" if detail == "" else " — %s" % detail])
		_failed += 1


# The smallest pack that activates, with the profiles under test on its campaign.
func _install(profiles: Array) -> void:
	Installer._remove_tree(Registry.DEFAULT_STORAGE_ROOT)
	var pack_root := _pack_path()
	var files := {
		"manifest.json":
		{
			"id": PACK_ID,
			"version": VERSION,
			"forked_from": "",
			"builder_content_version": "0.4",
			"format_version": 1,
			"save_migrations": [],
		},
		"data/catalogue.json":
		{
			"format_version": 1,
			"entries":
			[
				{"kind": "campaign", "id": "fixture", "path": "data/campaign.json"},
				{"kind": "map_registry", "id": "maps", "path": "data/map_registry.json"},
				{"kind": "map_data", "id": "map_01", "path": "data/map_01.json"},
				{"kind": "roster", "id": "heroes", "path": "data/roster.json"},
				{"kind": "class", "id": "fixture_class", "path": "data/class.json"},
				{"kind": "weapon", "id": "fixture_blade", "path": "data/weapon.json"},
			],
		},
		"data/campaign.json":
		{
			"campaign_id": "fixture",
			"label": "Fixture",
			"start_node_id": "start",
			"nodes": [{"node_id": "start", "label": "Start", "map_id": "map_01", "next": []}],
			"rules": {"interaction_profiles": profiles},
		},
		"data/map_registry.json":
		[{"id": "map_01", "label": "Map", "map_data_id": "map_01", "roster_id": "heroes"}],
		"data/map_01.json":
		{"id": "map_01", "display_name": "Map", "grid": ["..."], "player_start_tiles": [[0, 0]]},
		"data/roster.json":
		{
			"units":
			[
				{
					"unit_id": "hero",
					"unit_name": "Hero",
					"class_id": "fixture_class",
					"inventory": [{"weapon_id": "fixture_blade", "uses": -1}],
				}
			]
		},
		"data/class.json":
		{
			"id": "fixture_class",
			"display_name": "Fixture",
			"base_hp": 20,
			"base_movement": 5,
			"allowed_weapon_families": ["sword"],
			"weapon_wexp_bases": {"sword": 1},
			"weapon_wexp_caps": {"sword": 400},
		},
		"data/weapon.json":
		{
			"id": "fixture_blade",
			"display_name": "Fixture Blade",
			"combat_family": "sword",
			"wexp_track": "sword",
			"required_rank": "E",
			"mt": 1,
			"hit": 100,
			"crit": 0,
			"wt": 0,
			"range_min_formula": "1",
			"range_max_formula": "1",
			"uses": -1,
			"cost": 0,
			"wexp": 1,
		},
	}
	for relative in files:
		var path: String = pack_root.path_join(relative)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(files[relative]))
		file.close()
