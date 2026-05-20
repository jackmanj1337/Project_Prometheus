class_name ObjectiveCondition extends Resource
# A single victory/defeat condition evaluated per alliance group (M16).
#
# Authored on MapData.victory_conditions[group_id] or defeat_conditions[group_id]
# as an entry in an Array[ObjectiveCondition]. The evaluator
# (TurnManager.check_victory_conditions, M16 stage 2+) reads `type` to dispatch
# to the right check, and the other fields supply that check's parameters.
#
# A single typed resource (rather than a class hierarchy) keeps the inspector
# UX simple and matches the existing MapData.objective_params pattern. The
# trade-off is that only the fields relevant to `type` are meaningful — the
# others are inert defaults. See GDD_10_Roadmap.md § Milestone 16 for the
# full condition catalogue and which fields each type reads.

# Catalogue:
#   rout          — faction_id wiped (or "all hostiles" if faction_id empty)
#   defeat_boss   — every unit_ids id dead
#   seize         — a unit in allowed_unit_ids uses the Seize action on a `tiles` tile
#   escape        — every unit_ids id has reached any tile in `tiles`
#   survive       — turn_number advances by `turns` rounds (optionally while
#                   holding any of `tiles`)
#   protect       — every unit_ids id stays alive (replaces required_survivor_ids)
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

# seize: the tile(s) the Seize action may be used on.
# escape: the zone of tiles (a unit on any of them counts as escaped).
# survive (hold variant): the tile(s) that must be held for `turns` rounds.
@export var tiles: Array[Vector2i] = []

# seize: optional restriction on which unit_ids may perform the seize.
# Empty = any unit in the conditioning group may seize (Decision 4 / 2026-05-17).
@export var allowed_unit_ids: Array[String] = []

# survive: number of completed rounds the condition must persist.
# turn_limit: defeat fires once turn_number exceeds this value (0 = no limit,
# matching MapData.turn_limit's existing meaning).
@export var turns: int = 0
