extends "res://scripts/ui/ModalScreen.gd"
# Read-only unit details page (#1). Shows a unit's full stat block, inventory and
# skills. Opened by the inspect_unit action while the cursor is over a unit;
# MapCursor suppresses cursor input while it is up. Display-only — equipping and
# editing are deferred to the inventory milestone.
#
# Extends ModalScreen (B3) for the hide-on-ready + close handling; the `closed`
# signal MapCursor listens for is inherited from the base. _unhandled_input is
# overridden here because the inspect_unit key (same key that opens it) acts as
# a close-toggle — the base's cancel-only default isn't enough.
#
# Scene: UnitDetailsScreen > Dimmer + Panel > VBox > TitleLabel, StatsLabel,
#        InventoryLabel, SkillsLabel, BtnBack.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")

@onready var _title: Label     = $Panel/VBox/TitleLabel
@onready var _stats: RichTextLabel = $Panel/VBox/StatsLabel
@onready var _inventory: Label = $Panel/VBox/InventoryLabel
@onready var _skills: Label    = $Panel/VBox/SkillsLabel
@onready var _wexp: RichTextLabel = $Panel/VBox/WexpLabel
@onready var _btn_back: Button = $Panel/VBox/BtnBack


func _ready() -> void:
	_btn_back.pressed.connect(_close)
	super._ready()  # ModalScreen does the hide()


# Populates the panel from `unit` and shows it. A null/invalid unit is ignored.
func open(unit: Node) -> void:
	if unit == null or not is_instance_valid(unit) or unit.data == null:
		return
	var d: UnitData = unit.data
	_title.text = "%s — %s   Lv %d" % [d.unit_name, d.class_id, d.level]
	_stats.text = _format_stats(unit)
	_inventory.text = _format_inventory(d)
	_skills.text = _format_skills(d)
	_wexp.text = _format_weapon_wexp(unit)
	show()
	_btn_back.grab_focus()


func _format_stats(unit: Node) -> String:
	var d: UnitData = unit.data
	var str_cur: int = _effective_stat(unit, "strength", d.strength)
	var mag_cur: int = _effective_stat(unit, "magic", d.magic)
	var skl_cur: int = _effective_stat(unit, "skill", d.skill)
	var spd_cur: int = _effective_stat(unit, "speed", d.speed)
	var def_cur: int = _effective_stat(unit, "defense", d.defense)
	var res_cur: int = _effective_stat(unit, "resistance", d.resistance)
	var lck_cur: int = _effective_stat(unit, "luck", d.luck)
	var mov_cur: int = _effective_stat(unit, "movement", d.movement)
	var lines: Array[String] = [
		"HP   %d / %d" % [d.hp, d.max_hp],
		"Str  %s  Mag  %s" % [_format_current_stat(str_cur, d.strength),
			_format_current_stat(mag_cur, d.magic)],
		"Skl  %s  Spd  %s" % [_format_current_stat(skl_cur, d.skill),
			_format_current_stat(spd_cur, d.speed)],
		"Def  %s  Res  %s" % [_format_current_stat(def_cur, d.defense),
			_format_current_stat(res_cur, d.resistance)],
		"Lck  %s  Mov  %s" % [_format_current_stat(lck_cur, d.luck),
			_format_current_stat(mov_cur, d.movement)],
		"Int  %d" % d.internal_level,
		"EXP  %d / 100" % d.exp,
		"",
		"Stat Breakdown:",
	]
	for spec in [
		{"label": "Str", "stat": "strength"},
		{"label": "Mag", "stat": "magic"},
		{"label": "Skl", "stat": "skill"},
		{"label": "Spd", "stat": "speed"},
		{"label": "Def", "stat": "defense"},
		{"label": "Res", "stat": "resistance"},
		{"label": "Lck", "stat": "luck"},
		{"label": "Mov", "stat": "movement"},
	]:
		lines.append(_format_stat_breakdown(unit, spec["label"], spec["stat"]))
	return "\n".join(lines)


func _effective_stat(unit: Node, stat_name: String, fallback_value: int) -> int:
	if unit != null and unit.has_method("get_effective_stat"):
		return int(unit.get_effective_stat(stat_name))
	return fallback_value


