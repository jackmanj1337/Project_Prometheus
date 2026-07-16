# GDD_04 — Weapons & Items

**Status:** Active contract — split status per section (project weapon/item data is
**Implemented**; corpus weapon/item/triangle/WEXP adoption is **Target design**, tracked
in `GDD_Adoption_Matrix.md`).
**Last verified:** 2026-07-15
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This chapter owns weapon-family definitions, per-weapon/per-item data, the **rank-scaled
triangle bonus table**, WEXP thresholds/caps/gain/migration detail, effectiveness data,
and the item economy (selling, forging, inventory). The **combat application** of these
rules — how triangle, WEXP, durability, and effectiveness feed the exchange — is owned by
`GDD_02`. Resource/serialization schemas (`InventoryEntry`, `WeaponData`, `ItemData`) are
owned by `GDD_01`. Class WEXP baselines/caps live in `GDD_03`.

---

## Weapon System Overview

Status: **Implemented**
Last verified: 2026-07-15

### Summary
Weapons are `WeaponData` resources in `data/weapons/`; units carry weapons and items
together in one inventory.

### Specs
- `UnitData.inventory` is an `Array[InventoryEntry]`; each entry's `entry_type` is
  `"weapon"`, `"item"`, or `"equip"`. Any slot can hold either a weapon or an item
  (full `InventoryEntry` definition → GDD_01).
- `Unit.get_equipped_weapon()` filters for `is_weapon()` entries and returns the first
  one the unit can use. Items are accessed separately via the Item action.
- A unit can equip any inventory entry that: (1) is a weapon entry (`is_weapon()`),
  (2) matches one of the unit's proficiency tracks, (3) is at/below the unit's current
  rank for that track, (4) still has uses (`has_uses()`, `uses_remaining != 0`).

### Anchors
- Code: `scripts/resources/WeaponData.gd`, `scripts/units/Unit.gd`
- Schema owner: GDD_01 (`InventoryEntry` / `WeaponData` fields)

---

## Weapon Families & Triangle Membership

Status: **Split** — project families/relationships **Implemented**; rank-scaled corpus bonuses **Target design** (SET-003 / RULE-013)
Last verified: 2026-06-13

### Summary
Two triangles (physical + project magic). This section owns the **family table and the
rank-scaled bonus table**; the combat-facing triangle summary lives in `GDD_02 §Weapon
Triangle`.

### Specs

**Implemented (project family contract).** The engine accepts the combat families
declared by `GameConstants.VALID_COMBAT_FAMILIES`. The authored weapon library currently
uses sword, lance, axe, bow, fire, thunder, wind, staff, and fist; light, dark,
beaststone, and dragonstone are reserved accepted families without shipped weapon data.

| Type | Triangle | Notes |
|---|---|---|
| Sword | Physical (beats Axe, loses to Lance) | |
| Lance | Physical (beats Sword, loses to Axe) | |
| Axe | Physical (beats Lance, loses to Sword) | |
| Bow | None | Minimum range 2; effective vs Flying |
| Fire tome | Anima (beats Light, loses to Dark); effective vs Beast | Uses MAG, targets RES |
| Thunder tome | Anima (beats Light, loses to Dark); effective vs Dragon | Uses MAG, targets RES |
| Wind tome | Anima (beats Light, loses to Dark); effective vs Flying | Uses MAG, targets RES |
| Light tome | Magic (beats Dark, loses to Anima) | Uses MAG, targets RES |
| Dark tome | Magic (beats Anima, loses to Light) | Uses MAG, targets RES |
| Staff | None | Targets allies (healing) or enemies (status — Phase 2) |
| Fist | None | Infinite-use 0-Mt fallback asset; class access is authored |
| Beaststone / Dragonstone | None | Accepted family vocabulary; content deferred |

- Project relationships are retained: physical **Sword → Axe → Lance**; magic
  **Dark → Anima → Light** (the project keeps the Dark/Anima/Light ordering — see SET-003).
