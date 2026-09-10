---
Type: design
Status: Active exploration — initial designs, open questions pending
Last verified: 2026-06-26
---

# Candidate Systems — Initial Designs, Feasibility & Scope

**Started:** 2026-06-23 (session 2026-06-23l)
**Status:** Active exploration. Owner-requested initial designs + feasibility/scope research for
five candidate systems, with a **player-interaction question list** to walk later (register
`[CEX-1..N]`, `registers/candidate_systems_open_questions_2026-06-23.md`). **Not firmed** —
input to the pending priority re-evaluation. None of these is built or scheduled yet.
**Relation:** extends the firmed items/equipment composition model (`[IEQ]`), the
Proficiency/XP framework (`[PXP]`), and the CampaignRules author-profile pattern.

The throughline: each candidate **reuses existing machinery** rather than adding a parallel
engine. The questions to firm are mostly about **player interaction → designer authoring →
structural impact**, not feasibility.

---

## A. Shared resource pools  (stamina / mana / cast-from-HP)

**Concept.** Capabilities draw a per-use **cost** from a shared per-unit pool instead of (or
alongside) per-weapon `uses`. E.g. swords/axes spend **stamina**; spells spend **mana** or **HP**.

**Initial design.**
- New per-unit pools: `UnitData.resource_pools: Dictionary` (`{stamina: cur, mana: cur, …}`) +
  maxes; **HP is already a pool**, so "cast from health" reuses it.
- A component declares a cost: `{pool, amount}` on `weapon_component` / `consumable_component` /
  the spell capability — generalizing the `uses` field into a cost model.
- Use sites (CombatResolver attack, ItemHandler, staff) **deduct + gate** on sufficient pool.
- **Refill** rule in `CampaignRules` (per-map reset / per-turn regen / rest-at-hub / never).
- Pool **types** are author-defined in `CampaignRules` (like PXP profiles); class/unit sets maxes.

**Feasibility — Moderate.** No new engine; a per-use cost layered where `uses` is consumed today.
Work = save-schema add (pools), the cost field, deduction/gating hooks, refill rules, UI (show
pools), balance. ~1–2 build phases. Reuses the resource-keyed cost concept (`[SHP-1]`) for the
*in-combat* cost analogue.

**Scope.** v1: 1–2 pool types, per-map reset, cost on weapons + spells. Later: regen/rest refill,
pool-gated skills/movement.

**Dependencies.** Underpins **B (spells-from-pools)**. Pairs with the `[IEQ]` component model.

---

## B. Learned spell system  (Three Houses-style)

**Concept.** Units **learn** spells (not carried in inventory), each with **per-map charges** or
a **pool cost** (A). Learned via class levels / item-proficiency thresholds / items / training halls.

**Initial design.**
- A **known-spells list** on the unit (`UnitData.known_spells: Array[String]`, like `skills`).
  Spells are `ItemDef`s (with a spell/weapon component) referenced by id, **outside inventory**.
- **Casting:** a spell is a weapon-like capability sourced from the known list, not inventory —
  either folded into weapon selection (`get_equipped_weapon` considers known spells) or a
  dedicated **Cast** action + spell menu.
- **Charges:** per-map uses reuse the `skill_use_counters` + `reset_map_state` pattern; or a
  pool cost (A). Author picks per spell.
- **Learning hooks — all already exist or are firmed:**
  - class levels → `ClassData.skill_unlocks` (extend to spell unlocks).
  - item-proficiency thresholds → **`[PXP-4]` on-crossing event** (`grant_spell`).
  - items → a `learn_spell` consumable effect_id.
  - training halls → **`[PXP-9]`** panel grants a spell.

**Feasibility — High (feature-sized).** No single novel piece, but it's a **parallel
capability-source to inventory**: touches the equip/cast flow, a spell-select UI, save schema
(`known_spells` + per-spell charges), and the multi-source learning. Scale ≈ the accessory system.

