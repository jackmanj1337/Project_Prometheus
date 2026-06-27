---
Type: register
Status: OPEN
Last verified: 2026-06-25
Register: BAT-1..16
Resolved-in: 2026-06-25k (BAT-1..13 — entity architecture)
---

# Battalion Entity = the **Attached-Augment** Pattern — Player-Facing Design + Open Questions

**Started:** 2026-06-25 (session 2026-06-25k). The **last sub-cluster of A2** — the full battalion
*entity* (`[STY-11]`), after displacement (`[DSP-1..17]`) and action-grant (`[AGT-1..13]`). Resolves
`[STY-11]`, the only remaining open item in the A1 `[STY]` register. Branch `docs-reorg-2026-06-23`.

**Status (2026-06-25m):** the **entity architecture `[BAT-1..13]` stays RESOLVED** (the merge-vs-bespoke
verdict + substrate map — do not relitigate). The register is **re-OPENed** to mark **`[BAT-14..16]`** —
the **content & lifecycle** details deliberately left under-specified at the architecture pass: the
**bonus content** (refines `[BAT-3]`), the **resource model** — resources / use / replenishment
(consolidates + firms the `[BAT-5]` lean), and the **destruction + host-death lifecycle** (a genuine
gap). These are **persistent-state decisions**, so they must be defined in the define-all sweep **before
the F1 lock** — not hand-waved at build.

**Thesis.** The battalion is **not "a battalion."** It is the canonical configuration of a generic
**attached-augment entity**: a data entity bound to a host unit through a snapshot/restore **attach
registry**, conferring a *composed set* of {passive stat bonuses · granted source(s)/style(s) ·
optionally granted skills}, gated by a **charge/endurance** resource, progressing on its own **rank
ladder**. Five composable axes. Battalion lights up all five — so building it well = building one
generic entity that other "augment" tropes drop into as configurations.

| axis | substrate (existing) | battalion config |
|---|---|---|
| **attach** (one-per-unit, off-map, snapshot/restore, assign UI) | `PairUpRegistry` pattern (`[BAT-2]`) | a `BattalionData` id attached per unit |
| **passive stat bonus** | `StatContributions` / `PairUpBonusResolver` → combat modifiers (`[BAT-3]`) | the battalion's authored bonus block |
| **granted source/style** | `[CEX-20]` granted-weapon union + `[STY-7]` (`[BAT-4]`) | the **gambit** (AoE source, charged) — *already firmed A1* |
| **charge / endurance** | the `§5` action-rate-limit / charge primitive (`[BAT-5]`) | endurance pool the gambit spends |
| **rank / EXP** | the `weapon_rank_for_wexp` threshold helpers; storage bespoke (`[BAT-6]`) | E→S battalion rank, EXP via the `[AGT §6]`/A5 path |
| **(granted skills)** | `[SKL-4]` grant/revoke path | *off* for battalions; *on* for the maximal Emblem config (`[BAT-7]`) |

**The altitude ladder (why this is the right cut).** The attach pattern is seductive — "confers a bonus"
describes half the game. The discriminator that keeps it from swallowing solved systems is two-part:
**(1)** does it need the *attach lifecycle* (one-per-unit, non-positional, assign UI, snapshot/restore)?
and **(2)** does it confer *more than one axis* (bonus AND source/skill AND charge/rank)? Both yes ⇒ this
entity. Either no ⇒ an existing home:

```
pure passive item ............ equip / accessory_component (held or equipped bonus)   [IEQ]
  + a granted skill .......... equip + skill-grant path                               [IEQ §2f] (Knight Ring)
  + granted source+charge+rank ATTACHED-AUGMENT ENTITY                                this register (battalion, Emblem)
attach a real *unit* instead . Pair-Up / adjutant                                     PairUpRegistry  [BAT-8]
positional, not attached ..... aura skill (charm/anathema/daunt/motivate)             GDD_05 / M9
on the map, takes turns ...... summon / roster unit
mount / shapeshift ........... class / form toggle
```

**Pattern:** mirrors `[STY]`/`[DSP]`/`[AGT]` — find the substrate, prefer reuse, justify any bespoke.
Legend: **[OPEN]** / **[RESOLVED]**.

---

## 1. State today (code- + doc-grounded)
- **Greenfield.** No `battalion`/`gambit`/`endurance` exists in `scripts/` or any `.tres` (grep clean) —
  same starting point as `[DSP]`/`[AGT]`.
