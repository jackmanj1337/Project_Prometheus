extends SceneTree
# Run with:
#   godot --headless --path . --script res://scripts/tests/test_save_identity_unification.gd
#
# SAVE-IDENTITY-BLOCK-UNIFICATION: the save document has ONE writer for
# package_id / package_version / content_schema_version / content_fingerprint.
# `source` is authoritative and `campaign` is derived from it.
#
# The defect being prevented is V0716-03: migration rewrote the source identity
# block but not the campaign block, and a save committed with the two disagreeing
# was unloadable. SaveMigrationService._validate_candidate_payload() already
# asserts the two agree; these probes cover the other half -- that the normal
# read/write paths cannot CREATE a disagreement in the first place.

const SaveDataScript = preload("res://scripts/save/SaveData.gd")

const FINGERPRINT_A := "sha256:1111111111111111111111111111111111111111111111111111111111111111"
const FINGERPRINT_B := "sha256:2222222222222222222222222222222222222222222222222222222222222222"


func _init() -> void:
	print("=== Save Identity Unification Test ===")
	var passed := 0
	var failed := 0

	# 1. set_identity() writes source and derives the campaign mirror.
	var save: RefCounted = SaveDataScript.new()
	(
		save
		. set_identity(
			{
				"package_id": "pack.alpha",
				"package_version": "2.0.0",
				"content_schema_version": 3,
				"content_fingerprint": FINGERPRINT_A,
				"campaign_id": "demo_campaign",
			}
		)
	)
	if _blocks_agree(save.source, save.campaign) and save.source["package_id"] == "pack.alpha":
		print("OK  set_identity writes source and derives the campaign mirror")
		passed += 1
	else:
		print("FAIL set_identity: source=%s campaign=%s" % [save.source, save.campaign])
		failed += 1

	# 2. identity() reads back the authoritative block.
	var read_back: Dictionary = save.identity()
	if (
		read_back.get("content_fingerprint", "") == FINGERPRINT_A
		and read_back.get("content_schema_version", 0) == 3
		and read_back.size() == SaveDataScript.IDENTITY_FIELDS.size()
	):
		print("OK  identity() returns the whole identity from the source block")
		passed += 1
	else:
		print("FAIL identity(): %s" % [read_back])
		failed += 1

	# 3. A divergence poked directly onto the campaign block cannot be serialized.
	#    This is the V0716-03 shape: source rewritten, campaign left stale.
	var poked: RefCounted = SaveDataScript.new()
	(
		poked
		. set_identity(
			{
				"package_id": "pack.alpha",
				"package_version": "2.0.0",
				"content_schema_version": 3,
				"content_fingerprint": FINGERPRINT_A,
				"campaign_id": "demo_campaign",
			}
		)
	)
	poked.campaign["content_fingerprint"] = FINGERPRINT_B
	poked.campaign["package_version"] = "1.0.0"
	var serialized: Dictionary = poked.to_dict()
	if _blocks_agree(serialized["source"], serialized["campaign"]):
		print("OK  to_dict re-derives the campaign mirror, so a poked divergence never lands")
		passed += 1
	else:
		print(
			(
				"FAIL to_dict divergence: source=%s campaign=%s"
				% [serialized["source"], serialized["campaign"]]
			)
		)
		failed += 1

	# 4. Reading a document that ALREADY carries a divergence resolves it in favour
	#    of source. A save written by an older build is loadable, not sticky.
	var diverged: Dictionary = _identified_payload()
	diverged["campaign"]["content_fingerprint"] = FINGERPRINT_B
	diverged["campaign"]["package_version"] = "1.0.0"
	diverged["campaign"]["content_schema_version"] = 1
	var loaded: RefCounted = SaveDataScript.from_dict(diverged)
	if (
		_blocks_agree(loaded.source, loaded.campaign)
		and loaded.campaign["content_fingerprint"] == FINGERPRINT_A
		and loaded.campaign["package_version"] == "2.0.0"
		and loaded.campaign["content_schema_version"] == 3
	):
		print("OK  loading a diverged document resolves campaign from source")
		passed += 1
	else:
		print("FAIL diverged load: source=%s campaign=%s" % [loaded.source, loaded.campaign])
		failed += 1

	# 5. Content identity carried only on campaign is PROMOTED into source, not
	#    erased by the mirror. Reading must never destroy identity.
	var campaign_only: Dictionary = _identified_payload()
	campaign_only["source"]["content_fingerprint"] = ""
	campaign_only["source"]["content_schema_version"] = 0
	campaign_only["campaign"]["content_fingerprint"] = FINGERPRINT_A
	campaign_only["campaign"]["content_schema_version"] = 3
	var promoted: RefCounted = SaveDataScript.from_dict(campaign_only)
	if (
		promoted.source["content_fingerprint"] == FINGERPRINT_A
		and promoted.source["content_schema_version"] == 3
		and _blocks_agree(promoted.source, promoted.campaign)
	):
		print("OK  campaign-only content identity is promoted into source, not erased")
		passed += 1
	else:
		print("FAIL promotion: source=%s campaign=%s" % [promoted.source, promoted.campaign])
		failed += 1

	# 6. A format-1 save still promotes its campaign-side identity (regression
	#    guard on the pre-existing legacy path).
	var legacy: RefCounted = (
		SaveDataScript
		. from_dict(
			{
				"format_version": 1,
				"campaign":
				{
					"campaign_id": "legacy_campaign",
					"package_id": "pack.legacy",
					"package_version": "1.0.0",
				},
			}
		)
	)
	if (
		legacy.source["package_id"] == "pack.legacy"
		and legacy.source["campaign_id"] == "legacy_campaign"
		and _blocks_agree(legacy.source, legacy.campaign)
	):
		print("OK  format-1 identity still promotes into source")
		passed += 1
	else:
		print("FAIL legacy promotion: source=%s campaign=%s" % [legacy.source, legacy.campaign])
		failed += 1

	# 7. apply_identity_to_payload rewrites a raw candidate the way migration does:
	#    the four destination fields land on source, campaign is derived, and a
	#    campaign_id the identity dict never mentioned survives untouched.
	var payload: Dictionary = _identified_payload()
	(
		SaveDataScript
		. apply_identity_to_payload(
			payload,
			{
				"package_id": "pack.alpha",
				"package_version": "3.0.0",
				"content_schema_version": 4,
				"content_fingerprint": FINGERPRINT_B,
			}
		)
	)
	if (
		_blocks_agree(payload["source"], payload["campaign"])
		and payload["source"]["package_version"] == "3.0.0"
		and payload["source"]["content_fingerprint"] == FINGERPRINT_B
		and payload["campaign"]["campaign_id"] == "demo_campaign"
	):
		print("OK  apply_identity_to_payload rewrites source and derives campaign")
		passed += 1
	else:
		print(
			"FAIL payload rewrite: source=%s campaign=%s" % [payload["source"], payload["campaign"]]
		)
		failed += 1

	# 8. set_identity with a partial dict leaves the untouched fields alone and
	#    still leaves both blocks in agreement.
	var partial: RefCounted = SaveDataScript.new()
	(
		partial
		. set_identity(
			{
				"package_id": "pack.alpha",
				"package_version": "2.0.0",
				"content_schema_version": 3,
				"content_fingerprint": FINGERPRINT_A,
				"campaign_id": "demo_campaign",
			}
		)
	)
	partial.set_identity({"content_fingerprint": FINGERPRINT_B, "content_schema_version": 4})
	if (
		partial.source["package_id"] == "pack.alpha"
		and partial.source["campaign_id"] == "demo_campaign"
		and partial.source["content_fingerprint"] == FINGERPRINT_B
		and _blocks_agree(partial.source, partial.campaign)
	):
		print("OK  a partial set_identity keeps the rest of the identity and stays in step")
		passed += 1
	else:
		print("FAIL partial set: source=%s campaign=%s" % [partial.source, partial.campaign])
		failed += 1

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _blocks_agree(source: Dictionary, campaign: Dictionary) -> bool:
	for field in SaveDataScript.IDENTITY_FIELDS:
		if not campaign.has(field):
			return false
		if source.get(field) != campaign.get(field):
			return false
	return true


func _identified_payload() -> Dictionary:
	return {
		"format_version": 2,
		"source":
		{
			"package_id": "pack.alpha",
			"package_version": "2.0.0",
			"content_schema_version": 3,
			"content_fingerprint": FINGERPRINT_A,
			"campaign_id": "demo_campaign",
		},
		"campaign":
		{
			"campaign_id": "demo_campaign",
			"package_id": "pack.alpha",
			"package_version": "2.0.0",
			"content_schema_version": 3,
			"content_fingerprint": FINGERPRINT_A,
		},
	}
