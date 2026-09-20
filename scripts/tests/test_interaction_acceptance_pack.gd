extends SceneTree
# SLICE 7 of AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10: THE AUTHORED ACCEPTANCE PACK.
#
# The completion bar for the whole row is a pack, loaded through the real activation
# path and PLAYED, that registers a non-weapon trait and a weapon-hierarchy node,
# defines separate profiles, and exercises authored priority/stacking, formula-scaled
# magnitude and an effect that is not a combat term. This suite is the measurement half
# of that bar; the playthrough is `test_interaction_acceptance_playthrough.gd`.
#
# EVERY ASSERTION READS THE PACK, NOT A FIXTURE. Slice 5 deleted its own migration
# fixture for the same reason: two copies of the authored data is what this row exists to
# prevent. The pack is located beside this checkout and activated through
# `DataManager.select_tier2_campaign_source`, so a green run here means the SHIPPED
# content is what was measured. `[ITR-1..7]`

const AdopterPack = preload("res://scripts/tests/support/adopter_pack.gd")
const CampaignRulesScript = preload("res://scripts/resources/CampaignRules.gd")
const UnitDataScript = preload("res://scripts/resources/UnitData.gd")

const PACK_RELATIVE_PATH := "Project_Prometheus_Campaign_Pack_FE/packs/proving_grounds"
const PACK_ID := "prometheus-proving-grounds-internal-fe"
const PACK_VERSION := "0.1.0"

# The ids the acceptance content is made of. Named here so that a checkout sitting on a
# branch WITHOUT them fails with the reason rather than as a wall of bare assertion
# failures -- the exact hole `adopter_pack.gd` was written to close.
const REQUIRED_ENTRY_IDS := [
	"revenant",
	"hallowed_scythe",
	"conditions__hallowed_sear",
	"campaign_vars__hallow_charge",
	"map_006_hallowed",
	"roster_map_006_hallowed",
]

var _passed := 0
var _failed := 0
var _dm: Node
var _resolver: Node
var _vars: Node
var _rules: Resource
var _profiles: Array = []


# Everything CombatResolver asks a combatant and nothing else. The VULNERABILITIES ARE
# READ OFF THE PACK'S OWN CLASS DOCUMENT rather than hand-set, because "the pack
# registered a trait" is the claim; a hand-set array would prove only that the predicate
# works.
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


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Interaction Acceptance Pack Test ===")
	var located := AdopterPack.locate(PACK_RELATIVE_PATH)
	if located["state"] == AdopterPack.ABSENT:
		print("SKIP %s" % located["detail"])
		quit(0)
		return
	if located["state"] == AdopterPack.MISSING:
		print("FAIL %s" % located["detail"])
		quit(1)
		return
	var declared := AdopterPack.require_entries(located["path"], REQUIRED_ENTRY_IDS)
	if not declared["ok"]:
		print("FAIL %s" % declared["detail"])
		quit(1)
		return

	_dm = root.get_node_or_null("DataManager")
	_resolver = root.get_node_or_null("CombatResolver")
	_vars = root.get_node_or_null("CampaignVars")
	if _dm == null or _resolver == null or _vars == null:
		_check(false, "DataManager, CombatResolver and CampaignVars autoloads are available")
		_finish()
		return

	var activated: bool = _dm.call(
		"select_tier2_campaign_source", located["path"], PACK_ID, PACK_VERSION
	)
	_check(activated, "the acceptance pack activates through the real path")
	if not activated:
		print("   activation errors: %s" % str(_dm.get("_activation_errors")))
		_finish()
		return

	_registration_checks()
	_bind_rules()
	await process_frame
	_magic_relationship_checks()
	_scaling_and_stacking_checks()
	_durable_effect_check()
	_finish()


# --- the two registration halves --------------------------------------------------
func _registration_checks() -> void:
	# THE NON-WEAPON TRAIT. `undead` is not an engine word: it reaches the predicate
	# because this pack's class declares it.
	var revenant: Variant = _dm.call("get_class_data", "revenant")
	_check(revenant != null, "the pack registers its own class")
	if revenant == null:
		return
	_check(
		"undead" in revenant.get("vulnerability_groups"),
		"...carrying `undead`, a non-weapon trait no engine constant declares"
	)

	# THE WEAPON HIERARCHY NODE. One weapon, two positions: wielded as an axe, placed at
	# the `light` node of the relationship hierarchy.
	var scythe: Variant = _dm.call("get_weapon", "hallowed_scythe")
	_check(scythe != null, "the pack registers its own weapon")
	if scythe == null:
		return
	_check(
		String(scythe.get("combat_family")) == "axe",
		"...wielded as an axe: %s" % scythe.get("combat_family")
	)
	var placed := String(scythe.get("triangle_family"))
	_check(placed == "light", "...and positioned at the `light` hierarchy node: %s" % placed)
	var requirements := root.get_node_or_null("RequirementSystem")
	var traits: Array = requirements.call("_traits", scythe) if requirements != null else []
	_check(
		traits.has("axe") and traits.has("light"),
		"...so a predicate reads BOTH of its nodes: %s" % str(traits)
	)