- **Attach substrate exists.** `PairUpRegistry` (`scripts/autoloads/PairUpRegistry.gd`) is an id-keyed
  attach registry (`_pairs: unit_id -> {partner_id, role}`), with an **off-map sentinel**
  (`OFF_MAP_TILE = (-1,-1)`, line 21), campaign-gating (`_campaign_allows_pair_up`), and a **map-start
  snapshot + retry-restore** owned by `GameState` (`_snapshot_pair_up_registry`, `GameState.gd:177`).
  This is exactly the attach lifecycle a battalion needs.
- **Bonus pipeline exists.** `PairUpBonusResolver.bonuses_for(support)` returns a stat dict applied as
  `duration_type="combat"` modifiers via the normal `get_effective_stat` readers; `StatContributions`
  (`scripts/shared/StatContributions.gd`) already aggregates Pair-Up + stat-skill contributions for the
  character sheet, with a drift-guard test binding display to combat math.
- **Granted-source union exists.** `[CEX-20]` defines the inventory+granted weapon union; `[STY-7]`
  already firmed the **gambit as an AoE source** (provenance `battalion`) with per-map charges. The
  *attack side* of battalions is done — this register owns the *entity*.
- **Rank ladder exists (helpers only).** `GameConstants.weapon_rank_for_wexp` / `next_weapon_rank` /
  `WEXP_RANK_THRESHOLDS` (E→S, `GameConstants.gd:178`) are **pure int→rank** functions, reusable for any
  threshold ladder. But `Unit.add_wexp(track, amount)` (`Unit.gd:1175`) is **weapon-track keyed** — not a
  battalion track (the `[AGT §6]` gap).
- **EXP plumbing exists, with precedent.** `Unit.add_exp(amount)` (`Unit.gd:610`) is shared; staff use
  already calls it (`Unit.gd:482`, `STAFF_HEAL_EXP`). Non-combat actions *can* award level EXP today.
- **Accessory model exists.** `[IEQ]` resolves accessories as an **`accessory_component`** on an item
  (held/equipped bonus + its own **item-proficiency track**), and `[IEQ §2f]`/GDD_10 routes accessory
  effects through the **skill-grant path** (Knight Ring), *not* a bespoke item flag.

## 2. What this pass produced
The merge-vs-bespoke verdict (BAT-1: **neither pole — a thin bespoke entity over reused plumbing**), the
attach/bonus/source/charge/rank substrate mappings (BAT-2..6), the **generalization** of the entity so
an Emblem/Engage ring is a configuration not new code (BAT-7), the two **scope-boundary exclusions**
(adjutant → Pair-Up, BAT-8; accessory/bond-ring → equip, BAT-9), and the UI / save / campaign-default /
AI tail (BAT-10..13). **Consumes** the `[AGT §5]` rate-limit pin and the `[AGT §6]` non-combat-EXP pin.

---

## 3. Resolved decisions

### [BAT-1] Verdict — **neither merge nor fully bespoke: a thin entity over reused plumbing** — **RESOLVED** (owner call)
The battalion is **not** an equippable `InventoryEntry` (the "merge into items" pole) and **not** a
ground-up standalone subsystem (the "fully bespoke" pole). It is a **thin `BattalionData` resource +
`BattalionRegistry` attach** that **reuses four existing substrates**: the Pair-Up attach lifecycle
(`[BAT-2]`), the bonus-resolver pipeline (`[BAT-3]`), the granted-source union (`[BAT-4]`, already A1),
and the rank-threshold helpers (`[BAT-6]`). The only genuinely net-new state is the **endurance counter**
(`[BAT-5]`) and the **EXP/rank progress field** on the entity (`[BAT-6]`).
- **Why not merge into items:** a battalion is an *attachment*, not inventory. `InventoryEntry` is a
  `{weapon,item,equip}` slot with `uses_remaining`, convoy-stored, multiple-per-unit. A battalion is
  one-per-unit, off-map, snapshot-restored, with a rank track and a gambit — the Pair-Up shape, not the
  convoy shape. Forcing it through `[IEQ]` overloads "item" with attach semantics it lacks.
