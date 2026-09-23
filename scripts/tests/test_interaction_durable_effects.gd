extends SceneTree
# Slice 7's PREREQUISITE, AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: AN AUTHORED INTERACTION
# EFFECT THAT IS NOT A COMBAT TERM.
#
# Slices 1-6 gave a pack every part of a relationship except a consequence. A rule could
# move accuracy, damage, crit, avoid and might, because those land on a ledger that survives
# a forecast being thrown away — and it could not apply a condition or spend a point of HP,
# because the only place interactions ran was `strike_forecast`, which is called
# speculatively once per strike and once per projected branch into a transaction nobody
# commits. Slice 6 shipped that as a diagnostic: "an interaction wrote UnitData.hp from a
# forecast".
#
# What this suite pins is the seam that answers it, and the seam's whole risk is COUNTING.
# Firing once per forecast multiplies a durable write by however many times a UI asked for a
# number; firing from the wrong place fires it on a fight that never happened. So every
# assertion here is about HOW MANY TIMES a write landed, or about a caller that must produce
# none at all. `[ITR-7]`.

const CombatResolverScript = preload("res://scripts/core/CombatResolver.gd")
const RequirementSystemScript = preload("res://scripts/autoloads/RequirementSystem.gd")
const RegistryManagerScript = preload("res://scripts/autoloads/RegistryManager.gd")
const RegistryEntryScript = preload("res://scripts/resources/RegistryEntry.gd")
const ActionEffectRunnerScript = preload("res://scripts/autoloads/ActionEffectRunner.gd")
const CampaignRulesScript = preload("res://scripts/resources/CampaignRules.gd")
const UnitDataScript = preload("res://scripts/resources/UnitData.gd")
const WeaponDataScript = preload("res://scripts/resources/WeaponData.gd")
const Schema = preload("res://scripts/interaction/InteractionProfileSchema.gd")

# The recoil the fixture profile authors, in HP, per strike that lands.
const RECOIL := 3
# The damage bonus the MIXED fixture composition contributes as a term, beside its HP write.
const MIXED_BONUS := 4
const MIXED_RECOIL := 2

var _resolver: Node
var _rules: Resource
var _registry: Node
var _passed := 0


# Everything CombatResolver asks a combatant and nothing else, as in the slice 5 adapter
# suite. `hp` is a real UnitData field here because that is the thing under test: the sink
# reads and writes it through the transaction, so a stub that faked it would pass whether
# the seam committed or not.
class StubUnit:
	extends Node

	var data: Resource
	var team: String = "blue"
	var tile_position: Vector2i = Vector2i.ZERO
	var weapon: Resource

	func get_equipped_weapon() -> Resource:
		return weapon

	func get_equipped_weapon_entry():
		return null

	func has_vulnerability(_group: String) -> bool:
		return false

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

	func crit_rate(_candidate: Resource = null, _sink: RefCounted = null) -> int:
		return 0

	func crit_avoid(_sink: RefCounted = null) -> int:
		return 100

	func get_terrain_def_bonus() -> int:
		return 0

	func get_terrain_dodge_bonus() -> int:
		return 0


class StubGameState:
	extends Node

	var campaign_rules: Resource
	var turn_number: int = 1
	var all_units: Array = []


func _init() -> void:
	print("=== Interaction Durable Effects Test ===")
	var failed := 0
	_build_world()
	# The registry's own `_ready` deactivates the catalogue, and it has not run yet: a node
	# added from a SceneTree `_init` is readied on the first processed frame, so anything
	# committed before this await is wiped by it. Found by a fixture composition that was in
	# the catalogue when it was registered and gone by the time a fight asked for it.
	await process_frame
	_register_fixture_entries()
	failed += _catalog_checks()
	failed += _forecast_writes_nothing()
	failed += _strike_writes_once()
	failed += _miss_writes_nothing()
	failed += _mixed_composition_checks()
	print("=== Interaction Durable Effects Results: %d passed, %d failed ===" % [_passed, failed])
	quit(1 if failed else 0)


# ---- World ----------------------------------------------------------------


func _build_world() -> void:
	var requirements := RequirementSystemScript.new()
	requirements.name = "RequirementSystem"
	root.add_child(requirements)
	_registry = RegistryManagerScript.new()
	_registry.name = "RegistryManager"
	root.add_child(_registry)
	var runner := ActionEffectRunnerScript.new()
	runner.name = "ActionEffectRunner"
	root.add_child(runner)

	_rules = CampaignRulesScript.make_default()
	_rules.interaction_profiles.assign([])

	var state := StubGameState.new()
	state.name = "GameState"
	state.campaign_rules = _rules
	root.add_child(state)

	_resolver = CombatResolverScript.new()
	_resolver.name = "CombatResolver"
	root.add_child(_resolver)


