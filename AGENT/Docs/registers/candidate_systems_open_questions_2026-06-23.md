---
Role: dated
Type: register
Status: RESOLVED
Last verified: 2026-06-25
Register: CEX-1..24
Resolved-in: 2026-06-23l / 2026-06-24b / 2026-06-24c / 2026-06-24d / 2026-06-24i / 2026-06-25
---

# Candidate Systems — Player-Interaction Open Questions

**Started:** 2026-06-23 (session 2026-06-23l)
**Status:** **RESOLVED 2026-06-24i — all five clusters closed.** Cluster **A resolved 2026-06-23l** →
firms foundation **F7**; cluster **C resolved 2026-06-24b** → flexible weapon triangle, rides F4;
cluster **D resolved 2026-06-24c** → per-map-use items; cluster **E resolved 2026-06-24d** → story/key
items (tracking + locks now; event-mutation rides the MET build, persistent branching-state rides the
F6 build); cluster **B resolved 2026-06-24i** → the **weapon-source / equip model `[CEX-20..23]`**
(F1: granted-list + `equipped_source`) with **learned spells `[CEX-5..8]`** riding on it as a thin
application (originally **expanded 2026-06-24e** with `CEX-20..23` folded in). The
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

## B. Weapon sources & learned spells — **RESOLVED 2026-06-24i (eval session; cluster B closed)**

**Eval outcome — the cluster is two layers, now separated.** The 2026-06-24e merge analysis
(code-verified: combat is source-agnostic) established that a learned spell, a natural weapon, and
unarmed fists are the *same structural thing* — a `WeaponData` not in inventory. So cluster B splits:
- **B-foundation = the general weapon-source / equip model `[CEX-20..23]`** — the substrate (one
  enumerator over two sources, an `equipped_source` reference, fallback, attack-selection). Firms the
  **F1** save schema (granted-list + `equipped_source`) and feeds combat arts (#15) and gambits (#16).
- **B-application = learned spells `[CEX-5..8]`** — a thin spell flavor riding on B-foundation; the
  four original spell Qs largely *dissolve* into the source model rather than needing bespoke machinery.

The per-item resolutions are below; **the dedicated build-time register split + GDD owner updates land
WITH the A1 build, not now** (DoD in §Notes). Resolved leans ratified, with the three eval forks
decided by the designer: **CEX-22 = auto-fallback by priority**, **CEX-23 = reserve schema / defer
the combo build**, **CEX-7 = ever-growing list v1, cap later**.

### B-application: learned spells `[CEX-5..8]`

### [CEX-5] Cast interaction — spell menu vs folded into weapon select?  **[RESOLVED]**
Dedicated **Cast** action + spell list, or known-spells appear alongside weapons in the swap menu?
**Structural:** touches `get_equipped_weapon` vs a new action path. **Resolution: fold casting into
Equip Weapon / weapon-select; NO dedicated Cast action.** Combat is source-agnostic, so the `[CEX-20]`
two-source union already drives casting — a learned spell appears in the Equip Weapon menu like any
other granted source, and Attack→target then fires it. No bespoke spell list, no Cast verb.

### [CEX-6] Charge model — per-map uses, pool cost, or author's choice per spell?  **[RESOLVED]**
**Resolution: the per-source charge-backend abstraction from `[CEX-20]`.** A source is fired via
**entry-uses XOR per-map counter XOR pool XOR infinite**, chosen by the author *per source* (it is a
per-row property on the granted list, independent of provenance). Per-map reuses `skill_use_counters`;
pool = system A (F7); entry-uses = inventory durability; infinite = natural weapons. Per-source charge
state is reserved in the save alongside the granted-list (F1).
> **Extended by `[STY-5]` (2026-06-24j).** The XOR is per-*source storage*. A full attack is a
> **source + style** combo, and the **style adds its own cost SET** (composable, not XOR) — the combo
> cost = source per-use cost **+** the style's `{backend, amount}` components. See the `[STY]` register.

### [CEX-7] Learning surfaces in v1 + can spells be forgotten/swapped?  **[RESOLVED]**
**Resolution: class-level + PXP-threshold surfaces v1; known list is EVER-GROWING in v1 (no loadout
cap).** The learning hooks already exist (`skill_unlocks`, `[PXP-4]`, `learn_spell` consumable,
`[PXP-9]`). A loadout cap is added later by **reusing `[SKL-3]`'s `requires_equip`** mechanism (a
granted source that counts against a slot cap, drawn from an earned superset); **forget/swap ships
with that cap**, not in v1. (Designer fork decided: ever-growing now, cap later.)
> **Cap pinned to A5 (2026-06-25c) — RESOLVED 2026-06-27d → `[LDC-1..7]`**
> (`registers/loadout_cap_open_questions_2026-06-27.md`): generalize the skills earned/equipped/cap
> pattern to styles + sources; **separate author-configurable per-category caps** (`max_skills` +
> `max_styles` + `max_sources`); reuse `[SKL-3]` `requires_equip` (slot-bound vs passive); **swap freely
> in prep, earned superset never lost**, permanent `forget` optional + author-gated; a `[PHB]` prep panel.

