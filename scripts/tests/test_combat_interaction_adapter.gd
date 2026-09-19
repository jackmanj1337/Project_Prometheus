extends SceneTree
# Slice 5 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: THE COMBAT ADAPTER, against the
# DEFAULT PACK'S OWN DATA.
#
# The weapon triangle and weapon effectiveness were engine constants until this slice. They
# are now rules in `data/campaigns/proving_grounds.json`, and this suite reads that file --
# not a fixture -- because the thing worth asserting is that the shipped pack still says
# what the engine used to do, and that the adapter carries it into a fight. A fixture would
# prove the machinery and let the pack ship empty.
#
# EVERY NUMBER HERE IS A DIFFERENCE, not an absolute. "Advantage is worth ten points of
# accuracy and two of damage" is what the pack declares; the accuracy a particular iron
# sword produces is arithmetic tested elsewhere, and pinning it here would make this suite
# fail whenever a weapon's stats were retuned. So each case is measured twice -- once with
# the pack's profiles in scope and once with none -- and the delta is the assertion.

const CombatResolverScript = preload("res://scripts/core/CombatResolver.gd")
const RequirementSystemScript = preload("res://scripts/autoloads/RequirementSystem.gd")
const RegistryManagerScript = preload("res://scripts/autoloads/RegistryManager.gd")
const ActionEffectRunnerScript = preload("res://scripts/autoloads/ActionEffectRunner.gd")
const CampaignRulesScript = preload("res://scripts/resources/CampaignRules.gd")
const UnitDataScript = preload("res://scripts/resources/UnitData.gd")
const Schema = preload("res://scripts/interaction/InteractionProfileSchema.gd")
const Resolver = preload("res://scripts/interaction/InteractionRuleResolver.gd")
const Bridge = preload("res://scripts/interaction/InteractionEffectBridge.gd")

const PACK := "res://data/campaigns/proving_grounds.json"

var _resolver: Node
var _rules: Resource
var _profiles: Array = []


# Everything CombatResolver asks a combatant, and nothing else. The units are stubs on
# purpose: what is under test is the pack's data and the adapter, and a real Unit would
# bring a class registry, an inventory and a scene tree to say the same thing.
class StubUnit:
	extends Node

	var data: Resource
	var team: String = "blue"
	var tile_position: Vector2i = Vector2i.ZERO
	var weapon: Resource
	var vulnerabilities: Array[String] = []

	func get_equipped_weapon() -> Resource:
		return weapon

	func get_equipped_weapon_entry():
		if weapon == null:
			return null
		var entry = load("res://scripts/resources/InventoryEntry.gd").new()
		entry.entry_type = "weapon"
		entry.weapon_id = String(weapon.id)
		entry.uses_remaining = 40
		return entry

	func has_vulnerability(group: String) -> bool:
		return vulnerabilities.has(group)

	func has_skill(skill_id: String) -> bool:
		return data != null and skill_id in data.skills

	func has_quality(_quality: String) -> bool:
		return false

	func effective_modifiers(sink: RefCounted = null) -> Array:
		if sink != null and sink.has_method("effective_modifiers"):
			return sink.effective_modifiers(self)
		return data.active_modifiers

	func get_effective_stat(stat_name: String, sink: RefCounted = null) -> int:
		var base: Variant = data.get(stat_name)
		var total: int = int(base) if base != null else 0
		for modifier in effective_modifiers(sink):
			if String(modifier.get("stat", "")) == stat_name:
				total += int(modifier.get("delta", 0))
		return maxi(0, total)

	func battle_speed(candidate: Resource = null, sink: RefCounted = null) -> int:
		var w: Resource = candidate if candidate != null else weapon
		if w == null:
			return get_effective_stat("speed", sink)
		return (
			get_effective_stat("speed", sink)
			- maxi(0, int(w.wt) - get_effective_stat("strength", sink))
		)

	func accuracy(candidate: Resource = null, sink: RefCounted = null) -> int:
		var w: Resource = candidate if candidate != null else weapon
		var acc: int = get_effective_stat("skill", sink) * 2 + get_effective_stat("luck", sink)
		return acc + (int(w.hit) if w != null else 0)

	func dodge(candidate: Resource = null, sink: RefCounted = null) -> int:
		return battle_speed(candidate, sink) * 2 + get_effective_stat("luck", sink)

	func crit_rate(candidate: Resource = null, sink: RefCounted = null) -> int:
		var w: Resource = candidate if candidate != null else weapon
		return get_effective_stat("skill", sink) / 2 + (int(w.crit) if w != null else 0)

	func crit_avoid(sink: RefCounted = null) -> int:
		return get_effective_stat("luck", sink)

	func get_terrain_def_bonus() -> int:
		return 0

	func get_terrain_dodge_bonus() -> int:
		return 0


