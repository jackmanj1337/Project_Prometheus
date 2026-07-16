extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_tile_actions.gd
# Verifies the shared TileActions helper that ActionMenu and the HUD's
# terrain More Info panel both read from. Coverage:
#   - is_available delegates to TurnManager.can_seize / can_escape
#   - placeholder ids (shop/visit/activate) report unavailable in phase 1
#   - available_for returns the actions in canonical display order
#   - display_label looks up labels, with a raw-id fallback
#   - null inputs (unit / turn) are safe and report unavailable

const TileActions = preload("res://scripts/shared/TileActions.gd")


class StubTurn:
	extends Node
	var seize_for: Array[Vector2i] = []
	var escape_for: Array[Vector2i] = []

	func can_seize(_unit: Node, tile: Vector2i) -> bool:
		return tile in seize_for

	func can_escape(_unit: Node, tile: Vector2i) -> bool:
		return tile in escape_for


# Minimal unit-shaped stub — TileActions only checks for null and forwards
# the reference to TurnManager.
class StubUnit:
	extends Node
	pass


func _init() -> void:
	print("=== TileActions Test ===")
	var passed := 0
	var failed := 0

	var unit := StubUnit.new()
	root.add_child(unit)

	var turn := StubTurn.new()
	turn.seize_for = [Vector2i(5, 5)]
	turn.escape_for = [Vector2i(0, 0), Vector2i(0, 1)]
	root.add_child(turn)

	# ---- Seize: gate forwards to TurnManager.can_seize -----------------
	if (
		TileActions.is_available("seize", unit, Vector2i(5, 5), turn)
		and not TileActions.is_available("seize", unit, Vector2i(6, 5), turn)
	):
		print("OK  seize delegates to TurnManager.can_seize")
		passed += 1
	else:
		print("FAIL seize delegation")
		failed += 1

	# ---- Escape: gate forwards to TurnManager.can_escape ---------------
	if (
		TileActions.is_available("escape", unit, Vector2i(0, 0), turn)
		and not TileActions.is_available("escape", unit, Vector2i(2, 2), turn)
	):
		print("OK  escape delegates to TurnManager.can_escape")
		passed += 1
	else:
		print("FAIL escape delegation")
		failed += 1

	# ---- Placeholders: shop/visit/activate are wired but not yet active ----
	var any_placeholder: bool = (
		TileActions.is_available("shop", unit, Vector2i(5, 5), turn)
		or TileActions.is_available("visit", unit, Vector2i(5, 5), turn)
		or TileActions.is_available("activate", unit, Vector2i(5, 5), turn)
	)
	if not any_placeholder:
		print("OK  shop / visit / activate report unavailable in phase 1")
		passed += 1
	else:
		print("FAIL placeholder gate fired without being implemented")
		failed += 1

	# ---- Null inputs are safe -----------------------------------------
	var null_safe: bool = (
		not TileActions.is_available("seize", null, Vector2i(5, 5), turn)
		and not TileActions.is_available("seize", unit, Vector2i(5, 5), null)
		and not TileActions.is_available("nonsense", unit, Vector2i(5, 5), turn)
	)
	if null_safe:
		print("OK  is_available is null-safe and rejects unknown action ids")
		passed += 1
	else:
		print("FAIL null safety")
		failed += 1

	# ---- available_for returns ids in canonical order ----------------
	# Seize tile + escape tile happen to coincide here: both gates fire,
	# and the helper must list seize first (it's earlier in _ACTION_ORDER).
	turn.escape_for = [Vector2i(5, 5)]
	var ids: Array[String] = TileActions.available_for(unit, Vector2i(5, 5), turn)
	if ids == ["seize", "escape"]:
		print("OK  available_for returns seize before escape in canonical order")
		passed += 1
	else:
		print("FAIL available_for order: %s" % str(ids))
		failed += 1

	# ---- available_for empty when nothing gates --------------------
	var empty_ids: Array[String] = TileActions.available_for(unit, Vector2i(9, 9), turn)
	if empty_ids.is_empty():
		print("OK  available_for returns empty list when no gate fires")
		passed += 1
	else:
		print("FAIL available_for non-empty when expected empty: %s" % str(empty_ids))
		failed += 1

	# ---- display_label: known labels + raw-id fallback ---------------
	if (
		TileActions.display_label("seize") == "Seize"
		and TileActions.display_label("brand_new_id") == "brand_new_id"
	):
		print("OK  display_label resolves known ids and falls back to the raw id")
		passed += 1
	else:
		print("FAIL display_label")
		failed += 1

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
