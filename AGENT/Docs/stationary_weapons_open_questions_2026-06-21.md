# Stationary Weapon Interaction — Ballista/Onager (§5) — Draft Plan + Open Questions

**Started:** 2026-06-21d
**Status:** Planning draft — register OPEN. Mountable map objects; contained.
**Source:** `planning_backlog_2026-06-20.md` §5; roadmap line "already have WeaponData";
session note 2026-06-21c Tier 2 #6.
**Code:** `scripts/resources/WeaponData.gd`, `scripts/shared/TileActions.gd`,
`scripts/core/GridManager.gd`, `scripts/resources/MapData.gd`.
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

- **`WeaponData` already supports long range via formula strings.** `range_min_formula` /
  `range_max_formula` parse `"3"`, `"3"`–`"10"`, even `"MAG/2"`. A ballista is just a
  `WeaponData` with `range_min/max = "3"/"10"` (or similar) and a `combat_family`. The
  roadmap note "already have WeaponData" is correct — the *weapon* is data; the missing
  piece is the **mount object + occupancy**.
- **Range/targeting math is range-agnostic.** `get_attackable_enemies_from_tile`,
  `in_weapon_range_from_tile`, `_tiles_in_range` all read the equipped weapon's range; a
  3–10 ballista works through the existing pipeline once a unit "wields" it.
- **No map-object/occupancy model.** Same gap as doors/chests — `MapData` has no concept of
  a ballista sitting at a tile that a unit mounts. (Shared dependency — see [STW-1].)
- **`TileActions` has the `"activate"` placeholder** — "mount/use ballista" is a natural
  `activate` case, same wiring point as doors/chests.
- **Ammo: no model.** `WeaponData.uses` exists (and `InventoryEntry.uses_remaining`), but a
  *map-fixed* weapon's ammo isn't an inventory entry today.

## 2. Draft plan (classic FE convention)

Classic FE siege/stationary weapon convention (Ballista, Onager/Catapult, Fire Orb):
- A **fixed weapon occupies a map tile**. A unit **stands on/adjacent and "mounts"** it,
  gaining the weapon's long range for an attack (3–10 for a ballista) while mounted.
- The unit **cannot move and fire the siege weapon in the same turn** in classic titles
  (you garrison it). The weapon is **terrain-bound**, not carried.
- **Ammo is limited** (e.g. a ballista has N shots per map); some are infinite.
- **Enemies use them too** (siege tomes/ballistae on enemy turn are a classic threat).
- Different types = different range/might (Ballista vs Iron/Killer ballista vs Onager arc).

Core model: `MapData.map_objects` gains a `type:"siege_weapon"` entry `{ tile, weapon_id,
ammo, faction? }`. Mounting temporarily swaps the unit's effective weapon to the siege
weapon for targeting; dismount/turn-end restores. Overlaps doors/chests' object model.

## 3. Open questions register

### [STW-1] Map-object model — share with doors/chests or separate?  **[OPEN]**
- **A — Reuse the same `MapData.map_objects` array** (a `type:"siege_weapon"` entry beside
  `"door"`/`"chest"`). One object system, one validation path, one snapshot field.
- **B — Dedicated `MapData.siege_weapons` array.** Cleaner per-type schema, but a second
  parallel object system.
- **Rec: A** — siege weapons, doors, and chests are all "interactive thing at a tile";
  one `map_objects` model (shared with the doors/chests register) avoids three parallel
  systems and one validation/snapshot path serves all. Sequence this AFTER doors/chests so
  it inherits the model rather than defining it.
- **Resolution:** _[OPEN]_

### [STW-2] Occupancy: mount-in-place vs move-then-mount  **[OPEN]**
- **A — Stand ON the siege tile to use it** (the tile is a special terrain a unit can end
  movement on; "Activate" fires). Matches GBA ballista (you occupy the tile).
- **B — Stand adjacent and operate it** (the weapon is its own object the unit never stands
  on). More like an emplacement.