- A type has no advantage vs itself; bows, knives, staves have no triangle interaction.
- **Hybrid weapons** (e.g. Sonic Sword, Bolt Axe) carry a magic `triangle_family` and
  their physical `combat_family` at once; use whichever gives advantage.
  `get_triangle_family()` falls back to `combat_family` when `triangle_family` is unset.

**Target design (rank-scaled triangle bonus, SET-003 / RULE-013).** Both triangles adopt
the corpus **rank-scaled** advantage table (replacing the current flat ±10 Hit / ±2 Damage
in GDD_02). The bonus magnitude is driven by the **equipped weapon's trained WEXP track**;
`triangle_family` only sets the *relationship* — there is no second hidden magic rank.

| Equipped rank | Advantage | Disadvantage |
|---|---|---|
| E / D | Hit +5 | Hit −5 |
| C | Hit +10 | Hit −10 |
| B | Hit +10, Atk +1 | Hit −10, Atk −1 |
| A | Hit +15, Atk +1 | Hit −15, Atk −1 |
| S | corpus/source-defined | corpus/source-defined |

Provenance: `GDD_Adoption_Matrix.md` → `awakening_lookup_tables.md` (Weapon Triangle
Advantage Table / Weapon Triangle Participation). Not yet implemented — current behavior
is the flat project bonus in GDD_02.

**Design firmed 2026-06-24b — author-flexible triangle (`[CEX-9..12, 17]`, rides F4; build pending).**
The family list, relationship `matrix`, magnitude `effects`, and `reaver_multiplier` move into a
**`CampaignRules` `triangle` profile** (F4). **`families`** is **author-extensible** and becomes the
validation source for `triangle_family` (replacing the fixed `VALID_COMBAT_FAMILIES`); a family with
no matrix row = neutral (bows/knives/staves unchanged). The **rank-scaled table above ships as an
opt-in built-in `rank_scaled` profile**, while the **default profile stays the current flat ±10/±2**
(non-breaking). `effects` generalize to **arbitrary stat-mods** (conditions deferred to **F5**).
**Reaver** weapons set `weapon_component.reverses_triangle` (`[IEQ]`); an **odd** count across the
two combatants inverts the result and ×`reaver_multiplier` (default 2). See `[CEX]` block C.

### Anchors
- Code: `scripts/autoloads/DataManager.gd` (`get_weapon_triangle_result`),
  `GameConstants.WEAPON_TRIANGLE`, `scripts/resources/WeaponData.gd` (`triangle_family`)
- Tests: `scripts/tests/test_data_manager.gd`
- Decisions: SET-003, RULE-013
- Owner of combat application: GDD_02 §Weapon Triangle
- Reference: `awakening_weapons_physical.md`, `awakening_weapons_magic.md`, `awakening_lookup_tables.md`; `GDD_Adoption_Matrix.md`

---

## Weapon Data & Tables

Status: **Split** — project MVP weapons **Implemented**; corpus weapon roster **Target design** (SET-009 / SET-003)
Last verified: 2026-06-13

### Summary
The authored `.tres` weapons that ship today, and the corpus weapon roster they migrate to.

### Specs

**Implemented (project MVP weapons).** Authored `.tres` in `data/weapons/` and its
`resource_manifest.json` are the source of truth. The library includes iron/steel
physical weapons, Javelin, the four elemental tomes, Heal, and Fists. Mt, Hit, Crit,
range formulas, Wt, uses, cost, WEXP, and effect tags are deliberately not transcribed
here; the engine and documentation both consume or link the authored resources.

**Target design (corpus weapon roster, SET-009).** Adopt the corpus physical + magic
weapon encyclopedia wholesale; the project magic triangle is preserved (see Triangle
Membership). Provenance: `GDD_Adoption_Matrix.md` → `awakening_weapons_physical.md`,
`awakening_weapons_magic.md`. Staves stay deterministic: heal is computed, EXP is flat
(no dice).

