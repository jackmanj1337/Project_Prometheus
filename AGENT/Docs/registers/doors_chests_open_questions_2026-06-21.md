---
Type: register
Status: RESOLVED 2026-06-21g
Last verified: 2026-06-23
Register: DCH-1..6
Resolved-in: 2026-06-21g
---

# Doors & Chests (§5) — Draft Plan + Open Questions Register

**Started:** 2026-06-21d
**Status:** [DCH-1..6] **RESOLVED 2026-06-21g** — build-ready (one owner override: [DCH-2]
unified `map_objects` model). New interaction verbs; contained. **Defines the shared
`map_objects` tile-object model that STW (stationary weapons) inherits.**
> **Generalized 2026-06-27d (`[SAC-1]`):** doors/chests are now **specialized types in the one unified
> `map_objects`/`activate` model** that the A5 `shop`/`activate` walk firmed — levers/switches/shop/panel-
> triggers are author-defined object types in the same model (each `activate` behavior carries its own
> label, `[SAC-2]`). Don't build a parallel object system.
Save ask:
`map_objects_state` array reserved in the §2 schema.
**Source:** `planning_backlog_2026-06-20.md` §5 ("Pick/Unlock/Key"); session note
2026-06-21c Tier 2 #5.
**Code:** `scripts/shared/TileActions.gd`, `scripts/resources/ItemData.gd`,
`scripts/resources/MapData.gd`, `scripts/items/ItemHandler.gd`.
**Pattern:** mirrors §1 ICD / §2 CST. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)

- **`TileActions` already reserves the verbs.** `ACTION_LABELS` includes `"activate"`,
  `"visit"`, `"shop"`; `is_available()` returns `false` for them with a comment "wired into
  real gates as those systems land." Doors/chests are exactly this: new `is_available`
  cases + a gate. The HUD More-Info row and the ActionMenu both read `TileActions`, so one
  wiring point feeds both.
- **`ItemData.item_type` already includes `"key"`.** Key items are a declared type with
  zero consumers today. Door/chest unlock-by-key has its data hook ready.
- **No map object model.** `MapData` has terrain (string grid), `player_start_tiles`,
  `enemy_placements`, conditions — but **no concept of an interactive object** (a door at a
  tile, a chest with loot). This is the main new data structure.
- **No Pick/Unlock skill or staff.** No `SkillData`/`WeaponData` for lockpicking exists.
- **`MapData` save-TODO** (top of file) already warns that runtime terrain mutation isn't
  snapshotted — an opened door (passable now, blocked before) is exactly that case.
- **Reward/loot precedent:** `MapData.reward_items` (map-completion items) shows the loot
  → roster/convoy flow exists at map end; chest loot is the *mid-map* analogue (and convoy
  is deferred to §2b/D — see [DCH-5]).

## 2. Draft plan (classic FE convention)

Classic FE door/chest convention:
- **Doors** block movement; opened by a **Door Key** (consumed), an **Unlock staff** (Thief
  staff, no key), or a **Thief's lockpick skill** (innate, no item). Once open, the tile is
  permanently passable.
- **Chests** sit on a tile; opened by a **Chest Key** or a Thief's skill, yielding an item
  (sometimes gold). Thieves can open without keys; everyone else needs the matching key.
- **Thief race:** on many maps, *enemy* thieves loot chests and flee — a classic tension.
  (Depends on AI interaction — see [DCH-4].)
- **Action verb:** standing adjacent to (door) or on (chest) the object surfaces an
  **Unlock / Open** action; the existing `"activate"` placeholder is the natural home.

Core new data: `MapData.map_objects: Array[Dictionary]` — each `{ type:"door"|"chest",
tile:Vector2i, key_item_id:String, loot:... , locked:bool }`. Opened-state is per-map
runtime → snapshot.

## 3. Open questions register

### [DCH-1] Open method: key item vs lockpick skill vs unlock staff — which ship first?  **[OPEN]**
- **A — Key items only** (Door Key / Chest Key consume from inventory). Reuses the
  existing `item_type "key"`; no new skill/weapon system. Smallest.
