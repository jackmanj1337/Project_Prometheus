extends Control
# Shows attacker vs defender combat stats before the player confirms an attack.
# Populated by MapCursor when entering 'previewing' state.
#
# Phase 1 More Info host (see [GDD-07-SCREENS-PANELS]):
# every preview field is a clickable [url=combat_field:...] link that opens
# a description in the InfoBox side panel; the more_info action cycles
# through them in declaration order. Combat preview wins priority 1 in the
# F chain so its handler consumes the event when the panel is visible.
#
# Positioning: instead of a fixed bottom-of-screen slot the preview anchors
# beside the defender on screen. If neither side has room the camera pans
# horizontally via CameraController.pan_by_pixels(). The math reads the
# panel's current size after content updates so the InfoBox column can grow
# without breaking the screen-edge clamp.

const GameConstants = preload("res://scripts/shared/GameConstants.gd")
const MoreInfoContent = preload("res://scripts/shared/MoreInfoContent.gd")
const SelectionCursor = preload("res://scripts/ui/SelectionCursor.gd")
const InputDisplay = preload("res://scripts/shared/InputDisplay.gd")

@onready var _panel: PanelContainer = $Panel
# The column grid. Still named "HBox" because every harness and bridge path addresses the
# rows through `Panel/HBox/...`; it became a GridContainer so it can reflow (see
# `_columns_for_width`).
@onready var _columns: GridContainer = $Panel/HBox
@onready var _attacker_box: VBoxContainer = $Panel/HBox/AttackerBox
@onready var _defender_box: VBoxContainer = $Panel/HBox/DefenderBox
@onready var _info_box: VBoxContainer = $Panel/HBox/InfoBox
@onready var _atk_name: RichTextLabel = $Panel/HBox/AttackerBox/AtkName
@onready var _atk_weapon: RichTextLabel = $Panel/HBox/AttackerBox/AtkWeapon
@onready var _atk_hp: RichTextLabel = $Panel/HBox/AttackerBox/AtkHP
@onready var _atk_dmg: RichTextLabel = $Panel/HBox/AttackerBox/AtkDmg
@onready var _atk_hit: RichTextLabel = $Panel/HBox/AttackerBox/AtkHit
@onready var _atk_crit: RichTextLabel = $Panel/HBox/AttackerBox/AtkCrit
@onready var _atk_interactions: VBoxContainer = $Panel/HBox/AttackerBox/AtkInteractions
@onready var _def_name: RichTextLabel = $Panel/HBox/DefenderBox/DefName
@onready var _def_weapon: RichTextLabel = $Panel/HBox/DefenderBox/DefWeapon
@onready var _def_hp: RichTextLabel = $Panel/HBox/DefenderBox/DefHP
@onready var _def_dmg: RichTextLabel = $Panel/HBox/DefenderBox/DefDmg
@onready var _def_hit: RichTextLabel = $Panel/HBox/DefenderBox/DefHit
@onready var _def_crit: RichTextLabel = $Panel/HBox/DefenderBox/DefCrit
@onready var _def_interactions: VBoxContainer = $Panel/HBox/DefenderBox/DefInteractions
@onready var _info_title: Label = $Panel/HBox/InfoBox/InfoTitle
@onready var _info_hint: Label = $Panel/HBox/InfoBox/InfoHint
@onready var _info_desc: RichTextLabel = $Panel/HBox/InfoBox/InfoDescription

# BBCode colour strings (Hex without alpha — RichTextLabel matches the
# previous modulate colours). Inline [color] wraps the link text so the
# interaction rows stay readable while still being clickable.
#
# THIS IS THE SURFACE'S PALETTE, AND THAT IS DELIBERATE. `CombatInteractionReadout` answers
# "does this relationship help the strike"; it does not pick a colour, because a panel, a
# battle log and a future forecast overlay do not share one. An authored `presentation.color`
# overrides the mapping — the author is choosing for every surface at once, which is the
# point of authoring it.
const COLOR_ADVANTAGE := "#61c454"
const COLOR_DISADVANTAGE := "#d85b5b"
const COLOR_MIXED := "#eec84c"
const COLOR_NEUTRAL := "#9a9aa6"