### [CEX-8] Coexistence with tome-weapons — spells replace inventory tomes, or both?  **[RESOLVED]**
**Resolution: dissolved.** A tome and a learned spell are the **same** `ItemDef{WeaponComponent}`; the
only difference is the *reference path* — an inventory entry vs a granted-list row (`[CEX-20]`). So
coexistence is **free** and no force-migration is needed: a campaign picks its idiom (inventory tomes,
learned spells, or both) with zero reconciliation cost. The "biggest fork for B" evaporates under the
source-agnostic model.

---

### B-foundation: the general weapon-source / equip model `[CEX-20..23]`

> Merge analysis from session 2026-06-24e (below), **ratified at the 2026-06-24i eval**. This is the
> substrate the spell Qs above ride on. `CEX-20..23` are now **[RESOLVED]**; the analysis text is
> retained for the rationale.

**Combat is source-agnostic (code-verified).** Every computation in `CombatResolver`
(`compute_hit_pct` / `compute_damage` / `compute_crit_pct` / triangle / effectiveness /
`can_counterattack`) consumes a **`WeaponData`** obtained from `get_equipped_weapon()`; it never reads
inventory. So a **learned spell, a Laguz natural weapon, and unarmed fists are the same structural
thing** — a `WeaponData` *not* in inventory whose charge state is *not* an `InventoryEntry`. The whole
seam is **two `Unit.gd` functions** (`_find_equipped_weapon`, `get_equippable_weapons`) that today
iterate only `data.inventory`.

**Merge direction (hybrid — chosen as the working lean, non-binding until eval).** A spell's
*capability* = an `[IEQ]` `ItemDef{WeaponComponent}` (a tome minus the inventory slot); its
*known/equip/learn lifecycle* reuses the **skill** model. No bespoke `known_spells` field, no separate
Cast action. This **revises the leans** above:
- **`[CEX-5]`** → fold casting into **Equip Weapon / weapon-select**; no dedicated Cast action
  (combat is source-agnostic, so weapon-select already drives it).
- **`[CEX-6]`** → a **charge-source abstraction**: a source is fired via *entry-uses* **XOR**
  *per-map counter / pool* **XOR** *infinite* (natural). Author picks per source.
- **`[CEX-7]`** → reuse **`[SKL-3]`** `earned`/equipped subset + `requires_equip` loadout cap +
  existing learning hooks (`skill_unlocks`, `[PXP-4]`, learn consumable, `[PXP-9]`).
- **`[CEX-8]`** → **largely dissolved**: a tome and a spell are the *same* `ItemDef{WeaponComponent}`;
  the only difference is the reference path (inventory vs known-list), so "coexist" is free.

