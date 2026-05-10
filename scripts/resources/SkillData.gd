class_name SkillData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
# "passive"|"start_of_turn"|"on_attack"|"on_defend"|"on_hit"|"on_kill"
# |"on_damaged"|"on_combat_start"|"on_combat_end"|"on_move"|"on_level_up"|"player_activated"
@export var trigger: String = ""
# Stat used for activation roll (e.g. "skl"); empty = always triggers
@export var activation_chance_stat: String = ""
# Divisor for activation roll (e.g. 2 means SKL/2 % chance)
@export var activation_divisor: int = 2
@export var effect_id: String = ""
@export var effect_params: Dictionary = {}
@export var is_player_activated: bool = false