# Pixel gap between the defender's tile edge and the preview panel, and
# between the panel and the viewport edge.
const PANEL_MARGIN_PX: int = 16
const FORECAST_COLUMN_MIN_WIDTH: float = 300.0
const INFO_COLUMN_MIN_WIDTH: float = 300.0
const PANEL_DEFAULT_HEIGHT: float = 230.0
const FORECAST_ROW_PADDING_Y: float = 4.0
const FORECAST_ACTION_HINT := "Enter attacks."
# Horizontal slack subtracted from the forecast column when deciding whether a
# name fits on one line, so the ellipsis never butts right against the edge.
const NAME_FIT_PADDING_X: float = 6.0
const NAME_ELLIPSIS: String = "…"
const FORECAST_CANVAS_LAYER: int = 3
# Column counts the grid may take, widest first: attacker | defender | More Info, then
# attacker | defender with More Info below, then everything stacked.
const LAYOUT_COLUMN_COUNTS: Array[int] = [3, 2, 1]

# Injected by MapCursor.setup() so the panel can read the defender's screen
# position and ask the camera controller to pan when there is no room. All
# three may be null in headless tests — show_preview() then keeps the panel
# at its scene-file position rather than crashing.
var _camera: Camera2D = null
var _grid: Node = null
var _camera_ctrl: RefCounted = null

# Ordered list of selectable entries built during show_preview(). Each is
# {"side": "atk"|"def", "key": "hit"|..., "title": String} — `more_info`
# cycles through this list in left-to-right, top-to-bottom order.
var _entries: Array = []

# Index into _entries for the currently displayed side-panel entry. -1 means
# nothing is selected yet — InfoHint is visible and InfoDescription is empty.
# Mirrors _selector.index; kept as a plain field so existing readers/tests don't
# have to reach into the cursor.
var _current_index: int = -1

# Shared navigation core (B6-INPUT selector adoption). 1-D forward/back cycle over
# the _entries list, no inactive stop — the same core UnitDetailsScreen uses, so
# the gamepad d-pad wiring attaches in one place. Rendering stays per-surface:
# `changed` drives _show_entry / _reset_info_panel.
var _selector: RefCounted = SelectionCursor.new()

# Full, untruncated combatant names captured each show_preview(). The name rows
# may be shortened with an ellipsis to fit their column, so More Info reads from
# these to always show the complete name.
var _atk_full_name: String = ""
var _def_full_name: String = ""

# Battle Speed of each side and the follow-up threshold, captured each
# show_preview(). Surfaced in the Damage field's More Info so the player can
# verify the follow-up (doubling) math (handbook 8.3).
var _atk_battle_speed: int = 0
var _def_battle_speed: int = 0
var _follow_up_threshold: int = 5
var _can_counter: bool = false

# The defender the visible preview is anchored to, captured in show_preview() so a
# zoom change can re-anchor the panel beside it — the same reposition-on-zoom the
# context menus get (V025-04c). Cleared on hide so a stale defender is never used.
var _anchor_defender: Node = null

# Generation counter for the deferred sizing pass (V027-03a): each show_preview()
# bumps it, so a re-pass that awakens after a newer show has taken over bails out
# instead of restoring the panel alpha the newer pass is still holding at 0.
var _deferred_show_id: int = 0


func setup(camera: Camera2D, grid: Node, camera_ctrl: RefCounted) -> void:
	_camera = camera
	_grid = grid
	_camera_ctrl = camera_ctrl


func _ready() -> void:
	# The persistent HUD is on canvas layer 2. AttackPreview used to inherit layer 1 from
	# the action-menu layer, which let the bottom-right terrain card paint over the tallest
	# forecast. The menus and forecast are transient interaction surfaces and must sit above
	# the persistent HUD; raising their shared layer also preserves their existing ordering.
	var canvas_layer := get_parent() as CanvasLayer
	if canvas_layer != null:
		canvas_layer.layer = maxi(canvas_layer.layer, FORECAST_CANVAS_LAYER)
	_attacker_box.custom_minimum_size.x = FORECAST_COLUMN_MIN_WIDTH
	_defender_box.custom_minimum_size.x = FORECAST_COLUMN_MIN_WIDTH
	_info_box.custom_minimum_size.x = INFO_COLUMN_MIN_WIDTH
	# Wire every selectable field's meta_clicked to the same handler. The
	# [url=combat_field:KEY] meta string is parsed in _on_entry_clicked.
	for label in _all_selectable_labels():
		label.meta_clicked.connect(_on_entry_clicked)
	_selector.changed.connect(_on_selector_changed)
	# Prompt/glyph swapping (B6-INPUT): re-render the More Info hint when the input
	# scheme changes. AttackPreview is not a ModalScreen, so it subscribes directly.
	# Guarded so headless scenes without the autoload stay inert.
	var imm := get_node_or_null("/root/InputModeManager")
	if imm != null and imm.has_signal("input_mode_changed"):
		imm.connect("input_mode_changed", _on_input_mode_changed)
	hide()


