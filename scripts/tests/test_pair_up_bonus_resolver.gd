extends SceneTree
# Run with: godot --headless --path /workspace --script res://scripts/tests/test_pair_up_bonus_resolver.gd
# Covers step 4: PairUpBonusResolver computes flat + scaling support bonuses,
# and CombatResolver applies them as duration_type="combat" modifiers so
# get_effective_stat picks them up like any other temporary buff.

const PairUpBonusTableScript = preload("res://scripts/resources/PairUpBonusTable.gd")
const PairUpBonusResolverScript = preload("res://scripts/autoloads/PairUpBonusResolver.gd")


# Builds a small in-memory bonus table so tests don't depend on the production
# values in pair_up_bonus_table.tres.
func _make_test_table() -> Resource:
	var table: Resource = PairUpBonusTableScript.new()
	table.set("class_bonuses", {
		"cavalier": {"strength": 1, "defense": 1, "speed": 1},
		"mage":     {"magic": 2, "resistance": 1},
	})
	table.set("scaling_divisor", 4)
	table.set("scaling_stats", PackedStringArray(["strength", "magic", "skill", "speed"]))
	return table


# Minimal Unit-shaped stub for CombatResolver._apply_pair_up_bonuses tests.
# Tracks add_modifier calls so the test can verify the source/duration shape.
func _mk_unit_stub() -> GDScript:
	var src := """
extends Node
var data = null
var added: Array = []
func add_modifier(stat: String, delta: int, source: String,
		duration: int, duration_type: String) -> void:
	added.append({\"stat\": stat, \"delta\": delta, \"source\": source,
		\"duration\": duration, \"duration_type\": duration_type})
func get_effective_stat(stat_name: String) -> int:
	if data == null: return 0
	var v = data.get(stat_name)
	return int(v) if v != null else 0
"""
	var script := GDScript.new()
	script.source_code = src
	script.reload()
	return script