- **Why not fully bespoke:** passive bonuses *are* the bonus pipeline, the gambit *is* the granted-source
  union, the rank ladder *is* the wexp thresholds, the attach lifecycle *is* `PairUpRegistry`'s shape.
  Inventing parallels for those is unjustified duplication — the explicit anti-goal.
- This is the same call `[DSP]` made (reuse the Pair-Up off-map-attach substrate rather than inventing
  one).

### [BAT-2] Attach lifecycle = a sibling `BattalionRegistry` modeled on `PairUpRegistry` — **RESOLVED**
A `BattalionRegistry` autoload, **structurally the same** as `PairUpRegistry`: an id-keyed dict
(`unit_id -> battalion_id`), campaign-gated, **map-start snapshot + retry-restore owned by GameState**
(alongside `_snapshot_pair_up_registry`). It is the *pattern*, **not the same instance**, because a
battalion is a **`BattalionData` resource (a data entity), not a roster unit** — so the "partner" is a
battalion id referencing authored data, not another `unit_id` on the map. (Contrast `[BAT-8]`: an
adjutant *is* a roster unit, so it rides the *actual* `PairUpRegistry`.) Off-map-ness is implicit (the
battalion has no tile), so the `OFF_MAP_TILE` sentinel is unneeded; the snapshot/restore + campaign-gate
patterns transpose directly.

### [BAT-3] Passive bonuses = reuse the bonus-resolver / `StatContributions` pipeline — **RESOLVED**
A battalion's authored stat block is conferred to its host **exactly like a Pair-Up support bonus**: a
`battalion_bonuses_for(unit)` resolver returns a stat dict, applied as `duration_type="combat"` modifiers
that the existing `get_effective_stat` readers pick up — no bespoke combat-stat translation. It is added
as a **new contribution source in `StatContributions`** (the module's header already anticipates new
combat-only sources), and **the drift-guard test grows to cover it** (the playtest #8.5 lesson: display
and combat math never drift). Bonus *values* may scale with battalion **rank** (`[BAT-6]`).

### [BAT-4] Gambit source = already firmed A1 (`[STY-7]`) — reconcile, don't relitigate — **RESOLVED**
The battalion grants an **AoE `WeaponData`** to the host via the `[CEX-20]` granted-list (provenance
`battalion`), fired as a `strike` effect under an AoE **style** (`[STY-7]`/`[STY-9]`), with **per-map
charges**. This pass does **not** redesign the gambit attack — it owns the *entity that grants it*. The
gambit's "once per round" limit **consumes the `[AGT §5]` rate-limit primitive** (`[BAT-5]`).

