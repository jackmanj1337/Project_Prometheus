class_name CampaignRules extends Resource
# Per-save bundle of gameplay rules chosen at New Game and carried by the
# save/runtime state. Distinct from global app settings (SettingsManager, on
# disk) and from per-map launch state.
#
# Authority: GDD_01 §CampaignRules Contract
# Status: Stub (Stage 4.3). Fields are loose on GameState today; consolidation
# into this class is Target design. Use GameState's rule fields until then.

# --- Implemented rule fields (mirrored from GameState; not yet wired) ---

# Whether defeated allied units are permanently lost for the run.
@export var permadeath_enabled: bool = false

# Leveling method: "growth_random" or "growth_fixed".
@export var leveling_method: String = "growth_random"

# Whether units auto-promote when they reach their class's level cap.
@export var auto_promote_at_max_level: bool = false

# Whether Pair Up actions are available on the map.
@export var pair_up_enabled: bool = true

# Maximum number of equipped skills per unit (auto-equipped, cap enforced on grant).
@export var max_skills: int = 5

# Maximum inventory slots per unit (future-facing; not yet enforced).
@export var max_inventory: int = 8

# --- Target design fields (not yet wired into the engine) ---

# Which faction ids earn EXP from combat. Default: player (blue) + ally (green).
# Red (enemy) does not gain EXP by default. Designers may override per campaign.
# See GDD_01 §CampaignRules Contract, OPEN-4, and GDD_02 §EXP.
@export var exp_gaining_factions: Array[String] = ["blue", "green"]


# Returns a CampaignRules with all project defaults applied.
static func make_default() -> CampaignRules:
	return CampaignRules.new()
