class_name InventoryEntry extends Resource
# Typed replacement for the old Array[Dictionary] inventory format (ARCH-05).
# One InventoryEntry per slot. Use entry_type to determine which fields are active.

# "weapon" | "item" | "equip"
@export var entry_type: String = ""

# ── Weapon fields ──────────────────────────────────────────────────────────
@export var weapon_id: String = ""
# Reserved for the forging system (M10); no code reads this yet.
@export var forged_mods: Dictionary = {}

# ── Item fields ────────────────────────────────────────────────────────────
@export var item_id: String = ""

# ── Shared ────────────────────────────────────────────────────────────────
@export var uses_remaining: int = 0

# ── Equipment bonus fields (equip type — M10 forging) ──────────────────────
@export var accuracy: int = 0
@export var damage: int = 0
@export var crit: int = 0
@export var dodge: int = 0


func is_weapon() -> bool: return entry_type == "weapon"
func is_item()   -> bool: return entry_type == "item"
func is_equip()  -> bool: return entry_type == "equip"


# Factory helpers keep construction one-liners at call sites.
static func make_weapon(wid: String, uses: int) -> InventoryEntry:
	var e := InventoryEntry.new()
	e.entry_type = "weapon"
	e.weapon_id = wid
	e.uses_remaining = uses
	return e


static func make_item(iid: String, uses: int) -> InventoryEntry:
	var e := InventoryEntry.new()
	e.entry_type = "item"
	e.item_id = iid
	e.uses_remaining = uses
	return e
