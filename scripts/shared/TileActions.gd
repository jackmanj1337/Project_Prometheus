extends RefCounted
# Shared availability source for unit-on-tile actions (Seize, Escape, Shop,
# Visit, Activate). Both ActionMenu and the HUD's terrain More Info panel
# read from here so the button row and the description row never disagree
# about what a unit can do on a given tile — same source of truth for
# "what's offered" and "what's described."
#
# Phase 1 only wires Seize and Escape (the two map-objective entries
# already gated by TurnManager). Shop/Visit/Activate are listed so the HUD
# can describe them generically and so a future implementation only has to
# extend `is_available()` instead of also touching ActionMenu and the HUD.
#
# Usage:
#   const TileActions = preload("res://scripts/shared/TileActions.gd")
#   var ids: Array[String] = TileActions.available_for(unit, tile, turn)
#   var label: String = TileActions.display_label("seize")

# Display labels keyed by action id. Mirrors the button labels in
# ActionMenu so the More Info readout and the action menu use the same
# wording, and centralises the strings so a future localisation pass only
# has one place to edit.
const ACTION_LABELS: Dictionary = {
	"seize": "Seize",
	"escape": "Escape",
	"shop": "Shop",
	"visit": "Visit",
	"activate": "Activate",
}

# Canonical ordering for `available_for()` — matches the ActionMenu's
# vertical button order so the More Info readout reads top-down the same
# way the player would scan the menu.
const _ACTION_ORDER: Array[String] = [
	"seize",
	"escape",
	"shop",
	"visit",
	"activate",
]


# True when `unit` could perform `action_id` on `tile`, given the active
# TurnManager. `turn` may be null in tests / headless flows — every gate
# tolerates a missing turn manager and returns false, which is the safe
# default (an action you can't gate is an action you don't offer).
static func is_available(action_id: String, unit: Node, tile: Vector2i, turn: Node) -> bool:
	if unit == null:
		return false
	match action_id:
		"seize":
			return (
				turn != null and turn.has_method("can_seize") and bool(turn.can_seize(unit, tile))
			)
		"escape":
			return (
				turn != null and turn.has_method("can_escape") and bool(turn.can_escape(unit, tile))
			)
		# Shop / Visit / Activate are placeholders. They will be wired into
		# real gates as those systems land; until then they simply do not
		# appear in either the action menu or the More Info readout.
		"shop", "visit", "activate":
			return false
	return false


# Returns every action id `unit` could perform on `tile`, in the canonical
# display order. Empty when no action is available — callers should treat
# an empty list as "nothing to show in this section."
static func available_for(unit: Node, tile: Vector2i, turn: Node) -> Array[String]:
	var out: Array[String] = []
	for action_id in _ACTION_ORDER:
		if is_available(action_id, unit, tile, turn):
			out.append(action_id)
	return out


# Friendly button-label for an action id. Falls back to the raw id so a
# new action never crashes the display; the caller can still grep for the
# unmapped id in logs.
static func display_label(action_id: String) -> String:
	return ACTION_LABELS.get(action_id, action_id)
