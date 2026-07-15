class_name CampaignNode extends Resource
# One node of a campaign progression graph. Built from authored JSON by
# CampaignData.parse — never authored as a .tres, because [CST-3] resolved the
# progression graph to JSON so a campaign stays a portable, hand-editable
# document (B6-CAMPAIGN-SHARING later ships it as one file).
#
# Authority: GDD_01 §CampaignData Contract
# Node identity rule [CNC-1]: node_id is the durable save/progression identity.
# Everything else on the node (label, map binding, prep fields) is author-
# editable without invalidating a save.

# Durable progression identity. Referenced by campaign.node_id / cleared_nodes
# in the save envelope, so renaming it breaks existing saves.
@export var node_id: String = ""

# Player-facing chapter/mission name.
@export var label: String = ""

# Binding to a map_registry id. [B4-ENCOUNTER-MODEL] later splits this into a
# battle-map / battle-encounter pair; nodes bind by map id until then, which is
# exactly the adapter-friendly shape [CNC-3] asked for.
@export var map_id: String = ""

# Successor node ids. Empty = terminal node (campaign complete). A single entry
# is the linear MVP case; multiple entries are the branch case the same schema
# carries with no reshape.
@export var next_node_ids: Array[String] = []

# [CST-5] Deployment constraints live on the NODE, not the map. Consumed by
# B4-PREP-DEPLOYMENT; authored and validated here so the prep slice does not
# force a schema change.
@export var required_units: Array[String] = []
@export var excluded_units: Array[String] = []

# Max units the player may deploy. -1 = uncapped.
@export var deployment_cap: int = -1

# Rule-agnostic per-map layer. Keys are CampaignRules ids; values shadow campaign
# defaults for this node unless the campaign mandates that rule.
@export var rule_overrides: Dictionary = {}


func is_terminal() -> bool:
	return next_node_ids.is_empty()