- **B — Key items + Thief lockpick skill** (an innate `SkillData` letting a class open
  without keys). Needs a new skill effect + class wiring.
- **C — A + B + Unlock staff** (a `WeaponData` staff that opens at range).
- **Rec: A first, design B/C as fast-follows** — keys are fully data-ready (`item_type
  "key"` exists), require no new system, and deliver the loop end-to-end. Lockpick skill and
  unlock staff are additive once the object model + action gate exist. Note B as the
  Thief-fantasy follow-up.
- **Resolution:** **A (RESOLVED 2026-06-21g)** — keys first (reuse `item_type "key"`, zero new
  systems, full loop end-to-end). Thief lockpick skill ([DCH-1]→B) and unlock staff (→C) are
  fast-follows once the object model + action gate exist.

### [DCH-2] Map-object data model — new field vs extend placements  **[OPEN]**
- **A — New `MapData.map_objects: Array[Dictionary]`** (doors/chests/future levers).
  Parallel to `enemy_placements`; validated in `DataManager` like the other dicts.
- **B — Encode doors as a terrain code** (`"L"` for locked) in the string grid + a separate
  chest list. Doors-as-terrain reuses the grid + move-cost machinery (a locked door = an
  impassable tile that becomes passable).
- **Rec: B for doors, A for chests** — a door IS a terrain state (passable/not), so a
  terrain code that flips `impassable → passable` on open reuses `get_move_cost`/`is_passable`
  with no new movement code; the door's key requirement rides a small side-table. Chests
  carry loot (not a movement property) so they want the object list. *Or* unify under A if
  the team prefers one model — flagged as the real fork.
- **Resolution:** **B — UNIFY (RESOLVED 2026-06-21g; owner override of the split rec)** — ONE
  `MapData.map_objects: Array[Dictionary]` holds doors, chests, levers, and (later) stationary
  weapons. **Consequence to build:** doors are no longer terrain codes, so a **runtime
  passability overlay derived from `map_objects` state** is required — the pathfinder /
  `GridManager` movement-cost layer treats a closed-or-locked door tile as blocked, and re-opens
  it when the door's `open`/`locked` flag flips. **Upside bought:** the authored terrain `grid`
  stays immutable (the `MapData` save-TODO is resolved via `map_objects_state`, NOT terrain
  mutation), and STW inherits this single model. **Cost accepted:** bespoke door-passability
  code instead of reusing `get_move_cost`/`is_passable` for free. This is slice 1's main work.

### [DCH-3] Chest loot source: authored item vs loot table vs convoy-bound  **[OPEN]**
- **A — Authored fixed item per chest** (`loot_item_id` on the object). Deterministic,
  simplest, FE-classic (chests have known contents).
- **B — RNG loot table** — but this needs `RngService` (Package A) to be deterministic
  under rewind, and FE chests are usually fixed anyway.
- **Rec: A** — FE chests are authored, not random; fixed loot needs no RNG dependency and is
  trivially deterministic for suspend/rewind. (A random chest would be a Package-A consumer
  — out of scope here.) Gold-instead-of-item is just a `loot_gold:int` variant.
- **Resolution:** **A (RESOLVED 2026-06-21g)** — authored fixed `loot_item_id` (or `loot_gold`)
  per chest. FE-classic, deterministic, no RNG/Package-A dependency, trivially correct under
  suspend/rewind. A random-chest variant would be a Package-A consumer — out of scope here.

### [DCH-4] AI interaction: do enemies open doors / loot chests?  **[OPEN]**
- **A — No AI interaction v1.** Doors/chests are player-only; enemies ignore them. Smallest;
  no `EnemyAI` change.
- **B — Enemy thieves loot chests + flee** (the classic FE race). Needs a new AI behavior
  (path to chest → open → escape) — overlaps the AI-profiles register (a "looter" profile).
- **Rec: A v1** — the chest-race is a great feature but it's a whole AI behavior; ship
  player-facing doors/chests first, then add a looter profile as a cross-item follow-up
  (cross-ref `ai_profiles_open_questions`). Enemy-locked doors that only *block* the player
  still work under A (no AI needed to open them).
