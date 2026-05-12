extends Control
# Shows attacker vs defender combat stats before the player confirms an attack.
# Populated by MapCursor when entering 'previewing' state.

@onready var _atk_name: Label = $Panel/HBox/AttackerBox/AtkName
@onready var _atk_hp: Label = $Panel/HBox/AttackerBox/AtkHP
@onready var _atk_dmg: Label = $Panel/HBox/AttackerBox/AtkDmg
@onready var _atk_hit: Label = $Panel/HBox/AttackerBox/AtkHit
@onready var _atk_crit: Label = $Panel/HBox/AttackerBox/AtkCrit
@onready var _def_name: Label = $Panel/HBox/DefenderBox/DefName
@onready var _def_hp: Label = $Panel/HBox/DefenderBox/DefHP
@onready var _def_dmg: Label = $Panel/HBox/DefenderBox/DefDmg
@onready var _def_hit: Label = $Panel/HBox/DefenderBox/DefHit
@onready var _def_crit: Label = $Panel/HBox/DefenderBox/DefCrit


func _ready() -> void:
	hide()


func show_preview(attacker: Node, defender: Node) -> void:
	var cr := get_node_or_null("/root/CombatResolver")
	if cr == null:
		return
	var p: Dictionary = cr.preview_combat(attacker, defender)

	_atk_name.text = attacker.unit_name if "unit_name" in attacker else "???"
	_atk_hp.text = "HP %d" % (attacker.current_hp if "current_hp" in attacker else 0)
	_atk_dmg.text = "Dmg  %d×%d" % [p["attacker_damage"], p["attacker_attacks"]]
	_atk_hit.text = "Hit  %d%%" % p["attacker_hit"]
	_atk_crit.text = "Crit %d%%" % p["attacker_crit"]

	_def_name.text = defender.unit_name if "unit_name" in defender else "???"
	_def_hp.text = "HP %d" % (defender.current_hp if "current_hp" in defender else 0)
	if p["can_counter"]:
		_def_dmg.text = "Dmg  %d×%d" % [p["defender_damage"], p["defender_attacks"]]
		_def_hit.text = "Hit  %d%%" % p["defender_hit"]
		_def_crit.text = "Crit %d%%" % p["defender_crit"]
	else:
		_def_dmg.text = "No counter"
		_def_hit.text = ""
		_def_crit.text = ""

	show()


func hide_preview() -> void:
	hide()