func _on_input_mode_changed(_mode: String) -> void:
	# Only refresh while the hint is showing (nothing selected); a selected entry
	# shows a description, not a control prompt.
	if visible and _info_hint.visible:
		_info_hint.text = _forecast_info_hint()


func show_preview(attacker: Node, defender: Node) -> void:
	var projection := get_node_or_null("/root/ProjectionService")
	if projection == null:
		return
	var result = projection.project_combat(attacker, defender)
	_entries.clear()
	_current_index = -1
	if not result.valid:
		return
	var p: Dictionary = result.visible_outcome

	# Battle Speed + follow-up threshold for the Damage field's More Info (8.3).
	_atk_battle_speed = int(p.get("attacker_battle_speed", 0))
	_def_battle_speed = int(p.get("defender_battle_speed", 0))
	_follow_up_threshold = int(p.get("follow_up_threshold", 5))
	_can_counter = bool(p.get("can_counter", false))

	# ---- Attacker rows -----------------------------------------------
	var atk_name: String = attacker.data.unit_name if attacker.data else "???"
	_atk_full_name = atk_name
	# Name rows are one line; truncate with an ellipsis so a long name can't
	# wrap and clip. The full name stays available through More Info.
	_atk_name.text = _link(
		"atk", "name", "Attacker", BBCode.escape(_fit_name_to_column(atk_name, "", _atk_name))
	)
	# V021-14: name the equipped weapon under each combatant (the sheet already shows
	# full weapon stats; the forecast just needs the name for at-a-glance matchups).
	_atk_weapon.text = BBCode.escape(_weapon_name(attacker))
	var atk_hp_val: int = attacker.data.hp if attacker.data else 0
	var atk_hp_max: int = attacker.data.max_hp if attacker.data else 0
	_atk_hp.text = _link("atk", "hp", "HP", "HP %d / %d" % [atk_hp_val, atk_hp_max])
	_atk_dmg.text = _link(
		"atk", "damage", "Damage", "Dmg  %d×%d" % [p["attacker_damage"], p["attacker_attacks"]]
	)
	_atk_hit.text = _link("atk", "hit", "Hit Rate", "Hit  %d%%" % p["attacker_hit"])
	_atk_crit.text = _link("atk", "crit", "Crit Rate", "Crit %d%%" % p["attacker_crit"])
	_render_interactions("atk", _atk_interactions, p.get("attacker_interactions", []))

	# ---- Defender rows -----------------------------------------------
	var def_name_str: String = defender.data.unit_name if defender.data else "???"
	_def_full_name = def_name_str
	if p.get("defender_vantage", false):
		# Vantage is annotated on the name so the player sees the strike-order
		# change. The [Vantage] tag stays outside the [url] to keep the link
		# meta clean, and its width is reserved so it survives name truncation.
		var vantage_suffix: String = "  [Vantage]"
		_def_name.text = (
			_link(
				"def",
				"name",
				"Defender",
				BBCode.escape(_fit_name_to_column(def_name_str, vantage_suffix, _def_name))
			)
			+ vantage_suffix
		)
	else:
		_def_name.text = _link(
			"def",
			"name",
			"Defender",
			BBCode.escape(_fit_name_to_column(def_name_str, "", _def_name))
		)
	_def_weapon.text = BBCode.escape(_weapon_name(defender))
	var def_hp_val: int = defender.data.hp if defender.data else 0
	var def_hp_max: int = defender.data.max_hp if defender.data else 0
	_def_hp.text = _link("def", "hp", "HP", "HP %d / %d" % [def_hp_val, def_hp_max])
	if p["can_counter"]:
		_def_dmg.text = _link(
			"def", "damage", "Damage", "Dmg  %d×%d" % [p["defender_damage"], p["defender_attacks"]]
		)
		_def_hit.text = _link("def", "hit", "Hit Rate", "Hit  %d%%" % p["defender_hit"])
		_def_crit.text = _link("def", "crit", "Crit Rate", "Crit %d%%" % p["defender_crit"])
		_render_interactions("def", _def_interactions, p.get("defender_interactions", []))
	else:
		# No counter — the defender row collapses to a single "No counter"
		# line. We still register it as an entry so more_info cycle visits
		# the defender side, but the description is a plain note.
		_def_dmg.text = _link("def", "damage", "Damage", "No counter")
		# Dashes, not blanks (V026-04b): keep the row heights so the columns stay
		# aligned. Plain text (no _link) so More Info never describes a rate that
		# doesn't exist.
		_def_hit.text = "Hit  —"
		_def_crit.text = "Crit —"
		# No counter, no strike, so no relationships shaping one. The forecast already
		# returns an empty list here; rendering it keeps the column clear of the previous
		# preview's rows.
		_render_interactions("def", _def_interactions, [])

	_refresh_forecast_row_heights()
	# Reconfigure the cursor for this show's entry count and reset it to -1 so every
	# preview opens on the hint state (reset emits `changed(-1)` → _reset_info_panel).
	_selector.configure(_entries.size(), 1, true, false)
	_selector.reset()
	_reset_info_panel()
	_size_panel_to_content()
	_anchor_defender = defender
	_reposition_for(defender)
	show()
	_resize_after_layout()