**Scope.** v1: known list + per-map charges + a Cast action; learn via class-level + PXP-threshold.
Later: pool-cost spells, item/hall learning, forget/swap with a loadout cap.

**Dependencies.** Wants **A** (pool-cost spells); reuses **`[PXP]`** learning hooks + **`[IEQ]`**
ItemDef. Reconcile with current **tome-weapons** (inventory) — coexist vs migrate (open question).

---

## C. Authored trait relationships  (the weapon triangle is one adopter)

> **Corrected in place 2026-09-10.** The 2026-06-24b design made the triangle's
> families and effects authorable, but left the primitive coupled to weapons,
> combatants, WEXP, and advantage/disadvantage. The owner clarified that the goal is
> to exercise the general data systems authors use to relate registered traits. A
> magic triangle is an acceptance pack, not the architecture.

> **RESOLVED 2026-06-24b** → `[CEX-9..12, 17]` (register `candidate_systems_open_questions_2026-06-23.md`):
> a context-agnostic relationship evaluator composed from registered predicates,
> formulae, and effect compositions. Named profiles own their priority and stacking
> policy. The physical and magic triangles become authored profile presets.

**Concept.** Authors define directional relationships between any traits the active
pack can expose through existing or engine-added predicates and registries. Weapon
families are one source; `armoured`, `mounted`, `dragon`, or a pack-defined `undead`
trait are equally valid. A relationship selects two or more named subjects from a
caller-supplied context, evaluates predicates against them, and emits authored effects.

**Revised design.**
- `CampaignRules.relationship_profiles` is an ordered collection of named profiles.
  Each profile declares its contexts, subject bindings, directional rules, priority,
  stacking group/policy, and emitted effect compositions. The evaluator itself has no
  combat or weapon vocabulary.
- A rule's `when` clause uses the shared requirement/predicate system. Trait membership,
  hierarchy ancestry, equipped-source properties, map state, and other registered facts
  enter through predicate adapters; the relationship format does not invent a second
  trait language.
- Pack-defined trait values are valid as soon as their owning registry admits them.
  The relationship schema references those ids and fails closed on an unknown predicate,
  registry family, trait id, formula, effect composition, subject, or context.
- A rule emits one or more effect-composition ids with parameters. Magnitude parameters
  may be literals or shared formula references evaluated from the same named context.
  This supports stat modifiers, conditions, effectiveness, immunity, movement or cost
  changes, and future effects without adding relationship-specific switches.
- Authors define how simultaneous matches compose: `priority`, a named `stack_group`,
  and a group policy such as `first`, `highest`, `lowest`, `sum`, `multiply`, or
  `all`. Stable declaration order is the final tie-breaker. Profiles may stop lower
  priority groups explicitly; the engine supplies deterministic defaults but does not
  impose one global balance rule.
- Results are structured provenance records (profile, rule, subjects, predicate trace,
  formula inputs/result, effects, and suppression reason), so previews, AI, diagnostics,
  and execution consume the same resolution rather than recomputing it.
- Compatibility adapters translate today's `WEAPON_TRIANGLE` and effectiveness behavior
  into built-in profiles. `triangle_family` is retained only as a weapon trait adapter;
  it is not the generic model.

**Feasibility — High complexity, staged.** Predicate and registry composition, formula
evaluation, effect compositions, and structured projection already provide most seams.
The hard part is defining deterministic composition and ensuring preview/AI/execution
share one result. Do not implement this as a larger matrix in `CombatResolver`.

**Acceptance proof.** A campaign pack, loaded through `select_campaign()`, must add a
weapon family/hierarchy node and a non-weapon trait (recommended: `undead`), define at
least two independent relationship profiles, exercise authored priority/stacking,
formula-scaled magnitude, and an additional registered effect, then play the result.
The magic triangle may be one profile in that proof; whether it is balanced is explicitly
not the acceptance criterion.

**Dependencies.** Shared requirement predicates and registry composition; the common
formula evaluator; effect compositions; structured forecast/projection. Individual
effect kinds retain their own dependencies (for example, conditions require the status
system), but the relationship evaluator must not depend on any one effect family.