- **Rec: A** — occupying the tile is the FE-classic model and reuses `can_end_on_tile` /
  movement (the siege tile is just passable terrain a unit stops on). Simpler than a
  separate adjacency gate. The unit's sprite sits on the ballista.
- **Resolution:** _[OPEN]_

### [STW-3] Move-and-fire restriction  **[OPEN]**
- **A — Must NOT have moved this activation to fire** (classic: garrison then fire next
  turn, or fire from a stationary position). Reuses `TurnManager` MOVED-state to gate.
- **B — May move onto the tile and fire same turn** (more permissive; like a normal weapon).
- **Rec: A** — the move restriction is what makes siege weapons a *positional commitment*
  (the FE feel) and prevents a unit ferrying a 1–10 range weapon around the map. Gate "Fire"
  on the unit not having moved this activation (or only moving onto the siege tile itself).
- **Resolution:** _[OPEN]_

### [STW-4] Effective-weapon swap mechanism while mounted  **[OPEN]**
The unit's targeting must use the siege weapon's range, not its carried weapon's.
- **A — Temporary equipped-weapon override** while on the siege tile: `get_equipped_weapon`
  (or a thin wrapper) returns the siege `WeaponData` when the unit occupies a siege tile.
  Targeting math then "just works" (it already reads the equipped weapon).
- **B — A distinct "siege attack" action path** parallel to normal attack, with its own
  range/targeting calc.
- **Rec: A** — the whole targeting pipeline is weapon-range-driven already; a scoped
  equipped-weapon override is the minimal seam (mirrors the deferred Laguz natural-weapon
  auto-return pattern noted in `WeaponData.is_natural_weapon`). Avoids forking attack flow.
- **Resolution:** _[OPEN]_

### [STW-5] Ammo model + persistence  **[OPEN]**
- **A — `ammo:int` on the siege object** (decrements per shot; `-1` = infinite). Map-bound,
  shared between any unit that mounts it. Snapshot with the object state.
- **B — Treat the siege weapon as an `InventoryEntry`** granted on mount — but it's
  tile-bound and shared, so inventory is the wrong owner.
- **Rec: A** — ammo belongs to the *emplacement*, not the unit (whoever mans it draws from
  the same pool); store `ammo` on the `map_objects` entry and snapshot it alongside
  door/chest state ([STW-6]). `-1` for infinite (matches the `uses_remaining` sentinel).
- **Resolution:** _[OPEN]_

### [STW-6] AI use of siege weapons  **[OPEN]**
- **A — No AI siege use v1.** Player-only; enemy siege weapons (if any) are inert. Smallest.
- **B — AI mounts + fires** enemy siege weapons (classic enemy-phase siege threat). Needs an
  `EnemyAI` behavior (path to siege tile → fire long-range) — overlaps AI-profiles.
- **Rec: A v1** — enemy siege is a great threat but it's a new AI behavior; ship player siege
  use first. Add an enemy-siege behavior as a cross-item follow-up (cross-ref `ai_profiles`).
- **Resolution:** _[OPEN]_

## 4. Slice sketch (provisional)
1. (After doors/chests) `map_objects` `type:"siege_weapon"` entry + `DataManager` validation.
2. Occupy-tile mount + `TileActions` "Activate/Fire" gate ([STW-2]/[STW-3]).
3. Effective-weapon override while mounted ([STW-4]) — targeting reuses existing range math.
4. Ammo decrement + snapshot ([STW-5]/[STW-6]).
5. (Fast-follow) enemy AI siege use.

## 5. Test notes
- Headless: a unit on a siege tile gains 3–10 range targeting (assert `get_attackable_enemies
  _from_tile` returns far targets); off the tile, normal range. Firing decrements ammo;
  `ammo == 0` removes the Fire action. A unit that moved can't fire ([STW-3]).
- Snapshot round-trip restores `ammo`.