# Deferred second sizing pass (V027-03a): RichTextLabel content minimums read
# INFLATED until one layout frame passes (the V025-05a first-show trap), so the
# first open after boot froze an over-tall panel with dead tinted space under the
# rows. Re-run size + placement one frame after every show; the panel is held
# transparent for that frame so the over-tall frame never flashes on screen —
# the same mitigation MenuScale.apply_to_deferred uses.
func _resize_after_layout() -> void:
	if not is_inside_tree():
		return
	_deferred_show_id += 1
	var pass_id: int = _deferred_show_id
	_panel.modulate.a = 0.0
	await get_tree().process_frame
	if pass_id != _deferred_show_id:
		return  # a newer show owns the panel (and its alpha) now
	if visible and _anchor_defender != null and is_instance_valid(_anchor_defender):
		_size_panel_to_content()
		_reposition_for(_anchor_defender)
	_panel.modulate.a = 1.0


func hide_preview() -> void:
	_anchor_defender = null
	hide()


# Re-anchors the visible preview beside its current defender. Called by MapCursor
# when the map zoom changes so the panel tracks the unit the same way the context
# menus do (V025-04c). No-op when hidden or without a live anchor defender.
func reposition() -> void:
	if not visible or _anchor_defender == null or not is_instance_valid(_anchor_defender):
		return
	_reposition_for(_anchor_defender)


# Returns the labels that participate in selection. Hand-listed instead of
# walking the tree so a future "add a stat below crit" doesn't accidentally
# break selection ordering — the cycle order is exactly this declaration
# order, which matches how the player reads the preview.
# V021-14: the equipped weapon's display name for the forecast row, or "Unarmed".
func _weapon_name(unit: Node) -> String:
	if unit == null or not unit.has_method("get_equipped_weapon"):
		return "Unarmed"
	var w: WeaponData = unit.get_equipped_weapon()
	return w.display_name if w != null and String(w.display_name) != "" else "Unarmed"


# The scene-authored selectable labels. The interaction rows are NOT here: they are created
# per preview and connect their own `meta_clicked` as they are built, because a list written
# at _ready() cannot name a label that does not exist until a forecast says how many there
# are.
func _all_selectable_labels() -> Array[RichTextLabel]:
	return [
		_atk_name,
		_atk_hp,
		_atk_dmg,
		_atk_hit,
		_atk_crit,
		_def_name,
		_def_hp,
		_def_dmg,
		_def_hit,
		_def_crit,
	]


# Every row whose height the panel sizing pass measures, interaction rows included — a row
# left out of this list keeps a RichTextLabel's inflated content minimum and re-opens the
# over-tall panel V027-03a fixed.
func _all_forecast_rows() -> Array[RichTextLabel]:
	var rows: Array[RichTextLabel] = [
		_atk_name,
		_atk_weapon,
		_atk_hp,
		_atk_dmg,
		_atk_hit,
		_atk_crit,
	]
	rows.append_array(_interaction_rows(_atk_interactions))
	(
		rows
		. append_array(
			[
				_def_name,
				_def_weapon,
				_def_hp,
				_def_dmg,
				_def_hit,
				_def_crit,
			]
		)
	)
	rows.append_array(_interaction_rows(_def_interactions))
	return rows


func _interaction_rows(container: VBoxContainer) -> Array[RichTextLabel]:
	var rows: Array[RichTextLabel] = []
	for child in container.get_children():
		if child is RichTextLabel:
			rows.append(child as RichTextLabel)
	return rows


# Builds one selectable field. `title` is the side-panel title used when this
# field is selected; `text` is the visible row text. Registering the entry
# here keeps the _entries list in sync with the visible link order.
func _link(side: String, key: String, title: String, text: String) -> String:
	_entries.append({"side": side, "key": key, "title": title})
	return "[url=combat_field:%s:%s]%s[/url]" % [side, key, text]


# ── Authored interaction rows `[ITR-6]` ─────────────────────────────────────