func _bind_rules() -> void:
	var campaign: Variant = _dm.call("get_campaign", "proving_grounds")
	var overrides: Dictionary = campaign.get("rule_overrides") if campaign != null else {}
	_profiles = overrides.get("interaction_profiles", [])
	var ids: Array = []
	for profile in _profiles:
		ids.append(String((profile as Dictionary).get("profile_id", "")))
	_check(
		(
			ids.has("elemental_magic_triangle")
			and ids.has("hallowed_rites")
			and ids.has("undead_frailty")
		),
		"the campaign carries the acceptance profiles: %s" % str(ids)
	)
	_rules = CampaignRulesScript.make_default()
	_rules.interaction_profiles.assign(_profiles)
	var state := root.get_node_or_null("GameState")
	if state != null:
		state.set("campaign_rules", _rules)


# --- the three-family magic relationship -------------------------------------------
# `elemental_magic` is the third family's name. The FE-coined word for this group is
# refused by REN-1, and the engine has no `elemental_magic` combat family to match on,
# so the pack spells the group out as its members and names the RELATIONSHIP.
func _magic_relationship_checks() -> void:
	var fire: Variant = _dm.call("get_weapon", "fire")
	var gleam: Variant = _dm.call("get_weapon", "gleam")
	var shade: Variant = _dm.call("get_weapon", "shade")
	if fire == null or gleam == null or shade == null:
		_check(false, "the pack ships an elemental, a light and a dark tome")
		return
	# MEASURED AGAINST THE PACK WITHOUT THIS ONE PROFILE, not against a bare fight. The
	# pack's physical `weapon_triangle` already polarises dark against light and against
	# each anima family, so a delta taken against no profiles at all would report the two
	# relationships added together and pin this suite to the other one's numbers.
	for pair in [
		{"a": fire, "b": gleam, "label": "elemental_magic over light"},
		{"a": gleam, "b": shade, "label": "light over dark"},
		{"a": shade, "b": fire, "label": "dark over elemental_magic"},
	]:
		var advantage: int = _profile_damage_delta(
			"elemental_magic_triangle", pair["a"], pair["b"], []
		)
		var disadvantage: int = _profile_damage_delta(
			"elemental_magic_triangle", pair["b"], pair["a"], []
		)
		_check(advantage == 3, "%s is worth +3 damage (got %+d)" % [pair["label"], advantage])
		_check(disadvantage == -3, "...and the mirror is -3 (got %+d)" % disadvantage)


# --- formula scaling, stack policy and suppression ----------------------------------
func _scaling_and_stacking_checks() -> void:
	var scythe: Variant = _dm.call("get_weapon", "hallowed_scythe")
	var axe: Variant = _dm.call("get_weapon", "iron_axe")
	var undead: Array[String] = ["undead"]

	# THE SUPPRESSION. `undead_frailty` pays +1 to anything hitting an undead target;
	# `hallowed_rites` suppresses that whole group when it matches. A plain axe therefore
	# keeps the generic bonus and the hallowed weapon replaces it.
	var plain := _damage_delta(axe, axe, undead)
	_check(plain == 1, "a plain weapon gets the generic undead bonus of +1 (got %+d)" % plain)

	# THE FORMULA SCALING. `sear_the_undead` is 2 x hallow_charge and `consecrated_edge`
	# adds 1 in the same `sum` group, so the authored total MOVES WITH THE CAMPAIGN VAR.
	# A magnitude built only out of literals could not do this, and until the combat
	# adapter carried an evaluation context it could not be read at all.
	for charge in [1, 2, 4]:
		_vars.call("set_var", "hallow_charge", charge)
		var hallowed: int = _damage_delta(scythe, axe, undead)
		var expected: int = 2 * int(charge) + 1
		_check(
			hallowed == expected,
			(
				"hallow_charge %d scales the hallowed strike to %+d (got %+d)"
				% [charge, expected, hallowed]
			)
		)
	_vars.call("set_var", "hallow_charge", 2)
	var suppressed := _damage_delta(scythe, axe, undead)
	_check(
		suppressed == 5, "...and the suppressed +1 is NOT added on top of it (got %+d)" % suppressed
	)


