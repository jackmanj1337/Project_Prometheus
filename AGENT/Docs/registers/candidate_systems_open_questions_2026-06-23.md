---
Type: register
Status: OPEN
Last verified: 2026-06-23
Register: CEX-1..16
---

# Candidate Systems — Player-Interaction Open Questions

**Started:** 2026-06-23 (session 2026-06-23l)
**Status:** OPEN (cluster **A resolved 2026-06-23l** → firms foundation **F7**; B–E still open). The
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

## C. Author-flexible weapon triangle

### [CEX-9] Player readout — how is a custom hierarchy + its effects shown?  **[OPEN]**
The triangle/more-info UI is currently fixed to 3 families per triangle. How does a custom hierarchy
+ its (possibly non-Hit/Dmg) effects read to the player? *Lean:* a data-driven matchup readout in the
combat preview + more-info. **Resolution:** _[OPEN]_

### [CEX-10] Effect vocabulary — what may an advantage/disadvantage apply?  **[OPEN]**
Flat Hit/Dmg only, any stat mod (bonus/debuff), **condition application**, or a combo? *Lean:* stat-mod
set v1 (reuses the modifier model); condition application later (blocked on `ConditionManager`).
**Structural:** reuses modifiers; conditions need the stubbed manager built. **Resolution:** _[OPEN]_

### [CEX-11] Hierarchy shape — strict cycle vs arbitrary directed graph?  **[OPEN]**
Rock-paper-scissors cycles only, or arbitrary "A beats B and C, neutral to D"? *Lean:* arbitrary
directed graph (a matrix, like the current `WEAPON_TRIANGLE` dict) — more expressive, same storage.
**Resolution:** _[OPEN]_

### [CEX-12] Authoring + scaling — profile home + rank-scaled magnitude?  **[OPEN]**
Triangle profile in `CampaignRules` with a non-breaking default (PXP pattern); does magnitude scale
by equipped rank (GDD_04 target)? *Lean:* yes, reuse a PXP-style profile for magnitude. **Resolution:** _[OPEN]_

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