# ONE ROW PER AUTHORED RELATIONSHIP, built at runtime — slice 6 of
# AUTHORED-TRAIT-RELATIONSHIPS-2026-09-10.
#
# There used to be two fixed slots per side, `AtkTriangle` and `AtkEffective`, because the
# engine shipped exactly two relationships and named them both. It ships none now: a
# campaign authors as many as it likes, each with a name and an order of its own, so the
# panel cannot know how many rows it needs until the forecast answers. Two slots would
# either drop the third relationship a pack declares or show two empty rows for a pack that
# declares none — and a pack declaring none is the engine's default state.
#
# THE ROWS ARE REBUILT, NOT POOLED. A preview opens once per cursor move over an enemy, the
# row count changes with the matchup, and a pooled label that outlives its row is a label
# still carrying the previous fight's numbers if any path forgets to clear it. Freeing is
# `queue_free` + `remove_child`, so the container's child count is right immediately rather
# than one frame later, which is what `_all_selectable_labels` reads.
func _render_interactions(side: String, container: VBoxContainer, rows: Variant) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	if not rows is Array:
		return
	for index in (rows as Array).size():
		var row: Dictionary = (rows as Array)[index] as Dictionary
		var label := RichTextLabel.new()
		label.bbcode_enabled = true
		# AN INTERACTION ROW WRAPS AND SIZES ITSELF, which is the one place these rows depart
		# from every other forecast row. The scene's rows are authored single-line values that
		# fit a 150px column — "Hit  82%", and before slice 6 a fixed "▲ Advantage". A row here
		# is a pack's own label plus its terms, of no bounded length, and the two alternatives
		# are both worse: clipping loses whichever end the column runs out at, and ellipsising
		# loses either the relationship's name or its numbers. So it wraps, `fit_content` gives
		# it the height its wrapped content needs, and `_refresh_forecast_row_heights` leaves
		# it alone rather than pinning it to one line. The panel's deferred second sizing pass
		# (V027-03a) is what makes that safe: a content minimum reads inflated for one frame,
		# and the panel is already held transparent for exactly that frame.
		label.fit_content = true
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size.x = FORECAST_COLUMN_MIN_WIDTH
		label.meta_clicked.connect(_on_entry_clicked)
		container.add_child(label)
		label.text = _interaction_row_text(side, index, row)
		# The generated More Info body travels with the entry rather than being looked up in
		# MoreInfoContent: it is derived from THIS resolution, and the authored data it
		# describes is not in any table this panel could index. `[ITR-6]` asked for exactly
		# that — the old hardcoded triangle sentence was already false against the shipped
		# table it claimed to describe.
		_entries[_entries.size() - 1]["detail"] = String(row.get("detail", ""))


# The row's visible text. The glyph and colour are the author's when declared and the
# surface's mapping of `direction` otherwise, which is the whole of "authored presentation
# over a generic fallback".
func _interaction_row_text(side: String, index: int, row: Dictionary) -> String:
	var label: String = String(row.get("label", ""))
	var summary: String = String(row.get("summary", ""))
	var glyph: String = String(row.get("glyph", ""))
	var body: String = "%s %s" % [glyph, label] if glyph != "" else label
	if summary != "":
		body = "%s  %s" % [body, summary]
	# Escaped because a label and a summary are authored strings: a pack writing "[b]" in a
	# label_key's translation must not be able to style or break this panel.
	return _link(
		side,
		_interaction_key(index),
		label if label != "" else "Interaction",
		"[color=%s]%s[/color]" % [_interaction_color(row), BBCode.escape(body)]
	)


# The entry key for an interaction row. INDEX-BASED, not profile-id-based, because
# `_on_entry_clicked` parses a three-segment colon-delimited meta string and a profile id is
# authored text that may contain a colon. An index cannot.
func _interaction_key(index: int) -> String:
	return "interaction.%d" % index


func _interaction_color(row: Dictionary) -> String:
	var authored: String = String(row.get("color", ""))
	if authored != "":
		return authored
	match String(row.get("direction", "")):
		"advantage":
			return COLOR_ADVANTAGE
		"disadvantage":
			return COLOR_DISADVANTAGE
		"mixed":
			return COLOR_MIXED
		_:
			return COLOR_NEUTRAL


# Resets the side panel to its "nothing selected yet" hint state.
func _reset_info_panel() -> void:
	_info_title.text = "More Info"
	_info_hint.visible = true
	_info_hint.text = _forecast_info_hint()
	_info_desc.text = ""


func _forecast_info_hint() -> String:
	return "%s %s" % [InputDisplay.more_info_hint(self, "value"), FORECAST_ACTION_HINT]