**Implementation plan (do not collapse these slices).**

1. **Contract and validation:** specify profile/rule/result schemas, context and
   subject declarations, registry references, deterministic ordering, failure modes,
   and migration fixtures. No evaluator yet.
2. **Pure resolver:** evaluate supplied predicates and return matched/suppressed
   provenance records. Use inert test effects so this slice cannot mutate game state.
3. **Composition:** add authored priority, stack groups, policies, and stop behavior;
   property-test ordering independence except for the declared final tie-breaker.
4. **Formula and effect bridge:** resolve registered formulae and effect compositions
   into a transaction/projection. Preview and execution must consume the same result.
5. **Compatibility migration:** express the current physical triangle and weapon
   effectiveness as profiles, preserve saves and observed combat math, then remove the
   hardcoded `WEAPON_TRIANGLE`/effectiveness switches rather than maintain two paths.
6. **Authoring surfaces:** expose registry-backed selectors, hierarchy placement,
   validation diagnostics, relationship tracing, and stacking previews in the editor.
7. **Pack adoption:** author and play the acceptance pack described above. Only this
   slice can close the builder capability; fixtures alone leave it `in_review`.

Slices 1–4 build the reusable foundation. Slice 5 is the first engine adopter. Slices
6–7 prove that an author outside the engine can use it. The magic triangle belongs in
slice 7, after the system exists; it must not drive a bespoke shortcut in slices 1–5.

---

## D. Per-map-use items  (recharging consumables)

> **RESOLVED 2026-06-24c** → `[CEX-13]`: **pure recharge** — `ConsumableComponent.uses_per_map` +
> per-instance `InventoryEntry.map_uses_remaining` (refilled by `reset_map_state`); `uses_remaining`
> stays -1 (never consumed); distinct "N/max ⟳" badge readout. No finite total cap in v1.

**Concept.** Items whose uses **reset each map** (per-map charges) rather than decrementing
permanently — e.g. a "3×/map" healing trinket.

**Initial design.** A `uses_per_map` field on `consumable_component`; the instance tracks a per-map
counter that **reuses the `skill_use_counters` + `reset_map_state` pattern** (reset at map start),
instead of permanently decrementing `InventoryEntry.uses_remaining`. Player-facing: distinguish
"3/3 this map" (recharges) from "3 uses" (consumed).

**Feasibility — Easy.** Directly reuses an existing per-map-counter pattern; small save + UI add.

**Scope.** v1: per-map-use consumables. Later: per-N-turns recharge, charge-on-rest.

**Dependencies.** Slots into the `[IEQ]` `consumable_component`. Overlaps the spell charge model (B).

---

## E. Story / plot-relevant item tracking

> **RESOLVED 2026-06-24d** → `[CEX-14..16, 18, 19]`: `ItemDef.story` + author-configurable
> `no_sell`/`no_drop`/`no_trade` locks (auto-explained in More Info); convoy **"Key Items" view**,
> **capacity-exempt**; designer/editor tracking panel (derived holder scan); **holding item X = a live
> `[MET]` predicate** (no F6) for side-quests/recruitment; **event item-mutation** (upgrade/weaken/
> steal/destroy) rides the `[MET]` build; persistent branching-state rides **F6**; build-time
> validation warns on a key item with finite uses + no repair path.

**Concept.** Mark items as **plot-relevant** and **track** them, so the campaign/story layer can
drive changes (events, branches) off who holds what — and so the player/designer can see them.

**Initial design.**
- A **story flag** on the item def (`is_story_item` / a `story` tag) → locks it from sell/drop/trade
  (like a key), and surfaces it distinctly in inventory.
- A **tracking tool**: a registry/panel listing plot-relevant items + current holder (designer view;
  optional player "quest items" readout).
- **Story-driven changes** hang off the **`[MET]` map-events/triggers** framework: a trigger
  predicate like "unit holds item X" / "item X in convoy" fires an event/branch.

