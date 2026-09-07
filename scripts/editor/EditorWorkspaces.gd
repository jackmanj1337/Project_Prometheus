class_name EditorWorkspaces extends RefCounted
# `[CEUI-S12]`'s seven workspaces, the wireframes' per-content-kind width responses, and
# the three findings that gave the shell its remaining chrome rules -- `EW-4` (default the
# bottom panel by height), `EW-5` (centre column only, default per workspace) and `EW-7`
# (a second document column offered above the split threshold, never automatic).
#
# WHY A DECLARED TABLE HERE IS NOT THE CLOSED ENUM `[CEUI-S21]` BANS. That ruling forbids
# the editor enumerating CONTENT FAMILIES, because a pack may register a family the engine
# never heard of and hiding it would defeat the open registry. Workspaces are the opposite
# kind of thing: `[CEUI-S12]` ruled the list itself, exactly seven, as a design decision --
# no pack contributes one, and `CEUI-4` fixed the layout for v1. Deriving them from
# anything would be inventing an extension point the ruling declined to create.
#
# THE PANEL DEFAULT IS A FUNCTION OF WORKSPACE AND HEIGHT, NOT OF EITHER ALONE. `EW-5`
# ruled it per workspace ("Release wants it tall and open, Maps wants it collapsed") and
# `EW-4` ruled it by height ("Content wants it open at 1240 and collapsed at 880"). Those
# are one rule, not two: at the floor the document area is 552 px -- nineteen rows -- with
# the panel open, so a workspace that wants the panel still has to give it up down there.
# `PANEL_ABOVE_FLOOR` is that combination, and it is why the default is a call rather than
# a stored boolean.

const ResponsiveLayoutScript = preload("res://scripts/autoloads/ResponsiveLayout.gd")

const CONTENT := "content"
const MAPS := "maps"
const GRAPH := "graph"
const ASSETS := "assets"
const LOCALIZATION := "localization"
const TEST := "test"
const RELEASE := "release"

## In the order `[CEUI-S12]` names them. The order is the workspace bar's.
const ORDER: Array[String] = [CONTENT, MAPS, GRAPH, ASSETS, LOCALIZATION, TEST, RELEASE]

## The wireframes' answer to extra width: the editor is a single size class, so more room
## is spent according to what the content IS rather than at a breakpoint.
const WIDTH_CANVAS_FILLS := "canvas_fills"
const WIDTH_GRID_REFLOWS := "grid_reflows"
const WIDTH_FORM_CAPS := "form_caps"
const WIDTH_TABLE_EXTENDS := "table_extends"
## `[CEUI-S3]` plus the per-size-class preview obligation (DLUX-15): the embedded session
## takes its size class from its own sub-viewport. Stretching it would silently change the
## size class the author believes they are previewing, which is the failure that obligation
## exists to prevent -- so extra width becomes surround, not simulator.
const WIDTH_SIMULATOR_FIXED := "simulator_fixed"

const PANEL_OPEN := "open"
const PANEL_CLOSED := "closed"
## Open above `[CEUI-S2]`'s floor, closed at it. `EW-4`.
const PANEL_ABOVE_FLOOR := "above_floor"

## Everything ruled about a workspace, in one place so the shell reads it rather than
## branching on the id. Three of the panel defaults are named outright in the wireframes'
## `EW-5` finding (Content above the floor, Maps collapsed, Release tall and open); the
## other four take the default their WIDTH RESPONSE implies, which is the only principle
## in the ruled material that distinguishes them:
##
##   * a canvas or a grid spends height on rows, so the panel starts closed (Graph, Assets
##     follow Maps);
##   * `[L10N-14]`'s completeness report IS the panel's content for Localization, so a
##     locale table opens it wherever there is room;
##   * `[CEUI-S33]` made a test REPORT the outcome of a run and gave it nowhere else to
##     live, and the simulator does not grow with the editor, so Test opens it -- the
##     panel is not taking room the simulator would have used.
const WORKSPACES: Dictionary = {
	CONTENT: {"label": "Content", "width_response": WIDTH_FORM_CAPS, "panel": PANEL_ABOVE_FLOOR},
	MAPS: {"label": "Maps", "width_response": WIDTH_CANVAS_FILLS, "panel": PANEL_CLOSED},
	GRAPH: {"label": "Graph", "width_response": WIDTH_CANVAS_FILLS, "panel": PANEL_CLOSED},
	ASSETS: {"label": "Assets", "width_response": WIDTH_GRID_REFLOWS, "panel": PANEL_CLOSED},
	LOCALIZATION:
	{
		"label": "Localization",
		"width_response": WIDTH_TABLE_EXTENDS,
		"panel": PANEL_ABOVE_FLOOR,
	},
	TEST: {"label": "Test", "width_response": WIDTH_SIMULATOR_FIXED, "panel": PANEL_OPEN},
	RELEASE: {"label": "Release", "width_response": WIDTH_FORM_CAPS, "panel": PANEL_OPEN},
}

signal workspace_changed(new_id: String, previous_id: String)
signal panel_visibility_changed(workspace_id: String, is_open: bool)

var _active: String = CONTENT
# workspace id -> bool, written only when the author overrides the default. Absent means
# "still the ruled default", which is why a height change can still move an untouched
# workspace's panel and can never move one the author has set.
var _panel_override: Dictionary = {}
# workspace id -> bool. `EW-7`: remembered per workspace, and never turned on by a resize.
var _split_enabled: Dictionary = {}
## Effective centre-column width and viewport height, supplied by the surface. Held rather
## than read from a viewport so this stays a headless model.
var _centre_width: float = 0.0
var _viewport_height: float = 0.0


static func is_known(workspace_id: String) -> bool:
	return WORKSPACES.has(workspace_id)


