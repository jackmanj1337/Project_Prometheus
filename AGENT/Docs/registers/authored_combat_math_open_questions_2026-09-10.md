---
Type: register
Status: OPEN
Last verified: 2026-09-10
Register: ACM-1..9
Resolved-in: 2026-09-10 (ACM-1..5 by owner ruling; ACM-6..9 open)
---

# Authored Combat Math — Open Questions

**Started:** 2026-09-10, on owner direction: *"we should make as much of the combat math
and order data driven so that authors can customize it to fit them."*

**Status: PARTIALLY OPEN.** `[ACM-1..5]` closed on owner ruling the day they were opened.
`[ACM-6..9]` are the questions that ruling raises and are genuinely open — they need a
walk before slice 1 of the pipeline row writes its contract.

**Relation.** Sibling of `[ITR]`, which owns the generic interaction evaluator. This
register owns the **combat pipeline** the evaluator plugs into. The split was an owner
ruling on 2026-09-10: the evaluator is the smaller, reusable primitive — movement and
economy will use it with no combat math at all — so it closes on its own adopter and
does not wait for a combat rewrite.

> *One-in-one-out:* a register instance, not a document class or a mechanism. Nothing is
> retired for it, and that is the written reason the rule asks for.

---

## What the ruling actually changes

Combat math is currently a mix of three things, and only the first was ever author-facing:

| Layer | Today | After |
|---|---|---|
| Selectable presets | `CampaignRules.hit_formula` = `two_roll` \| `single_roll` (`[CRR-4]`) | Extends to every stage; the registry `[CRR-8]` deferred |
| Constants | `WEAPON_TRIANGLE`, 3×/4× effective, `FOLLOW_UP_SPEED_THRESHOLD`, crit ×3, `_EXP_TABLE`, `_ALWAYS_USE_DURABILITY` | Default-pack data |
| Order | Implicit in the shape of `compute_damage()` — Mt scales, then defence subtracts, then clamp | **Authored stage list** |

The third row is the substantive change. Everything else is data that was already
conceptually a pack's, sitting in the wrong file.

## What is NOT in scope

The engine keeps, and authors do not configure: RNG draw order and the canonical roll
sequence (`[GDD-01-RUNTIME-CONTRACTS]` §5 — reordering is save/replay-breaking),
transaction/commit semantics, subject binding, determinism, and the set of legal
operations a stage may perform. Authors compose bounded operations; they do not write
code. `[CRR-3]` already ruled GDScript out and it stays out.

---

### [ACM-1] How far down does data-driven go? — **[RESOLVED 2026-09-10]**
**RESOLVED: everything in combat.** Pipeline stages and their order, plus hit, crit
multiplier, follow-up threshold, EXP table, durability rules, weapon triangle,
effectiveness, and terrain application all become pack data. The engine owns the legal
operation set, subject binding, phase targets and determinism; the pack owns which stages
exist, in what order, fed by which terms.

### [ACM-2] Must the default pack reproduce today's numbers? — **[RESOLVED 2026-09-10]**
**RESOLVED: no.** There is no player data to preserve, so ±10/±2 and 3×/4× are not a
constraint. Tests asserting the constants are deleted with them; tests asserting
behaviour are re-pointed at the default pack's authored data.

### [ACM-3] Then what is the completion gate? — **[RESOLVED 2026-09-10]**
**RESOLVED: replicate rulesets from multiple different games accurately**, including at
least one that is not Fire Emblem. The named target set:

| Ruleset | What it forces the pipeline to express |
|---|---|
| GBA FE (FE6/7/8) | Two-roll hit, durability, one triangle, flat ±10/±2, 3× effective, WEXP ranks |
| A modern FE (Fates or Three Houses) | Fates: **no durability**, two triangles, both Mt *and* Hit move. Three Houses: the triangle is a **skill**, not a global rule — per-unit participation in a relationship |
| A non-FE tactics ruleset (FFT / Tactics Ogre) | **No weapon triangle at all**; faith/brave multiplying magic damage; elevation and facing entering the hit pipeline; damage **formula selected per weapon**, not per matchup |

The third column is the actual contract. A pipeline that does FE6 and FE8 proves nothing
— they are near-identical. The non-FE entry is what proves this is a tactics-combat
pipeline rather than an FE pipeline with knobs, and it forces three properties the FE-only
set does not: no assumed triangle stage, per-source formula selection, and spatial terms
inside hit resolution.

### [ACM-4] Where does the data live? — **[RESOLVED 2026-09-10]**
**RESOLVED: `CampaignRules`**, alongside `interaction_profiles`. Consistent with the
existing author-profile pattern (`hit_formula`, `pxp_profiles`) and ships without waiting
on `IMPL-ZERO-CONTENT-BASE-PACK`. That row is the natural successor for moving it into
pack data proper; name it as such rather than blocking on it.

