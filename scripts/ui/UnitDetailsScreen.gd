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

# Marker prepended to the directionally-selected entry's row so a keyboard /
# d-pad user can see which entry is highlighted (V020-10).
const _SEL_MARK := "▶ "

@onready var _title: Label             = $Panel/HBox/VBox/TitleLabel
@onready var _class_lbl: RichTextLabel = $Panel/HBox/VBox/ClassLabel
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

# The selectable section labels, in F-cycle / directional-nav order. Their
# unhighlighted text is cached in _base_texts so the row highlight can be
# re-applied without rebuilding every section on each keypress.
var _section_labels: Array = []
var _base_texts: Dictionary = {}


func _ready() -> void:
	_btn_pair.pressed.connect(_on_pair_button_pressed)
	_btn_back.pressed.connect(_close)
	# Each section label exposes selectable [url=...] entries; wire the
	# meta_clicked signal so clicks open the corresponding More Info entry.
	# RichTextLabel emits meta_clicked with the [url=...] meta value.
	_class_lbl.meta_clicked.connect(_on_entry_clicked)
	_stats.meta_clicked.connect(_on_entry_clicked)
	_inventory.meta_clicked.connect(_on_entry_clicked)
	_skills.meta_clicked.connect(_on_entry_clicked)
	_wexp.meta_clicked.connect(_on_entry_clicked)
	# Section labels in declaration order — drives both F-cycling and the
	# directional row highlight.
	_section_labels = [_class_lbl, _stats, _inventory, _skills, _wexp]
	super._ready()  # ModalScreen does the hide()


# Populates the panel from `unit` and shows it. A null/invalid unit is ignored.
func open(unit: Node) -> void:
	if unit == null or not is_instance_valid(unit) or unit.data == null:
		return
	_unit = unit
	_entries.clear()
	_current_index = -1
	var d: UnitData = unit.data
	# Title shows the friendly class display name (V020-11), falling back to the
	# raw class_id only when class data is unavailable.
	var cd: ClassData = _class_data_for(unit)
	var class_display: String = cd.display_name if (cd != null and cd.display_name != "") else d.class_id
	_title.text = "%s — %s   Lv %d" % [d.unit_name, class_display, d.level]
	# Class summary is registered first so F-cycling tours it before the stats.
	_class_lbl.text = _format_class(unit, cd)
	_stats.text = _format_stats(unit)
	_inventory.text = _format_inventory(d)
	_skills.text = _format_skills(d)
	_wexp.text = _format_weapon_wexp(unit)
	_update_pair_button(unit)
	# Cache each section's unhighlighted text so the directional selector can mark
	# a row without re-running the formatters (which would re-append to _entries).
	_base_texts.clear()
	for lbl in _section_labels:
		_base_texts[lbl] = lbl.text
	_reset_info_panel()
	show()
	_btn_back.grab_focus()


# Builds the compact class section (V020-11): a selectable class row plus one or
# two lines of traits, allowed weapon families, and class skill unlocks. Clicking
# it (or F-cycling to it) shows the full ClassData.description in the side panel.
# Full class-catalog prose stays out of the sheet — this is an at-a-glance summary.
func _format_class(unit: Node, class_data: ClassData) -> String:
	var d: UnitData = unit.data
	if class_data == null:
		# No class data resolved — keep the row selectable on the raw id so the
		# player still gets a (fallback) description rather than a dead row.
		_entries.append({"category": "class", "key": d.class_id, "title": d.class_id})
		return "[url=class:%s]Class: %s[/url]" % [d.class_id, d.class_id]
	var display: String = class_data.display_name if class_data.display_name != "" else class_data.id
	_entries.append({"category": "class", "key": class_data.id, "title": display})
	var lines: Array[String] = [
		"[url=class:%s]Class: %s  (Tier %d)[/url]" % [class_data.id, display, class_data.tier],
	]
	if not class_data.special_qualities.is_empty():
		lines.append("  Traits: " + ", ".join(class_data.special_qualities))
	var families: Array[String] = class_data.get_allowed_weapon_families()
	if not families.is_empty():
		var fam_labels: Array[String] = []
		for f in families:
			fam_labels.append(String(f).capitalize())
		lines.append("  Weapons: " + ", ".join(fam_labels))
	if not class_data.skill_unlocks.is_empty():
		var unlock_parts: Array[String] = []
		var levels: Array = class_data.skill_unlocks.keys()
		levels.sort()
		for lv in levels:
			unlock_parts.append("Lv%d %s" % [int(lv), String(class_data.skill_unlocks[lv])])
		lines.append("  Class skills: " + ", ".join(unlock_parts))
	return "\n".join(lines)


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
		# entry_key encodes the kind AND the specific id ("weapon:iron_sword") so
		# each row resolves to its own More Info — needed for per-weapon stats
		# (V020-10). Earlier this collapsed every weapon onto a generic "weapon"
		# key, so all weapons showed the same description.
		var entry_key: String = "weapon:"
		if entry.is_weapon():
			var w: WeaponData = dm.get_weapon(entry.weapon_id) if (dm and entry.weapon_id != "") else null
			label = w.display_name if w else entry.weapon_id
			entry_key = "weapon:" + entry.weapon_id
		elif entry.is_item():
			var it: ItemData = dm.get_item(entry.item_id) if (dm and entry.item_id != "") else null
			label = it.display_name if it else entry.item_id
			entry_key = "item:" + entry.item_id
		# -1 is the infinite-use sentinel — show ∞ rather than a literal "-1".
		var uses: String = "∞" if entry.uses_remaining == -1 else str(entry.uses_remaining)
		_entries.append({
			"category": "inventory",
			"key": entry_key,
			"title": label,
		})
		lines.append("  [url=inventory:%s]%s  (%s)[/url]" % [entry_key, label, uses])
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
	_refresh_highlight()
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
	# Class descriptions live on the ClassData resource, not in MoreInfoContent, so
	# resolve them directly; everything else uses the shared authored text.
	if category == "class":
		_info_desc.text = _class_description(key)
	elif category == "inventory":
		_info_desc.text = _inventory_description(key)
	else:
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


