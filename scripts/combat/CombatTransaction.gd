class_name CombatTransaction
# Explicit path rather than the class_name: a preloading autoload parses before
# the global class cache is populated, and the base resolves either way.
extends "res://scripts/actions/EffectTransaction.gd"

## One fight, prepared in full before any of it lands.
##
## Combat used to be two half-transactions. resolve_combat() rolled the dice and
## fired skill triggers, which wrote per-map skill counters to live UnitData on
## the spot; apply_combat_result() then committed HP, durability, wEXP, EXP and
## death. Between those two calls the game held a unit whose skill had been spent
## on a fight that had not happened yet, and an abandoned result left that spend
## behind with nothing to undo it.
##
## Everything durable now goes to the shared journal, and weapon durability
## joins as a participant because spending a last use destroys an inventory
## entry. It is the LAST participant deliberately: it cannot be un-spent, so
## nothing that could still refuse may run after it.
##
## What is NOT here, deliberately: EXP awards and death dispositions. Both are
## consequences the resolver runs after the commit lands, in that order, because
## a level-up draws from the RNG chain and must begin on the post-attack hash.
##
## What is no longer here: CombatModifierScope. Combat-duration modifiers used to
## be written LIVE during prepare, because stat evaluation could only read live
## UnitData, and the scope existed to promise they were taken back. They now live
## in the sink's scratch layer, which stat evaluation reads through the same view
## as everything else, so there is nothing live to take back — a forecast drops
## them with the transaction. SHARED-EFFECT-STAT-EVALUATION-2026-08-31.

const DurabilityScript = preload("res://scripts/combat/WeaponDurabilityParticipant.gd")

var durability: RefCounted


func _init() -> void:
	super()
	durability = DurabilityScript.new()
	add_participant(durability)


# Records one resolved exchange: the defender's HP loss and damage tally, the
# attacker's weapon use and weapon EXP. This is the single translation from
# "what the dice said" to "what will be written", shared by the strike series
# and by any caller that authors an exchange directly.
func prepare_exchange(exchange: Dictionary) -> void:
	var actor: Node = exchange.get("attacker")
	var target: Node = exchange.get("defender")
	var weapon = exchange.get("weapon")
	var step_id := next_step("exchange")

	if bool(exchange.get("loses_durability", false)):
		durability.plan(actor, String(weapon.id) if weapon != null else "")
	if not bool(exchange.get("hit", false)):
		return
	prepare_weapon_exp(actor, weapon)
	# Count HP actually lost, not the raw computed damage — an overkill blow
	# must not inflate damage_taken_this_map.
	var lost: int = sink.damage(step_id, target, int(exchange.get("damage", 0)))
	sink.add_damage_taken(step_id, target, lost)


func prepare_weapon_exp(unit: Node, weapon) -> void:
	if weapon == null or unit == null or not unit.has_method("plan_wexp_gain"):
		return
	var plan: Dictionary = unit.plan_wexp_gain(String(weapon.wexp_track), int(weapon.wexp))
	if not plan.get("ok", false):
		return
	var step_id := next_step("wexp")
	var totals: Dictionary = sink.read(unit, "weapon_wexp")
	totals[String(weapon.wexp_track)] = int(plan["next_total"])
	sink.write(step_id, unit, "weapon_wexp", totals)
	if bool(plan.get("grants_mastery", false)):
		var mastery: Array = sink.read(unit, "mastery_skills")
		mastery.append("s_rank_mastery")
		sink.write(step_id, unit, "mastery_skills", mastery)
