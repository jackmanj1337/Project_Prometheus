extends SceneTree
# Headless coverage for the open-registry, pack-scoped Tier-1 resolver.

const AssetResolverScript = preload("res://scripts/assets/AssetResolver.gd")
const ItemDataScript = preload("res://scripts/resources/ItemData.gd")
const WeaponDataScript = preload("res://scripts/resources/WeaponData.gd")


func _init() -> void:
	print("=== AssetResolver Test ===")
	var passed := 0
	var failed := 0
	var root_path := "user://test_asset_resolver/pack"
	var image_path := root_path.path_join("art/icons/generic.png")
	var wrote_fixture := _write_png(image_path)
	var resolver = AssetResolverScript.new(root_path)

	var icon_errors: Array[String] = resolver.register_group(
		"icons", AssetResolverScript.HANDLER_TEXTURE)
	var fallback_errors: Array[String] = resolver.register_group(
		"item_icons", AssetResolverScript.HANDLER_TEXTURE,
		[{"group": "icons", "id": "generic"}])
	var asset_error: String = resolver.register_asset(
		"icons", "generic", "art/icons/generic.png")
	var texture: Resource = resolver.resolve("icons", "generic")
	if wrote_fixture and icon_errors.is_empty() and fallback_errors.is_empty() \
			and asset_error.is_empty() and texture is Texture2D:
		print("OK  registered texture ids raw-load inside the campaign pack"); passed += 1
	else:
		print("FAIL registered texture resolution"); failed += 1

	resolver.clear_report()
	var fallback: Resource = resolver.resolve("item_icons", "missing_sword")
	var report := resolver.repair_report()
	if fallback is Texture2D and report.size() == 1 \
			and report[0]["reason"] == "missing_or_invalid":
		print("OK  missing optional assets report and follow registered fallbacks"); passed += 1
	else:
		print("FAIL fallback resolution: resource=%s report=%s" % [fallback, report]); failed += 1

	# A new authored group reuses an approved loader without changing resolver
	# code. This is the author-extensibility invariant for asset vocabularies.
	var portrait_errors: Array[String] = resolver.register_group(
		"portraits", AssetResolverScript.HANDLER_TEXTURE,
		[{"group": "icons", "id": "generic"}])
	if portrait_errors.is_empty() and resolver.resolve("portraits", "new_hero") is Texture2D:
		print("OK  data registration adds an asset group without an engine switch"); passed += 1
	else:
		print("FAIL data-defined asset group"); failed += 1

	var traversal_error: String = resolver.register_asset(
		"icons", "escape", "../../outside.png")
	if "escapes its campaign pack" in traversal_error:
		print("OK  registered paths cannot escape the campaign pack"); passed += 1
	else:
		print("FAIL traversal guard: %s" % traversal_error); failed += 1

	var unknown_errors: Array[String] = resolver.register_group("video", "raw_video")
	if unknown_errors.any(func(error): return "unknown loader 'raw_video'" in error):
		print("OK  groups fail loud when their loader primitive is unavailable"); passed += 1
	else:
		print("FAIL unknown loader validation: %s" % [unknown_errors]); failed += 1

	var item = ItemDataScript.new()
	var weapon = WeaponDataScript.new()
	item.icon = "potion"
	weapon.icon = "iron_sword"
	if item.icon == "potion" and weapon.icon == "iron_sword":
		print("OK  item and weapon schemas retain asset ids instead of textures"); passed += 1
	else:
		print("FAIL item/weapon icon schema"); failed += 1

	print("=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _write_png(path: String) -> bool:
	var parent := path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(parent)) != OK:
		return false
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.7, 1.0, 1.0))
	return image.save_png(path) == OK
