class_name ItemData extends Resource

@export var id: String = ""
@export var display_name: String = ""
# Pack-relative Tier-1 asset id/path; empty keeps the existing text-only row.
@export var icon: String = ""
@export var description: String = ""
# "healing"|"stat"|"promotion"|"equip"|"key"|"sellable"
@export var item_type: String = ""
# -1 = infinite / equippable
@export var uses: int = 1
@export var cost: int = 0
# Links to ItemHandler logic
@export var effect_id: String = ""
@export var effect_params: Dictionary = {}
