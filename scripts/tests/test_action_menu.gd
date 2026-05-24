extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_action_menu.gd
# Tests ActionMenu.show_for — the Attack / Staff / Item / Wait button-availability
# logic. Uses a stub grid (so the enemy / heal-target lists are fully controlled)
# and real weapon resources for the is_healing_staff() check.

var _unit_stub: GDScript
var _grid_stub: GDScript


# Builds a stub unit: get_equipped_weapon() returns `weapon`; data.inventory =
# `entries`; get_equippable_weapons() returns `weapons` (drives the Equip button).
func _mk_unit(weapon: Variant, entries: Array, weapons: Array = []) -> Node:
	var d := UnitData.new()
	d.hp = 20
	d.max_hp = 20
	var inv: Array[InventoryEntry] = []
	for e in entries:
		inv.append(e)
	d.inventory = inv
	var u: Node = _unit_stub.new()
	u.set("data", d)
	u.set("_weapon", weapon)
	u.set("_weapons", weapons)
	root.add_child(u)
	return u


# Builds a stub grid whose two query methods return exactly the given lists.
func _mk_grid(enemies: Array, heal_targets: Array) -> Node:
	var g: Node = _grid_stub.new()
	g.set("enemies", enemies)
	g.set("heal_targets", heal_targets)
	root.add_child(g)
	return g


# An InventoryEntry that is_item() and has_uses() → makes the Item button eligible.
func _usable_item() -> InventoryEntry:
	var e := InventoryEntry.new()
	e.entry_type = "item"
	e.item_id = "vulnerary"
	e.uses_remaining = 3
	return e