### Anchors
- Code/data: `data/weapons/`, `data/weapons/resource_manifest.json`
- Decisions: SET-009, SET-003
- Reference: `awakening_weapons_physical.md`, `awakening_weapons_magic.md`

---

## Weapon Proficiency (WEXP) — thresholds, gain & migration

Status: **Split** — project thresholds/gain **Implemented**; corpus thresholds/gain/migration **Target design** (SET-004 / RULE-003 / RULE-004)
Last verified: 2026-06-13

### Summary
This section owns WEXP **data**: the threshold values, caps, gain timing, and the
runtime migration rule. The combat-facing WEXP summary lives in `GDD_02 §Weapon
Proficiency`.

### Specs

**Implemented (project).**
- Per-track numeric totals on `UnitData.weapon_wexp`; rank letters derive via
  `GameConstants.WEXP_RANK_THRESHOLDS`.
- A unit equips only weapons at/below its current rank for that track.
- Class resources author baselines/caps (`ClassData.weapon_wexp_bases` /
  `weapon_wexp_caps`); promotion/reclass raise a unit to at least the new class's
  baselines for gained tracks. Gain stops at the authored cap (default A = 400 WEXP;
  explicit S-cap classes opt in).

**Target design.**
- **Thresholds/caps (SET-004):** corpus values E = 1, D = 31, C = 71, B = 121, A = 181,
  S = 251, Cap = 400 as the built-in corpus preset.
- **Gain timing (RULE-004):** per **valid use** (corpus-style), with weapon-defined
  exceptions; may change in a balance pass.
- **Migration (RULE-003):** proportional within the current rank band. There is no
  persistent WEXP save to migrate, so this governs **runtime/in-session** conversion when
  thresholds change.

### Known gaps
- Class WEXP cap ownership: explicit S caps are authored per class in GDD_03; this
  chapter owns only the threshold/derivation math.

### Anchors
- Code: `scripts/autoloads/DataManager.gd`, `GameConstants` (`WEXP_RANK_THRESHOLDS`)
- Decisions: SET-004, RULE-003, RULE-004
- Owner of combat application: GDD_02 §Weapon Proficiency; class caps: GDD_03
- Reference: `awakening_lookup_tables.md` (Numeric WEXP Thresholds / WEXP Gain Rule Table); `GDD_Adoption_Matrix.md`

---

## S-Rank Weapon Bonus

Status: **Split** — project bonus **Implemented**; move-to-engine + retire `s_rank_mastery` **Target design** (SET-005 / RULE-002)
Last verified: 2026-06-13

### Summary
At S rank in a weapon track, the wielder gains a combat bonus with that weapon type.

### Specs
- **Bonus (project extension):** +10 Hit, +5 Crit, +1 Damage with that weapon type.
- Applied as a **combat-time modifier** when computing derived values, never a permanent
  stat change — slots at the `S-rank bonus` step of the modifier pipeline (GDD_02).

**Target design (SET-005 / RULE-002).** Compute the S-rank bonus inside the **combat
engine** and **retire `s_rank_mastery`** as a pseudo/equipped skill. The +10/+5/+1
magnitude is the project variation on the corpus rank-bonus table.

The project extension is a built-in rank-bonus preset. The combat engine should read the
selected bonus profile rather than hardcoding the numbers once CampaignRules profiles
are built.

### Anchors
- Code: `scripts/core/CombatResolver.gd`, `scripts/shared/StatBreakdown.gd`
- Decisions: SET-005, RULE-002
- Owner of pipeline order: GDD_02 §Combat Modifier Pipeline Order
- Reference: `awakening_lookup_tables.md` (Weapon Rank Bonus table)

---

## Effectiveness Mechanic

Status: **Implemented** (3× multiplier; corpus matrix **Target design**)
Last verified: 2026-06-13

### Summary
A weapon's `effective_*` tag triples its Mt against a defender carrying the matching
vulnerability group.