func _init() -> void:
	print("=== PairUpBonusResolver Test ===")
	var passed := 0
	var failed := 0

	# ---- Direct resolver math (no autoload needed) ----
	var resolver: Node = PairUpBonusResolverScript.new()
	resolver.load_table(_make_test_table())

	# Unknown class still gets the scaling layer (flat block is per-class, scaling
	# applies to every support — see Q5 answer in the design doc). Strength 20 /
	# divisor 4 = 5; no flat contribution because "unknown" isn't in the table.
	var unknown: Dictionary = resolver.bonuses_for_class_and_stats("unknown", {"strength": 20})
	if int(unknown.get("strength", 0)) == 5 \
			and not unknown.has("defense"):  # defense had no scaling input AND no flat entry
		print("OK  unknown class returns scaling-only bonuses (no flat block)"); passed += 1
	else:
		print("FAIL unknown class returned: %s" % unknown); failed += 1

	# Known class: flat bonuses only when scaling stats are zero
	var flat_only: Dictionary = resolver.bonuses_for_class_and_stats("cavalier", {})
	if int(flat_only.get("strength", 0)) == 1 \
			and int(flat_only.get("defense", 0)) == 1 \
			and int(flat_only.get("speed", 0)) == 1 \
			and not flat_only.has("magic"):
		print("OK  known class returns flat block when no scaling input"); passed += 1
	else:
		print("FAIL flat-only: %s" % flat_only); failed += 1

	# Scaling adds floor(stat / 4) to listed scaling stats
	var scaled: Dictionary = resolver.bonuses_for_class_and_stats("cavalier",
		{"strength": 12, "speed": 7, "skill": 4})
	# strength: flat 1 + floor(12/4)=3 → 4
	# defense: flat 1, no scaling input → 1
	# speed: flat 1 + floor(7/4)=1 → 2
	# skill: flat 0 + floor(4/4)=1 → 1
	if int(scaled.get("strength", 0)) == 4 \
			and int(scaled.get("defense", 0)) == 1 \
			and int(scaled.get("speed", 0)) == 2 \
			and int(scaled.get("skill", 0)) == 1:
		print("OK  scaling layer adds floor(stat/divisor) per scaling stat"); passed += 1
	else:
		print("FAIL scaled: %s" % scaled); failed += 1

	# scaling_divisor <= 0 disables scaling
	var no_scale_table: Resource = _make_test_table()
	no_scale_table.set("scaling_divisor", 0)
	resolver.load_table(no_scale_table)
	var no_scale: Dictionary = resolver.bonuses_for_class_and_stats("cavalier",
		{"strength": 100})
	if int(no_scale.get("strength", 0)) == 1:  # flat only; no scaling
		print("OK  scaling_divisor <= 0 disables the scaling layer"); passed += 1
	else:
		print("FAIL scaling-disabled returned: %s" % no_scale); failed += 1
	resolver.load_table(_make_test_table())

	# Mutating the returned dict must not bleed back into the table
	var taint: Dictionary = resolver.bonuses_for_class_and_stats("cavalier", {})
	taint["strength"] = 999
	var fresh: Dictionary = resolver.bonuses_for_class_and_stats("cavalier", {})
	if int(fresh.get("strength", 0)) == 1:
		print("OK  returned dicts are isolated copies (no table mutation)"); passed += 1
	else:
		print("FAIL caller mutation leaked into next call: %s" % fresh); failed += 1

	# bonuses_for() with null support returns empty
	if resolver.bonuses_for(null).is_empty():
		print("OK  bonuses_for(null) returns empty dict"); passed += 1
	else:
		print("FAIL bonuses_for(null) returned non-empty"); failed += 1

	# bonuses_for() reads support_unit via get_effective_stat (stub path)
	var stub := _mk_unit_stub()
	var support: Node = stub.new()
	var support_data := UnitData.new()
	support_data.class_id = "cavalier"
	support_data.strength = 12
	support_data.speed = 7
	support_data.skill = 4
	support.set("data", support_data)
	var via_unit: Dictionary = resolver.bonuses_for(support)
	if int(via_unit.get("strength", 0)) == 4 \
			and int(via_unit.get("speed", 0)) == 2 \
			and int(via_unit.get("skill", 0)) == 1:
		print("OK  bonuses_for(unit) reads live stats via get_effective_stat"); passed += 1
	else:
		print("FAIL bonuses_for(unit) returned: %s" % via_unit); failed += 1

	# ---- CombatResolver._apply_pair_up_bonuses integration ----
	# Requires the live resolver autoload so the cross-autoload lookup works.
	var relay := Node.new()
	root.add_child(relay)
	await process_frame
	var cr := relay.get_node_or_null("/root/CombatResolver")
	var live_resolver := relay.get_node_or_null("/root/PairUpBonusResolver")
	relay.queue_free()
	if cr == null or live_resolver == null:
		print("BAIL: missing CombatResolver/PairUpBonusResolver autoload")
	else:
		live_resolver.load_table(_make_test_table())
		var combatant: Node = stub.new()
		var combatant_data := UnitData.new()
		combatant_data.unit_id = "lead"
		combatant.set("data", combatant_data)
		# Reuse the same support set up above (cavalier with str 12, spd 7, skl 4).
		cr.call("_apply_pair_up_bonuses", combatant, support)
		var added: Array = combatant.get("added")
		# Expect 4 non-zero modifiers: strength=4, defense=1, speed=2, skill=1
		# (magic / resistance / luck not in this support's bonus output).
		var by_stat: Dictionary = {}
		for entry in added:
			by_stat[entry["stat"]] = entry["delta"]
		var sources_ok: bool = true
		for entry in added:
			if not String(entry["source"]).begins_with("pair_up:") \
					or entry["duration_type"] != "combat":
				sources_ok = false
				break
		if added.size() == 4 and int(by_stat.get("strength", 0)) == 4 \
				and int(by_stat.get("defense", 0)) == 1 \
				and int(by_stat.get("speed", 0)) == 2 \
				and int(by_stat.get("skill", 0)) == 1 \
				and sources_ok:
			print("OK  _apply_pair_up_bonuses adds combat-duration modifiers per stat"); passed += 1
		else:
			print("FAIL integration: count=%d by_stat=%s sources_ok=%s" \
				% [added.size(), by_stat, sources_ok])
			failed += 1
		# Null support → no modifiers added.
		combatant.set("added", [])
		cr.call("_apply_pair_up_bonuses", combatant, null)
		if (combatant.get("added") as Array).is_empty():
			print("OK  _apply_pair_up_bonuses(null support) is a safe no-op"); passed += 1
		else:
			print("FAIL null support unexpectedly added modifiers"); failed += 1
		# Restore the on-disk table so any subsequent test sees production data.
		live_resolver.load_table(null)

	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