### [ACM-5] What does a pack that omits combat math do? — **[RESOLVED 2026-09-10]**
**RESOLVED:** there is a built-in default pipeline that packs fork, not a fallback branch
in the engine. This follows from the readout ruling in `[ITR-6]` — defaults come from the
pack being forked or from the editor — and applies to the math the same way. A pack never
inherits behavior from engine code it cannot see; it inherits data it can open and edit.

---

## Open

### [ACM-6] Stage vocabulary — what is a stage, and what may one do? — **[OPEN]**
The engine owns the legal operation set. What is in it? A first cut from the shapes the
`[ACM-3]` target set demands: `base` (read a stat), `scale` (multiply a term),
`add`/`subtract` (flat terms), `select` (choose a formula per source), `clamp`, and
`roll` (hand off to a `[CRR]` resolver). Open: whether stages are typed by output
(`damage`/`hit`/`crit`) or generic over a named accumulator; whether a stage may read a
previous stage's result or only the context; and how a pack expresses "this stage does
not exist" versus "this stage is empty".

**Lean:** typed accumulators, generic stages. Typing the accumulator gives validation
something to check and keeps the readout able to label what it shows; typing the stage
would reintroduce the switch the `[EXT]` model exists to avoid.

### [ACM-7] Does `[CRR]`'s resolver registry generalize, or stay hit-specific? — **[OPEN]**
`[CRR-6]` already ruled the resolver contract "generalizes to any 0–100 check; hit is the
first consumer", and `[CRR-8]` deferred the registry. Open: whether the `roll` stage in
`[ACM-6]` simply *is* a `[CRR]` resolver reference — which would make crit, skill
activation and the `[REQ-10]` chance gate all one mechanism — or whether combat rolls and
requirement chances stay separate registries.

**Lean:** one mechanism. `[REQ-10]` and `[CRR-2]` already describe the same shape (a
declared `rn_count` and a pure predicate over a skewed comparison), and `[CEX-F]`
(contest/skill-check) is a third consumer waiting. Three registries for one primitive is
exactly the collision this project keeps paying for.

### [ACM-8] What is the authoring surface, and does the editor need a pipeline view? — **[OPEN]**
An ordered stage list with per-stage terms is a different editing shape from the
record/form surfaces `EPIC-SHARED-RECORD-UI-V1` builds. Open: whether this is a bespoke
editor workspace, a table over the existing Inspector, or authored as data with
validation only in v1 and a visual surface later.

**Lean:** validation-only in v1. The pipeline is authored once per pack and rarely edited;
a visual builder is a large surface for a low-frequency task, and `[ACM-3]`'s proof needs
correctness, not ergonomics.

### [ACM-9] How is an authored pipeline's arithmetic bounded? — **[OPEN]**
`[CRR-7]` constrains custom hit predicates for determinism, and RequirementSystem has
node/depth budgets (`requirement_node_budget`, `value_term_node_budget`). Open: whether
the pipeline reuses those budgets, needs its own, and what happens when a pack's pipeline
exceeds them mid-combat — which is not a place a `calculation_budget` fallback can be
shown to the player, unlike `[CAU-5]`'s preview case.

**Lean:** validate at load, refuse the pack, never fail mid-combat. A pipeline is fixed
data, so its cost is knowable before a fight starts; that is a strictly better failure
point than a forecast that degrades.

---

## Inherited corrections

**`[CRR-5]` is corrected by this ruling.** It resolved that "displayed hit % stays
`compute_hit_pct`" — a fixed function as the readout authority. Once the pipeline is
authored, the displayed number must come from the authored pipeline's own result, or the
forecast and the fight compute hit differently. The *intent* of `CRR-5` survives and is
the stronger half: the player sees the **displayed** odds, and the resolver's internal
true-hit curve is not exposed. That separation stays; the function named in it does not.
Recorded in `combat_roll_resolver_open_questions_2026-06-30.md`.

**`[CRR-8]`'s deferred half is owned here.** "Registry + author tiers" was scheduled after
the built-in seam. This row is where it lands. It is not a new system.

## Defects to fix in the code being replaced

Found 2026-09-10 while reviewing the interaction plan; all three are in code this row
rewrites, so they are fixed by replacement rather than patched first.

1. `_triangle_accuracy` / `_triangle_damage` discard the `weapon` argument their caller
   resolved and re-read `attacker.get_equipped_weapon()`. Becomes visible under
   `[CAU-1A]` live source cycling.
2. `_current_triangle_profile()` and `_current_hit_formula()` read `/root/GameState` per
   computation. Resolve once in `_build_combat_context()`.
3. `DataManager.get_weapon_triangle_result()` still reads the legacy constant after the
   resolver was routed through the authored profile — a green suite proving nothing about
   shipped behaviour. Its only callers are five assertions in `test_data_manager.gd`.