### Specs
When a weapon has an `effective_*` tag matching a defending unit's
`ClassData.vulnerability_groups`, the weapon's Mt is treated as **3× its listed value**
for damage (**4×** with the Giantkiller skill).

**Effect tags** are strings in `WeaponData.effect_tags`. **Reference them via the
`GameConstants.TAG_*` constants — never raw strings** — so a typo is a compile error.
These constants are the implemented built-in ids. Target IEQ/effectiveness work should
validate source tags and defender groups through item/component registries so new
campaign vulnerability groups are data additions where the same primitive applies.

| Tag | `GameConstants` constant | Effect |
|---|---|---|
| `effective_flying` | `TAG_EFFECTIVE_FLYING` | 3× Mt vs `flying` |
| `effective_armoured` | `TAG_EFFECTIVE_ARMOURED` | 3× Mt vs `armoured` |
| `effective_mounted` | `TAG_EFFECTIVE_MOUNTED` | 3× Mt vs `mounted` |
| `effective_dragon` | `TAG_EFFECTIVE_DRAGON` | 3× Mt vs `dragon` |
| `effective_beast` | `TAG_EFFECTIVE_BEAST` | 3× Mt vs `beast` |
| `heal_10_plus_mag` | `TAG_HEAL_PLUS_MAG` | Marks a healing staff (`is_healing_staff()`) |

**Not tags — dedicated `WeaponData` fields:** Brave (`strikes_per_attack = 2`),
tome MAG/RES (`uses_mag = true`), hybrid triangle (`triangle_family`).

### Known gaps
- **Designed, not implemented (Phase 2):** `poison`, `heal_on_hit`, `ignores_def` /
  `ignores_half_def`, `always_hits`. Each needs a `GameConstants.TAG_*` constant and a
  matching check in `CombatResolver.gd`.
- **Target design:** the corpus effectiveness matrix (source→group) is the migration
  target; provenance `GDD_Adoption_Matrix.md` → `awakening_lookup_tables.md` (Effectiveness
  Matrix).

### Anchors
- Code: `scripts/core/CombatResolver.gd`, `GameConstants` (`TAG_*`)
- Owner of vulnerability-group definitions: GDD_03 §Special Qualities
- Reference: `awakening_lookup_tables.md` (Effectiveness Matrix / Vulnerability Groups)

---

## Items & Economy

Status: **Split** — project item use **Implemented**; selling/shops/forging **Planned**;
corpus item roster **Target design**
Last verified: 2026-07-15

### Summary
Non-weapon inventory entries with single-use or equippable effects, plus the sale/forge
economy.

### Specs

**Implemented item use.** `ItemData` selects an `effect_id` plus parameters;
`ItemEffectRegistry` loads data entries that bind validation, preview, and commit
primitives, and `ItemHandler` executes the selected handler without a closed id
switch. Compatibility entries retain `heal_flat`, `heal_full`, `promote`, `reclass`,
and `stat_buff`. Authored data includes Vulnerary, Elixir, promotion/reclass items,
Strength Tonic, and the validation-only Debuff Tonic. Exact resource fields are owned
by `GDD_01`; promotion eligibility is owned by `GDD_03`.

**Planned (Phase 2) items.** Keys (Chest/Door); permanent stat boosters (+2 to a stat /
+7 max HP / Arms Scroll = advance one proficiency rank); equip items (Full Guard, Iron
Rune, Knight Ring, Wing Guard, Laguz Guard). Promotion items are owned by GDD_03; full
corpus item roster is the adoption target (provenance `awakening_items.md`).

**Selling (Planned).** The target default sale value is
`sale_value = floor(base_cost × (uses_remaining / max_uses) / 2)`; `max_uses` reads from
the matching `WeaponData.uses` / `ItemData.uses`. Equip items (uses = −1) sell for
`floor(base_cost / 2)`. No production sell action or shop UI exists yet. Gold is the
shared `GameState.party_gold` treasury, and the shared ledger supports fixed party/unit
quote, atomic commit, and recorded-delta refund operations; selling and future shop UI
have not yet been migrated as consumers.