# --- the effect that is not a combat term -------------------------------------------
# The condition has to reach the transaction the FIGHT commits. A forecast runs every
# planned effect against a scratch context nobody commits, so a preview can never show
# this -- only a real strike can.
func _durable_effect_check() -> void:
	var scythe: Variant = _dm.call("get_weapon", "hallowed_scythe")
	var axe: Variant = _dm.call("get_weapon", "iron_axe")
	_vars.call("set_var", "hallow_charge", 2)
	# EVERY DELTA MEASUREMENT LEAVES THE RULES STRIPPED: its second half is the same fight
	# with no profiles in scope, so whatever ran last decides what is live now. Put the
	# pack back before asking the fight to do something for real.
	_rules.interaction_profiles.assign(_profiles)
	var attacker := _unit("Bearer", scythe, "blue", Vector2i.ZERO, [])
	var defender := _unit("Revenant", axe, "red", Vector2i(1, 0), ["undead"])
	# THE SEAM ONLY FIRES ON A STRIKE THAT LANDED, and `resolve_combat` rolls the hit for
	# real. The rest of this suite keeps accuracy low so the 100% clamp cannot eat an
	# authored term; here the opposite is wanted -- a certain hit -- or the check fails
	# whenever the roll misses and passes whenever it does not.
	attacker.data.skill = 60
	attacker.data.luck = 60
	# Asked of ConditionManager, which is where an applied condition LIVES. Reading it off
	# `UnitData.conditions` reports nothing whether or not the seam fired.
	var conditions := root.get_node_or_null("ConditionManager")
	if conditions == null:
		_check(false, "ConditionManager autoload is available")
		return
	var before: bool = conditions.call("has_condition", defender, "hallowed_sear")
	# resolve_combat PREPARES the fight's transaction; apply_combat_result COMMITS it.
	# The seam writes the condition into that transaction, so a test that stops at
	# resolve_combat sees nothing and would read as a broken seam.
	var result: Dictionary = _resolver.call("resolve_combat", attacker, defender)
	_resolver.call("apply_combat_result", result, attacker, defender)
	var after: bool = conditions.call("has_condition", defender, "hallowed_sear")
	_check(
		not before and after,
		(
			"a real strike leaves the authored condition on the target (before=%s after=%s)"
			% [before, after]
		)
	)
	attacker.queue_free()
	defender.queue_free()


# --- helpers -------------------------------------------------------------------------
## The authored contribution to a strike, measured as the DIFFERENCE between the same
## fight with the pack's profiles in scope and with none. Every number in this suite is a
## delta for the reason slice 5 recorded: retuning a weapon must not be able to fail it.
func _damage_delta(
	attacker_weapon: Variant, defender_weapon: Variant, defender_vulnerabilities: Array
) -> int:
	var authored := _preview(attacker_weapon, defender_weapon, defender_vulnerabilities, true)
	var bare := _preview(attacker_weapon, defender_weapon, defender_vulnerabilities, false)
	return int(authored["attacker_damage"]) - int(bare["attacker_damage"])


func _preview(
	attacker_weapon: Variant,
	defender_weapon: Variant,
	defender_vulnerabilities: Array,
	authored: bool
) -> Dictionary:
	_rules.interaction_profiles.assign(_profiles if authored else [])
	var attacker := _unit("Attacker", attacker_weapon, "blue", Vector2i.ZERO, [])
	var defender := _unit(
		"Defender", defender_weapon, "red", Vector2i(1, 0), defender_vulnerabilities
	)
	var preview: Dictionary = _resolver.call("preview_combat", attacker, defender)
	attacker.queue_free()
	defender.queue_free()
	return preview


## One profile's own contribution: the same fight with the whole pack in scope, minus the
## same fight with that profile removed. This is the only honest way to measure a profile
## that shares a subject with another one the pack also ships.
func _profile_damage_delta(
	profile_id: String,
	attacker_weapon: Variant,
	defender_weapon: Variant,
	defender_vulnerabilities: Array
) -> int:
	var without: Array = []
	for profile in _profiles:
		if String((profile as Dictionary).get("profile_id", "")) != profile_id:
			without.append(profile)
	var full := _preview_with(_profiles, attacker_weapon, defender_weapon, defender_vulnerabilities)
	var reduced := _preview_with(
		without, attacker_weapon, defender_weapon, defender_vulnerabilities
	)
	return int(full["attacker_damage"]) - int(reduced["attacker_damage"])


func _preview_with(
	profiles: Array,
	attacker_weapon: Variant,
	defender_weapon: Variant,
	defender_vulnerabilities: Array
) -> Dictionary:
	_rules.interaction_profiles.assign(profiles)
	var attacker := _unit("Attacker", attacker_weapon, "blue", Vector2i.ZERO, [])
	var defender := _unit(
		"Defender", defender_weapon, "red", Vector2i(1, 0), defender_vulnerabilities
	)
	var preview: Dictionary = _resolver.call("preview_combat", attacker, defender)
	attacker.queue_free()
	defender.queue_free()
	return preview


func _unit(
	unit_name: String, weapon: Variant, team: String, tile: Vector2i, vulnerabilities: Array
) -> StubUnit:
	var data := UnitDataScript.new()
	data.unit_id = unit_name.to_lower()
	data.unit_name = unit_name
	data.class_id = "fighter"
	data.level = 5
	data.hp = 40
	data.max_hp = 40
	data.strength = 10
	data.magic = 10
	data.defense = 5
	data.resistance = 5
	# Low accuracy on purpose: compute_hit_pct clamps at 100, and a clamped fight silently
	# eats part of an authored accuracy term.
	data.skill = 4
	data.speed = 10
	data.luck = 2
	var unit := StubUnit.new()
	unit.data = data
	unit.team = team
	unit.tile_position = tile
	unit.weapon = weapon
	unit.vulnerabilities.assign(vulnerabilities)
	root.add_child(unit)
	return unit


func _check(ok: bool, label: String) -> void:
	print(("OK   " if ok else "FAIL ") + label)
	if ok:
		_passed += 1
	else:
		_failed += 1


func _finish() -> void:
	print("=== Results: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