# A PACK'S OWN COMPOSITION, layered over the baseline exactly as a Tier-2 package registers
# one. The mixed term-and-write composition the last case needs is not an engine entry and
# should not become one: what it exists to prove is that a composition the ENGINE never saw
# is counted correctly by the seam.
func _register_fixture_entries() -> void:
	var entries: Array[Resource] = [_mixed_composition()]
	var candidate: Dictionary = _registry.build_layered_candidate(entries, "test://interaction")
	if not _registry.commit_candidate(candidate):
		push_error("fixture registry candidate refused: %s" % str(_registry.load_errors()))


# One composition, two steps, one of each kind: a combat term that lives and dies with the
# forecast's ledger, and an HP write that has to reach the fight's transaction. A
# composition is the unit the runner prepares, so the seam cannot re-run half of one — which
# is the case the throwaway ledger in `_apply_interaction_effects` exists for.
func _mixed_composition() -> Resource:
	var entry = RegistryEntryScript.new()
	entry.id = "fixture_combat_bite"
	entry.family = "effect_compositions"
	entry.label_key = "registry.effect.fixture_combat_bite"
	entry.owner_feature = "AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10"
	entry.kind = "composition"
	entry.projection_support = true
	entry.docs_text = "Fixture: one composition that both moves a combat term and spends HP."
	entry.test_fixture = {"composition_id": "fixture_combat_bite"}
	var steps: Array[Dictionary] = [
		{
			"step_id": "term",
			"primitive_id": "apply_combat_term",
			"params": {"term": "damage", "delta": MIXED_BONUS},
			"target": {"kind": "subject", "key": "target"},
			"required": true,
			"on_failure": "abort",
		},
		{
			"step_id": "hp",
			"primitive_id": "apply_hp_delta",
			"params": {"delta": -MIXED_RECOIL},
			"target": {"kind": "subject", "key": "target"},
			"required": true,
			"on_failure": "abort",
		},
	]
	entry.composition = steps
	entry.save_fields = ([] as Array[String])
	return entry


# ---- Fixtures --------------------------------------------------------------


# "A sword drawn against an axe costs its bearer blood." Authored against `source`, so the
# HP that moves belongs to the unit whose strike it is and never mixes with the damage the
# exchange itself deals — which is what makes the count readable.
func _recoil_profile(
	composition_id: String = "combat_hp_delta", amount: int = RECOIL
) -> Dictionary:
	return {
		"profile_id": "fixture_recoil",
		"context": "combat",
		"subjects": ["source", "target", "equipped_source", "equipped_target"],
		"priority": 100,
		"stack_group": "fixture_recoil",
		"stack_policy": "highest",
		"stops_below": false,
		"presentation": {"label_key": "interaction.fixture_recoil", "display_order": 10},
		"rules":
		[
			{
				"rule_id": "sword_costs_blood",
				"when":
				{
					"op": "all",
					"children":
					[
						{
							"predicate_id": "has_trait",
							"subject": {"kind": "equipped_source"},
							"params": {"id": "sword"},
						},
						{
							"predicate_id": "has_trait",
							"subject": {"kind": "equipped_target"},
							"params": {"id": "axe"},
						},
					],
				},
				"effects":
				[
					{
						"composition_id": composition_id,
						"target": "source",
						"magnitude": {"op": "neg", "operands": [{"literal": amount}]},
					}
				],
			}
		],
	}


# ---- Cases -----------------------------------------------------------------


# The pack has to be admissible before the seam can matter, and the two compositions this
# slice adds have to be in the live catalogue — a seam with nothing durable to fire is a
# seam no pack can reach.
func _catalog_checks() -> int:
	var failed := 0
	failed += _check(
		_registry.has_entry("effect_compositions", "combat_hp_delta"),
		"the engine ships a combat composition that spends HP"
	)
	failed += _check(
		_registry.has_entry("effect_compositions", "combat_apply_condition"),
		"...and one that applies a condition, so a relationship can write state at all"
	)
	var errors := (
		Schema
		. validate(
			[_recoil_profile()],
			{
				"rules": _rules,
				"requirements": root.get_node_or_null("RequirementSystem"),
				"catalog": _registry,
			}
		)
	)
	failed += _check(
		errors.is_empty(), "a profile naming one validates against the catalogue: %s" % str(errors)
	)
	return failed


