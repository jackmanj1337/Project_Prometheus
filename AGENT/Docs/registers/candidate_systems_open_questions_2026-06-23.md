---
Type: register
Status: OPEN
Last verified: 2026-06-24
Register: CEX-1..19
---

# Candidate Systems — Player-Interaction Open Questions

**Started:** 2026-06-23 (session 2026-06-23l)
**Status:** OPEN (cluster **A resolved 2026-06-23l** → firms foundation **F7**; cluster **C resolved
2026-06-24b** → flexible weapon triangle, rides F4; cluster **D resolved 2026-06-24c** → per-map-use
items; cluster **E resolved 2026-06-24d** → story/key items (tracking + locks now; event-mutation
rides the MET build, persistent branching-state rides the F6 build); **B (learned spells) is the
last open cluster**). The
player-interaction question list for the five candidate systems drafted in
`design/candidate_systems_2026-06-23.md`. Each question is framed
**player interaction → designer authoring → structural impact**, so answers define both how
players use a system and how campaign designers configure it (and what that costs structurally).
**Firming order = the pending priority re-evaluation** — these are exploratory, not scheduled.
**Pattern:** mirrors `[IEQ]`/`[PXP]`. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

> Grouped by system (A–E). A "lean" is a non-binding starting recommendation, not a resolution.

---

## A. Shared resource pools — **RESOLVED 2026-06-23l (firms foundation F7)**

### [CEX-1] Player spend surface  **[RESOLVED]**
Pool bar on the **unit sheet + combat/action preview**; the **cost is shown before the player
commits** a cast/attack/skill; an empty pool **greys out** that capability. **Structural:** a pool
readout in the combat-preview pipeline.

### [CEX-2] Refill model — **RESOLVED: author-controlled refill modes**  **[RESOLVED]**
v1 ships **per-map reset**, but the end-shape is an **author-selected refill mode** (a `CampaignRules`
refill profile, F4): e.g. per-map reset **vs** "**persist until the author refills**" (for climactic
**back-to-back battles** that drain resources). Plus two restoration avenues, both reusing existing
machinery:
- **Pool-restoration items** — a "mana vulnerary": a `consumable_component` effect_id `restore_pool`
  (`{pool, amount}`), mirroring `heal_flat` for HP.
- **Regen skills** — a skill effect that restores pool over time (mirrors Renewal for HP).

### [CEX-3] What may a pool gate — **RESOLVED: weapon/spell use AND skills**  **[RESOLVED]**
Pools gate **attacking/casting costs and skill activation** in v1 (a stamina-gated combat art is a
first-class case). Movement stays free in v1 (later growth). **Structural:** cost hooks at the use
site + at `SkillHandler` activation.

### [CEX-4] Authoring home — **RESOLVED: CampaignRules types + class/unit maxes**  **[RESOLVED]**
Pool **types** = a `CampaignRules` profile (the **F4** mechanism); a unit's **max** comes from
**class** (per-unit override later); a component/skill declares its `{pool, amount}` cost; **an item
or skill may cost from multiple pools**.

## B. Learned spell system

### [CEX-5] Cast interaction — spell menu vs folded into weapon select?  **[OPEN]**
Dedicated **Cast** action + spell list, or known-spells appear alongside weapons in the swap menu?
*Lean:* a Cast action keeps spells (no-inventory) distinct from carried weapons. **Structural:**
touches `get_equipped_weapon` vs a new action path. **Resolution:** _[OPEN]_

### [CEX-6] Charge model — per-map uses, pool cost, or author's choice per spell?  **[OPEN]**
*Lean:* support both, author picks per spell (per-map reuses `skill_use_counters`; pool = system A).
**Structural:** per-spell charge state in the save. **Resolution:** _[OPEN]_

### [CEX-7] Learning surfaces in v1 + can spells be forgotten/swapped?  **[OPEN]**
Which of class-level / proficiency-threshold / item / training-hall ship first, and is there a
**loadout cap** (forget/swap) or is the known list ever-growing? *Lean:* class-level + PXP-threshold
v1; ever-growing list v1, loadout cap later. **Designer:** the learning hooks already exist
(`skill_unlocks`, `[PXP-4]`, `learn_spell`, `[PXP-9]`). **Resolution:** _[OPEN]_

### [CEX-8] Coexistence with tome-weapons — spells replace inventory tomes, or both?  **[OPEN]**
Today magic = tome **weapons** in inventory. Do learned spells **coexist** with tomes or **replace**
them? *Lean:* coexist v1 (a campaign chooses its idiom); don't force-migrate tomes. **Structural:**
the biggest reconciliation fork for B. **Resolution:** _[OPEN]_