**Feasibility — Moderate, with a real dependency.** The item flag + lock + panel are easy. The
**story-driven changes need a campaign-flag / story-state store that does NOT exist yet** — so this
couples to a broader story/branching system (and the `[MET]` triggers). Tracking ≠ branching:
*tracking* (flag + panel + sell-lock) is cheap and independently useful; *branching* on it is the
larger dependency.

**Scope.** v1: the story-item flag + sell/drop lock + a tracking panel. Later: holder-based `[MET]`
triggers (needs the story-state store).

**Dependencies.** `[MET]` map-events/triggers; a campaign-flag/story-state store (**not yet built**);
the `[IEQ]` item model + `[CNV]` convoy.

---

## F. Comparison-skewed contest / skill-check system  (built on the `[REQ-10]` chance gate)
**Added 2026-06-26** (surfaced by the F16/`[REQ]` work; **not firmed** — a candidate to revisit at
feature planning).
- **Idea:** a named, reusable **contest / skill-check** action — persuade · steal · intimidate ·
  status-infliction · lockpick · "talk-down" — all of which are a **chance whose odds are skewed by a
  comparison of two values** (mirrors combat hit math). The primitive **already exists** as `[REQ-10]`
  (`chance` = base + an F4 skew profile over a difference/ratio of two `[REQ-9]` terms, rolled via
  `RngService`/Package A, roll-once-and-latch).
- **Why a candidate, not just a predicate:** REQ-10 gives the *gate*; a *feature* adds the
  **player-facing action + UX** (a check prompt, the odds readout, success/fail outcomes, retry rules)
  and authoring (which stat-vs-stat, the skew profile, on-success/on-fail effects). That is the part to
  design.
- **Reuses:** `[REQ-9/10]` (terms + chance), the F4 skew profile, Package A RNG, the `[DLG]` choice/
  outcome flow (a dialogue choice can BE a check), the `[STY-6]` steal/capture path.
- **Open (its own walk):** generic "check" action authors drop anywhere vs per-use-case configs over
  one engine · on-fail consequences (alert/aggro via `[PRV]`? item break?) · retry/save-scum policy
  (the REQ-10 latch already blocks reload-rerolls).