func _init() -> void:
	print("=== ActionMenu Test ===")
	var passed := 0
	var failed := 0

	_unit_stub = GDScript.new()
	_unit_stub.source_code = "extends Node\nvar data = null\nvar _weapon = null\nvar _weapons: Array = []\nvar tile_position: Vector2i = Vector2i.ZERO\nvar team: String = \"blue\"\nfunc get_equipped_weapon(): return _weapon\nfunc get_equippable_weapons() -> Array: return _weapons\n"
	_unit_stub.reload()
	_grid_stub = GDScript.new()
	_grid_stub.source_code = "extends Node\nvar enemies: Array = []\nvar heal_targets: Array = []\nfunc get_attackable_enemies_from_tile(_u, _t) -> Array: return enemies\nfunc get_healable_allies(_u) -> Array: return heal_targets\n"
	_grid_stub.reload()

	var sword = load("res://data/weapons/iron_sword.tres")
	var staff = load("res://data/weapons/heal_staff.tres")
	var dummy: Array = [null]   # a non-empty list — ActionMenu only checks .size()

	# Typed Node, not ActionMenu — the ActionMenu class_name is not in the headless
	# class cache (the project types its menu refs as Node for the same reason).
	var am: Node = load("res://scenes/ui/ActionMenu.tscn").instantiate()
	root.add_child(am)
	await process_frame

	# Unavailable actions are HIDDEN (not greyed out) so the menu shrinks to
	# fit (playtest 3 #21). Assertions check visibility, not disabled.

	# ---- Attack shown: a weapon equipped + an enemy in range ----
	am.show_for(_mk_unit(sword, []), _mk_grid(dummy, []))
	if am._btn_attack.visible and am._focused_idx == 0:
		print("OK  Attack shown (weapon + enemy in range); focus on Attack"); passed += 1
	else:
		print("FAIL Attack should be shown and focused"); failed += 1

	# ---- Attack hidden: a weapon but no enemy in range ----
	am.show_for(_mk_unit(sword, []), _mk_grid([], []))
	if not am._btn_attack.visible:
		print("OK  Attack hidden when no enemy is in range"); passed += 1
	else:
		print("FAIL Attack should be hidden (no enemies)"); failed += 1

	# ---- Attack hidden: no weapon equipped, even with enemies present ----
	am.show_for(_mk_unit(null, []), _mk_grid(dummy, []))
	if not am._btn_attack.visible:
		print("OK  Attack hidden with no weapon equipped"); passed += 1
	else:
		print("FAIL Attack should be hidden (no weapon)"); failed += 1

	# ---- Staff shown: a healing staff + a heal target in range ----
	am.show_for(_mk_unit(staff, []), _mk_grid([], dummy))
	if am._btn_staff.visible:
		print("OK  Staff shown with a healing staff and a target in range"); passed += 1
	else:
		print("FAIL Staff should be shown"); failed += 1

	# ---- Staff hidden: a non-staff weapon never offers Staff ----
	am.show_for(_mk_unit(sword, []), _mk_grid([], dummy))
	if not am._btn_staff.visible:
		print("OK  Staff hidden with a non-staff weapon"); passed += 1
	else:
		print("FAIL Staff should be hidden (sword)"); failed += 1

	# ---- Item shown: inventory holds a usable item ----
	am.show_for(_mk_unit(sword, [_usable_item()]), _mk_grid([], []))
	if am._btn_item.visible:
		print("OK  Item shown when the inventory holds a usable item"); passed += 1
	else:
		print("FAIL Item should be shown"); failed += 1

	# ---- All else hidden: Item off, Wait still on, focus falls to Wait ----
	# Wait is now index 9 in _buttons: [attack, staff, item, equip, seize, escape,
	# pair_up, swap, separate, wait]. (M16 stage 3 inserted Seize at index 4; the
	# 2026-05-20 review added Escape at index 5; step 6a inserted Swap; step 6b
	# inserted Pair Up; step 6c inserted Separate before Wait.)
	am.show_for(_mk_unit(null, []), _mk_grid([], []))
	if not am._btn_item.visible and am._btn_wait.visible and am._focused_idx == 9:
		print("OK  Item hidden / Wait always shown / focus falls to Wait"); passed += 1
	else:
		print("FAIL Wait fallback: item_visible=%s wait_visible=%s focus=%d" % [
			am._btn_item.visible, am._btn_wait.visible, am._focused_idx])
		failed += 1

	# ---- Equip shown only with 2+ usable weapons (#8) ----
	am.show_for(_mk_unit(sword, [], [null, null]), _mk_grid([], []))
	var equip_two: bool = am._btn_equip.visible
	am.show_for(_mk_unit(sword, [], [null]), _mk_grid([], []))
	var equip_one: bool = not am._btn_equip.visible
	if equip_two and equip_one:
		print("OK  Equip shown with 2+ weapons, hidden with fewer (#8)"); passed += 1
	else:
		print("FAIL Equip toggle: two_ok=%s one_ok=%s" % [equip_two, equip_one]); failed += 1

	# ---- Menu shrinks when some actions are hidden (playtest 3 #21) ----
	# Full menu (all five rows) must be taller than minimal menu (Wait only).
	am.show_for(_mk_unit(sword, [_usable_item()], [null, null]), _mk_grid(dummy, dummy))
	await process_frame
	var full_h: float = am.get_combined_minimum_size().y
	am.show_for(_mk_unit(null, []), _mk_grid([], []))  # only Wait survives
	await process_frame
	var minimal_h: float = am.get_combined_minimum_size().y
	if full_h > minimal_h and minimal_h > 0:
		print("OK  ActionMenu shrinks to fit visible rows (full=%.0f minimal=%.0f)" % [full_h, minimal_h])
		passed += 1
	else:
		print("FAIL menu did not shrink: full=%.0f minimal=%.0f" % [full_h, minimal_h])
		failed += 1

	# ---- the menu renders at a real size (PanelContainer sizes to its buttons) ----
	# Regression for the audit: the old Control root was 0-height, so the panel
	# background never drew once the menu was actually shown.
	am.show_for(_mk_unit(sword, [_usable_item()]), _mk_grid(dummy, []))
	await process_frame
	if am.size.x > 0 and am.size.y > 0:
		print("OK  ActionMenu has a non-zero size (%s)" % str(am.size)); passed += 1
	else:
		print("FAIL ActionMenu size is zero: %s" % str(am.size)); failed += 1

	# ---- choosing an action hides the menu (it used to linger on screen) ----
	am.show_for(_mk_unit(sword, []), _mk_grid(dummy, []))
	var chose := [""]
	am.action_chosen.connect(func(a): chose[0] = a)
	am._btn_wait.pressed.emit()
	if not am.visible and chose[0] == "wait":
		print("OK  picking an action hides the menu and emits action_chosen")
		passed += 1
	else:
		print("FAIL menu after press: visible=%s chose=%s" % [am.visible, chose[0]])
		failed += 1

	# ── M16 stage 3: Seize + Escape button visibility ──────────────────────────
	# Stub TurnManager: can_seize / can_escape each return whatever the test sets.
	# Reproduces the gate contract without spinning up the real evaluator. Escape
	# was added in the 2026-05-20 review (H-1, reverses Decision 5 / 2026-05-17).
	var turn_stub_src := "extends Node\nvar seize_result: bool = false\nvar escape_result: bool = false\nfunc can_seize(_u, _t) -> bool: return seize_result\nfunc can_escape(_u, _t) -> bool: return escape_result\n"
	var turn_stub: GDScript = GDScript.new()
	turn_stub.source_code = turn_stub_src
	turn_stub.reload()

	# ---- Seize hidden when no TurnManager is passed (turn = null) ----
	am.show_for(_mk_unit(sword, []), _mk_grid([], []))
	if not am._btn_seize.visible and not am._btn_escape.visible:
		print("OK  Seize + Escape hidden when no TurnManager is passed"); passed += 1
	else:
		print("FAIL Seize/Escape should be hidden without a TurnManager"); failed += 1

	# ---- Seize hidden when can_seize returns false ----
	var t_no: Node = turn_stub.new()
	t_no.set("seize_result", false)
	root.add_child(t_no)
	am.show_for(_mk_unit(sword, []), _mk_grid([], []), t_no)
	if not am._btn_seize.visible:
		print("OK  Seize hidden when TurnManager.can_seize == false"); passed += 1
	else:
		print("FAIL Seize should be hidden (can_seize=false)"); failed += 1

	# ---- Seize shown when can_seize returns true ----
	var t_yes: Node = turn_stub.new()
	t_yes.set("seize_result", true)
	root.add_child(t_yes)
	am.show_for(_mk_unit(sword, []), _mk_grid([], []), t_yes)
	if am._btn_seize.visible:
		print("OK  Seize shown when TurnManager.can_seize == true"); passed += 1
	else:
		print("FAIL Seize should be shown (can_seize=true)"); failed += 1

	# ---- Escape hidden when can_escape returns false ----
	var t_esc_no: Node = turn_stub.new()
	t_esc_no.set("escape_result", false)
	root.add_child(t_esc_no)
	am.show_for(_mk_unit(sword, []), _mk_grid([], []), t_esc_no)
	if not am._btn_escape.visible:
		print("OK  Escape hidden when TurnManager.can_escape == false"); passed += 1
	else:
		print("FAIL Escape should be hidden (can_escape=false)"); failed += 1

	# ---- Escape shown when can_escape returns true ----
	var t_esc_yes: Node = turn_stub.new()
	t_esc_yes.set("escape_result", true)
	root.add_child(t_esc_yes)
	am.show_for(_mk_unit(sword, []), _mk_grid([], []), t_esc_yes)
	if am._btn_escape.visible:
		print("OK  Escape shown when TurnManager.can_escape == true"); passed += 1
	else:
		print("FAIL Escape should be shown (can_escape=true)"); failed += 1

	# ── Step 6a/6b: Pair Up + Swap button visibility ──────────────────────────
	# Swap is offered when the unit is paired; Pair Up is offered when the unit
	# is unpaired AND has an adjacent unpaired ally. Both depend on a live
	# PairUpRegistry autoload; Pair Up additionally walks grid.get_unit_at.
	var reg := root.get_node_or_null("/root/PairUpRegistry")
	if reg == null:
		print("SKIP Pair Up / Swap visibility tests (PairUpRegistry autoload absent)")
	else:
		var gs_pairs := root.get_node_or_null("/root/GameState")
		reg.call("clear")
		var paired_unit_a := _mk_unit(sword, [])
		paired_unit_a.data.unit_id = "chrom"
		paired_unit_a.set("team", "blue")
		paired_unit_a.tile_position = Vector2i(2, 2)
		var paired_unit_b := _mk_unit(sword, [])
		paired_unit_b.data.unit_id = "lissa"
		paired_unit_b.set("team", "blue")
		paired_unit_b.tile_position = Vector2i(3, 2)  # cardinal-adjacent to chrom
		if gs_pairs != null:
			gs_pairs.register_unit(paired_unit_a)
			gs_pairs.register_unit(paired_unit_b)
		reg.pair("chrom", "lissa")
		am.show_for(paired_unit_a, _mk_grid([], []))
		var paired_visible: bool = am._btn_swap.visible
		am.show_for(paired_unit_b, _mk_grid([], []))
		var support_visible: bool = am._btn_swap.visible
		reg.call("clear")
		am.show_for(paired_unit_a, _mk_grid([], []))
		var unpaired_visible: bool = am._btn_swap.visible
		if paired_visible and support_visible and not unpaired_visible:
			print("OK  Swap shown for paired lead and support; hidden when unpaired"); passed += 1
		else:
			print("FAIL Swap visibility: lead=%s support=%s unpaired=%s" \
				% [paired_visible, support_visible, unpaired_visible])
			failed += 1
		# Choosing Swap emits the "swap_roles" action name so MapCursor can route it.
		reg.pair("chrom", "lissa")
		am.show_for(paired_unit_a, _mk_grid([], []))
		var swap_chose := [""]
		am.action_chosen.connect(func(a): swap_chose[0] = a)
		am._btn_swap.pressed.emit()
		if swap_chose[0] == "swap_roles":
			print("OK  Swap button emits action_chosen('swap_roles')"); passed += 1
		else:
			print("FAIL Swap emission: %s" % swap_chose[0]); failed += 1
		reg.call("clear")

		# Pair Up visibility: needs an adjacency-aware grid stub so the
		# show_for helper can find an unpaired ally next to the lead.
		var adj_stub_src := "extends Node\nvar adjacency: Dictionary = {}\nfunc get_attackable_enemies_from_tile(_u, _t) -> Array: return []\nfunc get_healable_allies(_u) -> Array: return []\nfunc get_unit_at(tile: Vector2i): return adjacency.get(tile, null)\nfunc is_passable(tile: Vector2i, _unit) -> bool: return not adjacency.has(tile)\nfunc can_end_on_tile(tile: Vector2i, _unit) -> bool: return not adjacency.has(tile)\n"
		var adj_stub: GDScript = GDScript.new()
		adj_stub.source_code = adj_stub_src
		adj_stub.reload()
		var adj_grid: Node = adj_stub.new()
		adj_grid.set("adjacency", {Vector2i(3, 2): paired_unit_b})  # lissa next to chrom
		root.add_child(adj_grid)

		# Pair Up shown when an adjacent unpaired ally exists.
		am.show_for(paired_unit_a, adj_grid)
		var pair_btn_shown: bool = am._btn_pair_up.visible
		# Pair Up hidden if the candidate ally is already paired.
		reg.pair("chrom", "lissa")
		am.show_for(paired_unit_a, adj_grid)
		var pair_btn_hidden_when_paired: bool = not am._btn_pair_up.visible
		reg.call("clear")
		# Pair Up hidden when nobody is adjacent.
		adj_grid.set("adjacency", {})
		am.show_for(paired_unit_a, adj_grid)
		var pair_btn_hidden_when_alone: bool = not am._btn_pair_up.visible
		if pair_btn_shown and pair_btn_hidden_when_paired and pair_btn_hidden_when_alone:
			print("OK  Pair Up shown only with an adjacent unpaired ally"); passed += 1
		else:
			print("FAIL Pair Up visibility: shown=%s hidden_paired=%s hidden_alone=%s" \
				% [pair_btn_shown, pair_btn_hidden_when_paired, pair_btn_hidden_when_alone])
			failed += 1
		# Pair Up button emits "pair_up" so MapCursor can route to the targeting flow.
		adj_grid.set("adjacency", {Vector2i(3, 2): paired_unit_b})
		am.show_for(paired_unit_a, adj_grid)
		var pair_chose := [""]
		am.action_chosen.connect(func(a): pair_chose[0] = a)
		am._btn_pair_up.pressed.emit()
		if pair_chose[0] == "pair_up":
			print("OK  Pair Up button emits action_chosen('pair_up')"); passed += 1
		else:
			print("FAIL Pair Up emission: %s" % pair_chose[0]); failed += 1
		# Separate shown only for a paired lead with an adjacent legal drop tile.
		reg.call("clear")
		reg.pair("chrom", "lissa")
		paired_unit_b.tile_position = reg.OFF_MAP_TILE
		adj_grid.set("adjacency", {})
		am.show_for(paired_unit_a, adj_grid)
		var separate_shown: bool = am._btn_separate.visible
		adj_grid.set("adjacency", {
			Vector2i(2, 1): Node.new(),
			Vector2i(2, 3): Node.new(),
			Vector2i(1, 2): Node.new(),
			Vector2i(3, 2): Node.new(),
		})
		am.show_for(paired_unit_a, adj_grid)
		var separate_hidden_blocked: bool = not am._btn_separate.visible
		adj_grid.set("adjacency", {})
		var separate_chose := [""]
		am.show_for(paired_unit_a, adj_grid)
		am.action_chosen.connect(func(a): separate_chose[0] = a)
		am._btn_separate.pressed.emit()
		var separate_emits: bool = separate_chose[0] == "separate"
		if separate_shown and separate_hidden_blocked and separate_emits:
			print("OK  Separate shown only with a legal drop tile and emits action_chosen('separate')"); passed += 1
		else:
			print("FAIL Separate visibility/emission: shown=%s hidden_blocked=%s emitted=%s" % [
				separate_shown, separate_hidden_blocked, separate_emits]); failed += 1
		var gs := root.get_node_or_null("/root/GameState")
		if gs != null:
			var prior_pair_up_enabled: bool = bool(gs.get("pair_up_enabled"))
			gs.set("pair_up_enabled", false)
			reg.call("clear")
			am.show_for(paired_unit_a, adj_grid)
			var hidden_when_disabled: bool = not am._btn_pair_up.visible
			gs.set("pair_up_enabled", prior_pair_up_enabled)
			if hidden_when_disabled:
				print("OK  Pair Up hidden when the campaign setting disables it"); passed += 1
			else:
				print("FAIL Pair Up should be hidden while disabled"); failed += 1
		else:
			print("SKIP Pair Up disabled visibility test (GameState autoload absent)")
		reg.call("clear")

	print("\n=== Results: %d passed, %d failed ===" % [passed, failed])
	quit(0 if failed == 0 else 1)