**Demo asset landed (2026-06-24e).** `data/weapons/fists.tres` — **0 Mt**, **∞ uses** (`-1`), neutral
in the triangle, `is_natural_weapon = true`; new **`fist`** combat family + WEXP track in
`GameConstants`. Validates clean (`DataManager`). Designers choose **default-for-all** vs
**martial-artist class** via `ClassData.allowed_weapon_families` (no engine change to demo it through
inventory). Covered by `test_data_manager`.

**Equip reality (code-verified).** The weapon-swap path is **fully built and wired** — `ActionMenu`
"Equip" → `MapCursor._open_weapon_menu()` → `WeaponMenu` (instantiated in `GameMap.tscn`) →
`weapon_chosen` → `set_equipped_weapon()` — but it has **never surfaced in playtesting**: the Equip
button needs **≥2 equippable weapons** (`has_weapon_swap = get_equippable_weapons().size() >= 2`,
`ActionMenu.gd`) and **every roster unit ships exactly one weapon**. `WeaponMenu` has **no test**; only
the button-visibility toggle is covered (`test_action_menu`).

### [CEX-20] Two-source weapon enumeration (inventory + granted)  **[RESOLVED]**
Generalize `get_equippable_weapons()` / `_find_equipped_weapon()` to return the **union** of just
**two** sources — **not three**. (Discussion 2026-06-24e settled this: "source" only buys storage +
lifecycle; combat consumes a `WeaponData` regardless. The only real behavioral fork is **physical
object vs reference**.)
- **Inventory** — physical items: occupy a slot, trade/drop, durability via `entry.uses`.
- **Granted list** — every **non-inventory** `WeaponData` reference (spells, natural weapons,
  accessory-conferred attacks, event grants). Each row carries a **provenance tag** —
  `learned | class_innate | accessory | event` — **reusing the `[SKL]` pattern** (`[SKL-3]`
  `retain_on_reclass` already models "class-innate vs earned"); this is **metadata, not a third
  enumeration path**. Each row also carries its **charge backend** (entry-uses / counter / pool /
  infinite) as an *independent* per-row property — e.g. a natural weapon is `class_innate` + infinite,
  a learned spell is `learned` + counter/pool. **Do not conflate provenance with charge backend.**
Class-innate is **not stored** — it is **recomputed from the class at runtime** (like class-active
skills aggregate without being saved), so it contributes *into* the granted list rather than being a
separate stored source. This single union delivers spells, wires up the dangling
`is_natural_weapon`/`natural_weapon_type`, and gives monster/boss innate attacks the same path.
**Resolution: ratified — one enumerator over two sources, provenance + charge-backend tagged per row.**
`get_equippable_weapons()` / `_find_equipped_weapon()` return the **union** of inventory + granted-list.
`class_innate` granted rows are **recomputed from the class at runtime** (not saved), contributing into
the union. This single union delivers spells, wires up the dangling `is_natural_weapon` /
`natural_weapon_type`, and gives monster/boss innate attacks the same path. **Provenance ≠ charge
backend** (two independent per-row properties).

### [CEX-21] Equipped source as a reference + action-menu vocabulary  **[RESOLVED]**
Today "equipped" = the first usable inventory entry, and `set_equipped_weapon` **reorders
`data.inventory`** — so it **cannot select** a spell or natural source (there is no entry to reorder).
Design: a single **`equipped_source` reference** that `get_equipped_weapon()` resolves; with the
two-source model (`[CEX-20]`) it distinguishes only **two** cases — **inventory-entry id** vs
**granted-list id** (the granted row's provenance tag is read from the row, not encoded in the
reference). Reserve it in the **F1** save schema (inventory + granted-list are the saved structures;
class-innate granted rows are recomputed, not saved). Action-menu vocabulary:
**Attack** (initiator, unchanged) · **Equip Weapon** (today's `WeaponMenu`, fed by `[CEX-20]`'s union;
visibility keys off **union** size, not inventory size) · **Inventory** (use consumables now +
accessory-equip later — likely **prep-only**, a scope flag). Keep **Attack** distinct from **Equip
Weapon** so re-targeting never forces re-selection. **Resolution: ratified.** A single
**`equipped_source` reference** that `get_equipped_weapon()` resolves, distinguishing two cases —
**inventory-entry id** vs **granted-list id** (provenance read from the row, not the reference).
**Reserve `equipped_source` + the granted-list (with per-source charge state) in the F1 save schema**
(class-innate rows recomputed, not saved). **`set_equipped_weapon` must stop reordering
`data.inventory`** — it sets the `equipped_source` reference instead, so it can select a non-inventory
source. Menu vocabulary as above.

