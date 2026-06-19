extends "res://scripts/ui/ModalScreen.gd"
# Read-only unit details page (#1). Shows a unit's full stat block, inventory,
# skills, and weapon ranks. Opened by the inspect_unit action while the cursor
# is over a unit; MapCursor suppresses cursor input while it is up. Equipping
# and editing are deferred to the inventory milestone.
#
# Phase-1 More Info host (see AGENT/Docs/more_info_mode_plan_2026-05-24.md).
# Every visible entry is a BBCode [url] link; clicking one populates the
# side panel via MoreInfoContent (description) and StatBreakdown (modifiers
# for stats). The `more_info` action cycles through entries in declaration
# order so a player who never reaches for the mouse can still tour them.
#
# Extends ModalScreen (B3) for hide-on-ready + close handling; the `closed`
# signal MapCursor listens for is inherited. _unhandled_input is overridden
# because the inspect_unit key is a toggle and the new more_info key cycles
# the selection.

const GameConstants    = preload("res://scripts/shared/GameConstants.gd")
const ClassData        = preload("res://scripts/resources/ClassData.gd")
const StatBreakdown    = preload("res://scripts/shared/StatBreakdown.gd")
const StatContributions = preload("res://scripts/shared/StatContributions.gd")
const MoreInfoContent  = preload("res://scripts/shared/MoreInfoContent.gd")

# Green flags a stat an active bonus is currently raising; red flags one a
# net debuff is currently lowering below its base+class value.
const _BOOST_COLOR := "#5fd35f"
const _DEBUFF_COLOR := "#ff6b6b"

@onready var _title: Label             = $Panel/HBox/VBox/TitleLabel
@onready var _stats: RichTextLabel     = $Panel/HBox/VBox/StatsLabel
@onready var _inventory: RichTextLabel = $Panel/HBox/VBox/InventoryLabel
@onready var _skills: RichTextLabel    = $Panel/HBox/VBox/SkillsLabel
@onready var _wexp: RichTextLabel      = $Panel/HBox/VBox/WexpLabel
@onready var _btn_pair: Button         = $Panel/HBox/VBox/BtnPair
@onready var _btn_back: Button         = $Panel/HBox/VBox/BtnBack
@onready var _info_title: Label        = $Panel/HBox/InfoVBox/InfoTitle
@onready var _info_hint: Label         = $Panel/HBox/InfoVBox/InfoHint
@onready var _info_desc: RichTextLabel = $Panel/HBox/InfoVBox/InfoDescription
@onready var _info_mods: RichTextLabel = $Panel/HBox/InfoVBox/InfoModifiers

# The unit currently being inspected. Stored so the side panel can look up
# modifier breakdowns on demand without re-passing the unit through every
# click handler.
var _unit: Node = null
var _paired_unit: Node = null

# Ordered list of selectable entries built during populate. Each entry is
# {"category": String, "key": String, "title": String}. `more_info` (F)
# advances through this list; clicks jump straight to the matching entry.
var _entries: Array = []

# Index into _entries for the currently displayed side-panel entry. -1 means
# no entry is selected yet — the hint is visible and description/mods are
# blank.
var _current_index: int = -1


func _ready() -> void:
	_btn_pair.pressed.connect(_on_pair_button_pressed)
	_btn_back.pressed.connect(_close)
	# Each section label exposes selectable [url=...] entries; wire the
	# meta_clicked signal so clicks open the corresponding More Info entry.
	# RichTextLabel emits meta_clicked with the [url=...] meta value.
	_stats.meta_clicked.connect(_on_entry_clicked)
	_inventory.meta_clicked.connect(_on_entry_clicked)
	_skills.meta_clicked.connect(_on_entry_clicked)
	_wexp.meta_clicked.connect(_on_entry_clicked)
	super._ready()  # ModalScreen does the hide()


# Populates the panel from `unit` and shows it. A null/invalid unit is ignored.
func open(unit: Node) -> void:
	if unit == null or not is_instance_valid(unit) or unit.data == null:
		return
	_unit = unit
	_entries.clear()
	_current_index = -1
	var d: UnitData = unit.data
	_title.text = "%s — %s   Lv %d" % [d.unit_name, d.class_id, d.level]
	_stats.text = _format_stats(unit)
	_inventory.text = _format_inventory(d)
	_skills.text = _format_skills(d)
	_wexp.text = _format_weapon_wexp(unit)
	_update_pair_button(unit)
	_reset_info_panel()
	show()
	_btn_back.grab_focus()


