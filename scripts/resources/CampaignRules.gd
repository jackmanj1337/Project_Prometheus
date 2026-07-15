class_name CampaignRules extends Resource
# Per-save bundle of gameplay rules chosen at New Game and carried by the
# save/runtime state. Distinct from global app settings (SettingsManager, on
# disk) and from per-map launch state.
#
# Authority: GDD_01 §CampaignRules Contract
# Status: live per-save rule object. GameState owns one instance and callers read
# rules through GameState.campaign_rules.

# --- Implemented rule fields ---

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

# Which faction ids earn EXP from combat. Default: player (blue) + ally (green).
# Red (enemy) does not gain EXP by default. Designers may override per campaign.
# See GDD_01 §CampaignRules Contract, OPEN-4, and GDD_02 §EXP.
@export var exp_gaining_factions: Array[String] = ["blue", "green"]

# Hit-roll resolver preset (CRR-4): "two_roll" (RULE-001 default, true-hit curve)
# or "single_roll" (displayed = real odds). Registry promotion is
# B3-COMBAT-ROLL-RESOLVER.
@export var hit_formula: String = "two_roll"

# Per-map rewind budget. Zero is the ironman-style no-rewind preset.
@export var rewind_charges_per_map: int = 4

# B1-LEDGER Phase 2 — within-map ledger retention budgets. They set how deep the
# decaying ledger keeps entries: the union of the last `undo_activations`
# per-activation entries and the last `undo_rounds` round-start entries (the
# round-0 boundary is always retained on top, so a Retry works regardless). These
# are the RETENTION depth; making the budget spendable mid-battle is Rewind
# (Phase 3), which reconciles these with rewind_charges_per_map. -1 means retain
# every entry of that tier (the coarse round tier may legitimately be infinite);
# 0 keeps none beyond the round-0 boundary.
@export var undo_activations: int = 0
@export var undo_rounds: int = 0

# B1-LEDGER Phase 5 — player/manual slot classes and independent autosave pools.
# Dictionaries stay data-shaped so campaign JSON can supply new combinations
# without adding engine modes.
@export var save_slot_classes: Array[Dictionary] = [
	{"count": 3, "accepts": "between_map", "consumed_on_load": false,
		"label": "Campaign Save"},
	{"count": 1, "accepts": "mid_map", "consumed_on_load": true,
		"label": "Suspend"},
]
@export var autosave_rules: Array[Dictionary] = [{
	"rule_id": "campaign_progress",
	"trigger": "battle_end",
	"keep": 1,
	"label": "Campaign Autosave",
	"consumed_on_load": false,
}]


# Returns a CampaignRules with all project defaults applied.
static func make_default() -> CampaignRules:
	return CampaignRules.new()