static func label_for(workspace_id: String) -> String:
	return String((WORKSPACES.get(workspace_id, {}) as Dictionary).get("label", workspace_id))


static func width_response_for(workspace_id: String) -> String:
	return String((WORKSPACES.get(workspace_id, {}) as Dictionary).get("width_response", ""))


static func split_threshold() -> float:
	return float(
		ResponsiveLayoutScript.tokens_for_mode(ResponsiveLayoutScript.MENU_MODE_EDITOR).get(
			"split_threshold", 2400.0
		)
	)


func active_id() -> String:
	return _active


## `CEUI-4` fixed the layout, so switching a workspace changes what the centre shows and
## nothing about where the regions are. Refuses an unknown id rather than falling back to
## Content: a silent fallback turns a typo into a workspace that quietly never opens.
func activate(workspace_id: String) -> bool:
	if not is_known(workspace_id):
		return false
	if workspace_id == _active:
		return true
	var previous := _active
	_active = workspace_id
	workspace_changed.emit(_active, previous)
	return true


## `{id, label, active, width_response, panel_open, split_offered, split_enabled}` in the
## bar's order.
func rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for workspace_id in ORDER:
		(
			out
			. append(
				{
					"id": workspace_id,
					"label": label_for(workspace_id),
					"active": workspace_id == _active,
					"width_response": width_response_for(workspace_id),
					"panel_open": is_panel_open(workspace_id),
					"split_offered": is_split_offered(),
					"split_enabled": is_split_enabled(workspace_id),
				}
			)
		)
	return out


# ---- `EW-4`/`EW-5` the bottom panel ----


## Measurements the panel and split rules depend on. Supplied by the surface on every
## resize; both default to zero, which reads as "at the floor" and therefore as the
## conservative answer rather than as an accidentally-open panel.
func set_metrics(centre_width: float, viewport_height: float) -> void:
	var changed_ids: Array[String] = []
	for workspace_id in ORDER:
		if not _panel_override.has(workspace_id):
			changed_ids.append(workspace_id)
	var before: Dictionary = {}
	for workspace_id in changed_ids:
		before[workspace_id] = is_panel_open(workspace_id)
	_centre_width = centre_width
	_viewport_height = viewport_height
	for workspace_id in changed_ids:
		var now := is_panel_open(workspace_id)
		if now != bool(before[workspace_id]):
			panel_visibility_changed.emit(workspace_id, now)


func is_panel_open(workspace_id: String = "") -> bool:
	var target := workspace_id if workspace_id != "" else _active
	if _panel_override.has(target):
		return bool(_panel_override[target])
	match String((WORKSPACES.get(target, {}) as Dictionary).get("panel", PANEL_CLOSED)):
		PANEL_OPEN:
			return true
		PANEL_ABOVE_FLOOR:
			return _viewport_height > EditorShellMetrics.VIEWPORT_FLOOR.y
		_:
			return false


## The author's own choice, which outranks the ruled default from here on. `[CEUI-S6]`
## lists panel state among the things that are explicitly NOT undoable -- it is view
## state, and `CEUI-4`/`[CEUI-S12]` own whether it persists beyond the session at all.
func set_panel_open(is_open: bool, workspace_id: String = "") -> void:
	var target := workspace_id if workspace_id != "" else _active
	if not is_known(target):
		return
	var before := is_panel_open(target)
	_panel_override[target] = is_open
	if is_open != before:
		panel_visibility_changed.emit(target, is_open)


## Drops the author's override so the workspace follows its ruled default again.
func clear_panel_override(workspace_id: String = "") -> void:
	var target := workspace_id if workspace_id != "" else _active
	var before := is_panel_open(target)
	_panel_override.erase(target)
	var now := is_panel_open(target)
	if now != before:
		panel_visibility_changed.emit(target, now)


# ---- `EW-7` the second document column ----


## Offered, never automatic. `[CEUI-4]` fixed the layout precisely so that resizing a
## window does not rearrange it, and an automatic split is that rearrangement with a
## threshold attached.
func is_split_offered() -> bool:
	return _centre_width >= split_threshold()


func is_split_enabled(workspace_id: String = "") -> bool:
	var target := workspace_id if workspace_id != "" else _active
	# Enabled AND offered: shrinking below the threshold hides the second column without
	# forgetting that the author wanted it, so widening again brings it back.
	return bool(_split_enabled.get(target, false)) and is_split_offered()


## Remembered per workspace even when the width has since taken the offer away, which is
## what `EW-7`'s "offered and remembered" means. Refuses while the offer is not standing:
## turning on a column that cannot be shown is a setting with no observable effect.
func set_split_enabled(enabled: bool, workspace_id: String = "") -> bool:
	var target := workspace_id if workspace_id != "" else _active
	if not is_known(target):
		return false
	if enabled and not is_split_offered():
		return false
	_split_enabled[target] = enabled
	return true


# ---- `[TSV-24]` ----


func capture_state() -> Dictionary:
	return {
		"active": _active,
		"panel_override": _panel_override.duplicate(true),
		"split_enabled": _split_enabled.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	_panel_override.clear()
	for workspace_id in state.get("panel_override", {}) as Dictionary:
		if is_known(String(workspace_id)):
			_panel_override[String(workspace_id)] = bool(
				(state["panel_override"] as Dictionary)[workspace_id]
			)
	_split_enabled.clear()
	for workspace_id in state.get("split_enabled", {}) as Dictionary:
		if is_known(String(workspace_id)):
			_split_enabled[String(workspace_id)] = bool(
				(state["split_enabled"] as Dictionary)[workspace_id]
			)
	var active := String(state.get("active", ""))
	if is_known(active):
		activate(active)