## C. Author-flexible weapon triangle — **RESOLVED 2026-06-24b (rides F4; conditions slice after F5)**

**Resolved model (2026-06-24b).** Lift the triangle into a **`CampaignRules` `triangle` profile**
(the F4 author-profile mechanism). The profile carries:
- **`families`** — author-extensible family list (default = current `VALID_COMBAT_FAMILIES`; becomes
  the DataManager validation source for `triangle_family`). A family with **no matrix row = always
  neutral** (bows/knives/staves keep "no triangle interaction").
- **`matrix`** — an **arbitrary directed graph** `atk_family → { def_family → "advantage" |
  "disadvantage" }` — exactly today's `WEAPON_TRIANGLE` shape (`dark` already beats all three anima).
  "Multiple triangles" = **disjoint subgraphs in one matrix** (no separate concept needed).
- **`effects`** — **arbitrary stat-mod sets** for `advantage`/`disadvantage` (`{hit, atk, avo, crit,
  …}`), applied via the existing triangle/modifier path (no new engine). **May be flat OR a per-rank
  table** keyed by the wielder's **trained WEXP rank in the equipped weapon's track** (GDD_04).
- **`reaver_multiplier`** — magnitude multiplier when a reaver is involved (CEX-17; default 2).

**Default profile = current flat ±10 Hit / ±2 Atk (non-breaking).** A built-in **`rank_scaled`**
profile reproduces the **GDD_04 SET-003/RULE-013** table, opt-in per campaign.

### [CEX-9] Player readout — how is a custom hierarchy + its effects shown?  **[RESOLVED]**
**RESOLVED:** the combat preview shows the **net triangle stat deltas** + an
**advantage / disadvantage / reversed** indicator; more-info shows the matchup row. **Data-driven
over the `effects` set**, so custom (non-Hit/Atk) stats render generically. No fixed "3 families" UI.

### [CEX-10] Effect vocabulary — what may an advantage/disadvantage apply?  **[RESOLVED]**
**RESOLVED: arbitrary stat-mods v1** (any combination from the modifier model — Hit/Atk/Avo/Crit/…),
reusing the existing modifier/triangle application. **Condition application is deferred to the F5
(`ConditionManager`) build**; it rides the same `effects` slot when F5 lands.

### [CEX-11] Hierarchy shape — strict cycle vs arbitrary directed graph?  **[RESOLVED]**
**RESOLVED: arbitrary directed matrix** (already the storage shape). Disjoint groups in the matrix =
separate triangles; an empty row = neutral participation. Same storage, fully author-defined.

### [CEX-12] Authoring + scaling — profile home + rank-scaled magnitude?  **[RESOLVED]**
**RESOLVED:** the `triangle` profile lives in `CampaignRules` (F4). **Default = flat (non-breaking);
the GDD_04 rank-scaled table ships as an opt-in built-in `rank_scaled` profile.** Magnitude (when
rank-scaled) is driven by the **equipped weapon's trained WEXP rank** — `triangle_family` only sets
the relationship (no second hidden magic rank, per GDD_04).

### [CEX-17] Reaver-style triangle reversal (Swordreaver etc.)  **[RESOLVED]**
**RESOLVED:** a per-weapon **`reverses_triangle: bool`** (on the `weapon_component`, `[IEQ]`). In a
matchup let **R** = the number of the two combatants' equipped weapons with `reverses_triangle` (0–2):
- **R odd (1)** → **invert** the triangle result (advantage↔disadvantage; neutral stays neutral)
  **and** multiply the magnitude by **`reaver_multiplier`** (profile, default 2) — the FE
  "reverse + double" staple.
- **R even (0 or 2)** → normal result, normal magnitude (two reavers cancel, GBA-style).
A reaver only matters where a relationship already exists (it cannot create advantage out of a
neutral matchup). **Structural:** one bool on `weapon_component` + the parity branch in the existing
`_get_triangle_result`/magnitude path; `reaver_multiplier` authorable on the profile.

## D. Per-map-use items — **RESOLVED 2026-06-24c (pure recharge; reuses the per-map counter pattern)**

