extends SceneTree
# Validates an on-disk campaign pack through the SAME path activation takes —
# CampaignTier2RuntimeAdapter.load() — rather than a second, weaker copy of the
# rules. If this passes, DataManager.select_tier2_campaign_source can activate it.
#
#   godot --headless --path . --script res://scripts/tools/validate_pack.gd -- --pack /abs/path

const CampaignTier2RuntimeAdapter = preload(
	"res://scripts/resources/CampaignTier2RuntimeAdapter.gd"
)


func _init() -> void:
	var pack := ""
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--pack" and i + 1 < args.size():
			pack = args[i + 1]
	if pack.is_empty():
		printerr("--pack is required")
		quit(2)
		return

	var manifest_raw: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(pack.path_join("manifest.json"))
	)
	if not manifest_raw is Dictionary:
		printerr("no readable manifest.json at %s" % pack)
		quit(2)
		return
	var manifest: Dictionary = manifest_raw

	var adapted = CampaignTier2RuntimeAdapter.load(
		pack, str(manifest.get("id", "")), str(manifest.get("version", ""))
	)
	print("=== pack validation: %s ===" % pack)
	print("valid: %s" % adapted.valid)
	print(
		(
			"classes=%d weapons=%d items=%d maps=%d rosters=%d campaigns=%d terrain=%d variants=%d assets=%d"
			% [
				adapted.classes.size(),
				adapted.weapons.size(),
				adapted.items.size(),
				adapted.maps.size(),
				adapted.rosters.size(),
				adapted.campaigns.size(),
				adapted.terrain.size(),
				adapted.terrain_variants.size(),
				adapted.assets.size(),
			]
		)
	)
	if not adapted.valid:
		print("--- %d error(s) ---" % adapted.errors.size())
		var shown := 0
		for error in adapted.errors:
			print("  %s" % error)
			shown += 1
			if shown >= 40:
				print("  … %d more" % (adapted.errors.size() - shown))
				break
	quit(0 if adapted.valid else 1)
