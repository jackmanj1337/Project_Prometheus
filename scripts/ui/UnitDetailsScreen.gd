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

@onready var _title: Label     = $Panel/VBox/TitleLabel
@onready var _stats: Label     = $Panel/VBox/StatsLabel
@onready var _inventory: Label = $Panel/VBox/InventoryLabel
@onready var _skills: Label    = $Panel/VBox/SkillsLabel
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
	_stats.text = _format_stats(d)
	_inventory.text = _format_inventory(d)
	_skills.text = _format_skills(d)
	show()
	_btn_back.grab_focus()


func _format_stats(d: UnitData) -> String:
	# Two stats per line keeps the panel compact and readable.
	return "\n".join([
		"HP   %d / %d" % [d.hp, d.max_hp],
		"Str  %-3d  Mag  %d" % [d.strength, d.magic],
		"Skl  %-3d  Spd  %d" % [d.skill, d.speed],
		"Def  %-3d  Res  %d" % [d.defense, d.resistance],
		"Lck  %-3d  Mov  %d" % [d.luck, d.movement],
		"EXP  %d / 100" % d.exp,
	])


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