# Routes an inventory entry key ("weapon:<id>" / "item:<id>") to the right
# detail renderer. Weapons get a full stat block (V020-10); items show their
# authored description; anything else falls back to the generic inventory text.
func _inventory_description(key: String) -> String:
	var sep: int = key.find(":")
	var kind: String = key.substr(0, sep) if sep >= 0 else key
	var id: String = key.substr(sep + 1) if sep >= 0 else ""
	if kind == "weapon":
		return _weapon_info_text(id)
	if kind == "item":
		return _item_info_text(id)
	return MoreInfoContent.describe("inventory", kind)


# Builds the More Info stat block for a weapon: the generic weapon blurb plus
# Mt/Hit/Crit, Wt/Range, rank + family, uses, and any effect tags. Range is
# resolved against the inspected unit so dynamic ranges (e.g. "MAG/2") read true.
func _weapon_info_text(weapon_id: String) -> String:
	var dm := get_node_or_null("/root/DataManager")
	var w: WeaponData = dm.get_weapon(weapon_id) if (dm != null and weapon_id != "") else null
	if w == null:
		return MoreInfoContent.describe("inventory", "weapon")
	var lines: Array[String] = [MoreInfoContent.describe("inventory", "weapon"), ""]
	lines.append("[b]%s[/b]" % w.display_name)
	lines.append("Mt %d   Hit %d   Crit %d" % [w.mt, w.hit, w.crit])
	var rmin: int = w.get_range_min(_unit)
	var rmax: int = w.get_range_max(_unit)
	var rng_text: String = str(rmin) if rmin == rmax else "%d-%d" % [rmin, rmax]
	lines.append("Wt %d   Rng %s" % [w.wt, rng_text])
	# -1 uses = unbreakable/natural weapon; show ∞ rather than a literal "-1".
	var uses_text: String = "∞" if w.uses < 0 else str(w.uses)
	lines.append("Rank %s (%s)   Uses %s" % [w.required_rank, w.combat_family.capitalize(), uses_text])
	if not w.effect_tags.is_empty():
		lines.append("Effects: " + ", ".join(w.effect_tags))
	return "\n".join(lines)


# Builds the More Info text for an item: its authored description, falling back
# to the generic item blurb when the item has no description of its own.
func _item_info_text(item_id: String) -> String:
	var dm := get_node_or_null("/root/DataManager")
	var it: ItemData = dm.get_item(item_id) if (dm != null and item_id != "") else null
	if it != null and it.description != "":
		return it.description
	return MoreInfoContent.describe("inventory", "item")


# Returns the authored class description for a class id, or a safe fallback so the
# side panel never shows a blank box for a class with no description text.
func _class_description(class_id: String) -> String:
	var dm := get_node_or_null("/root/DataManager")
	if dm != null:
		var cd: ClassData = dm.get_class_data(class_id)
		if cd != null and cd.description != "":
			return cd.description
	return "No class description available."


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


# Directional selection runs in _input (before GUI focus navigation) so the
# cursor keys / d-pad drive the More Info highlight instead of moving focus
# between the Back / View buttons — same pattern as ActionMenu.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("cursor_up") or event.is_action_pressed("cursor_left"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cursor_down") or event.is_action_pressed("cursor_right"):
		_move_selection(1)
		get_viewport().set_input_as_handled()


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
# first entry; each subsequent press moves forward one and wraps around. F-cycle
# is forward-only; the cursor keys add backward movement via _move_selection.
func _cycle_more_info() -> void:
	_move_selection(1)


# Moves the highlighted selection by `delta` (wrapping), updates the row marker,
# and shows the entry in the side panel. The first press from "nothing selected"
# lands on the first (delta>0) or last (delta<0) entry.
func _move_selection(delta: int) -> void:
	if _entries.is_empty():
		return
	if _current_index < 0:
		_current_index = 0 if delta > 0 else _entries.size() - 1
	else:
		_current_index = (_current_index + delta) % _entries.size()
		if _current_index < 0:
			_current_index += _entries.size()
	var e: Dictionary = _entries[_current_index]
	_refresh_highlight()
	_show_entry(String(e["category"]), String(e["key"]), String(e["title"]))


# Re-applies the row marker for the currently-selected entry. Each section label
# is reset to its cached base text, then the one containing the selected entry's
# [url=...] tag gets the marker inserted just inside the link.
func _refresh_highlight() -> void:
	for lbl in _section_labels:
		lbl.text = String(_base_texts.get(lbl, lbl.text))
	if _current_index < 0 or _current_index >= _entries.size():
		return
	var e: Dictionary = _entries[_current_index]
	var needle: String = "[url=%s:%s]" % [String(e["category"]), String(e["key"])]
	for lbl in _section_labels:
		var base: String = String(_base_texts.get(lbl, ""))
		var idx: int = base.find(needle)
		if idx >= 0:
			var insert_at: int = idx + needle.length()
			lbl.text = base.substr(0, insert_at) + _SEL_MARK + base.substr(insert_at)
			return


# _close is inherited from ModalScreen — emits `closed` and hides. Override
# only to clear local references so we don't pin a stale unit between opens.
func _close() -> void:
	_unit = null
	_paired_unit = null
	_entries.clear()
	_base_texts.clear()
	_current_index = -1
	super._close()