### [BAT-5] Endurance = a charge/resource pool on the entity, drawing the `§5` primitive — **RESOLVED (lean; replenish curve → build/CampaignRules)**
Endurance is a **per-battalion depleting counter** held on the entity (not the unit), spent by gambit use
and consuming the **generic action-rate-limit / charge primitive** pinned at `[AGT §5]` (so "gambit once
per round / N per map" is not battalion-specific code). **Lean (owner call):** v1 endurance is a
**per-map resource pool the gambit spends, replenished at map start** (the simplest model that reads as
"battalions tire and recover between battles"); whether endurance *also* depletes from the host taking
hits / battalion losses, and the exact replenish curve (supply convoy, partial carry-over), are
**`CampaignRules`-tunable and settled at build** — mirrors how `[STY-8]` pushed finer battalion
action-economy edge-cases to the build. **Not yet locked:** the depletion trigger set (per-gambit only
vs per-gambit + per-hit). Flagged for the build pass.

### [BAT-6] Rank / EXP = reuse the rank-threshold helpers; **bespoke the storage**; EXP rides A5 — **RESOLVED**
Battalion rank is an **E→S ladder reusing the pure helpers** (`weapon_rank_for_wexp`, `next_weapon_rank`,
`WEXP_RANK_THRESHOLDS`) — these are int→rank functions with no weapon coupling. But the **progress is
stored on the battalion entity** (`BattalionData.exp` / current rank), **not** in `unit.weapon_wexp`: a
battalion rank is not a weapon track, and `add_wexp` is weapon-keyed and class-capped (`[AGT §6]`). EXP
*award* (does a gambit / a battalion kill grant battalion-EXP, and how much) **rides the A5 non-combat-
action EXP rule** (`[AGT §6]` forward-pin → A5 EXP-economy / Bonus-EXP #18): an authored amount, not a
hardcoded constant, generalizing the `STAFF_HEAL_EXP` precedent. Reusing the *threshold helpers* while
keeping the *storage/track* separate is the boundary — using `weapon_wexp` would be a category error.
A battalion may *also* scale its behavior off the **host's** Charm stat / Command (Authority) proficiency
— see the F14 stat-model pin `[STM-2]` (`registers/extensible_stat_model_open_questions_2026-06-25.md`);
that command-proficiency *earn* path is the same `[AGT §6]`/A5 non-weapon-proficiency generalization.

### [BAT-7] Generalize the entity — battalion is config A; **Emblem/Engage ring is the maximal config** — **RESOLVED** (owner call)
Author the data entity **generically as an attached-augment**, not as "the battalion type." The validation
that the abstraction sits at the right altitude: a hypothetical **Emblem/Engage ring drops in as the
maximal configuration** — same entity shape, with the **granted-skills axis turned on** (`[SKL-4]` path)
and "endurance" reading as an "Engage gauge" charge. **Emblems are NOT on the roadmap** (no GDD mention) —
this is a stress-test of the cut, not a feature to build. The payoff: an Engage-style system later is
**content, not code** (the same dividend `[STY]` got by absorbing arts + gambits + staves into one
pipeline). Do not build the skill-grant axis now; design the entity so it is a flag, not a fork.

### [BAT-8] Scope boundary — **Adjutant ≠ this entity; it is Pair-Up** — **RESOLVED** (owner call; resolves the prior-turn open question)
An adjutant *looks* like "a battalion that's a person," but it attaches a **real roster unit**, not a data
entity — which is precisely `PairUpRegistry`'s job (it already has `lead`/`support` roles, the
`OFF_MAP_TILE` sentinel for an off-map support, and snapshot/restore). So an adjutant is a **Pair-Up mode**
— a `support` that stays off-map and confers a bonus, plus an **intervention-behavior flag** (occasional
follow-up/guard/heal) — reusing the **actual `PairUpRegistry` instance**, *not* `BattalionRegistry`. This
settles the question flagged last pass ("does the adjutant variant reuse the actual registry or just its
pattern?"): **the actual instance.** `[STY-11]`'s "adjutant/pair-up variant" therefore lands in the
Pair-Up system, not here.

### [BAT-9] Scope boundary — **Accessories / bond-rings ≠ this entity; they are equip + skill-grant** — **RESOLVED** (owner call)
A single-axis passive (a stat ring) or a single granted skill (Knight Ring) does **not** meet the
two-part discriminator (`§ thesis`). `[IEQ]` already homes these: the **`accessory_component`** (held or
equipped bonus, with its own **item-proficiency track**) plus the **`[IEQ §2f]` skill-grant path** for
ring-granted effects. A **bond ring** = an `accessory_component` (bonus + item-bond proficiency) — it
stays in `[IEQ]`. Escalate to *this* entity **only** when an item additionally needs a **granted source +
a charge gauge + a rank**, i.e. when it becomes an Emblem (`[BAT-7]`). This prevents the attach pattern
from re-forking the solved equip/accessory system.

### [BAT-10] Assignment / prep UI = reuse the prep hub + Pair-Up assignment pattern — **RESOLVED**
Battalion assignment is a **prep-screen action** on the `[PHB]` prep-hub, reusing the Pair-Up assignment
UI pattern (pick unit → pick battalion from an unassigned pool → confirm) and the existing
equip/loadout UI affordances. No bespoke screen framework; the entity's prep surface is one more
hub panel.

### [BAT-11] Save / F1 reserve — **RESOLVED**
Reserve at the F1 schema-lock: **(a)** the `unit_id -> battalion_id` attach (snapshotted like the Pair-Up
registry, map-start + retry-restore); **(b)** per-battalion **endurance/charge** state (`[BAT-5]`) and
**EXP/rank** progress (`[BAT-6]`) — these are *persistent battalion state*, distinct from the *transient*
per-turn rate-limit counters (`[AGT-11]`). Coordinate with the Pair-Up snapshot owner and the `[AGT §5]`
rate-limit counters so all attach/charge state is reserved together.

### [BAT-12] Campaign-default + override — **RESOLVED**
Mirrors `[DSP-17]`/`[AGT-12]`: every battalion tunable — endurance pool + replenish (`[BAT-5]`), rank
curve / EXP amounts (`[BAT-6]`), bonus tables (`[BAT-3]`), gambit charge caps (`[BAT-4]`) — is a
**`CampaignRules` default overridable per battalion** (resolution = battalion → campaign → framework).

### [BAT-13] AI battalions — **RESOLVED (in principle); heuristic at AI build**
Enemy battalions query the **same** capability surface (the granted gambit source, the passive bonus, the
endurance pool); the use heuristic (when to spend a gambit charge) is detailed when the AI work picks it
up — no separate data (mirror `[AGT-10]`/`[SMV-10]`).

---

## 3b. OPEN — content & lifecycle (must be defined before F1)
The architecture (`[BAT-1..13]`) said *how* a battalion attaches and confers; it deliberately did not
pin *what* it confers, *what resources it runs on*, or *what happens to it across the unit lifecycle*.
These three are now marked OPEN. All persist state, so they gate the F1 lock.

### [BAT-14] Bonus content & shape — **OPEN** (refines `[BAT-3]`)
`[BAT-3]` fixed the *pipeline* (a stat dict → combat modifiers, like a Pair-Up support bonus). Still to
define: **what** a battalion confers and on **what stat axes**.
- **Stat set:** which stats a bonus may touch — the existing seven combat stats, derived stats
  (Hit/Avo/Crit), and/or the future Charm/Command axes (F14 `[STM]`). Does a battalion grant *only* flat
  stat deltas, or also derived-combat modifiers (the `[STY]`/aura-style hit/dodge/crit layer)?
- **Conditionality:** always-on while attached vs gated (terrain, adjacency to allies, vs a unit-type —
  the 3H "effective vs cavalry" battalion flavor). v1 lean = **always-on flat block** (the simplest,
  reuses `[BAT-3]` unchanged); conditional bonuses ride the existing skill/`[STY]` gate vocabulary if
  authored.
- **Rank scaling:** how the block scales with battalion rank (`[BAT-6]`) — a per-rank table vs a
  multiplier. Lean = a **per-rank authored block** (table), mirroring class stat-cap tables.
- **Owner:** the battalion build; **data-def, not engine** — but the *stat axes* it may touch depend on
  F14 `[STM]` if Charm/Command are bonus targets.

### [BAT-15] Resource model — resources, use, replenishment — **OPEN** (firms the `[BAT-5]` lean)
`[BAT-5]` set the *mechanism* (a per-battalion counter consuming the `[AGT §5]` rate-limit/charge
primitive) and a lean (per-map pool, refill at map start). To **firm**:
- **What resources exist:** is "endurance" a *single* pool that the gambit spends, or are **gambit
  charges** and **endurance** two distinct resources (3H has both — charges = per-battle gambit uses,
  endurance = a longer-horizon attrition meter)? **Decide one-pool vs two-pool.** Lean = **two named
  resources** (`charges` = per-map gambit budget via `[AGT §5]`; `endurance` = the attrition meter that
  drives destruction, `[BAT-16]`), so destruction is decoupled from "out of gambit charges."
- **What spends them:** gambit use spends a charge (`[BAT-4]`); does taking the host into combat / losing
  the host's HP / time also drain endurance? (`[BAT-16]` depends on this answer.)
- **Replenishment:** per-map refill (lean) vs carry-over with a between-map repair step (a prep-hub /
  convoy "resupply battalion" action, reusing `[PHB]`) vs a paid repair (gold/`[SHP]`). Lean = **charges
  refill each map; endurance is the persistent meter** that only recovers via an authored repair action.
- **Owner:** the battalion build; all values = `CampaignRules` defaults per `[BAT-12]`. **Save (F1):**
  persistent `endurance` (and rank/EXP, `[BAT-11]`); transient `charges` reset per map like other
  `[AGT §5]` counters.

### [BAT-16] Lifecycle — destruction & host-death disposition — **OPEN** (genuine gap)
Neither "can a battalion be destroyed?" nor "what happens to it when its host dies?" was covered. Both
are **persistent-state** questions and **must** be settled before F1.
- **Destruction:** can a battalion be permanently lost? Lean = **endurance-zero = routed**, an authored
  `CampaignRules` choice between **`disband`** (battalion destroyed/removed from the roster pool) and
  **`exhausted`** (survives at 0 endurance — no gambit/bonus until repaired, the softer default).
  Routed-via-disband is the harsh/Classic option; exhausted-and-repairable is the Casual-leaning default.
- **Host death:** when the attached unit dies, the battalion does **not** die with it by default — it
  **detaches and returns to the unassigned battalion pool** for reassignment in prep (the battalion is an
  authored asset, like an unequipped item returning to convoy). Author override for harsher campaigns:
  **`lost_with_host`** (the battalion is destroyed with its commander).
- **Reconcile with the death pipeline:** route host-death battalion disposition through the **single
  `handle_death` hook** the **Death-inventory disposition rule set** (A5, pinned 2026-06-25h) already
  mandates — a battalion is part of the host's "loadout disposition," a sibling case to dropped/convoyed
  inventory and the `[DSP-5]` "death while carrying" precedent. **Do not invent a second death hook.**
  Edge cases inherit that rule set: no convoy/pool on this map → hold; Casual/Phoenix (#12) — a returning
  unit reclaims its battalion; simultaneous deaths — **snapshot-then-resolve per-unit in roster order**
  (`[DTH-8]`). **Now RESOLVED** as `registers/death_inventory_disposition_open_questions_2026-06-27.md`
  `[DTH-1..12]`; host-death = a faction disposition-chain case routed through `handle_death(ctx)`
  (`[DTH-9]`).
- **Owner:** the battalion build **+ the A5 death-disposition rule set** (host-death is a disposition
  mode there). **Save (F1):** the battalion's `disband`/`exhausted` state and its
  attached-vs-pooled status (extends `[BAT-11]`).

---

## 4. Build hand-off (when scheduled)
- **GDD owners at build:** GDD_03 (the battalion entity + attach on units/classes) · GDD_02 (the passive
  bonus into the combat-stat pipeline + the gambit action economy) · GDD_05 (the granted gambit source /
  style cross-ref) · GDD_07 (the prep-hub assignment panel) · GDD_10 (battalion milestone; reconcile the
  `[STY-7]` gambit attack-side).
- **Reuses, doesn't add:** the `PairUpRegistry` attach pattern + GameState snapshot/restore (`[BAT-2]`),
  the `PairUpBonusResolver`/`StatContributions` pipeline + its drift-guard test (`[BAT-3]`), the
  `[CEX-20]` granted-source union + `[STY-7/9]` gambit (`[BAT-4]`), the `[AGT §5]` rate-limit/charge
  primitive (`[BAT-5]`), the `weapon_rank_for_wexp` threshold helpers (`[BAT-6]`), the `[PHB]` prep hub
  (`[BAT-10]`), `CampaignRules` defaults (`[BAT-12]`).
- **Net-new code:** the `BattalionData` resource + `BattalionRegistry` autoload (`[BAT-1]`/`[BAT-2]`), the
  battalion bonus resolver + its `StatContributions` source (`[BAT-3]`), the endurance counter (`[BAT-5]`),
  the on-entity EXP/rank progress + the A5-owned battalion-EXP award amount (`[BAT-6]`), the prep
  assignment panel (`[BAT-10]`).
- **DoD#1/#2 apply at build**, not at this firming (no behavior changed yet).

## 5. Consumed pins (this pass closes the loop on two A2 forward-pins)
- **`[AGT §5]` generic action-rate-limit / charge primitive** — battalions are a named consumer (`[BAT-5]`,
  gambit "once per round / N per map"). Still owned by the action/turn-flow foundation; reserve its
  counters at F1.
- **`[AGT §6]` non-combat-action EXP / proficiency path** — battalion rank EXP rides it (`[BAT-6]`). Still
  owned by **A5**; this pass adds battalion-EXP to the list of support actions A5 must price.

## 6. Reconcile-don't-relitigate
- The battalion is the **attached-augment entity**, of which it is config A; design it generically so
  Emblem (`[BAT-7]`) is content. Do **not** hardcode a battalion-only entity.
- **Adjutant lives in Pair-Up** (`[BAT-8]`), **accessories/bond-rings live in `[IEQ]`** (`[BAT-9]`) — do
  not pull single-axis or attach-a-unit tropes into this entity.
- The gambit attack-side is **`[STY-7]`** (A1, firmed) — this entity grants it; it does not redesign it.
- Battalion rank reuses the **rank-threshold helpers**, **not** the `weapon_wexp` track (`[BAT-6]`).