func _refresh_forecast_row_heights() -> void:
	for label in _all_forecast_rows():
		# An interaction row wraps and takes its height from its own content (see
		# `_render_interactions`); pinning it to a one-line minimum here would clip the second
		# line of every relationship whose label and numbers do not fit the column.
		if label.fit_content:
			continue
		if label.text == "":
			label.custom_minimum_size.y = 0.0
			continue
		# Forecast rows are authored as single-line values. Keep a stable
		# one-line minimum height instead of letting fit_content drive the
		# whole panel size from RichTextLabel internals.
		label.custom_minimum_size.y = _measure_forecast_row_height(label)


func _measure_forecast_row_height(label: RichTextLabel) -> float:
	var font: Font = label.get_theme_default_font()
	if font == null:
		return 20.0
	return ceilf(font.get_height(label.get_theme_default_font_size()) + FORECAST_ROW_PADDING_Y)


# Shortens `name` with a trailing ellipsis so it plus `suffix` fits on one line
# in a forecast column. RichTextLabel has no built-in overrun ellipsis, so we
# measure against the column width and trim by hand. Returns the (possibly
# truncated) name only — the caller re-wraps it in the [url] link and appends
# any suffix. If the font can't be measured the full name is returned and the
# label's clip falls back to a hard cut.
func _fit_name_to_column(p_name: String, suffix: String, label: RichTextLabel) -> String:
	var font: Font = label.get_theme_default_font()
	if font == null:
		return p_name
	var font_size: int = label.get_theme_default_font_size()
	var budget: float = FORECAST_COLUMN_MIN_WIDTH - NAME_FIT_PADDING_X
	budget -= font.get_string_size(suffix, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if font.get_string_size(p_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= budget:
		return p_name
	var ellipsis_w: float = (
		font.get_string_size(NAME_ELLIPSIS, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	)
	var fitted: String = ""
	for i in p_name.length():
		var candidate: String = p_name.substr(0, i + 1)
		if (
			font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + ellipsis_w
			> budget
		):
			break
		fitted = candidate
	# Drop a trailing space so the ellipsis reads as "Name…" not "Name …".
	return fitted.strip_edges(false, true) + NAME_ELLIPSIS


func _size_panel_to_content() -> void:
	# REFLOW BEFORE MEASURING (v0.8.2 rejection). Three 300px columns make the panel ~976px
	# wide, and below that the old fixed row pushed More Info and the defender's rows off the
	# canvas at 560px. The columns are NOT narrowed instead: a narrower column wraps the
	# relationship rows, and three-line wrapping is what rejected v0.8.1.
	_columns.columns = _columns_for_width(
		get_viewport_rect().size.x - PANEL_MARGIN_PX * 2.0,
		_panel_chrome_width(),
		float(_columns.get_theme_constant("h_separation"))
	)
	_panel.reset_size()
	var min_size: Vector2 = _panel.get_combined_minimum_size()
	# Height is deliberately NOT taken from get_combined_minimum_size(): on the
	# first show that height is still settling and reads inflated, and pinning it
	# into offset_bottom freezes the over-tall panel. Seed a stable default and
	# let PanelContainer's own minimum-size pass grow the panel to fit the rows
	# (it already enforces its content minimum, so tall previews never clip).
	min_size.y = PANEL_DEFAULT_HEIGHT
	_panel.offset_right = _panel.offset_left + min_size.x
	_panel.offset_bottom = _panel.offset_top + min_size.y


# The panel's horizontal stylebox padding — what the panel adds around its columns.
func _panel_chrome_width() -> float:
	var style: StyleBox = _panel.get_theme_stylebox("panel")
	return style.get_minimum_size().x if style != null else 0.0


# Pure layout rule (unit-testable): the most columns whose minimum widths, separations and
# panel padding fit `available` screen width. Falls back to one column, which is as narrow
# as the forecast can go without wrapping its rows.
static func _columns_for_width(available: float, chrome: float, separation: float) -> int:
	for count in LAYOUT_COLUMN_COUNTS:
		var needed: float = (
			maxf(FORECAST_COLUMN_MIN_WIDTH, INFO_COLUMN_MIN_WIDTH) * count
			+ separation * (count - 1)
			+ chrome
		)
		if needed <= available:
			return count
	return 1


# Parses the [url=...] meta. Expected shape: "combat_field:atk:hit" — a
# three-segment colon-delimited key carrying category, side, and field.
func _on_entry_clicked(meta: Variant) -> void:
	var s: String = String(meta)
	var parts: PackedStringArray = s.split(":")
	if parts.size() != 3:
		return
	var side: String = parts[1]
	var key: String = parts[2]
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		if e["side"] == side and e["key"] == key:
			_selector.set_index(i)
			return


func _show_entry(entry: Dictionary) -> void:
	_info_title.text = String(entry["title"])
	_info_hint.visible = false
	# An interaction row carries its OWN description, generated from the resolution that
	# produced it. MoreInfoContent has no entry to look up and deliberately no longer has
	# one: its hardcoded weapon-triangle sentence described a table the engine no longer
	# owns, and was already false about the one it did.
	if entry.has("detail"):
		_info_desc.text = BBCode.escape(String(entry["detail"]))
		return
	var desc: String = BBCode.escape(MoreInfoContent.describe("combat_field", String(entry["key"])))
	# Name rows can be ellipsised in the column, so lead the description with the
	# full name — this is where the player reads a name that didn't fit.
	if String(entry["key"]) == "name":
		var full_name: String = _atk_full_name if String(entry["side"]) == "atk" else _def_full_name
		desc = "%s\n\n%s" % [BBCode.escape(full_name), desc]
	# The Damage field carries the follow-up (×N attacks) outcome, so append the
	# Battle Speed comparison and threshold there — the values the tester needed to
	# verify doubling (handbook 8.3).
	if String(entry["key"]) == "damage":
		desc = "%s\n\n%s" % [desc, _battle_speed_note()]
	_info_desc.text = desc


# Builds the Battle Speed / follow-up line shown under the Damage field's More
# Info. Shows BOTH sides' Battle Speed and the threshold; notes who (if anyone)
# earns a follow-up. Defender speed is shown even when it cannot counter
# (playtest v0.1.5.0 #8.3): the value is still informative, and the attacker can
# still double a non-countering defender, so the comparison is meaningful. When
# the defender can't counter it simply never attacks, so it can't follow up
# regardless of its speed — that is called out in the note rather than hidden.
func _battle_speed_note() -> String:
	var diff: int = _atk_battle_speed - _def_battle_speed
	var who: String = ""
	if not _can_counter:
		# Only the attacker can follow up here; the defender deals no strikes.
		who = "Attacker follows up." if diff >= _follow_up_threshold else "No follow-up."
		return (
			"Battle Speed — Attacker %d vs Defender %d.\nNeeds +%d to follow up. %s (defender cannot counter)"
			% [_atk_battle_speed, _def_battle_speed, _follow_up_threshold, who]
		)
	if diff >= _follow_up_threshold:
		who = "Attacker follows up."
	elif -diff >= _follow_up_threshold:
		who = "Defender follows up."
	else:
		who = "No follow-up."
	return (
		"Battle Speed — Attacker %d vs Defender %d.\nNeeds +%d to follow up. %s"
		% [_atk_battle_speed, _def_battle_speed, _follow_up_threshold, who]
	)


# Advances through _entries. First press shows the first entry; subsequent
# presses move forward one and wrap. Same semantics as UnitDetailsScreen so
# the player only has to learn one F behaviour across both surfaces. Delegates
# to the shared cursor; the `changed` handler does the rendering.
func _cycle_more_info() -> void:
	_selector.advance(1)


# Cursor callback: mirror the index and render. -1 (or out of range) restores the
# hint state; any valid index shows that entry's More Info in the side panel.
func _on_selector_changed(index: int) -> void:
	_current_index = index
	if index < 0 or index >= _entries.size():
		_reset_info_panel()
		return
	_show_entry(_entries[index])


func _unhandled_input(event: InputEvent) -> void:
	# Priority 1 in the More Info chain: when the preview is visible the F
	# action belongs to the preview, not the character sheet or terrain HUD.
	# Consuming the event here keeps both implicit (the other handlers also
	# guard on `visible`) and explicit (they receive set_input_as_handled).
	if not visible:
		return
	if event.is_action_pressed("more_info"):
		get_viewport().set_input_as_handled()
		_cycle_more_info()


# ── Positioning helpers (unchanged from 2026-05-24d) ──────────────────────


func _reposition_for(defender: Node) -> void:
	if defender == null or not is_instance_valid(defender) or _camera == null:
		return
	if not (defender is Node2D):
		return
	# PanelContainer doesn't always report its minimum size until after a
	# layout pass; reset_size() forces it to recompute from current content.
	var panel_size: Vector2 = _panel.size
	if panel_size == Vector2.ZERO:
		panel_size = _panel.get_combined_minimum_size()
	var view: Vector2 = get_viewport_rect().size
	# On-screen size of one tile = world TILE_SIZE × camera zoom. defender_screen below
	# is already in canvas/screen space (the canvas transform bakes in camera zoom), so
	# the offset beside it must be the *screen* tile size, not the raw world constant —
	# otherwise the panel sits too far/near the defender at any zoom != 1 (Display &
	# Accessibility item 1d).
	var zoom_x: float = _camera.zoom.x if _camera != null and _camera.zoom.x > 0.0 else 1.0
	var tile_px: float = float(GameConstants.TILE_SIZE) * zoom_x
	var defender_screen: Vector2 = (defender as Node2D).get_global_transform_with_canvas().origin

	var right_left: float = defender_screen.x + tile_px + PANEL_MARGIN_PX
	var left_left: float = defender_screen.x - PANEL_MARGIN_PX - panel_size.x
	var panel_left: float = right_left
	if right_left + panel_size.x > view.x - PANEL_MARGIN_PX:
		if left_left >= PANEL_MARGIN_PX:
			panel_left = left_left
		else:
			var max_right_left: float = view.x - PANEL_MARGIN_PX - panel_size.x
			var pan_x: float = right_left - max_right_left
			if pan_x > 0 and _camera_ctrl != null and _camera_ctrl.has_method("pan_by_pixels"):
				_camera_ctrl.pan_by_pixels(Vector2(pan_x, 0))
				defender_screen = (defender as Node2D).get_global_transform_with_canvas().origin
				panel_left = defender_screen.x + tile_px + PANEL_MARGIN_PX
			panel_left = min(panel_left, view.x - PANEL_MARGIN_PX - panel_size.x)
			panel_left = max(panel_left, PANEL_MARGIN_PX)

	var panel_top: float = defender_screen.y + tile_px * 0.5 - panel_size.y * 0.5
	panel_top = clampf(panel_top, PANEL_MARGIN_PX, view.y - panel_size.y - PANEL_MARGIN_PX)

	# Nudge the panel clear of the HUD panels and the defender tile before committing
	# the position. Degrades to the plain viewport clamp when the HUD isn't reachable.
	var avoid: Array[Rect2] = _hud_avoid_rects()
	avoid.append(_defender_avoid_rect(defender_screen, tile_px))
	var placed: Vector2 = _place_clear_of(
		Vector2(panel_left, panel_top), panel_size, view, avoid, float(PANEL_MARGIN_PX)
	)

	_panel.position = placed
	_panel.offset_right = _panel.offset_left + panel_size.x
	_panel.offset_bottom = _panel.offset_top + panel_size.y


# Screen-space rects of the visible HUD panels the combat preview should not cover.
# Read live from the HUD (a sibling CanvasLayer, so its Control rects are already in
# the same screen space as the preview). Returns [] — i.e. no avoidance, plain
# viewport clamp — when the HUD or a panel is absent/hidden, so this never hard-fails.
func _hud_avoid_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var hud := get_node_or_null("../../HUDMainLayer/HUD")
	if hud == null:
		return out
	for panel_name in ["ObjectivePanel", "UnitInfoPanel", "TerrainCorner"]:
		var p := hud.get_node_or_null(panel_name)
		if p != null and p is Control and (p as Control).visible:
			var r: Rect2 = (p as Control).get_global_rect()
			if r.size.x > 0.0 and r.size.y > 0.0:
				out.append(r)
	return out


static func _defender_avoid_rect(defender_screen: Vector2, tile_px: float) -> Rect2:
	return Rect2(defender_screen, Vector2(tile_px, tile_px))


# Pure placement helper (no node access, so it is unit-testable): start from `pos`
# and, for each `avoid` rect the panel overlaps, slide it vertically clear — above
# the rect when there is room, otherwise below, preferring the smaller move. The
# result is always re-clamped inside `view`. A panel too tall to clear a rect is
# left where it is (clamped); avoidance is best-effort, never off-screen.
static func _place_clear_of(
	pos: Vector2, panel_size: Vector2, view: Vector2, avoid: Array[Rect2], margin: float
) -> Vector2:
	var rect := Rect2(pos, panel_size)
	for a in avoid:
		if not rect.intersects(a):
			continue
		var above_y: float = a.position.y - panel_size.y - margin
		var below_y: float = a.position.y + a.size.y + margin
		var above_ok: bool = above_y >= margin
		var below_ok: bool = below_y + panel_size.y <= view.y - margin
		if (
			above_ok
			and (not below_ok or absf(above_y - rect.position.y) <= absf(below_y - rect.position.y))
		):
			rect.position.y = above_y
		elif below_ok:
			rect.position.y = below_y
	rect.position.x = clampf(rect.position.x, margin, maxf(margin, view.x - panel_size.x - margin))
	rect.position.y = clampf(rect.position.y, margin, maxf(margin, view.y - panel_size.y - margin))
	return rect.position