### [CEX-13] Player distinction + structure — recharging vs consumed?  **[RESOLVED]**
**RESOLVED — pure recharge.** `ConsumableComponent.uses_per_map: int` (-1 = not per-map). When set:
the item is **never consumed** (`InventoryEntry.uses_remaining` stays **-1**) and a per-instance
**`InventoryEntry.map_uses_remaining`** counter — refilled to `uses_per_map` by `reset_map_state` at
map start, mirroring `skill_use_counters` — gates each use. Per-**instance** (two trinkets track
independently). **No finite total cap** in v1 (permanent recharging item).
**Player readout:** a **distinct "N/max ⟳" badge** + a "resets each map" tooltip in inventory + the
action menu; consumed items show `×N`. **Future (out of v1):** per-N-turns / charge-on-rest intervals.
**Save (F1):** `map_uses_remaining` is per-map runtime — reserve only if a mid-map save persists
runtime (same caveat as pool state). **Owners at build:** `[IEQ]` `ConsumableComponent` + `ItemHandler`
(skip `consume_entry` when `uses_per_map` set; decrement the map counter instead).

## E. Story / plot-relevant item tracking — **RESOLVED 2026-06-24d (tracking + locks now; mutation→MET, branching-state→F6)**

**Terminology.** `ItemDef.story: bool` is the flag (base-level, orthogonal to weapon/consumable/
accessory components — a story item can be any of them); the **player-facing label is "Key Item."**
"Story item" / "key item" are used interchangeably below.

### [CEX-14] Player visibility & lock — how do story items appear/behave?  **[RESOLVED]**
**RESOLVED — author-configurable locks.** `ItemDef` gains `story: bool` plus independent
**`no_sell` / `no_drop` / `no_trade`** booleans. When `story = true` the **defaults** are
`no_sell = true`, `no_drop = true`, `no_trade = false` (cannot be lost, but can be handed within the
party; an author sets `no_trade = true` to **bind** a relic to its holder). The **More Info page
auto-generates** a plain-language line describing the active locks (e.g. "Key Item — cannot be sold
or dropped"). Inventory shows a **distinct inline tag**. (Replaces the old `item_type=="key"`/
`"sellable"` enum, which dissolves with `[IEQ]`.)

### [CEX-15] Story hooks — presence-as-flag + branching  **[RESOLVED]**
**RESOLVED.** **Holding an item is itself a player-visible story flag.** "Unit/party holds item X" is
a **`[MET]` trigger predicate** read **live from inventory** (roster + convoy) — **needs no F6 store**
— usable to gate side-quest events and **recruitment conversations**. *Persistent* story STATE
(quest stages, "spoke to NPC") still rides the **F6 flag store**, so those branches land **with the
F6 build**; the holds-predicate ships independently with the `[MET]` work.

### [CEX-16] Tracking tool + convoy integration  **[RESOLVED]**
**RESOLVED.** (a) **Convoy "Key Items" view** — a dedicated sub-view; **key items are exempt from
`convoy_capacity`** (reconcile `[CNV]` — they never count against the limit and can't be lost).
(b) **Designer / GUI-editor tracking** — a key-items registry/panel listing each story item + its
**current holder** across roster/convoy (a **derived scan**, no new storage). (c) Player surface =
the inline tag + auto More-Info explanation (CEX-14).

### [CEX-18] Story-event item mutation — relic upgraded / weakened / stolen / destroyed  **[RESOLVED]**
**RESOLVED (design; rides the `[MET]` build).** New `[MET]` event **actions that target a specific
item**: **upgrade / weaken** (modify the item — reuses the `forged_mods` overlay on `weapon_component`,
and overlaps `[PXP]` **item-bond** for relics that grow with use), **steal/transfer** (move the entry
to another unit/faction), **destroy** (remove the entry). These extend the `[MET]` action vocabulary
and land with the MET/F6 build; the item model just needs to be mutable by id+holder (it is).

### [CEX-19] Authoring validation — key item that can be permanently lost  **[RESOLVED]**
**RESOLVED (build-time check).** Marking an item `story`/key must **warn** (GUI editor + a
`DataManager.validate()` warning at load) when it has **finite uses** (a `weapon_component`/
`consumable_component` that can break/exhaust) **AND no defined repair path** (Hammerne-class staff /
shop repair / forge) — i.e. it could become **permanently lost**, breaking the plot. The warning
lands **with the item-model build** (the .tres data doesn't exist yet), not as a docs check.

## Notes
- **Cross-cutting dependencies** (design doc §Cross-cutting): `ConditionManager` (stub) is wanted by
  C + the poison/immunity gaps — trending foundational; resource pools (A) underpin spells (B); a
  campaign-flag/story-state store is the missing piece behind E's branching.
- **DoD:** any system that graduates from exploration gets its own register split + GDD owner updates
  with the build, not now.
