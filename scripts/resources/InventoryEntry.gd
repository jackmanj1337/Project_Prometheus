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
# Remaining uses. -1 = infinite (sentinel), 0 = empty/exhausted, >0 = finite.
# Equip-type entries ignore this — gate those with is_equip(), not uses.
@export var uses_remaining: int = 0

# ── Equipment bonus fields (equip type — M10 forging) ──────────────────────
@export var accuracy: int = 0
@export var damage: int = 0
@export var crit: int = 0
@export var dodge: int = 0


func is_weapon() -> bool:
	return entry_type == "weapon"


func is_item() -> bool:
	return entry_type == "item"


func is_equip() -> bool:
	return entry_type == "equip"


# Whether this weapon/item entry still has uses. -1 (infinite) and any positive
# count are usable; 0 means exhausted. Equip entries are exempt — they are gated
# by is_equip(), not by uses.
func has_uses() -> bool:
	return uses_remaining != 0


# Checks for common misconfiguration: wrong type/id combinations, unset entry_type.
# Call after loading from .tres or after manual construction.
func validate() -> bool:
	const VALID_TYPES := ["weapon", "item", "equip"]
	if not (entry_type in VALID_TYPES):
		push_error("InventoryEntry.validate: invalid entry_type '%s'" % entry_type)
		return false
	if is_weapon() and weapon_id == "":
		push_error("InventoryEntry.validate: weapon entry has empty weapon_id")
		return false
	if is_item() and item_id == "":
		push_error("InventoryEntry.validate: item entry has empty item_id")
		return false
	if is_weapon() and item_id != "":
		push_warning(
			"InventoryEntry.validate: weapon entry has item_id set — likely copy/paste error"
		)
	if is_item() and weapon_id != "":
		push_warning(
			"InventoryEntry.validate: item entry has weapon_id set — likely copy/paste error"
		)
	return true


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