**Victory reward observation (Implemented 2026-07-16).** Once the ledger credit
succeeds, `TurnManager` publishes a committed receipt with the gold delta, resulting
party balance, and copied item list. Map Results and Map Menu are read-only consumers.

**Forging (Planned, Phase 2).** Forge a weapon once, at purchase (staves cannot forge).
Adjustable Mt (±5/step 1), Hit (±25/step 5), Crit (±15/step 3), Wt (±5/step 1); up to 20
total modifications; per-stat increment cost 150/300/450/600/750g (max 9,000g fully
forged). Stored in the existing `InventoryEntry.forged_mods` dictionary (reserved — no
code reads it yet, M10); unforged weapons leave it empty.

The item `effect_id` and forging cost curve are authored data targets. Built-in curves
support the current corpus/project presets; alternate campaign economies should select
or author cost profiles through the resource ledger/cost resolver rather than adding
shop-specific arithmetic branches.

### Anchors
- Code: `scripts/items/ItemHandler.gd`, `scripts/registries/ItemEffectRegistry.gd`,
  `scripts/resources/ItemData.gd`, `data/registries/item_effects/`,
  `scripts/autoloads/ResourceLedger.gd`, `data/items/`
- Schema owner: GDD_01 (`ItemData`, `InventoryEntry.forged_mods`)
- Owner of combat/map reward integration: GDD_02 §Gold & Economy
- Decisions: D-D (shops as campaign prerequisite)
- Reference: `awakening_items.md`

---

## Inventory Management

Status: **Implemented** (limit not yet enforced; Trade designed-only)
Last verified: 2026-07-13

### Specs
- One inventory per unit (`UnitData.inventory`), a flat `Array[InventoryEntry]`; each
  `entry_type` is `"weapon"`, `"item"`, or `"equip"` and slots interchange.
- **Limit:** 8 slots (`CampaignRules.max_inventory`) — **NOT yet enforced** (no inventory UI).
- **Trade** is designed but not implemented; no current action moves entries between units.
- Items and weapons cannot be used during the enemy phase.
- Death snapshots the inventory into `DeathContext` before removal, then routes it
  through `DeathDisposition`. The groundwork disposition is a no-op, so classic and
  casual deaths preserve the existing inventory data unchanged; custody, drops, and
  key-item transfer remain later inventory-system work.

### Anchors
- Code: `scripts/autoloads/GameState.gd` (`max_inventory`), `scripts/resources/UnitData.gd`
- Owner of Trade action flow: GDD_02 §Actions

---

## Stationary Weapons

Status: **Planned** (Phase 2)
Last verified: 2026-06-13

### Specs
Battlefield map objects (not inventory items), usable by non-mounted units with bow
proficiency at any rank: Ballista, Iron Ballista, Killer Ballista, Onager (AoE). All are
effective vs Flying and ignore user STR. Implement as interactable tiles with a weapon
definition embedded in `MapData`.

Target implementation rides `B4-MAP-OBJECTS` and the map-object component registry.
Weapon stats, mounting requirements, ammo, and on-activate behavior are authored object
data; the named ballista/onager set is a developer preset library.

### Anchors
- Owner of MapData/authored-map schema: GDD_06

---

## Broken-Weapon Degraded Mode

Status: **Deferred** (optional rule, backlog — OPEN-5)
Last verified: 2026-06-13

### Specs
An optional rule where a weapon at 0 uses enters a **degraded mode** (stat penalty +
infinite uses while broken, repairable later) instead of being destroyed. Likely a
`CampaignRules` toggle. Current behavior (weapon destroyed at 0 uses) is owned by
`GDD_02 §Weapon Durability`.

### Anchors
- Decisions: OPEN-5
- Owner of durability behavior: GDD_02 §Weapon Durability
- Tracking: Stage 4.3 roadmap backlog
