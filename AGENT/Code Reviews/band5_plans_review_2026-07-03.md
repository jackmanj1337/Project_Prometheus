# Band 5 Implementation Plans — Review, Questions & Concerns (2026-07-03)

**Scope:** review doc accompanying the four Band 5 implementation plans drafted
this session, per the owner ask ("write the implementation plans for band 5; make
a review doc of any questions or concerns"). Plans drafted against the settled
Q1-Q7 walkthrough decisions (2026-07-01) and the
[`band5_implementation_plan_handoff_2026-07-02.md`](../Docs/plans/band5_implementation_plan_handoff_2026-07-02.md).

Plans produced (grouped per the handoff's recommended four-plan shape,
Q-B5-2):

- [`band5_conditions_skills_implementation_plan_2026-07-03.md`](../Docs/plans/band5_conditions_skills_implementation_plan_2026-07-03.md)
  — `B5-CONDITIONS` + `B5-DURATION-LIFECYCLE` + `B5-SKILLS-EFFECTS` +
  `B5-LOADOUT-CAPS` (shell + skills adapter).
- [`band5_source_style_implementation_plan_2026-07-03.md`](../Docs/plans/band5_source_style_implementation_plan_2026-07-03.md)
  — `B5-SOURCE-STYLE` + `B5-UTILITY-STAVES` + styles/sources loadout adapters.
- [`band5_action_economy_implementation_plan_2026-07-03.md`](../Docs/plans/band5_action_economy_implementation_plan_2026-07-03.md)
  — `B5-ACTION-GRANT` + `B5-SECONDARY-MOVEMENT`.
- [`band5_ai_implementation_plan_2026-07-03.md`](../Docs/plans/band5_ai_implementation_plan_2026-07-03.md)
  — `B5-AI-COMPOSITION` + `B5-AI-MIN-SCORER`.

The plans are **planning artifacts, not build authorizations** — Band 5 code
must not start before the Band 1-3 gates and (for Source+Style) `B4-IEQ` land.

---

## A. Handoff owner questions carried forward

These were raised by the handoff and are still owner decisions; the plans made
provisional calls where noted, but they want confirmation.

- **Q-B5-1 (the Q2 gate) — carried, provisional.** The plans build **machinery +
  fixtures** and mark the required-v1 effect/condition/staff id manifest as a
  late demo-gated content slice (handoff lean: draft now, manifest deferred).
  Confirm this, or schedule the demo-campaign design pass first. **`on_level_up`
  is treated as an engine trigger and is wired in Plan 1 Slice 4 regardless** —
  it is not deferrable content. *Recommendation: draft-now stands; the manifest
  is content on finished machinery.*

- **Q-B5-2 — provisionally confirmed.** The four-plan grouping is used as-is.
  Flag if you want the AI chain split further or the loadout shell pulled into
  its own plan.

- **Q-B5-3 (duration-lifecycle boundary) — needs a decision; see concern C1.**
  The plans build **one lifecycle store** (Plan 1 Slice 2) that both `B4-IEQ`
  equipment (`until_unequipped`) and Band 5 conditions/skills register into. Open
  sub-question below.

- **Q-B5-4 (forging pull) — provisional: forging v1 waits.** Plan 2 reserves the
  effect-registry seam that `FRG-18` needs but does **not** pull `B5-SOURCE-STYLE`
  earlier. Confirm forging v1 waits (its non-`FRG-18` slices don't need the
  registry), or elevate Source+Style in the sequence because the demo includes
  forging.

---

## B. New concerns surfaced while drafting

- **C1 — the `until_unequipped` ownership seam (feeds Q-B5-3).** Plan 1 builds a
  shared `LifecycleStore`, but `B4-IEQ` Slice 5 already builds an
  `until_unequipped` producer/remover keyed by `item:<instance_id>:<stat>`.
  Two clean options, and the plans should not both implement a store:
  - (a) `B4-IEQ` builds the store; Band 5 registers into it. Cleaner if IEQ lands
    first (it does — it's a Band 4 gate).
  - (b) `B4-IEQ` keeps a local producer now; Band 5 generalizes it into the
    shared store and migrates IEQ onto it.
  *Recommendation: (a) — IEQ owns the store (it lands first), Band 5's
  `B5-DURATION-LIFECYCLE` adds the `until_end_of_map` + fixed-N modes and the
  condition/skill producers.* This makes `B5-DURATION-LIFECYCLE` a *mode +
  producer* add, not a new engine — matches the row's "land with first producer,
  not label-only" mandate. **Decision needed: which plan physically creates
  `LifecycleStore`?** Plan 1 currently assumes it may need to; if (a), Plan 1
  Slice 2 shrinks to "register conditions into the existing store."

- **C2 — `UnitData.conditions` save-schema migration.** The field today is
  `Array[Dictionary]` of `{ "type": "poison", "turns_remaining": 3 }`. Plan 1
  promotes each entry to reference a `ConditionDef` id + a lifecycle `source_key`.
  That is a **save-schema change** needing an F1 row + a load-time migration for
  any existing suspend saves (there likely are none pre-v1, but the F1 manifest
  and migration default must be explicit). Flagged in Plan 1 Slice 3; calling it
  out here so F1 reserves it deliberately.

- **C3 — `B2-ACTION-EFFECT` vs `B5-SKILLS-EFFECTS` ownership overlap.** The IEQ
  plan says "Band 2 action/effect work should own the open-registry migration
  before broad new item effects land," and `SkillHandler._dispatch` is already a
  registry-in-spirit built in `_ready()`. Plan 1 Slice 4 assumes **Band 2 lands
  the effect-registry seam and Band 5 migrates `SkillHandler` onto it** (not that
  Band 5 invents the registry). Confirm the division: Band 2 owns the effect
  registry primitive; Band 5 owns skill-effect *content* + grant/revoke +
  `on_level_up`. If Band 2's `B2-ACTION-EFFECT` does **not** deliver a general
  effect registry, Plan 1 grows to build it, which changes its size.

- **C4 — cross-plan loadout-shell dependency.** The `LoadoutPanel` shell + skills
  adapter is in **Plan 1** (Slice 5); the styles/sources adapters are in **Plan 2**
  (Slice 6). Plan 2 Slice 6 therefore cannot run before Plan 1 Slice 5. This is
  intentional (Q4: skills adapter first, unblock skills from Source+Style) but is
  a build-ordering constraint the control plane should reflect —
  `B5-LOADOUT-CAPS` is "done enough to ship skills" after Plan 1 and "fully done"
  after Plan 2. Recommend the control-plane `B5-LOADOUT-CAPS` row note this split.

- **C5 — does the v1 AI need to score styles/staves?** The AI chain is drafted as
  parallel and can land before Plan 2. Its Slice 3 scorer scores **weapon
  actions** at minimum; scoring styles/sources at parity needs Plan 2's
  projection hooks. **Question: do v1 demo enemies wield styles or offensive
  staves?** If no (typical for an early demo — enemies plain-attack), the scorer
  needs only weapon tuples for v1 and the style-parity term is a Band 7 add. If
  yes, the AI plan's Slice 3 must wait on Plan 2. *Recommendation: v1 enemies
  plain-attack; style-scoring waits — but this is demo-campaign-dependent (ties
  to Q-B5-1).*

- **C6 — berserk + the AI scorer.** Berserk "overrides target selection" (Q1). A
  berserked **AI-controlled** unit must have the scorer honor the override
  (hostile-to-all targeting, own-side included) rather than the profile weights.
  Minor, but the interaction between the condition targeting-override and the
  scorer's tuple enumeration (Plan 4 Slice 3) should be an explicit test. Not
  currently a slice-level test; flag to add when built.

- **C7 — capability gating should show *disabled-with-reason*, not vanish.** The
  Band 4 audit established the `shown_disabled` degradation convention (a
  blocked action shows greyed with a reason, not removed). Plan 1's capability
  gating disables `ActionMenu` rows for silence/sleep — it should reuse that
  convention (row shown disabled: "Silenced") so players understand *why*, rather
  than the row disappearing. Flagged here; Plan 1 Slice 3 should adopt it
  explicitly.

---

## C. Things deliberately NOT done (correctly deferred)

- The **Q2 content manifest** (exact effect / condition / staff ids) — machinery
  only, per the 2026-07-01 watchout.
- **Gambits, capture-carry, broad AoE, the casual-author preset library** — later
  consumers/content on the finished Source+Style pipeline (Plan 2 Non-Goals).
- **AoE / remote / self-refresh action grants** — later authored extensions
  (Plan 3 Non-Goals).
- **Multi-ply `search_depth`, perception `[PER]`, economy/role valuation `[VAL]`**
  — Band 7, added as registered scorer terms on the Plan 4 engine.
- **Repair/Hammerne staves** — deferred unless durability/broken-weapon content
  is v1 (Plan 2 Slice 5).

---

## D. Recommended next steps

1. Owner resolves Q-B5-1 / Q-B5-3 (via C1) / Q-B5-4, and the demo-facing C5.
2. If C1 lands on option (a), trim Plan 1 Slice 2 to "register into the IEQ
   store" and note the store's owner in both plans.
3. Point the Band 5 control-plane rows at the four new plans; note the
   `B5-LOADOUT-CAPS` two-phase split (C4) and the `B5-DURATION-LIFECYCLE`
   store-owner decision (C1).
4. Regenerate the docs index; `check_docs.py`; commit.
5. Band 5 implementation stays gated on Band 1-3 + `B4-IEQ`; these plans wait
   behind those gates.