func _format_stats(unit: Node) -> String:
	var d: UnitData = unit.data
	# HP is shown for context but is not selectable as a modifier-bearing
	# stat row (max_hp tracking is a separate concern). Make it a plain link
	# so the player can still read its More Info description.
	_entries.append({"category": "stat", "key": "hp", "title": "HP"})
	var lines: Array[String] = [
		"[url=stat:hp]HP   %d / %d[/url]" % [d.hp, d.max_hp],
	]
	# Two stats per row to keep the compact summary the player is used to.
	# Each side of each row registers its own entry so F-cycling visits them
	# all in the same left-to-right, top-to-bottom order they're read.
	# Core combat stats first (unchanged scan order), then a final utility row for
	# the uncapped support stats (V020-15: CON/LoS were handbook-expected but the
	# sheet only showed Movement before).
	var pairs: Array = [
		["strength", "magic"],
		["skill",    "speed"],
		["defense",  "resistance"],
		["luck",     "movement"],
		["constitution", "line_of_sight"],
	]
	for pair in pairs:
		var left_link  := _stat_link(unit, pair[0])
		var right_link := _stat_link(unit, pair[1])
		lines.append("%s  %s" % [left_link, right_link])
	lines.append("Internal Lv  %d" % d.internal_level)
	lines.append("EXP  %d / 100" % d.exp)
	return "\n".join(lines)


# Builds one selectable stat row: friendly label, current colored value, and
# registers an entry for F-cycling. Boosted = green, lowered = red, unchanged
# = default colour — same convention the previous inline formatter used.
func _stat_link(unit: Node, stat_name: String) -> String:
	var extra_mods: Array = StatContributions.for_stat(unit, stat_name, _contribution_deps())
	var bd: Dictionary = StatBreakdown.build(unit, stat_name, null, extra_mods)
	var label: String = bd["label"]
	var current: int = bd["effective_display"]
	var base: int = bd["base"]
	_entries.append({"category": "stat", "key": stat_name, "title": label})
	var value_text: String = "%-3d" % current
	var coloured: String
	if current > base:
		coloured = "[color=#61c454]%s[/color]" % value_text
	elif current < base:
		coloured = "[color=#d85b5b]%s[/color]" % value_text
	else:
		coloured = value_text
	return "[url=stat:%s]%s  %s[/url]" % [stat_name, label, coloured]


func _format_inventory(d: UnitData) -> String:
	if d.inventory.is_empty():
		return "Inventory: (empty)"
	var dm := get_node_or_null("/root/DataManager")
	var lines: Array[String] = ["Inventory:"]
	for entry in d.inventory:
		var label: String = "?"
		var category_key: String = "weapon"
		var entry_key: String = ""
		if entry.is_weapon():
			var w: WeaponData = dm.get_weapon(entry.weapon_id) if (dm and entry.weapon_id != "") else null
			label = w.display_name if w else entry.weapon_id
			entry_key = "weapon:" + entry.weapon_id
			category_key = "weapon"
		elif entry.is_item():
			var it: ItemData = dm.get_item(entry.item_id) if (dm and entry.item_id != "") else null
			label = it.display_name if it else entry.item_id
			entry_key = "item:" + entry.item_id
			category_key = "item"
		# -1 is the infinite-use sentinel — show ∞ rather than a literal "-1".
		var uses: String = "∞" if entry.uses_remaining == -1 else str(entry.uses_remaining)
		_entries.append({
			"category": "inventory",
			"key": category_key,
			"title": label,
			"meta_key": entry_key,  # carried so clicks resolve to this row
		})
		lines.append("  [url=inventory:%s]%s  (%s)[/url]" % [category_key, label, uses])
	return "\n".join(lines)


func _update_pair_button(unit: Node) -> void:
	_paired_unit = _paired_unit_for(unit)
	if _paired_unit == null or _paired_unit.data == null:
		_btn_pair.hide()
		return
	var registry := get_node_or_null("/root/PairUpRegistry")
	var role: String = ""
	if registry != null and unit != null and unit.data != null:
		role = String(registry.call("get_role", unit.data.unit_id))
	_btn_pair.text = "View Lead" if role == "support" else "View Support"
	_btn_pair.show()