func _format_stat_breakdown(unit: Node, label: String, stat_name: String) -> String:
	var d: UnitData = unit.data
	var base_value: int = int(d.get(stat_name))
	var effective: int = _effective_stat(unit, stat_name, base_value)
	var parts: Array[String] = []
	var total_delta: int = 0
	for mod in d.active_modifiers:
		if String(mod.get("stat", "")) != stat_name:
			continue
		var delta: int = int(mod.get("delta", 0))
		total_delta += delta
		parts.append("%s %s" % [String(mod.get("source", "?")), _signed(delta)])
	var mod_text: String = "mods: none"
	if not parts.is_empty():
		mod_text = "mods: " + ", ".join(parts)
	return "%s  base %d; %s; total %d" % [label, base_value, mod_text, effective]


func _signed(value: int) -> String:
	return ("%+d" % value)


func _format_current_stat(current: int, base: int) -> String:
	var value_text: String = "%-3d" % current
	if current > base:
		return "[color=#61c454]%s[/color]" % value_text
	if current < base:
		return "[color=#d85b5b]%s[/color]" % value_text
	return value_text


func _format_inventory(d: UnitData) -> String:
	if d.inventory.is_empty():
		return "Inventory: (empty)"
	var dm := get_node_or_null("/root/DataManager")
	var lines: Array[String] = ["Inventory:"]
	for entry in d.inventory:
		var label: String = "?"
		if entry.is_weapon():
			var w: WeaponData = dm.get_weapon(entry.weapon_id) if (dm and entry.weapon_id != "") else null
			label = w.display_name if w else entry.weapon_id
		elif entry.is_item():
			var it: ItemData = dm.get_item(entry.item_id) if (dm and entry.item_id != "") else null
			label = it.display_name if it else entry.item_id
		# -1 is the infinite-use sentinel — show ∞ rather than a literal "-1".
		var uses: String = "∞" if entry.uses_remaining == -1 else str(entry.uses_remaining)
		lines.append("  %s  (%s)" % [label, uses])
	return "\n".join(lines)


func _format_skills(d: UnitData) -> String:
	if d.skills.is_empty():
		return "Skills: (none)"
	return "Skills: " + ", ".join(d.skills)


func _format_weapon_wexp(unit: Node) -> String:
	var d: UnitData = unit.data
	if d.weapon_wexp.is_empty():
		return "Weapon Ranks: (none)"
	var tracks: Array[String] = []
	for key in d.weapon_wexp.keys():
		if int(d.weapon_wexp[key]) > 0:
			tracks.append(String(key))
	tracks.sort()
	if tracks.is_empty():
		return "Weapon Ranks: (none)"
	var lines: Array[String] = ["Weapon Ranks:"]
	for track in tracks:
		var total: int = int(d.weapon_wexp.get(track, 0))
		var rank: String = unit.get_stored_weapon_rank(track) if unit.has_method("get_stored_weapon_rank") \
			else GameConstants.weapon_rank_for_wexp(total)
		var next_rank: String = GameConstants.next_weapon_rank(rank)
		var progress_text: String
		if next_rank == "":
			progress_text = "%d / MAX" % total
		else:
			progress_text = "%d / %d to %s" % [total, GameConstants.minimum_wexp_for_rank(next_rank), next_rank]
		var line := "%s  %s  %s" % [_display_track_name(track), rank, progress_text]
		var available: bool = unit.has_method("is_weapon_track_available") and unit.is_weapon_track_available(track)
		if available:
			lines.append(line)
		else:
			lines.append("[color=#9a9aa6]%s (Unavailable)[/color]" % line)
	return "\n".join(lines)


func _display_track_name(track: String) -> String:
	match track:
		"elemental_magic":
			return "Elemental Magic"
		"beaststone":
			return "Beaststone"
		"dragonstone":
			return "Dragonstone"
		_:
			return track.capitalize()


func _unhandled_input(event: InputEvent) -> void:
	# Override the base: this screen also closes on the inspect_unit key (toggle
	# behaviour — the same I press opens it and dismisses it). Cancel still closes.
	if not visible:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("inspect_unit"):
		get_viewport().set_input_as_handled()
		_close()


# _close is inherited from ModalScreen — emits `closed` and hides. Subclasses
# only override when they have an additional per-screen signal to emit.
