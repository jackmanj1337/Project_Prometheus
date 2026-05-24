extends Control
# Shows attacker vs defender combat stats before the player confirms an attack.
# Populated by MapCursor when entering 'previewing' state.
#
# Phase 1 More Info content (see AGENT/Docs/more_info_mode_plan_2026-05-24.md):
# the preview shows weapon-triangle and effectiveness markers because both are
# pre-requisites for the upcoming combat-preview More Info selector. Both
# fields read straight from CombatResolver.preview_combat() — the resolver is
# the math authority; this script only formats the result.

@onready var _atk_name: Label      = $Panel/HBox/AttackerBox/AtkName
@onready var _atk_hp: Label        = $Panel/HBox/AttackerBox/AtkHP
@onready var _atk_dmg: Label       = $Panel/HBox/AttackerBox/AtkDmg
@onready var _atk_hit: Label       = $Panel/HBox/AttackerBox/AtkHit
@onready var _atk_crit: Label      = $Panel/HBox/AttackerBox/AtkCrit
@onready var _atk_triangle: Label  = $Panel/HBox/AttackerBox/AtkTriangle
@onready var _atk_effective: Label = $Panel/HBox/AttackerBox/AtkEffective
@onready var _def_name: Label      = $Panel/HBox/DefenderBox/DefName
@onready var _def_hp: Label        = $Panel/HBox/DefenderBox/DefHP
@onready var _def_dmg: Label       = $Panel/HBox/DefenderBox/DefDmg
@onready var _def_hit: Label       = $Panel/HBox/DefenderBox/DefHit
@onready var _def_crit: Label      = $Panel/HBox/DefenderBox/DefCrit
@onready var _def_triangle: Label  = $Panel/HBox/DefenderBox/DefTriangle
@onready var _def_effective: Label = $Panel/HBox/DefenderBox/DefEffective

# Colors tuned to read against the dark panel: green = advantage / boost,
# red = disadvantage, amber = effective. Modulate is used instead of BBCode
# because these are plain Labels and modulate avoids upgrading the whole row
# to a RichTextLabel for one short tag.
const COLOR_ADVANTAGE    := Color(0.38, 0.77, 0.33)
const COLOR_DISADVANTAGE := Color(0.85, 0.36, 0.36)
const COLOR_EFFECTIVE    := Color(0.94, 0.78, 0.30)
const COLOR_NEUTRAL      := Color(1, 1, 1, 0.6)


func _ready() -> void:
	hide()


func show_preview(attacker: Node, defender: Node) -> void:
	var cr := get_node_or_null("/root/CombatResolver")
	if cr == null:
		return
	var p: Dictionary = cr.preview_combat(attacker, defender)

	_atk_name.text = attacker.data.unit_name if attacker.data else "???"
	_atk_hp.text = "HP %d" % (attacker.data.hp if attacker.data else 0)
	_atk_dmg.text = "Dmg  %d×%d" % [p["attacker_damage"], p["attacker_attacks"]]
	_atk_hit.text = "Hit  %d%%" % p["attacker_hit"]
	_atk_crit.text = "Crit %d%%" % p["attacker_crit"]
	_apply_triangle(_atk_triangle, String(p.get("attacker_triangle", "neutral")))
	_apply_effective(_atk_effective,
		bool(p.get("attacker_effective", false)),
		float(p.get("attacker_effectiveness_mult", 1.0)))

	# Flag Vantage on the defender's name — the defender will strike first.
	var def_name: String = defender.data.unit_name if defender.data else "???"
	if p.get("defender_vantage", false):
		def_name += "  [Vantage]"
	_def_name.text = def_name
	_def_hp.text = "HP %d" % (defender.data.hp if defender.data else 0)
	if p["can_counter"]:
		_def_dmg.text = "Dmg  %d×%d" % [p["defender_damage"], p["defender_attacks"]]
		_def_hit.text = "Hit  %d%%" % p["defender_hit"]
		_def_crit.text = "Crit %d%%" % p["defender_crit"]
		_apply_triangle(_def_triangle, String(p.get("defender_triangle", "neutral")))
		_apply_effective(_def_effective,
			bool(p.get("defender_effective", false)),
			float(p.get("defender_effectiveness_mult", 1.0)))
	else:
		# No counter -> defender row is mostly blank; clear the markers too so
		# stale text from a previous preview never leaks through.
		_def_dmg.text = "No counter"
		_def_hit.text = ""
		_def_crit.text = ""
		_apply_triangle(_def_triangle, "neutral")
		_apply_effective(_def_effective, false, 1.0)

	show()


func hide_preview() -> void:
	hide()


# Writes the triangle marker into `label`. Neutral collapses to an empty
# string so the row doesn't reserve vertical space for a marker that has no
# meaning right now.
func _apply_triangle(label: Label, result: String) -> void:
	match result:
		"advantage":
			label.text = "▲ Advantage"
			label.modulate = COLOR_ADVANTAGE
		"disadvantage":
			label.text = "▼ Disadvantage"
			label.modulate = COLOR_DISADVANTAGE
		_:
			label.text = ""
			label.modulate = COLOR_NEUTRAL


# Writes the effectiveness marker. Mult is shown when > 1 so the player can
# see Giantkiller's 4× distinct from the normal 3× effective bonus.
func _apply_effective(label: Label, is_effective: bool, mult: float) -> void:
	if is_effective:
		label.text = "Effective ×%d" % int(round(mult))
		label.modulate = COLOR_EFFECTIVE
	else:
		label.text = ""
		label.modulate = COLOR_NEUTRAL