# A GameState with the one field combat reads off it. The real autoload brings a save
# system; the adapter wants `campaign_rules`.
class StubGameState:
	extends Node

	var campaign_rules: Resource
	var turn_number: int = 1
	var all_units: Array = []


func _init() -> void:
	print("=== Combat Interaction Adapter Test ===")
	var failed := 0
	_build_world()
	# The autoload stand-ins are only reachable by absolute path once the tree has ticked,
	# and the adapter looks them up exactly as production does.
	await process_frame
	failed += _pack_checks()
	failed += _triangle_checks()
	failed += _effectiveness_checks()
	failed += _agreement_checks()
	print("=== Combat Interaction Adapter Results: %d failed ===" % failed)
	quit(1 if failed else 0)


func _build_world() -> void:
	var requirements := RequirementSystemScript.new()
	requirements.name = "RequirementSystem"
	root.add_child(requirements)
	var registry := RegistryManagerScript.new()
	registry.name = "RegistryManager"
	root.add_child(registry)
	registry.activate_engine_baseline()
	var runner := ActionEffectRunnerScript.new()
	runner.name = "ActionEffectRunner"
	root.add_child(runner)

	var document: Variant = JSON.parse_string(FileAccess.get_file_as_string(PACK))
	_profiles = (document.get("rules", {}) as Dictionary).get("interaction_profiles", [])
	_rules = CampaignRulesScript.make_default()
	_rules.interaction_profiles.assign(_profiles)

	var state := StubGameState.new()
	state.name = "GameState"
	state.campaign_rules = _rules
	root.add_child(state)

	_resolver = CombatResolverScript.new()
	_resolver.name = "CombatResolver"
	root.add_child(_resolver)


# The pack has to be ADMISSIBLE before anything it says can matter: `DataManager` refuses a
# campaign whose profiles do not validate, so a shipped pack that failed here would not
# activate at all.
func _pack_checks() -> int:
	var failed := 0
	failed += _check(_profiles.size() == 2, "the default pack ships its authored profiles")
	var errors := (
		Schema
		. validate(
			_profiles,
			{
				"rules": _rules,
				"requirements": root.get_node_or_null("RequirementSystem"),
				"catalog": root.get_node_or_null("RegistryManager"),
			}
		)
	)
	failed += _check(
		errors.is_empty(), "...and they validate against the shipped catalogue: %s" % str(errors)
	)

	# Admissible is not the same as runnable: every composition the pack names must also be
	# in the live catalogue, and every magnitude must evaluate. A profile that plans with a
	# `skipped` payload is one that matched and did nothing, which is this system's quietest
	# failure.
	var registry := root.get_node_or_null("RegistryManager")
	var sword := load("res://data/weapons/iron_sword.tres")
	var axe := load("res://data/weapons/iron_axe.tres")
	var attacker := _unit("Swordsman", sword, "blue", Vector2i.ZERO)
	var defender := _unit("Axeman", axe, "red", Vector2i(1, 0))
	var envelope := (
		Resolver
		. resolve(
			_profiles,
			"combat",
			{
				"source": attacker,
				"target": defender,
				"equipped_source": sword,
				"equipped_target": axe,
			},
			{"requirements": root.get_node_or_null("RequirementSystem"), "rules": _rules}
		)
	)
	failed += _check(
		envelope["errors"].is_empty(), "the pack resolves clean: %s" % str(envelope["errors"])
	)
	var plan := Bridge.plan(envelope, {"catalog": registry})
	failed += _check(
		plan["errors"].is_empty() and plan["skipped"].is_empty(),
		(
			"...and every effect it produced can actually run: %s %s"
			% [str(plan["errors"]), str(plan["skipped"])]
		)
	)
	return failed


