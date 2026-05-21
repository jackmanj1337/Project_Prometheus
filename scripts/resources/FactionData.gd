class_name FactionData extends Resource
# A single faction in the M14 N-faction model. One FactionData instance per
# faction per map, listed on MapData.factions; an empty list on MapData falls
# back to the built-in blue + red defaults so existing maps keep working.
#
# The defining design rule (feasibility doc §9 / GDD_10 § Milestone 14): a
# 5th+ faction must be **data**, not a code enum value. Adding one is a
# FactionData entry on MapData and a turn_order entry, nothing else — the
# turn scheduler, AI, and hostility model are all faction-blind.

# Faction id — the string written into Unit.team. Conventionally one of
# "blue" / "green" / "red" / "yellow" but any non-empty string is valid;
# unknown ids resolve to their own one-faction alliance group automatically
# (see GameState.are_hostile).
@export var id: String = ""

# Human-readable label used by PhaseBanner / results screens. Defaults to a
# title-cased id when empty.
@export var display_name: String = ""

# Tint applied to unit sprites + the PhaseBanner background. Defaults to a
# soft gray for the "id has no design colour yet" case.
@export var color: Color = Color(0.55, 0.55, 0.55, 1.0)

# Alliance group name. Factions in the same group are NEVER hostile to each
# other — see GameState.are_hostile. Default groups (when authored maps
# don't override): blue/green → "allies", red → "foes", yellow → "rogues".
@export var alliance_group: String = ""

# Who drives this faction's activations. Recognised values: "AI" (default),
# "HUMAN" (a local human-controlled faction — what blue uses), "HOTSEAT"
# (lands with M15 Part A), "REMOTE" (M15 Part B, deferred). Open enum on
# purpose so new controllers slot in without touching this file.
@export var controller: String = "AI"


# Returns display_name if set, otherwise a title-cased id ("blue" → "Blue").
# Lets a stage-3 MapData author leave display_name empty for the default
# four armies without leaving the PhaseBanner showing "blue".
func get_label() -> String:
	if display_name != "":
		return display_name
	if id == "":
		return ""
	return display_label(id)


# Title-cases a raw faction id for the "no FactionData authored" fallback used
# by faction-aware UI (HUD phase label, PhaseBanner). "" → "Unknown";
# "blue" → "Blue". Static so callers don't need a FactionData instance.
static func display_label(faction_id: String) -> String:
	if faction_id == "":
		return "Unknown"
	return faction_id.substr(0, 1).to_upper() + faction_id.substr(1)