func _paired_unit_for(unit: Node) -> Node:
	if unit == null or unit.data == null or unit.data.unit_id == "":
		return null
	var registry := get_node_or_null("/root/PairUpRegistry")
	var gs := get_node_or_null("/root/GameState")
	if registry == null or gs == null or not bool(registry.call("is_paired", unit.data.unit_id)):
		return null
	var partner_id: String = registry.call("get_partner_id", unit.data.unit_id)
	if partner_id == "" or not gs.has_method("find_unit_by_id"):
		return null
	return gs.call("find_unit_by_id", partner_id)


func _on_pair_button_pressed() -> void:
	if _paired_unit != null and is_instance_valid(_paired_unit):
		open(_paired_unit)


func _format_skills(d: UnitData) -> String:
	if d.skills.is_empty():
		return "Skills: (none)"
	var rendered: Array[String] = []
	for skill_id in d.skills:
		_entries.append({"category": "skill", "key": skill_id, "title": skill_id})
		rendered.append("[url=skill:%s]%s[/url]" % [skill_id, skill_id])
	return "Skills: " + ", ".join(rendered)


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
		_entries.append({"category": "wexp", "key": track, "title": _display_track_name(track)})
		if available:
			lines.append("[url=wexp:%s]%s[/url]" % [track, line])
		else:
			# Unavailable tracks stay selectable so the player can read why a
			# weapon family is greyed out — dimmed colour keeps the affordance.
			lines.append("[url=wexp:%s][color=#9a9aa6]%s (Unavailable)[/color][/url]" % [track, line])
	return "\n".join(lines)


func _display_track_name(track: String) -> String:
	match track:
		"elemental_magic": return "Elemental Magic"
		"beaststone":      return "Beaststone"
		"dragonstone":     return "Dragonstone"
		_:                 return track.capitalize()


# Resets the side panel to its "nothing selected yet" state.
func _reset_info_panel() -> void:
	_info_title.text = "More Info"
	_info_hint.visible = true
	_info_desc.text = ""
	_info_mods.text = ""


# RichTextLabel.meta_clicked passes the [url=...] meta value. We expect
# `category:key` (e.g. "stat:strength", "inventory:weapon", "skill:rally").
# Anything else is logged-and-ignored rather than crashing.
func _on_entry_clicked(meta: Variant) -> void:
	var s: String = String(meta)
	var sep: int = s.find(":")
	if sep < 1:
		return
	var category: String = s.substr(0, sep)
	var key: String = s.substr(sep + 1)
	# Find the matching entry so F-cycling resumes from this point.
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		if e["category"] == category and e["key"] == key:
			_current_index = i
			break
	_show_entry(category, key, _title_for(category, key))


# Picks the best human-readable title for the side panel. Inventory and skill
# entries already carry their game-name in `_entries`; stat/wexp fall back to
# the friendly label.
func _title_for(category: String, key: String) -> String:
	for e in _entries:
		if e["category"] == category and e["key"] == key:
			return String(e["title"])
	# Fallback for clicks on a key we did not register (defensive).
	if category == "stat":
		return StatBreakdown.label_for_stat(key)
	return key


# Renders the side panel for (category, key). Stats also get a modifier
# breakdown via StatBreakdown; other categories show description only.
func _show_entry(category: String, key: String, title: String) -> void:
	_info_title.text = title
	_info_hint.visible = false
	_info_desc.text = MoreInfoContent.describe(category, key)
	if category == "stat" and _unit != null:
		_info_mods.text = _format_mods_block(_unit, key)
	else:
		_info_mods.text = ""


