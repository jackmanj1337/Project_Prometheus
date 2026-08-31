class_name CombatModifierScope extends RefCounted

## Guarantees that combat-duration scratch modifiers are reverted.
##
## Stat evaluation still reads live UnitData: Resolve's "+50% STR" has to reach
## `get_effective_stat()` before `compute_damage()` asks for strength, and Pair
## Up bonuses have to be visible to every formula downstream. So those modifiers
## are applied live for the length of the fight, and this scope is what makes
## that safe: it captures `active_modifiers` for each combatant when the fight
## opens and restores exactly that array when the fight (or the forecast) ends.
##
## It replaces CombatResolver's private _snapshot_unit_state/_restore_unit_state
## pair, which the forecast and the projection each had to remember to call, and
## which restored FOUR fields because the resolver had no other way to undo the
## durable writes skills made in passing. Those durable writes now go to the
## transaction journal, so the scope's job is only the scratch modifiers.
##
## Moving stat evaluation itself onto EffectStateView — so nothing has to be
## applied live to be readable — is tracked separately as
## SHARED-EFFECT-STAT-EVALUATION-2026-08-31.

var _entries: Array[Dictionary] = []
var _released: bool = false


func capture(unit: Node) -> void:
	if unit == null or unit.data == null:
		return
	for entry in _entries:
		if entry["unit"] == unit:
			return
	_entries.append({"unit": unit, "modifiers": unit.data.active_modifiers.duplicate(true)})


func release() -> void:
	if _released:
		return
	_released = true
	for entry in _entries:
		var unit: Node = entry["unit"]
		if unit == null or not is_instance_valid(unit) or unit.data == null:
			continue
		unit.data.active_modifiers = entry["modifiers"]


func is_released() -> bool:
	return _released
