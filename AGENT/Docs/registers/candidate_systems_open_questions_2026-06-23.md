---
Type: register
Status: OPEN
Last verified: 2026-06-24
Register: CEX-1..17
---

# Candidate Systems — Player-Interaction Open Questions

**Started:** 2026-06-23 (session 2026-06-23l)
**Status:** OPEN (cluster **A resolved 2026-06-23l** → firms foundation **F7**; cluster **C resolved
2026-06-24b** → flexible weapon triangle, rides F4; B/D/E still open). The
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

## D. Per-map-use items

### [CEX-13] Player distinction + structure — recharging vs consumed?  **[OPEN]**
How does the player tell "3/3 this map" (recharges) from "3 uses" (consumed)? Structurally a
`uses_per_map` field on `consumable_component` + a per-map counter (reuses `skill_use_counters` /
`reset_map_state`). *Lean:* distinct UI affordance; reuse the counter pattern. **Resolution:** _[OPEN]_

## E. Story / plot-relevant item tracking

### [CEX-14] Player visibility & lock — how do story items appear/behave?  **[OPEN]**
Are plot items shown distinctly + locked from sell/drop/trade (like keys)? Is there a player-facing
"quest items" readout? *Lean:* a `story` flag → sell/drop lock + distinct tag; player readout optional.
**Resolution:** _[OPEN]_

### [CEX-15] Designer branching hook — how do story items drive changes?  **[OPEN]**
Via `[MET]` map-events/triggers (predicate "unit holds item X"). **This needs a campaign-flag /
story-state store that does not exist yet** — tracking is cheap, *branching* on it is a larger
dependency. *Lean:* ship tracking now; gate branching on the story-state build. **Resolution:** _[OPEN]_

### [CEX-16] Tracking tool — what shape is the "plot items" view?  **[OPEN]**
A designer registry/panel listing plot-relevant items + holder? A player quest log? *Lean:* designer
tracking panel v1 (lists item + current holder across roster/convoy). **Resolution:** _[OPEN]_

## Notes
- **Cross-cutting dependencies** (design doc §Cross-cutting): `ConditionManager` (stub) is wanted by
  C + the poison/immunity gaps — trending foundational; resource pools (A) underpin spells (B); a
  campaign-flag/story-state store is the missing piece behind E's branching.
- **DoD:** any system that graduates from exploration gets its own register split + GDD owner updates
  with the build, not now.