# A FORECAST LEAVES NO TRACE. `preview_combat` runs the same plan through the same bridge;
# what separates it from a fight is that it never reaches the seam.
func _forecast_writes_nothing() -> int:
	var failed := 0
	_rules.interaction_profiles.assign([_recoil_profile()])
	var attacker := _unit("Attacker", _weapon("sword", "sword"), "blue", Vector2i.ZERO)
	var defender := _unit("Defender", _weapon("axe", "axe", 0), "red", Vector2i(1, 0))

	var preview: Dictionary = _resolver.preview_combat(attacker, defender)
	failed += _check(attacker.data.hp == 30, "a preview spends no HP: %d" % attacker.data.hp)
	# The deferral is the designed path, not a fault, so it must not fill the diagnostics
	# channel. It used to: slice 6 reported every durable write as undeliverable, which
	# would have made an authored pack noisy on every forecast the UI asked for.
	failed += _check(
		(preview["interaction_diagnostics"] as Array).is_empty(),
		"...and reports no problem for deferring it: %s" % str(preview["interaction_diagnostics"])
	)
	# Asked repeatedly, because "once per forecast" and "once per fight" only diverge when a
	# caller asks more than once — which every open attack panel does.
	for _i in 5:
		_resolver.preview_combat(attacker, defender)
	_resolver.clear_exchange_projection_cache()
	_resolver.project_exchange(attacker, defender)
	failed += _check(
		attacker.data.hp == 30,
		"six previews and a projection still spend none: %d" % attacker.data.hp
	)
	return failed


# The seam itself: once per strike that landed, in the transaction the fight commits.
func _strike_writes_once() -> int:
	var failed := 0
	_rules.interaction_profiles.assign([_recoil_profile()])
	var attacker := _unit("Hitter", _weapon("sword", "sword"), "blue", Vector2i.ZERO)
	# The defender counters with a weapon that cannot land, so the only thing that moves the
	# ATTACKER's HP in this fight is the authored recoil. Equal speed, so nobody doubles.
	var defender := _unit("Target", _weapon("axe", "axe", 0), "red", Vector2i(1, 0))
	var result: Dictionary = _resolver.resolve_combat(attacker, defender)
	failed += _check(
		_landed(result, attacker) == 1,
		"the fixture lands exactly one attacker strike: %d" % _landed(result, attacker)
	)
	failed += _check(
		_landed(result, defender) == 0, "...and the counter cannot connect, so HP has one source"
	)
	failed += _check(
		attacker.data.hp == 30,
		"nothing is spent before the result is applied: %d" % attacker.data.hp
	)
	_resolver.apply_combat_result(result, attacker, defender)
	failed += _check(
		attacker.data.hp == 30 - RECOIL,
		"the authored HP cost lands exactly once, on commit: %d" % attacker.data.hp
	)
	# The defender holds an axe against a sword, which is the OTHER arm of the matchup and
	# one the fixture writes no rule for. Its direction must therefore cost it nothing
	# beyond the damage it took -- the seam fires what a DIRECTION resolved.
	failed += _check(
		defender.data.hp == 30 - _dealt(result, attacker),
		(
			"the counter-attacking side, whose direction matched no rule, spends nothing extra: %d"
			% defender.data.hp
		)
	)
	return failed


# A miss writes nothing, which is the engine's one timing choice here and the reason the
# call sits inside the hit branch rather than beside the roll.
func _miss_writes_nothing() -> int:
	var failed := 0
	_rules.interaction_profiles.assign([_recoil_profile()])
	# Zero hit chance: `compute_hit_pct` clamps at 0 and `did_hit` cannot pass. The recoil
	# is authored on the attacker, so a fight it never connects in has to leave it whole.
	var attacker := _unit("Misser", _weapon("sword", "sword", 0), "blue", Vector2i.ZERO)
	var defender := _unit("Evader", _weapon("axe", "axe", 0), "red", Vector2i(1, 0))
	# Fast, not lucky: dodge is speed-led, and luck would have raised the counter's OWN
	# accuracy as well -- which it did, and the counter landed in a case about a miss.
	defender.data.speed = 40
	defender.data.luck = 5
	var result: Dictionary = _resolver.resolve_combat(attacker, defender)
	_resolver.apply_combat_result(result, attacker, defender)
	failed += _check(
		_landed(result, attacker) == 0 and _landed(result, defender) == 0,
		"neither side connects in the fixture fight"
	)
	failed += _check(attacker.data.hp == 30, "a missed strike spends no HP: %d" % attacker.data.hp)
	failed += _check(defender.data.hp == 30, "...and neither does the side it was aimed past")
	return failed