- **Resolution:** **A v1 (RESOLVED 2026-06-21g)** — player-only doors/chests; enemies ignore
  them (enemy-locked doors still block the player without any AI). The enemy-thief chest-race
  lands later as a **looter AI profile** that converges in the AIP register (cross-ref
  `ai_profiles_open_questions_2026-06-21.md`), not in this cluster.

### [DCH-5] Loot destination — convoy is deferred (§2b/D)  **[OPEN]**
Opened-chest items need somewhere to go; the convoy/party-items system is deferred to §2b.
- **A — Loot goes to the opener's inventory** (must have a free slot; classic FE — and
  blocks if full). No convoy dependency.
- **B — Loot goes to party convoy** — but convoy doesn't exist yet (§2b/D).
- **Rec: A** — direct-to-opener works today with zero convoy dependency and matches FE
  (you pick it up, inventory-full warns). When convoy lands (§2b/D), add "send to convoy"
  as an option. This keeps doors/chests un-blocked by the deferred economy cluster.
- **Resolution:** **A (RESOLVED 2026-06-21g)** — loot goes to the opener's inventory; full
  inventory warns/blocks (classic FE). Zero convoy dependency. When convoy lands (§2b/D), add
  "send to convoy" as an option then.

### [DCH-6] Opened-state persistence (snapshot/§2)  **[OPEN]**
An opened door (now passable) / looted chest (now empty) is mutable per-map state; the
`MapData` save-TODO names exactly this.
- **A — Snapshot the opened/looted object states** (per-object `opened:bool`) in the map
  snapshot; reserve in §2 schema.
- **B — Re-derive from inventory** (can't — looting is a one-way event).
- **Rec: A** — opened/looted is a latched event, not derivable. Reserve a `map_objects_state`
  array in the §2 schema; this register's only §2 ask. (Also resolves the `MapData` terrain
  save-TODO for the door-as-terrain case from [DCH-2].)
- **Resolution:** **A (RESOLVED 2026-06-21g)** — snapshot per-object opened/looted state;
  reserve a `map_objects_state` array in the §2 save schema (this register's only §2 ask).
  Looting/opening is a latched one-way event, not re-derivable. **Note (post-[DCH-2] unify):**
  with doors in `map_objects` (not terrain), `map_objects_state` is the SINGLE home for both
  door open-state and chest looted-state — and it fully resolves the `MapData` runtime-terrain
  save-TODO, since the authored `grid` is never mutated.

## 4. Slice sketch (RESOLVED 2026-06-21g)
1. **Unified `map_objects` model + passability overlay** ([DCH-2]→B unify): add
   `MapData.map_objects: Array[Dictionary]` (`{type, tile, key_item_id, loot_item_id/loot_gold,
   locked, open}`) + `DataManager` validation; build the **runtime door-passability overlay** so
   `GridManager` movement/pathfinding treats a closed-or-locked door tile as blocked (authored
   `grid` stays immutable). Test map with one door + one chest.
2. `TileActions` wires `"activate"` (Open/Unlock) with the key-in-inventory gate ([DCH-1]→A,
   keys first). Door adjacent / chest on-tile surfaces the action; keyless unit sees none.
3. Door open → flip its `map_objects` state (overlay re-opens the tile); chest open → fixed loot
   ([DCH-3]→A) to the opener's inventory, full-inventory warns ([DCH-5]→A).
4. Snapshot opened/looted via the `map_objects_state` array ([DCH-6]→A; reserve in §2 schema);
   extend `test_snapshot_coverage`.
5. (Fast-follows) Thief lockpick skill ([DCH-1]→B) + unlock staff (→C); enemy looter profile
   ([DCH-4]→B) lands in the AIP register, not here.

## 5. Test notes
- Headless: a unit with a Door Key adjacent to a locked door sees the Open action; opening
  flips the tile passable; key is consumed. A keyless unit sees no action.
- Chest: opening transfers loot to inventory (or warns if full); chest marked looted.
- Snapshot round-trip restores opened/looted state.