- **Depends on** the `[EXT]` extensibility decision (how authors define a check's terms/profile).

## G. `redirect` — combat effect-redirect primitive  (owner — discuss **before A5**)
**Added 2026-06-26** (owner request). **Timing override:** unlike A–F (which firm at the priority
re-eval), the owner wants this **discussed before A5**. **Walked 2026-06-26** (sessions 2026-06-26e
end-shape + 2026-06-26f full walk) — the model is firmed and **`[RDR-1..11]` RESOLVED**
(`registers/redirect_effect_open_questions_2026-06-26.md`); the walk **spawned a sibling primitive
`cover`** (see candidate H + register `[CVR]`).

- **Conceptual model — an effect INTERCEPTOR.** `redirect` subscribes to incoming **effect-application
  events** on its holder; for events matching a predicate it emits a **transformed effect at a selected
  target-set**. "Reflect" (bounce back at the dealer) is the **preset** `target = {source}`; the
  primitive itself is the general "on-intercept → transform → emit at a target-set." Authored once as an
  engine primitive, then composed as data (consistent with the closed `[EXT]` "one model = A" outcome).
- **Resolved end-shape (owner, 2026-06-26):**
  - **Subject = damage · conditions · other combat effects** (general, not damage-only) — see the
    foundation dependency below.
  - **Carrier = any source** — `redirect` is defined once as an effect; a **status condition, equipped
    item, or class/unit trait** all GRANT it (the granted-source pattern, as battalions use). No bespoke
    carrier.
  - **Target = a target-selector** = `anchor` + spatial `scope` + `[REQ]` predicate (composes
    `GridManager._tiles_in_range` + `_get_units()` + a REQ filter — no new spatial math).
  - **`fires_on_death` = an author flag** (per-`redirect`), engine **default = dying-thorns** (fires
    from the killing blow; the target may die simultaneously).
- **Three new engine rules (recommended defaults — see `[RDR]`):** **(1) read point** = the
  **post-mitigation actual** value, with the emitted effect applied **through the target's own pipeline**
  (target's defenses + the F5 lethal/floor projection `[REQ-15]` apply); **(2) termination** = an emitted
  effect is flagged **non-redirectable → one bounce only** (prevents thorns-vs-thorns and radiate
  cascades — non-negotiable for determinism); **(3) death ordering** = the lethal blow defers disposition
  to a safe point, `redirect` fires per `fires_on_death`, then all flagged deaths resolve in **A5's**
  order — so `redirect` is a **co-input to the A5 death/removal-disposition decision** (the reason it is
  walked pre-A5).
- **Determinism class:** **class-2 state-mutation** in the per-output-path model — deterministic, ordered,
  runs at safe points, fixed-point, RNG (if a magnitude term uses `chance`) via Package A.
- **⚠ Naming — disambiguated.** `[DLG-9]` already defines a *dialogue-visual* `reflect` (portrait
  mirror). The combat primitive is named **`redirect`** (general); the back-to-source preset may be
  surfaced to authors as **`reflect`** but is a config of `redirect`, never the DLG visual.
- **⚠ Foundation dependencies (the real cost — not in current code):** general `redirect` is **not
  buildable on today's stubs.** `ConditionManager.gd` is a 37-line no-op until **M8**, and damage flows
  through `Unit.take_damage(amount)` which applies an **already-mitigated** number and emits
  `unit_damaged(self, amount)` **with no source**. So `redirect` requires the M8 build to expose **(a) a
  uniform, source-bearing `effect_applied(kind, magnitude, source, target)` event** to intercept, and
  **(b) a shared unit-selector** (anchor + scope + predicate) — the **same** selector the spell/style AoE
  system needs, so build once, both consume. The interception hook belongs in **`CombatResolver`** (the
  only place that knows attacker→defender and owns death timing), not in `take_damage`.
- **`absorb` (RDR-10):** a `[REQ-16]` term removes a portion of the incoming effect off the holder
  **before it lands** (clamped `[0, incoming]`); `absorb = 0` = additive thorns, `absorb = full` = the
  **parry/full-reflect** fantasy. `absorb_on_unavailable` (RDR-11, default **proportional**:
  `absorb × N_valid/N_intended`) decides whether absorption still applies when the target-set is
  missing/invalid (dead/environmental source).
- **Resource coupling (RDR-13):** a `cost: {pool, amount(term), subject: holder|granting_item}` clause
  reuses the F7 / candidate-A cost-pool model — one clause covers **uses/charges** (`amount: 1`),
  **scaled cost** (mana = `incoming_value × 0.5`), and a **depleting barrier** (`amount: absorbed_value`
  + `absorb: min(incoming_value, pool(holder, barrier))`). Gate = pure read; drain = the class-2
  side-effect. Works against existing HP/item-`uses` pools before author-defined pools land.
- **Event binding (RDR-12):** triggers/terms read the intercepted hit via a new F16/REQ **`event`
  subject** (`kind`/`damage_class`/`magnitude`/`is_crit`/`range`/`source`/`condition_id`/`stacks`).
- **Stacking:** multiple `redirect` effects each evaluate independently and emit their own effect (no
  auto-sum, for predictability); the combat **preview** must show the holder's reduced incoming (absorb)
  + the combined redirected total across **all** affected targets before commit.

## H. `cover` — pre-application effect-reassignment primitive  (sibling of G — owner: spec now)
**Spawned 2026-06-26** by the `redirect` walk (`[RDR-9]` scope boundary). The mirror of `redirect`:
`redirect` is **post-application + additive** (holder took the hit; a new transformed effect is emitted
elsewhere), whereas `cover` is **pre-application + reassignment** — it moves the **original** effect's
target to a protector **before** it lands (the protector takes the original hit with **their** mitigation
vs the original attacker, original kill-attribution = the FE Aegis/guardian "take the hit *instead of* my
ally"). Same `[EXT]` interceptor family, `[STY-9]` selector, RDR-12 `event` binding, RDR-13 cost model,
and M8/A5 dependencies as `redirect`. **Walked + `[CVR-1..6]` RESOLVED 2026-06-26** (session 2026-06-26g):
substitution = **per-hit intercept** (to-hit vs the ally, **mitigation + HP vs the protector**;
**distinct from `[PRV]` provoke**, which is pre-decision aggro, not mid-combat interception); scope =
**damage + conditions + displacement** (displacement = the shove vector re-applied to the protector from
its own tile, via DSP). Needs a **pre-mitigation defender hook** in `CombatResolver` (earlier than
`redirect`'s post-mitigation hook). Register `registers/cover_intercept_open_questions_2026-06-26.md`.

## I. `reactive-reposition` — phase-0 interceptor (on-targeted DSP swap)  (sibling of G/H)
**Spawned 2026-06-26** (session 2026-06-26h) from an owner scenario ("the adjacent general swaps places
with the targeted healer; the attack now resolves fully against the general — evade, defense, skills,
counter — and the general stays put"). The **earliest** phase of the interceptor family: on a `[REQ]`+
`event` trigger at **target-declaration**, a `[STY-9]` reactor does a **`[DSP]` reposition** (swap/shove/
pull/pivot), then **normal combat resolution** runs against the tile's new occupant — so full substitution
(incl. **counter**) is automatic, no special hook. **Walked + `[RCT-1..6]` RESOLVED 2026-06-26**.
- **The interceptor family = three phases** (same `[STY-9]` selector + `[REQ]`/`event` trigger + RDR-13
  cost; differ only by hook timing): **phase 0** `reactive-reposition` (`[RCT]`, full substitution +
  counter) → **phase 1** `cover` (`[CVR]`, mitigation only) → **phase 2** `redirect` (`[RDR]`, emit
  elsewhere). "How much substitutes" = which phase you author.
- **The one new cost:** RCT needs a **pre-resolution reaction trigger**, which bumps the F11 "no new
  triggers" discipline → build-time architecture sign-off. Everything else is `[DSP]` + `[STY-9]` +
  `[REQ]` + RDR-13 reuse. Register `registers/reactive_reposition_open_questions_2026-06-26.md`.
- **Gap-audit (2026-06-26i):** three composition closers complete the family's operation set (block /
  reduce / reflect / redirect / absorb / convert / split / copy / **ward**) — `[RDR-14]` **`gain`**
  (lifesteal/charge), `[RDR-2]` **`emit.kind`** (damage→heal), `[CVR-7]` **`share_disposition: negate`**
  (in-place ward) — plus a board-re-eval determinism rule. Residual gaps (per-strike latch, universal
  effect event, delayed auto-release, forecast dry-run, undo transaction) are **forward-reqs/deferrals**,
  tracked in **`[ICP-1..6]`** (`registers/interceptor_family_gaps_open_questions_2026-06-26.md`) — none
  reopen the core model.

## Cross-cutting dependencies (worth surfacing for the priority re-eval)
- **`ConditionManager` is a stub** but is now wanted by **C** (triangle-conditions) **and** the
  earlier effect gaps (poison weapon tag, condition immunity). It's trending toward a **foundational
  build**, not a one-off.
- **Resource pools (A)** underpin **spells-from-pools (B)**.
- **A campaign-flag / story-state store** is the missing piece behind **E**'s branching (and likely
  other narrative features). Tracking is independent of it; branching is not.
- The **CampaignRules author-profile pattern** (default-reproduces-current, non-breaking) recurs in
  **A** (pool types), **C** (triangle), and `[PXP]` (rank profiles) — a reusable design idiom.

## Next step
Walk the player-interaction questions in `[CEX-1..N]` to define, per system, how players interact →
how designers author/modify → how that shapes the underlying structure. Firming order = the pending
priority re-evaluation.
