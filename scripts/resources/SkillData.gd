class_name SkillData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
# "passive"|"start_of_turn"|"on_attack"|"on_defend"|"on_hit"|"on_kill"
# |"on_damaged"|"on_combat_start"|"on_combat_end"|"on_move"|"on_level_up"|"player_activated"
# "on_combat_start_negate" runs in a pre-pass before "on_combat_start" — reserved for
# skill-cancellers (Nihil) that must resolve before the modifier skills they suppress.
# Phase 2 triggers: "on_combat_apply_modifiers"|"on_ally_attacked"
# |"on_enemy_leaves_adjacent"|"on_map_start"|"on_shift"
@export var trigger: String = ""
# Stat used for activation roll (e.g. "skill"); empty = always triggers
@export var activation_chance_stat: String = ""
# Divisor for activation roll (e.g. 2 means SKL/2 % chance)
@export var activation_divisor: int = 2
@export var effect_id: String = ""
@export var effect_params: Dictionary = {}
@export var is_player_activated: bool = false

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