### [CEX-22] Equipped attack method becomes unavailable on another player's turn  **[RESOLVED]**
If a unit's equipped source becomes unusable **between its own turns** — weapon broke, spell out of
charges, pool drained, or source revoked by a `[MET]` event — what happens when the unit is attacked
and would **counterattack** on the enemy phase (or in any forced/reactive attack outside its owner's
turn)? Options: auto-fallback to another usable source (by what priority?), fall back to a universal
unarmed/fists if one exists, or counter with **nothing**. Touches `can_counterattack` (which reads
`get_equipped_weapon()`). **Resolution: auto-fallback by priority** (designer fork). When
`get_equipped_weapon()` resolves and the referenced `equipped_source` is unusable (broke / out of
charges / pool drained / `[MET]`-revoked), the engine **auto-re-resolves `equipped_source` to the
highest-priority *usable* source and persists the swap** (FE-style auto-equip-next, covering both the
enemy-phase counter and the unit's next own turn). **Priority order:** among sources usable *right now*
(durability / charges / pool satisfied) → inventory slot order, then granted-list order; a **universal
infinite source (fists, if the campaign defines one) is the guaranteed floor**. If nothing is usable
AND no universal floor exists → **counter with nothing**. `can_counterattack` then evaluates range as
today against the resolved source.
>
> **REVISITED & REFINED 2026-06-25 (marker cleared).** Re-validated against the finished `[STY]` model.
> Two findings reshaped it: (a) **styles never fire on counters** (they are per-attack + `player_activated`,
> `[STY-2]`/`[STY-8]`) — a counter is always `equipped_source` + null style, so the fallback only needs a
> usable **source**, not a style; (b) the flat "inventory-slot → granted" order is replaced by a
> **player-driven order + equip history**. The refined model (designer call):
> - **Persistent auto-equip stays** (FE-style: the swap sticks for both the counter and the next own turn).
> - **Fallback order = a player-orderable source priority**, falling *through* sources that are listed
>   but currently unavailable (greyed, not removed). Default ordering = **most-recently-equipped still-
>   usable source** (an **equip history / MRU** per unit); the player's explicit ordering overrides MRU;
>   a universal infinite **fists** floor is last; nothing usable + no floor → **counter with nothing**.
> - **Not range-aware by default** — the picked source may be out of range and thus **deny a counter**
>   (an intentional build consideration, not a bug).
> - **Opt-in skill = range-aware fallback:** a skill makes the resolver auto-select the highest-priority
>   (most-recent) source that *would permit a counter* (usable **AND** in range). Build content (GDD_05);
>   a passive flag the fallback resolver reads. Supersedes the old `[CEX-23]`-deferred range note for the
>   counter case.
> - **Save (F1):** reserve a per-unit **equip history (MRU)** + the **player source-ordering** (new
>   runtime/persistent state beyond `equipped_source`).

### [CEX-23] Rework attack-selection + target-acquisition for source/maneuver combinations  **[RESOLVED]**
The current "equip a weapon, then **Attack → pick target**" flow assumes a single fixed source.
Reconsider the pattern to streamline **combinations** — choosing an attack source *together with* a
combat maneuver/art that may alter the attack's **resource use, stats, range, or targeting rules**
(e.g. an AoE maneuver, a longer-range variant, a mode that spends extra pool for more Mt). Implies the
selection step and the **combat preview** must reflect the *combined* effect before commit, and
targeting must **re-derive** range/rules from the chosen combo. Largest UX/structural fork in the
cluster; interacts with system A (pools) and the `[SKL]` combat-art cases. **Resolution: reserve
schema, defer the build** (designer fork). The combined **source + maneuver/art** selection (AoE,
longer-range mode, spend-pool-for-more-Mt), the **combined combat preview**, and **re-derived
targeting** are acknowledged as the end-shape but are **NOT built now**. For **F1**, reserve only: the
`equipped_source` reference (`[CEX-21]`) plus a note that a committed attack may carry an **optional
maneuver/art id** whose effects re-derive range/stats/targeting before commit. **v1 attack flow stays
single-source** (equip a source → Attack → pick target) until the **combat-arts (#15) / gambits (#16)
build**, where this rework lands alongside system A pools and the `[SKL]` combat arts. This is the
largest UX/structural fork in the cluster, so deferring it keeps the F1 schema-lock moving.
> **Now owned by the `[STY]` register (2026-06-24j).** The "maneuver" became the **style** half of the
> **source + style** model; combat arts, gambits, and non-lethal capture are all styles over the
> CEX-20 source. This resolution's "optional maneuver/art id" = a `style_id`. Design lives in `[STY]`.

### [CEX-24] Universal `no_attack` source — a mandatory "won't fight" floor  **[RESOLVED 2026-06-25]**
The **inverse of `fists`** (`[CEX-20]`): an infinite, never-breaking source whose **effect set is empty**
so it **cannot initiate AND cannot counter**. Equipping it (or letting the auto-equip fall to it) makes a
unit **hold its hand** — the headline use is **not killing a weak recruitable on your own counterattack**
(an alternative to the `[STY-6]` non-lethal capture style: don't strike back at all).
- **Mandatory & universal:** present in **every** unit's known attack sources — a built-in granted row
  on all units (recomputed like `class_innate`, **not saved**, **not removable**). Player-facing label is
  author-skinnable (default **"Restrain"**); internal id `no_attack`.
- **Behavior when it is the resolved `equipped_source`:** the **Attack** action is unavailable and
  `can_counterattack()` returns **false**. Other actions (Staff/Use, Item) are unaffected — equipping
  `no_attack` blocks *attacks*, not the whole turn. It takes **no styles** (`[STY]`).
- **In the `[CEX-22]` fallback queue:** it is a valid **equip target** and a valid **queue entry**, but
  **defaults to the BOTTOM** (below `fists`) so a breaking weapon never makes a unit accidentally
  pacifist; the player promotes it (or equips it directly) to opt into "stop fighting." Choosing it as
  the floor makes "**counter with nothing**" (`[CEX-22]`) an *explicit, equippable* state rather than the
  mere absence of a usable source.
- **Save (F1):** none new (universal built-in; the `equipped_source` pointer + `[CEX-22]` MRU/ordering
  already reserved can reference it).

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
**RESOLVED.** (a) **Convoy "Key Items" view** — ~~a dedicated sub-view~~ **a pool facet, amended
2026-08-18 by `[CVS-S2]`**: `[DSX-S1]` ruled one shell with registered adapters and a *declared*
escape hatch nine weeks after this answer, so a dedicated sub-view is now the bespoke screen that
ruling forbids. The affordance is unchanged — the convoy still shows every key item in one place,
as a `[DSX-S23]` facet available to any consumer with a holder region. **Key items are exempt from
`convoy_capacity`** (reconcile `[CNV]` — they never count against the limit and can't be lost);
`[CVS-S2]` also makes that exemption, unsellability, bulk-transfer exclusion and the `[DTH-5]`
disposition chain **four independent per-instance properties** set together by a "key item"
authoring preset, rather than one class flag.
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