func _triangle_checks() -> int:
	var failed := 0
	var sword := load("res://data/weapons/iron_sword.tres")
	var axe := load("res://data/weapons/iron_axe.tres")

	var authored := _preview(sword, axe, [], [])
	var unauthored := _preview(sword, axe, [], [], false)
	failed += _check(
		int(authored["attacker_hit"]) - int(unauthored["attacker_hit"]) == 10,
		"the pack's advantage is worth +10 accuracy: sword over axe"
	)
	failed += _check(
		int(authored["attacker_damage"]) - int(unauthored["attacker_damage"]) == 2,
		"...and +2 damage"
	)
	failed += _check(
		int(unauthored["defender_hit"]) - int(authored["defender_hit"]) == 10,
		"the losing side of the same matchup is -10 accuracy"
	)
	failed += _check(
		int(unauthored["defender_damage"]) - int(authored["defender_damage"]) == 2,
		"...and -2 damage, which is the pack's mirror rule and not an engine one"
	)
	# THE READOUT `[ITR-6]`, slice 6: one row per authored relationship, naming the profile the
	# pack declared and the rule that fired. The old `attacker_triangle` could say "advantage"
	# and nothing else; this says WHICH relationship, WHICH arm of it, and by how much.
	var atk_rows: Array = authored["attacker_interactions"]
	var def_rows: Array = authored["defender_interactions"]
	failed += _check(
		atk_rows.size() == 1 and def_rows.size() == 1,
		"one readout row per side: %s / %s" % [str(atk_rows), str(def_rows)]
	)
	if atk_rows.size() == 1 and def_rows.size() == 1:
		var atk_row: Dictionary = atk_rows[0]
		var def_row: Dictionary = def_rows[0]
		failed += _check(
			(
				String(atk_row["profile_id"]) == "weapon_triangle"
				and String(atk_row["label"]) == "Weapon Triangle"
				and bool(atk_row["authored"])
			),
			"the row names the PACK's profile and renders the label it authored"
		)
		failed += _check(
			atk_row["rule_ids"] == ["sword_vs_axe"] and def_row["rule_ids"] == ["axe_vs_sword"],
			(
				"...and each side names the arm of it that fired: %s / %s"
				% [str(atk_row["rule_ids"]), str(def_row["rule_ids"])]
			)
		)
		failed += _check(
			(
				String(atk_row["direction"]) == "advantage"
				and String(def_row["direction"]) == "disadvantage"
			),
			"the direction is read from the terms, so it cannot disagree with the numbers"
		)
		failed += _check(
			String(atk_row["summary"]) == "+10 Hit, +2 Dmg",
			"the row carries the authored numbers themselves: %s" % String(atk_row["summary"])
		)
		failed += _check(
			String(def_row["summary"]) == "-10 Hit, -2 Dmg",
			(
				"...and the mirror rule's, signed as the pack wrote them: %s"
				% String(def_row["summary"])
			)
		)
		failed += _check(
			"sword_vs_axe" in String(atk_row["detail"]),
			"the More Info body is GENERATED from this resolution, naming its own rule"
		)

	var same := _preview(sword, load("res://data/weapons/steel_sword.tres"), [], [])
	failed += _check(
		(same["attacker_interactions"] as Array).is_empty(),
		"a matchup the pack declares no rule for produces no row at all"
	)
	return failed


func _effectiveness_checks() -> int:
	var failed := 0
	var bow := load("res://data/weapons/iron_bow.tres")
	var sword := load("res://data/weapons/iron_sword.tres")

	# The bow is tagged `effective_flying`; the defender's class is vulnerable to it. Both
	# halves are needed, and both are read by the pack's rule rather than by the engine.
	var effective := _preview(bow, sword, [], ["flying"], true, 2)
	var inert := _preview(bow, sword, [], [], true, 2)
	failed += _check(
		_row_summary(effective["attacker_interactions"], "weapon_effectiveness") == "\u00d73 Might",
		(
			"the pack's effectiveness rule reads as x3 might: %s"
			% _row_summary(effective["attacker_interactions"], "weapon_effectiveness")
		)
	)
	failed += _check(
		(inert["attacker_interactions"] as Array).is_empty(),
		"...and it needs the target's vulnerability, not only the weapon's tag"
	)
	failed += _check(
		int(effective["attacker_damage"]) - int(inert["attacker_damage"]) == int(bow.mt) * 2,
		"x3 multiplies MIGHT before defence, which is where effectiveness has always applied"
	)

	# Giantkiller reads the skill off the STRIKE's actor, so a DEFENDER who has it gets the
	# x4 on its counter -- the behaviour the engine's `_get_effectiveness_multiplier` had,
	# now a higher-magnitude rule in the same stack group that `highest` picks.
	var counter := _preview(sword, bow, ["flying"], [], true, 2, ["giantkiller"])
	failed += _check(
		_row_summary(counter["defender_interactions"], "weapon_effectiveness") == "\u00d74 Might",
		(
			"a counter-attacking Giantkiller reads as x4, from the rule the pack declares: %s"
			% _row_summary(counter["defender_interactions"], "weapon_effectiveness")
		)
	)
	failed += _check(
		_row_rules(counter["defender_interactions"], "weapon_effectiveness") == ["giantkiller"],
		"...and the row names GIANTKILLER, which is what the old single float could not say"
	)
	var no_skill := _preview(sword, bow, ["flying"], [], true, 2, [])
	failed += _check(
		_row_summary(no_skill["defender_interactions"], "weapon_effectiveness") == "\u00d73 Might",
		"...and without the skill the same counter is x3: `highest` picks between them"
	)
	failed += _check(
		(
			_row_rules(no_skill["defender_interactions"], "weapon_effectiveness")
			== ["effective_weapon"]
		),
		"...naming the OTHER rule, so the readout follows the composition rather than echoing it"
	)
	return failed


