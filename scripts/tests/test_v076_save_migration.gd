extends SceneTree

const Migration = preload("res://scripts/save/SaveMigrationService.gd")
const Installer = preload("res://scripts/resources/CampaignPackInstaller.gd")
const ROOT := "user://test_v076_save_migration"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== v0.7.6 Direct Save Migration Test ===")
	var passed := 0
	var failed := 0
	var source: SaveData = (
		(
			SaveData
			. from_dict(
				{
					"save_label": "Original",
					"campaign":
					{
						"package_id": "fixture-pack",
						"package_version": "1.0.0",
						"campaign_id": "old_campaign",
						"node_id": "old_node",
						"cleared_nodes": []
					},
					"roster":
					{
						"units":
						[
							{
								"unit_id": "hero",
								"class_id": "old_class",
								"skills": ["old_skill"],
								"inventory": []
							}
						]
					},
				}
			)
		)
		as SaveData
	)
	var declaration := _declaration()
	var source_identity: Dictionary = source.source.duplicate(true)
	source_identity["content_schema_version"] = 1
	source_identity["content_fingerprint"] = "sha256:%s" % "a".repeat(64)
	source_identity["campaign_id"] = "old_campaign"
	var exact_summary := {
		"package_id": "fixture-pack",
		"package_version": "1.0.0",
		"content_schema_version": 1,
		"content_fingerprint": source_identity["content_fingerprint"],
		"save_migrations": [],
	}
	var exact := Migration.resolve_source(source_identity, [exact_summary])
	var changed_summary: Dictionary = exact_summary.duplicate(true)
	changed_summary["content_fingerprint"] = "sha256:%s" % "b".repeat(64)
	var changed := Migration.resolve_source(source_identity, [changed_summary])
	var successor_summary: Dictionary = changed_summary.duplicate(true)
	successor_summary["package_version"] = "2.0.0"
	successor_summary["save_migrations"] = [declaration]
	var successor := Migration.resolve_source(source_identity, [successor_summary])
	var incompatible_summary: Dictionary = successor_summary.duplicate(true)
	incompatible_summary["save_migrations"] = []
	var incompatible := Migration.resolve_source(source_identity, [incompatible_summary])
	var missing_resolution := Migration.resolve_source(source_identity, [])
	var invalid := Migration.resolve_source({}, [exact_summary])
	if (
		exact.status == Migration.STATUS_EXACT
		and exact.can_continue()
		and changed.status == Migration.STATUS_FINGERPRINT_MISMATCH
		and not changed.can_continue()
		and successor.status == Migration.STATUS_SUCCESSOR
		and successor.can_continue()
		and incompatible.status == Migration.STATUS_INCOMPATIBLE
		and missing_resolution.status == Migration.STATUS_MISSING
		and invalid.status == Migration.STATUS_INVALID
		and source_identity["package_version"] == "1.0.0"
	):
		passed += 1
		print("OK  pure source resolution distinguishes every load disposition")
	else:
		failed += 1
		print(
			(
				"FAIL source resolution: %s/%s/%s/%s/%s/%s"
				% [
					exact.status,
					changed.status,
					successor.status,
					incompatible.status,
					missing_resolution.status,
					invalid.status
				]
			)
		)
	var manifest_errors: Array[String] = []
	var manifest := PackManifest.parse(
		{
			"id": "fixture-pack",
			"version": "2.0.0",
			"builder_content_version": "1.0",
			"format_version": 1,
			"save_migrations": [declaration]
		},
		"manifest.json",
		manifest_errors
	)
	if manifest != null and manifest.save_migrations.size() == 1:
		passed += 1
		print("OK  destination manifest admits one validated direct declaration")
	else:
		failed += 1
		print("FAIL manifest migration declaration: %s" % [manifest_errors])
	var middle := _declaration()
	middle["destination_package_version"] = "1.5.0"
	middle["destination_content_fingerprint"] = "sha256:%s" % "c".repeat(64)
	var final := _declaration()
	final["source_package_version"] = "1.5.0"
	final["source_content_fingerprint"] = middle["destination_content_fingerprint"]
	var chain := Migration.plan_chain(source_identity, successor_summary, [final, middle])
	var gap := Migration.plan_chain(source_identity, successor_summary, [final])
	var ambiguous_edge: Dictionary = middle.duplicate(true)
	ambiguous_edge["destination_package_version"] = "1.6.0"
	var ambiguous_chain := Migration.plan_chain(
		source_identity, successor_summary, [middle, ambiguous_edge, final]
	)
	var cycle_edge: Dictionary = final.duplicate(true)
	cycle_edge["destination_package_version"] = "1.0.0"
	cycle_edge["destination_content_fingerprint"] = source_identity["content_fingerprint"]
	var cycle := Migration.plan_chain(source_identity, successor_summary, [middle, cycle_edge])
	if (
		chain["ok"]
		and chain["chain"].size() == 2
		and "migration_chain_gap:%s" % Migration._endpoint_key(source_identity) in gap["errors"]
		and ambiguous_chain["errors"].any(func(e): return "chain_ambiguous" in e)
		and cycle["errors"].any(func(e): return "chain_cycle" in e)
	):
		passed += 1
		print("OK  migration chain is complete and rejects gaps, cycles, and ambiguity")
	else:
		failed += 1
		print(
			(
				"FAIL migration chain contract: %s / %s / %s / %s"
				% [chain, gap, ambiguous_chain, cycle]
			)
		)
	var existing := {
		"campaign:new_campaign": true,
		"campaign:old_campaign": true,
		"campaign_node:new_node": true,
		"campaign_node:old_node": true,
		"unit:hero": true,
		"class:new_class": true,
		"skill:new_skill": true,
		"skill:old_skill": true,
	}
	var exists := func(family: String, id: String) -> bool:
		return existing.has("%s:%s" % [family, id])
	var preview := Migration.preview(source, "fixture-pack", declaration, exists)
	if (
		preview["ok"]
		and preview["save"].campaign["campaign_id"] == "new_campaign"
		and preview["save"].campaign["package_version"] == "2.0.0"
		and source.campaign["campaign_id"] == "old_campaign"
	):
		passed += 1
		print("OK  direct migration maps a deep copy and preserves the source")
	else:
		failed += 1
		print("FAIL direct migration: %s" % [preview])

	var operation_declaration := _declaration()
	operation_declaration["aliases"] = {}
	operation_declaration["operations"] = [
		{
			"op": "rename_id",
			"path": "roster.units[].class_id",
			"family": "class",
			"from": "old_class",
			"to": "new_class"
		},
		{"op": "map_value", "path": "campaign.rules.death_mode", "values": {"classic": "casual"}},
		{"op": "set_default_if_absent", "path": "campaign.vars.migration_marker", "value": true},
		{
			"op": "numeric_transform",
			"path": "party.resources.party_gold",
			"multiply": 2,
			"add": 3,
			"minimum": 0,
			"maximum": 25
		},
		{
			"op": "copy_field",
			"path": "campaign.vars.migration_marker",
			"destination": "campaign.vars.migration_marker_copy"
		},
		{
			"op": "move_field",
			"path": "campaign.vars.migration_marker_copy",
			"destination": "campaign.vars.migration_marker_moved"
		},
		{"op": "delete_field", "path": "campaign.vars.remove_me"},
	]
	var operation_source: SaveData = SaveData.from_dict(source.to_dict()) as SaveData
	operation_source.campaign["rules"]["death_mode"] = "classic"
	operation_source.campaign["vars"] = {"remove_me": 1}
	operation_source.party["resources"] = {"party_gold": 20}
	# This looks like a reference but is outside the explicit path allow-list.
	operation_source.campaign["vars"]["nested"] = {"class_id": "old_class"}
	var operation_preview := Migration.preview(
		operation_source, "fixture-pack", operation_declaration, exists
	)
	if (
		operation_preview["ok"]
		and operation_preview["save"].roster["units"][0]["class_id"] == "new_class"
		and operation_preview["save"].campaign["rules"]["death_mode"] == "casual"
		and operation_preview["save"].campaign["vars"]["migration_marker_moved"]
		and not operation_preview["save"].campaign["vars"].has("migration_marker_copy")
		and not operation_preview["save"].campaign["vars"].has("remove_me")
		and operation_preview["save"].party["resources"]["party_gold"] == 25
		and operation_preview["save"].campaign["vars"]["nested"]["class_id"] == "old_class"
		and operation_source.roster["units"][0]["class_id"] == "old_class"
	):
		passed += 1
		print("OK  allow-listed operations transform only explicit paths on a deep copy")
	else:
		failed += 1
		print("FAIL allow-listed operation engine: %s" % [operation_preview])

	var unsafe_declaration := _declaration()
	unsafe_declaration["operations"] = [
		{"op": "delete_field", "path": "integrity"},
		{
			"op": "rename_id",
			"path": "campaign.vars.class_id",
			"family": "class",
			"from": "a",
			"to": "b"
		},
		{
			"op": "numeric_transform",
			"path": "party.resources.party_gold",
			"minimum": 5,
			"maximum": 1
		},
	]
	var unsafe_errors := Migration.validate_declaration(unsafe_declaration, "fixture-pack")
	if (
		unsafe_errors.any(func(error): return "path_not_allowed" in error)
		and unsafe_errors.any(func(error): return "reference_path_mismatch" in error)
		and unsafe_errors.any(func(error): return "numeric_bounds_reversed" in error)
	):
		passed += 1
		print("OK  malformed and non-allow-listed operations are rejected before execution")
	else:
		failed += 1
		print("FAIL operation declaration validation: %s" % [unsafe_errors])

	var ambiguous := _declaration()
	ambiguous["aliases"]["class"] = {"old_class": "same", "other": "same"}
	var ambiguity_errors := Migration.validate_declaration(ambiguous, "fixture-pack")
	var cross_errors := Migration.validate_declaration(declaration, "different-pack")
	if (
		ambiguity_errors.any(func(e): return "ambiguous" in e)
		and "cross_package_migration_unsupported" in cross_errors
	):
		passed += 1
		print("OK  ambiguous aliases and cross-package v1 moves are rejected")
	else:
		failed += 1
		print("FAIL declaration validation: %s / %s" % [ambiguity_errors, cross_errors])

	var missing := Migration.preview(
		source, "fixture-pack", declaration, func(_f, _i): return false
	)
	if not missing["ok"] and missing["errors"].any(func(e): return "destination_missing" in e):
		passed += 1
		print("OK  unmapped or removed destination references block migration")
	else:
		failed += 1
		print("FAIL missing destination: %s" % [missing])

	var invalid_candidate_source: SaveData = SaveData.from_dict(source.to_dict()) as SaveData
	invalid_candidate_source.party["resources"] = {"party_gold": -1}
	var invalid_candidate := Migration.preview(
		invalid_candidate_source, "fixture-pack", declaration, exists
	)
	var migrated_identity: Dictionary = preview["save"].source if preview["ok"] else {}
	if (
		not invalid_candidate["ok"]
		and "migration_candidate_wallet_invalid:party_gold" in invalid_candidate["errors"]
		and migrated_identity.get("content_schema_version") == 1
		and migrated_identity.get("content_fingerprint") == "sha256:%s" % "b".repeat(64)
	):
		passed += 1
		print("OK  final candidate validation rewrites identity and rejects invalid wallets")
	else:
		failed += 1
		print(
			"FAIL candidate envelope validation: %s / %s" % [invalid_candidate, migrated_identity]
		)

	var mixed_board := {
		"roster": {"units": [{"unit_id": "old_hero"}]},
		"map_runtime":
		{
			"map_id": "campaign-pack://fixture-pack/2.0.0/map_02",
			"units": [{"unit_id": "old_hero"}, {"unit_id": "red_02_a"}]
		}
	}
	var board_result := {"errors": [], "mappings": [], "pass_through": []}
	var board_exists := func(family: String, id: String) -> bool:
		return id in ["new_hero", "campaign-pack://fixture-pack/2.0.0/map_02#red_02_a"]
	Migration._apply_map_runtime_unit_ids(
		mixed_board,
		{"old_hero": true},
		{"unit": {"old_hero": "new_hero"}},
		board_exists,
		board_result
	)
	# Candidate validation sees destination roster identities after aliases.
	mixed_board["roster"]["units"][0]["unit_id"] = "new_hero"
	Migration._validate_map_runtime_unit_ids(mixed_board, board_exists, board_result["errors"])
	var missing_enemy_errors: Array[String] = []
	Migration._validate_map_runtime_unit_ids(
		mixed_board,
		func(family: String, id: String) -> bool: return family != "map_unit",
		missing_enemy_errors
	)
	if (
		mixed_board["map_runtime"]["units"][0]["unit_id"] == "new_hero"
		and mixed_board["map_runtime"]["units"][1]["unit_id"] == "red_02_a"
		and board_result["errors"].is_empty()
		and missing_enemy_errors.any(func(e): return "map_unit" in e and "red_02_a" in e)
	):
		passed += 1
		print("OK  runtime roster ids migrate while map-owned units validate against their map")
	else:
		failed += 1
		print("FAIL mixed runtime unit ownership: %s / %s" % [board_result, missing_enemy_errors])

	# V0715-02: a map reference carries the SOURCE package version in its URI while
	# the registry records map ids bare, so the whole-URI lookup failed every
	# cross-version migration. The version segment is identity and is re-scoped;
	# only the trailing map id is aliased and looked up.
	var scoped_board := {
		"campaign": {"campaign_id": "c", "node_id": "n", "cleared_nodes": []},
		"map_runtime": {"map_id": "campaign-pack://fixture-pack/1.0.0/map_02", "units": []}
	}
	var scoped_result := {"errors": [], "mappings": [], "pass_through": []}
	var looked_up: Array[String] = []
	var map_exists := func(family: String, id: String) -> bool:
		if family == "map":
			looked_up.append(id)
			return id == "map_02b"
		return true
	Migration._apply_aliases(
		scoped_board,
		{"map": {"map_02": "map_02b"}},
		map_exists,
		scoped_result,
		{"package_id": "fixture-pack", "package_version": "2.0.0"}
	)
	# An empty alias table still re-scopes: the version segment is not authored content.
	var unaliased_board := {
		"campaign": {"campaign_id": "c", "node_id": "n", "cleared_nodes": []},
		"map_runtime": {"map_id": "campaign-pack://fixture-pack/1.0.0/map_02", "units": []}
	}
	var unaliased_result := {"errors": [], "mappings": [], "pass_through": []}
	Migration._rescope_map_references(
		unaliased_board,
		{"package_id": "fixture-pack", "package_version": "2.0.0"},
		unaliased_result
	)
	# A candidate still carrying the source version is rejected rather than resolved.
	var unscoped_declaration := {
		"source_package_id": "fixture-pack",
		"source_package_version": "1.0.0",
		"source_content_schema_version": 1,
		"source_content_fingerprint": "sha256:%s" % "a".repeat(64),
		"destination_package_id": "fixture-pack",
		"destination_package_version": "2.0.0",
		"destination_content_schema_version": 1,
		"destination_content_fingerprint": "sha256:%s" % "b".repeat(64),
		"aliases": {}
	}
	var unscoped_errors: Array = Migration._validate_candidate_payload(
		{
			"source":
			{
				"package_id": "fixture-pack",
				"package_version": "2.0.0",
				"content_schema_version": 1,
				"content_fingerprint": "sha256:%s" % "b".repeat(64)
			},
			"map_runtime": {"map_id": "campaign-pack://fixture-pack/1.0.0/map_02", "units": []}
		},
		unscoped_declaration,
		func(_family: String, _id: String) -> bool: return true
	)
	if (
		scoped_board["map_runtime"]["map_id"] == "campaign-pack://fixture-pack/2.0.0/map_02b"
		and looked_up == ["map_02b"]
		and scoped_result["errors"].is_empty()
		and (
			unaliased_board["map_runtime"]["map_id"] == "campaign-pack://fixture-pack/2.0.0/map_02"
		)
		and unaliased_result["errors"].is_empty()
		and unscoped_errors.any(func(e): return "migration_candidate_reference_unscoped" in e)
	):
		passed += 1
		print("OK  map URIs are re-scoped to the destination while only map ids are aliased")
	else:
		failed += 1
		print(
			(
				"FAIL map URI scoping: %s / %s / %s / %s"
				% [scoped_board, looked_up, unaliased_board, unscoped_errors]
			)
		)

	# Commit rollback is exercised with installed content and the returned-save
	# shape in test_v0716_save_return. Fabricated package identities cannot pass
	# the exact saved-catalogue write gate.
	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed else 0)


func _declaration() -> Dictionary:
	return {
		"source_package_id": "fixture-pack",
		"source_package_version": "1.0.0",
		"source_content_schema_version": 1,
		"source_content_fingerprint": "sha256:%s" % "a".repeat(64),
		"destination_package_id": "fixture-pack",
		"destination_package_version": "2.0.0",
		"destination_content_schema_version": 1,
		"destination_content_fingerprint": "sha256:%s" % "b".repeat(64),
		"aliases":
		{
			"campaign": {"old_campaign": "new_campaign"},
			"campaign_node": {"old_node": "new_node"},
			"map": {},
			"unit": {},
			"item": {},
			"class": {"old_class": "new_class"},
			"skill": {"old_skill": "new_skill"},
		},
		"operations": [],
	}
