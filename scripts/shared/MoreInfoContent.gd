extends RefCounted
# Shared description source for the More Info side panels. Maps namespaced
# entry keys (stat:strength, weapon_field:hit, terrain:forest,
# tile_action:seize, ...) to a short human-readable description: what the
# entry is, where it shows up, and why a player or tester should care. Values are
# plain text, never trusted BBCode; every RichTextLabel consumer must escape them.
#
# Phase 1 keeps these descriptions inline so we can iterate fast during
# playtests. If the list grows past ~50 entries, move it to a JSON resource
# loaded by DataManager — the lookup API would stay the same.
#
# Usage:
#   const MoreInfoContent = preload("res://scripts/shared/MoreInfoContent.gd")
#   var text: String = MoreInfoContent.describe("stat", "strength")
#
# Unknown keys return a "No description yet" placeholder, never an empty
# string and never a crash — More Info should remain useful even before every
# entry is authored.

const FALLBACK_TEXT := "No description yet — add one in scripts/shared/MoreInfoContent.gd."

# Stat descriptions. Player-facing language; assume the reader knows the game
# is a Fire Emblem-style SRPG but does not yet know this game's formulas.
const STATS: Dictionary = {
	"strength":
	"Physical attack power. Adds to damage with swords, lances, axes, and bows, and reduces weapon weight penalties.",
	"magic": "Magic attack power. Adds to damage with tomes and to healing from staves.",
	"skill":
	"Hit-rate stat. Each point of Skill adds 2% to hit; half of Skill (rounded down) adds to crit.",
	"speed":
	"Determines attack speed and avoid. Reaching the doubling threshold over the opponent grants a follow-up attack.",
	"defense": "Reduces physical damage taken (sword/lance/axe/bow). Has no effect against magic.",
	"resistance":
	"Reduces magical damage taken (tomes and breath). Has no effect against physical attacks.",
	"luck": "Boosts hit, avoid, and crit avoid; also reduces incoming crit.",
	"movement": "Number of tiles the unit can move per turn before terrain costs.",
	"constitution":
	"Body/build stat. Affects rescue and Pair Up eligibility and reduces a weapon's weight penalty alongside Strength. Intentionally uncapped by class.",
	"line_of_sight":
	"How many tiles the unit can see, used for fog-of-war vision once that system is active. Intentionally uncapped by class.",
	"hp": "Current and maximum hit points. Reaching 0 HP defeats the unit.",
}

# Inventory entry kinds shown on the character sheet.
const INVENTORY: Dictionary = {
	"weapon":
	"An equippable weapon. Affects which combat formulas apply and consumes a use per attack (unless the weapon is unbreakable).",
	"item":
	"A consumable or key item. Some items heal, some grant temporary stat boosts, and some unlock map events.",
}

# Skills section on the character sheet.
const SKILLS: Dictionary = {
	"generic":
	"An ability the unit has learned. Skills can trigger in combat, modify stats, or grant map abilities.",
}

# Weapon-rank tracks on the character sheet.
const WEXP: Dictionary = {
	"generic":
	"Weapon experience for this combat family. Higher ranks unlock stronger weapons of the same type.",
}

# Combat preview field descriptions.
const COMBAT_FIELDS: Dictionary = {
	"name":
	"The combatant in this exchange. Press the inspect-unit key on the map for their full character sheet.",
	"hp": "Current HP / Max HP for this combatant. Reaching 0 HP defeats them.",
	"hit": "Chance to land a single hit, after the defender's avoid is subtracted.",
	"crit":
	"Chance the hit deals triple damage. Critical hits still need to land — they are rolled after hit.",
	"damage": "Damage dealt per successful hit, before any defensive stat is applied.",
	"as":
	"Attack Speed. The attacker doubles when their AS exceeds the defender's by the threshold.",
	"triangle":
	"Weapon Triangle: swords beat axes, axes beat lances, lances beat swords. Tomes follow fire>wind>thunder>fire.",
	"effectiveness":
	"Some weapons deal extra damage to specific unit types (e.g. armoured, flying, beast, dragon).",
}

# Terrain descriptions used by the HUD's expanded More Info mode.
const TERRAIN: Dictionary = {
	"plain": "Open ground. No movement cost penalty and no defensive bonus.",
	"forest": "Slows most ground units; grants avoid bonus and some defense.",
	"mountain":
	"Heavy movement penalty for ground units; impassable to many. Strong defensive bonus.",
	"village": "A friendly tile. Many villages can be visited for items or events.",
	"fort": "Defensive structure. Grants strong defense and slow HP recovery each turn.",
	"throne":
	"Seat of a commander. Major defensive bonus and may be a Seize target for the chapter objective.",
	"river":
	"Impassable to most ground units; fliers cross freely. Some units have wading bonuses.",
	"sea": "Open water. Generally impassable except to fliers and dedicated naval classes.",
	"desert":
	"Loose sand that slows most units. Mounted and armoured units struggle most; light-footed units cross it more easily.",
	"wall":
	"Solid obstruction. Blocks movement and usually blocks passage entirely unless a special ability says otherwise.",
}

# Tile-action descriptions surfaced by the terrain More Info expansion.
const TILE_ACTIONS: Dictionary = {
	"seize":
	"Seize the tile to complete the chapter objective. Counts as the unit's action for the turn.",
	"shop": "Open a shop interface on this tile. Buying or selling does not end the unit's turn.",
	"activate": "Trigger a tile-specific event such as a door, switch, or scripted scene.",
	"visit": "Visit this tile for an item or scene unique to this chapter.",
	"escape": "Leave the map. Counts as the unit's action for the turn.",
}


# Returns the description for (category, key), or the fallback placeholder if
# the key is not authored yet. Never returns an empty string.
static func describe(category: String, key: String) -> String:
	var table: Dictionary = _table_for_category(category)
	if table.has(key):
		return String(table[key])
	# Some categories have a "generic" fallback that is more useful than the
	# global placeholder (e.g. all weapon-rank rows share one description).
	if table.has("generic"):
		return String(table["generic"])
	return FALLBACK_TEXT


# Returns true when (category, key) has an authored description. UI code can
# use this to decide whether to show a "(no description yet)" hint badge.
static func has_description(category: String, key: String) -> bool:
	return _table_for_category(category).has(key)


# Internal: dispatch to the right lookup table by category name. Unknown
# categories return an empty dict, so describe() falls through to FALLBACK_TEXT
# instead of crashing on a typo.
static func _table_for_category(category: String) -> Dictionary:
	match category:
		"stat":
			return STATS
		"inventory":
			return INVENTORY
		"skill":
			return SKILLS
		"wexp":
			return WEXP
		"combat_field":
			return COMBAT_FIELDS
		"terrain":
			return TERRAIN
		"tile_action":
			return TILE_ACTIONS
		_:
			return {}
