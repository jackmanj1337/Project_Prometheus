extends Node
# Manages status conditions (Poison, Sleep, Silence, Berserk, Stun) applied to units.
# Stub in M1 — all methods are no-ops until M8.
# Register as autoload after DataManager:
#   EventBus → SettingsManager → GameState → DataManager → ConditionManager

const CONDITION_POISON   := "poison"
const CONDITION_SLEEP    := "sleep"
const CONDITION_SILENCE  := "silence"
const CONDITION_BERSERK  := "berserk"
const CONDITION_STUN     := "stun"


# Apply a condition to a unit, refreshing duration if already present.
func apply_condition(_unit: Node, _condition_type: String, _duration: int) -> void:
	pass  # [STUB — implement in M8]


# Remove a specific condition from a unit.
func remove_condition(_unit: Node, _condition_type: String) -> void:
	pass  # [STUB — implement in M8]


# Called by TurnManager at the start of each unit's activation.
# Applies per-turn effects (e.g. Poison damage) and decrements durations.
func tick_conditions(_unit: Node) -> void:
	pass  # [STUB — implement in M8]


# Returns true if the unit currently has the given condition.
func has_condition(_unit: Node, _condition_type: String) -> bool:
	return false  # [STUB — implement in M8]


# Removes all conditions from a unit (called by Restore staff and Panacea item).
func clear_all_conditions(_unit: Node) -> void:
	pass  # [STUB — implement in M8]
