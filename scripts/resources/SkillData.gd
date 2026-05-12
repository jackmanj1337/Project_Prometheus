class_name SkillData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
# "passive"|"start_of_turn"|"on_attack"|"on_defend"|"on_hit"|"on_kill"
# |"on_damaged"|"on_combat_start"|"on_combat_end"|"on_move"|"on_level_up"|"player_activated"
# Phase 2 triggers: "on_combat_apply_modifiers"|"on_ally_attacked"
# |"on_enemy_leaves_adjacent"|"on_map_start"|"on_shift"
@export var trigger: String = ""
# Stat used for activation roll (e.g. "skl"); empty = always triggers
@export var activation_chance_stat: String = ""
# Divisor for activation roll (e.g. 2 means SKL/2 % chance)
@export var activation_divisor: int = 2
@export var effect_id: String = ""
@export var effect_params: Dictionary = {}
@export var is_player_activated: bool = false

# -1 = unlimited. Checked against UnitData.skill_use_counters[effect_id] each use.
@export var max_uses_per_map: int = -1
# -1 = unlimited. Counter cleared after each combat resolves.
@export var max_uses_per_combat: int = -1
