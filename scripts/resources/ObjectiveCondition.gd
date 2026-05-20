class_name ObjectiveCondition extends Resource
# A single victory/defeat condition evaluated per alliance group (M16).
#
# Authored on MapData.victory_conditions[group_id] or defeat_conditions[group_id]
# as an entry in an Array[ObjectiveCondition]. The evaluator
# (TurnManager.check_victory_conditions, M16 stage 2+) reads `type` to dispatch
# to the right check, and the other fields supply that check's parameters.
#
# A single typed resource (rather than a class hierarchy) keeps the inspector
# UX simple. The trade-off is that only the fields relevant to `type` are
# meaningful — the others are inert defaults. See GDD_10_Roadmap.md § Milestone
# 16 for the full condition catalogue and which fields each type reads.

# Catalogue:
#   rout          — faction_id wiped (or "all hostiles" if faction_id empty)
#   defeat_boss   — every unit_ids id dead
#   seize         — a unit in allowed_unit_ids uses the Seize action on a `tiles` tile
#   escape        — every unit_ids id has reached any tile in `tiles`
#   survive       — turn_number advances by `turns` rounds (optionally while
#                   holding any of `tiles`)
#   protect       — every unit_ids id stays alive
#   turn_limit    — turn_number exceeds `turns` (defeat-only convention)
@export var type: String = "rout"

# rout: the faction id (or alliance group name) that must be wiped. Empty for
# rout means "every faction outside the conditioning group" — the natural
# blue-routs-everyone-else case authored without naming red+yellow explicitly.
@export var faction_id: String = ""

# defeat_boss, protect, escape: the named unit_ids the condition watches.
# protect = these must stay alive; defeat_boss = these must die; escape =
# these must reach any tile in `tiles`.
@export var unit_ids: Array[String] = []

# escape: the zone of tiles (a unit on any of them counts as escaped).
# survive (hold variant): the tile(s) that must be held for `turns` rounds.
# NOT used by seize — seize is one tile per condition (see `tile` below). A map
# that wants two seizable thrones authors two seize conditions, not one with
# tiles.size() == 2.
@export var tiles: Array[Vector2i] = []

# seize: the single tile the Seize action may be used on. Vector2i(-1, -1)
# means "not authored" — DataManager validation flags a seize condition that
# leaves this at the sentinel. Kept separate from `tiles` because the seize
# semantics are fundamentally one-tile-per-condition (L-1 / 2026-05-20 review).
@export var tile: Vector2i = Vector2i(-1, -1)

# seize: optional restriction on which unit_ids may perform the seize.
# Empty = any unit in the conditioning group may seize (Decision 4 / 2026-05-17).
@export var allowed_unit_ids: Array[String] = []

# Measured in completed *rounds* (one full faction cycle = one round; turn_number
# ticks once per round in both WHOLE_PHASE and ALTERNATING modes — see TurnManager).
#   survive: condition is met once turn_number > turns (i.e. `turns` full rounds
#     have elapsed since the map began on turn 1).
#   turn_limit: defeat fires once turn_number > turns. 0 = no limit, meaning the
#     condition never fires — useful as a noop authored stub.
@export var turns: int = 0


# One-line summary for the HUD objective readout (M16 stage 4). Concise enough
# to fit in the side panel; type-specific so each condition reads naturally.
# Returns "" for the internal _group_routed sentinel — it isn't author-facing.
func get_display_text() -> String:
	match type:
		"rout":
			if faction_id == "":
				return "Rout all hostiles"
			return "Rout %s" % faction_id
		"defeat_boss":
			if unit_ids.is_empty():
				return "Defeat boss"
			return "Defeat %s" % ", ".join(unit_ids)
		"seize":
			if tile == Vector2i(-1, -1):
				return "Seize"
			return "Seize %s" % str(tile)
		"escape":
			if unit_ids.is_empty():
				return "Escape"
			return "Escape: %s" % ", ".join(unit_ids)
		"survive":
			if tiles.is_empty():
				return "Survive %d turn(s)" % turns
			return "Hold for %d turn(s)" % turns
		"protect":
			if unit_ids.is_empty():
				return "Protect"
			return "Protect: %s" % ", ".join(unit_ids)
		"turn_limit":
			return "Win before turn %d" % turns
		_:
			return ""