# The row a profile produced on one side, or an empty dictionary. Readout rows are keyed by
# profile so a test never depends on how many OTHER relationships a matchup happened to fire.
func _row_for(rows: Variant, profile_id: String) -> Dictionary:
	for row in rows as Array:
		if String((row as Dictionary)["profile_id"]) == profile_id:
			return row as Dictionary
	return {}


func _row_summary(rows: Variant, profile_id: String) -> String:
	return String(_row_for(rows, profile_id).get("summary", ""))


func _row_rules(rows: Variant, profile_id: String) -> Array:
	return _row_for(rows, profile_id).get("rule_ids", [])


# The convergence slice 4 landed, now carrying interactions: one resolution feeds the
# preview, the projection and the fight. If the adapter had been wired into any of them
# separately this is the check that would fail.
func _agreement_checks() -> int:
	var failed := 0
	var sword := load("res://data/weapons/iron_sword.tres")
	var axe := load("res://data/weapons/iron_axe.tres")
	var attacker := _unit("Swordsman", sword, "blue", Vector2i.ZERO)
	var defender := _unit("Axeman", axe, "red", Vector2i(1, 0))

	var preview: Dictionary = _resolver.preview_combat(attacker, defender)
	_resolver.clear_exchange_projection_cache()
	var projection: Dictionary = _resolver.project_exchange(attacker, defender)
	var first_attacker_strike: Dictionary = {}
	for strike in projection.get("strikes", []):
		if String(strike["actor_role"]) == "attacker":
			first_attacker_strike = strike
			break
	failed += _check(
		(
			not first_attacker_strike.is_empty()
			and int(first_attacker_strike["damage"]) == int(preview["attacker_damage"])
		),
		"the projection and the preview read the same interaction-bearing damage"
	)
	failed += _check(
		(
			not first_attacker_strike.is_empty()
			and (is_equal_approx(
				float(first_attacker_strike["hit_probability"]),
				int(preview["attacker_hit"]) / 100.0
			))
		),
		"...and the same accuracy, triangle term included"
	)
	return failed


# One preview, with the pack's profiles in scope or with none. `distance` places the units
# so the defender can counter with the weapon it holds.
func _preview(
	attacker_weapon: Resource,
	defender_weapon: Resource,
	attacker_vulnerabilities: Array,
	defender_vulnerabilities: Array,
	authored: bool = true,
	distance: int = 1,
	defender_skills: Array = []
) -> Dictionary:
	_rules.interaction_profiles.assign(_profiles if authored else [])
	var attacker := _unit("Attacker", attacker_weapon, "blue", Vector2i.ZERO)
	attacker.vulnerabilities.assign(attacker_vulnerabilities)
	var defender := _unit("Defender", defender_weapon, "red", Vector2i(distance, 0))
	defender.vulnerabilities.assign(defender_vulnerabilities)
	defender.data.skills.assign(defender_skills)
	return _resolver.preview_combat(attacker, defender)


func _unit(unit_name: String, weapon: Resource, team: String, tile: Vector2i) -> StubUnit:
	var data := UnitDataScript.new()
	data.unit_id = unit_name.to_lower()
	data.unit_name = unit_name
	data.class_id = "soldier"
	data.level = 5
	data.hp = 30
	data.max_hp = 30
	data.strength = 10
	data.magic = 0
	data.defense = 5
	data.resistance = 2
	data.skill = 10
	data.speed = 10
	data.luck = 5
	var unit := StubUnit.new()
	unit.data = data
	unit.team = team
	unit.tile_position = tile
	unit.weapon = weapon
	root.add_child(unit)
	return unit


func _check(ok: bool, label: String) -> int:
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
