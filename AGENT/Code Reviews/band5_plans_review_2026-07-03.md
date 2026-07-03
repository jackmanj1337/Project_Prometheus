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

- **Q-B5-1 (the Q2 gate) — RESOLVED 2026-07-03: build the full manifest now.**
  Owner reversed the deferral: the v1 content floor is specified up front in
  [`band5_v1_content_manifest_2026-07-03.md`](../Docs/design/band5_v1_content_manifest_2026-07-03.md)
  and the demo campaign is designed to consume it (the memory's "≥1
  player-facing feature per code feature" floor). The plans now ship the manifest
  content directly rather than deferring it to a late slice; `on_level_up` is
  wired regardless. The prune-not-carry rule still holds for anything the shipped
  demo leaves unconsumed.

- **Q-B5-2 — provisionally confirmed.** The four-plan grouping is used as-is.
  Flag if you want the AI chain split further or the loadout shell pulled into
  its own plan.

- **Q-B5-3 (duration-lifecycle boundary) — RESOLVED via C1.** One lifecycle store,
  **owned by `B4-IEQ`** (Slice 5); Band 5 (`B5-DURATION-LIFECYCLE`) adds the
  `until_end_of_map` + fixed-N modes and the condition/skill producers. See C1.

- **Q-B5-4 (forging pull) — RESOLVED 2026-07-03: pull Source+Style forward.**
  `B5-SOURCE-STYLE` is elevated to run as early as its hard gates allow (`B4-IEQ`
  + `B3-RESOURCE-POOLS` + conditions), in parallel with skills/loadout rather than
  after them. The AI scorer (C5) and Band 7 forging (`FRG-18`) both consume its
  effect registry, so it is on the critical path. Forging v1 no longer waits on a
  separate schedule — it builds once Source+Style lands. Plan 2 Purpose /
  Dependency / Commit Order and the control-plane `B5-SOURCE-STYLE` row updated.

---

## B. New concerns surfaced while drafting

- **C1 — the `until_unequipped` ownership seam (feeds Q-B5-3). RESOLVED
  2026-07-03: `B4-IEQ` owns the store.** `B4-IEQ` Slice 5 now builds the shared
  `LifecycleStore` generically (`register` / `remove` / `tick` /
  `clear_end_of_map`, `mode` as registry data) with `until_unequipped` as its
  first mode. Band 5's `B5-DURATION-LIFECYCLE` (Plan 1 Slice 2) adds the
  `until_end_of_map` + fixed-N modes and registers conditions/skills as
  producers — one engine, many producers. Plan 1 Slice 2 shrank from "build a
  store" to "extend the IEQ-owned store"; `B4-IEQ` Slice 5 gained the
  build-it-generically note; the control-plane `B5-DURATION-LIFECYCLE` row
  reflects the ownership. IEQ Slice 5 is now a hard gate for the Band 5
  lifecycle work.

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

- **C5 — does the v1 AI need to score styles/staves? RESOLVED 2026-07-03: yes,
  enemies use staves and styles.** The AI plan's Slice 3 scorer now enumerates
  and scores source+style tuples (staves, dances, combat arts) at parity with
  weapons, through the Plan 2 forecast. Consequence: **the scorer (Plan 4 Slice
  3) now gates on Plan 2 (`B5-SOURCE-STYLE`)** — only the composition half
  (Slices 1-2) stays parallel to the content chain. The AI plan's Purpose,
  Dependency Note, Slice 3, and Commit Order were updated; a test was added for an
  enemy healer/dancer choosing its staff/dance when it scores highest.

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

1. **Done 2026-07-03:** all four owner questions resolved — Q-B5-1 (build the
   full manifest now), Q-B5-2 (four-plan grouping), Q-B5-3/C1 (IEQ owns the
   `LifecycleStore`), Q-B5-4 (pull Source+Style forward), plus C5 (enemies use
   styles/staves). All folded into the plans, the manifest, and the control plane.
2. Remaining are build-time notes, not owner gates: C6 (berserk + scorer test),
   C7 (capability gating shows disabled-with-reason), and the manifest's "open
   content picks" (poison magnitude, which skill showcases `on_level_up`, extra
   combat arts) — content flavor, adjustable freely.
3. Band 5 implementation stays gated on Band 1-3 + `B4-IEQ`. Intra-Band-5 order:
   conditions → Source+Style (pulled forward, parallel with skills/loadout) →
   staves/action-economy; the AI scorer (Plan 4 Slice 3) gates on Source+Style
   (C5).
