class_name SkillData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
# Closed engine vocabulary: GameConstants.VALID_SKILL_TRIGGERS.
@export var trigger: String = ""
# Stat used for activation roll (e.g. "skill"); empty = always triggers
@export var activation_chance_stat: String = ""
# Divisor for activation roll (e.g. 2 means SKL/2 % chance)
@export var activation_divisor: int = 2
@export var effect_id: String = ""
@export var effect_params: Dictionary = {}
@export var is_player_activated: bool = false
# False keeps authored/debug/legacy records loadable while removing the skill
# from release-facing choices until its effect is implemented.
@export var release_available: bool = true


func is_available_for_release() -> bool:
	return release_available


# -1 = unlimited. Checked against UnitData.skill_use_counters[skill.id] each
# use (changed from effect_id in 2026-06-10 issue 2.6 so two skills sharing
# an effect_id keep isolated counters).
@export var max_uses_per_map: int = -1
# -1 = unlimited. Counter cleared after each combat resolves.
@export var max_uses_per_combat: int = -1


# Validates required fields. Called by DataManager after load; logs warnings for bad data.
func validate() -> void:
	if id.is_empty():
		push_warning("SkillData: resource missing 'id' field")
	if effect_id.is_empty():
		push_warning("SkillData '%s': missing effect_id" % id)
	if trigger.is_empty():
		push_warning("SkillData '%s': missing trigger" % id)
	elif not (trigger in GameConstants.VALID_SKILL_TRIGGERS):
		push_warning("SkillData '%s': unknown trigger '%s'" % [id, trigger])