# Renders the full breakdown block for one stat: the personal/class
# decomposition, the class cap, the displayed effective value (green when an
# active bonus raises it), growth info, and every active bonus with its amount
# and source. Combat-only bonuses (pair-up, stat skills) are pulled via
# StatContributions because they never live in active_modifiers outside a fight.
func _format_mods_block(unit: Node, stat_name: String) -> String:
	var class_data: ClassData = _class_data_for(unit)
	var extra_mods: Array = StatContributions.for_stat(unit, stat_name, _contribution_deps())
	var bd: Dictionary = StatBreakdown.build(unit, stat_name, class_data, extra_mods)

	var lines: Array[String] = []
	# Decomposition — only meaningful when we resolved the class.
	if String(bd["cap_state"]) != "unknown":
		lines.append("Personal base  %d" % int(bd["personal_base"]))
		var class_name_txt: String = class_data.display_name if class_data != null else "Class"
		lines.append("Class base     %s  (%s)" % [
			StatBreakdown.format_signed(int(bd["class_base"])), class_name_txt])
		lines.append(_cap_line(bd))

	# Effective — green when a bonus raises it above base, red when a net debuff
	# lowers it below base, plain otherwise.
	var eff: int = int(bd["effective_display"])
	var eff_txt: String = str(eff)
	if eff > int(bd["base"]):
		eff_txt = "[color=%s]%d[/color]" % [_BOOST_COLOR, eff]
	elif eff < int(bd["base"]):
		eff_txt = "[color=%s]%d[/color]" % [_DEBUFF_COLOR, eff]
	lines.append("Effective      %s" % eff_txt)

	lines.append_array(_growth_info_lines(unit, stat_name))

	var mods: Array = bd["mods"]
	if mods.is_empty():
		lines.append("[color=#9a9aa6]No active bonuses[/color]")
	else:
		lines.append("Bonuses:")
		for m_any in mods:
			var m: Dictionary = m_any
			var dur := StatBreakdown.format_duration(
				String(m["duration_type"]), int(m["remaining"]))
			lines.append("  %s  %s  (%s)" % [
				String(m["source_label"]),
				StatBreakdown.format_signed(int(m["delta"])),
				dur,
			])
	return "\n".join(lines)


# The cap row: the integer when authored, a loud NO_CAP_DEFINED when a capped
# stat is missing its entry (a class-data hole), or "—" for the intentionally
# uncapped stats (MOV / CON / LoS).
func _cap_line(bd: Dictionary) -> String:
	match String(bd["cap_state"]):
		"capped":   return "Class cap      %d" % int(bd["cap"])
		"uncapped": return "Class cap      —"
		_:          return "Class cap      [color=#ff5a5a]NO_CAP_DEFINED[/color]"


# Resolves the inspected unit's ClassData via DataManager, or null if unavailable.
func _class_data_for(unit: Node) -> ClassData:
	if unit == null or unit.data == null:
		return null
	var dm := get_node_or_null("/root/DataManager")
	if dm == null:
		return null
	return dm.get_class_data(unit.data.class_id)


# Autoload handles StatContributions needs to surface combat-only bonuses.
func _contribution_deps() -> Dictionary:
	return {
		"registry":     get_node_or_null("/root/PairUpRegistry"),
		"game_state":   get_node_or_null("/root/GameState"),
		"resolver":     get_node_or_null("/root/PairUpBonusResolver"),
		"data_manager": get_node_or_null("/root/DataManager"),
	}


func _growth_info_lines(unit: Node, stat_name: String) -> Array[String]:
	var lines: Array[String] = []
	if unit == null or unit.data == null:
		return lines
	if not (stat_name in ClassData.STAT_KEYS):
		return lines
	var dm := get_node_or_null("/root/DataManager")
	if dm == null:
		return lines
	var class_data: ClassData = dm.get_class_data(unit.data.class_id)
	if class_data == null:
		return lines
	var effective_growth: int = int(class_data.player_growth_rates.get(stat_name, 0)) \
		+ int(unit.data.growth_rates.get(stat_name, 0))
	var fixed_progress: int = int(unit.data.growth_accumulators.get(stat_name, 0))
	lines.append("Growth %d%%" % effective_growth)
	lines.append("Fixed %d / 100" % fixed_progress)
	return lines


func _unhandled_input(event: InputEvent) -> void:
	# Override the base: this screen also closes on the inspect_unit key
	# (toggle behaviour — same key opens and dismisses it). The more_info
	# action cycles through the entry list so a keyboard user can review
	# every breakdown without clicking.
	if not visible:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("inspect_unit"):
		get_viewport().set_input_as_handled()
		_close()
		return
	if event.is_action_pressed("more_info"):
		get_viewport().set_input_as_handled()
		_cycle_more_info()


# Advances the side-panel selection through _entries. First press shows the
# first entry; each subsequent press moves forward one and wraps around.
func _cycle_more_info() -> void:
	if _entries.is_empty():
		return
	_current_index = (_current_index + 1) % _entries.size()
	var e: Dictionary = _entries[_current_index]
	_show_entry(String(e["category"]), String(e["key"]), String(e["title"]))


# _close is inherited from ModalScreen — emits `closed` and hides. Override
# only to clear local references so we don't pin a stale unit between opens.
func _close() -> void:
	_unit = null
	_paired_unit = null
	_entries.clear()
	_current_index = -1
	super._close()