# ONE COMPOSITION, BOTH KINDS. The term half was counted by the forecast and must not be
# counted again when the seam re-runs the composition for its durable half.
func _mixed_composition_checks() -> int:
	var failed := 0
	_rules.interaction_profiles.assign([])
	var plain_attacker := _unit("Plain", _weapon("sword", "sword"), "blue", Vector2i.ZERO)
	var plain_defender := _unit("PlainFoe", _weapon("axe", "axe", 0), "red", Vector2i(1, 0))
	var plain: Dictionary = _resolver.preview_combat(plain_attacker, plain_defender)

	# Both halves are authored on `source`, because that is the subject the term has to land
	# on to move the attacker's own damage -- a damage term is an ACTOR term, and a
	# composition is prepared against ONE authored subject for all of its steps.
	var profile := _recoil_profile("fixture_combat_bite", MIXED_RECOIL)
	(profile["rules"][0]["effects"][0] as Dictionary)["magnitude"] = {"literal": MIXED_BONUS}
	_rules.interaction_profiles.assign([profile])
	# FAST ENOUGH TO DOUBLE, and that is the whole design of this case. A term counted twice
	# is invisible in a single strike -- the forecast is computed before the seam runs -- but
	# the ledger is cached per direction, so a seam that re-ran the term into the FIGHT's
	# ledger instead of a throwaway one would make the second strike hit harder than the
	# first. Two strikes is the smallest fight that can see it.
	var attacker := _unit("Biter", _weapon("sword", "sword"), "blue", Vector2i.ZERO)
	attacker.data.speed = 20
	var defender := _unit("Bitten", _weapon("axe", "axe", 0), "red", Vector2i(1, 0))
	defender.data.hp = 90
	defender.data.max_hp = 90
	var bitten: Dictionary = _resolver.preview_combat(attacker, defender)
	failed += _check(
		int(bitten["attacker_damage"]) - int(plain["attacker_damage"]) == MIXED_BONUS,
		(
			"the term half reaches the forecast: %d vs %d"
			% [int(bitten["attacker_damage"]), int(plain["attacker_damage"])]
		)
	)

	var result: Dictionary = _resolver.resolve_combat(attacker, defender)
	var damages: Array[int] = []
	for exchange in result.get("exchanges", []):
		var ex := exchange as Dictionary
		if ex["attacker"] == attacker and bool(ex["hit"]):
			damages.append(int(ex["damage"]))
	failed += _check(
		damages.size() == 2, "the attacker doubles, so the fight has two strikes: %s" % str(damages)
	)
	failed += _check(
		damages.size() == 2 and damages[0] == damages[1],
		"...and both deal the SAME damage: a term re-run into the fight's ledger would not"
	)
	_resolver.apply_combat_result(result, attacker, defender)
	failed += _check(
		attacker.data.hp == 30 - MIXED_RECOIL * 2,
		(
			"the durable half lands once per strike, and its term half not at all: %d"
			% attacker.data.hp
		)
	)
	return failed


# ---- Helpers ---------------------------------------------------------------


func _weapon(id: String, family: String, hit: int = 200) -> Resource:
	var w = WeaponDataScript.new()
	w.id = id
	w.display_name = id
	# `has_trait` reads a weapon's combat family as one of its traits, which is how a pack
	# says "a sword" without a triangle-shaped predicate of its own.
	w.combat_family = family
	w.mt = 5
	w.hit = hit
	w.crit = 0
	w.wt = 0
	w.uses = 40
	return w


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


# Strikes by `actor` that connected. Counted off the exchange list rather than a summary
# figure because every assertion in this suite is a COUNT, and a total cannot say whether
# one write happened twice or two strikes happened once.
func _landed(result: Dictionary, actor: Node) -> int:
	var count := 0
	for exchange in result.get("exchanges", []):
		var ex := exchange as Dictionary
		if ex["attacker"] == actor and bool(ex["hit"]):
			count += 1
	return count


func _dealt(result: Dictionary, actor: Node) -> int:
	var total := 0
	for exchange in result.get("exchanges", []):
		var ex := exchange as Dictionary
		if ex["attacker"] == actor and bool(ex["hit"]):
			total += int(ex["damage"])
	return total


func _check(ok: bool, label: String) -> int:
	if ok:
		_passed += 1
	print(("OK  " if ok else "FAIL ") + label)
	return 0 if ok else 1
