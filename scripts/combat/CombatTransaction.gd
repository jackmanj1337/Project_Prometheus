class_name CombatTransaction extends RefCounted

## One fight, prepared in full before any of it lands.
##
## Combat used to be two half-transactions. resolve_combat() rolled the dice and
## fired skill triggers, which wrote per-map skill counters to live UnitData on
## the spot; apply_combat_result() then committed HP, durability, wEXP, EXP and
## death. Between those two calls the game held a unit whose skill had been spent
## on a fight that had not happened yet, and an abandoned result left that spend
## behind with nothing to undo it.
##
## This is the whole fight as one prepared transaction. Every durable write —
## HP, damage tallies, skill counters, weapon rank — is recorded as before/after
## evidence in the shared EffectStateView journal, and weapon durability joins as
## a fallible participant because spending a last use destroys an inventory
## entry. commit() revalidates every recorded before-value against live state
## first, so a fight resolved against state that has since moved fails whole
## rather than landing half.
##
## What is NOT here, deliberately: EXP awards and death dispositions. Both are
## consequences the resolver runs after the commit lands, in that order, because
## a level-up draws from the RNG chain and must begin on the post-attack hash.

const SinkScript = preload("res://scripts/actions/UnitStateSink.gd")
const ScopeScript = preload("res://scripts/combat/CombatModifierScope.gd")
const DurabilityScript = preload("res://scripts/combat/WeaponDurabilityParticipant.gd")

var sink: RefCounted
var scope: RefCounted
var durability: RefCounted
var committed: bool = false
var failure: Dictionary = {}

var _step: int = 0


func _init() -> void:
	sink = SinkScript.new()
	scope = ScopeScript.new()
	durability = DurabilityScript.new()


# ---- Prepare ----


# Records one resolved exchange: the defender's HP loss and damage tally, the
# attacker's weapon use and weapon EXP. This is the single translation from
# "what the dice said" to "what will be written", shared by the strike series
# and by any caller that authors an exchange directly.
func prepare_exchange(exchange: Dictionary) -> void:
	var actor: Node = exchange.get("attacker")
	var target: Node = exchange.get("defender")
	var weapon = exchange.get("weapon")
	var step_id := _next_step("exchange")

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
	var step_id := _next_step("wexp")
	var totals: Dictionary = sink.read(unit, "weapon_wexp")
	totals[String(weapon.wexp_track)] = int(plan["next_total"])
	sink.write(step_id, unit, "weapon_wexp", totals)
	if bool(plan.get("grants_mastery", false)):
		var mastery: Array = sink.read(unit, "mastery_skills")
		mastery.append("s_rank_mastery")
		sink.write(step_id, unit, "mastery_skills", mastery)


# ---- Commit ----


# Fallible participants first, then the journal — an inventory entry that has
# moved must be able to abort before any HP is written. Returns the outcome
# dictionary rather than a bare bool so the caller can report WHY a fight did
# not land.
func commit() -> Dictionary:
	if committed:
		return {"ok": true, "already_committed": true}
	var check: Dictionary = sink.state_view.revalidate()
	if not check.get("ok", false):
		failure = check
		return check
	var participant_outcome: Dictionary = durability.commit(null)
	if not participant_outcome.get("ok", false):
		failure = participant_outcome
		return participant_outcome
	var journal_outcome: Dictionary = sink.state_view.commit()
	if not journal_outcome.get("ok", false):
		durability.rollback(null)
		failure = journal_outcome
		return journal_outcome
	committed = true
	return {"ok": true}


# Presentation is replayed only after the commit lands, so no bar or signal
# announces a change the transaction went on to reject.
func flush_presentation(bus: Node) -> void:
	sink.flush_presentation(bus)


func save_fields_touched() -> Array[String]:
	return sink.state_view.journal.save_fields()


func deltas() -> Array[Dictionary]:
	return sink.state_view.journal.duplicate_entries()


func _next_step(prefix: String) -> String:
	_step += 1
	return "%s_%d" % [prefix, _step]
