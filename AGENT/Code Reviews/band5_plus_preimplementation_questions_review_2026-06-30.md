# Band 5+ Preimplementation Questions Review (2026-06-30)

**Scope:** Bands 5-8 in
[`project_control_plane_2026-06-29.md`](../Docs/plans/project_control_plane_2026-06-29.md),
plus the source plans/registers they point at. This is a review queue for
questions to settle before writing implementation plans. It is not an
implementation plan.

## Executive Summary

Most Band 5+ mechanics already have resolved design registers. The blockers are
mostly plan-shaping questions: what v1 subset to build, which optional systems
actually enter v1 content, and where shared UI/selector/asset work is owned.

Recommendation: draft Band 5 in small grouped plans rather than one large plan:
`B5-CONDITIONS` + `B5-DURATION-LIFECYCLE`, `B5-SOURCE-STYLE` + utility staves,
`B5-SKILLS-EFFECTS` + `B5-LOADOUT-CAPS` + `B5-ACTION-GRANT` +
`B5-SECONDARY-MOVEMENT`, and an AI plan for `B5-AI-COMPOSITION` +
`B5-AI-MIN-SCORER`. Bands 6-8 should only get plans when their scope gate below
is answered.

## Band 5 - Tactical V1 Enrichment

### Q1 - How much of the condition system is v1?

- **Rows:** `B5-CONDITIONS`, `B5-DURATION-LIFECYCLE`.
- **Question:** Is the first condition plan the full author-extensible F5
  lifecycle, or a v1 condition floor plus registry/lifecycle seams?
- **Why it blocks planning:** The control-plane next action says to rewrite M8
  around registry/condition lifecycle before build. Duration labels should land
  with their first real producer, not as label-only work.
- **Recommendation:** Plan one combined condition/lifecycle substrate with a
  small v1 content floor: poison, sleep, silence, berserk/stun if v1 content
  needs them, Restore/Panacea hooks, `until_unequipped`, `until_end_of_map`, and
  active-condition save rows. Leave exotic condition content to content plans.

### Q2 - Which skill/effect ids are required v1 content?

- **Rows:** `B5-SKILLS-EFFECTS`, `B5-LOADOUT-CAPS`, `B5-ACTION-GRANT`.
- **Question:** Which existing placeholder skills/effects must ship in v1, and
  which should be pruned or explicitly optional?
- **Why it blocks planning:** The row explicitly says to split required v1 ids
  from optional content ids. The atlas also flags `on_level_up` as declared but
  unwired; the plan must either wire it or remove/drop that trigger from v1.
- **Recommendation:** Make a short v1 effect manifest before the plan. Include
  only effects consumed by v1 classes/items/maps and the action-grant/dancer
  slice. Put optional skill content behind content rows.

### Q3 - What is the bounded v1 action-grant slice?

- **Row:** `B5-ACTION-GRANT`.
- **Question:** Does v1 build only single-target Dance/Reinvigorate, or also
  AoE/special dance variants and broader grant modes?
- **Why it blocks planning:** The register supports more than the likely v1
  need. The control plane asks for a bounded dancer slice.
- **Recommendation:** Start with one activated ally-refresh skill, default full
  turn, range parameter, same-faction/non-hostile target filter, one-refresh cap,
  suspend-safe counters, and effect forecast display. Reserve AoE/multi-target
  and self-refresh as authored extensions after the single-target path is stable.

### Q4 - Is loadout management grouped with skills or Source+Style?

- **Rows:** `B5-SKILLS-EFFECTS`, `B5-LOADOUT-CAPS`, `B5-SOURCE-STYLE`.
- **Question:** Should the loadout cap panel plan land with skills/grants or
  wait for Source+Style learned/equipped styles and granted sources?
- **Why it blocks planning:** `LDC` covers skills, styles, and granted sources.
  A skill-only panel risks needing a rewrite when styles/sources arrive.
- **Recommendation:** Plan a single loadout panel shell with three registered
  categories, but implement category adapters incrementally. Skills can ship
  first; styles/sources plug into the same panel when Source+Style lands.

### Q5 - What is the minimum Source+Style implementation plan scope?

- **Row:** `B5-SOURCE-STYLE`.
- **Question:** Does the plan include combat arts, utility staves, capture
  hooks, AoE, gambit-compatible shapes, and full effect forecast in one pass?
- **Why it blocks planning:** Source+Style is the shared pipeline for many
  features. Overbuilding it risks a large plan; underbuilding it risks a second
  action pipeline.
- **Recommendation:** Plan the pipeline, registry, target filters, shape
  registry, cost/projection hooks, and generalized effect forecast first. Then
  implement one hostile style and one utility staff as proof consumers. Gambits
  and capture-carry stay as later consumers.

### Q6 - Which utility staves are v1?

- **Row:** `B5-UTILITY-STAVES`.
- **Question:** Which staff effects are part of the v1 content floor?
- **Why it blocks planning:** Utility staves depend on conditions and
  Source+Style. The exact list drives effect kinds, targeting, projection, and
  tests.
- **Recommendation:** Pick a small set before the plan: heal, restore/cure,
  warp or rescue, and repair only if item-use state is ready. Keep Hammerne-like
  repair optional if durability/broken-weapon content is not v1.

### Q7 - What is the bounded v1 AI scorer?

- **Rows:** `B5-AI-COMPOSITION`, `B5-AI-MIN-SCORER`.
- **Question:** What minimum scorer is enough for first campaign maps without
  advanced search/perception?
- **Why it blocks planning:** The advanced valuation register is Band 7. Band 5
  needs a small deterministic scorer, not the final AI brain.
- **Recommendation:** Define a v1 scorer that chooses legal action + target +
  weapon/source by immediate projected outcome, survival danger, objective
  pressure, and author profile weights. Leave multi-turn search, perception, and
  role/economy scoring to Band 7.

## Band 6 - V1-Lean / Stretch Packs

### Q8 - Is campaign sharing planned with status records or separately?

- **Rows:** `B6-CAMPAIGN-SHARING`, `B6-CAMPAIGN-STATUS`.
- **Question:** Should the first implementation plan cover package export/import
  and `CampaignStatusRecord` together?
- **Why it blocks planning:** Status records depend on the import/export path
  and need chosen-record save fields. Planning them separately may duplicate
  compatibility and manual-import UI.
- **Recommendation:** Draft one campaign sharing/import plan with a status-record
  slice. Keep status facts and import rules data-driven through TCV/resources.

### Q9 - What is the relationship minimum for v1?

- **Row:** `B6-RELATIONSHIP-MIN`.
- **Question:** Build a minimal relationship graph in v1, or defer the whole
  feature?
- **Why it blocks planning:** The control plane explicitly says to decide v1
  minimum vs defer during the GDD rewrite.
- **Recommendation:** If included, plan only pair graph, rank profile, gain
  caps, and optional conversation unlock hooks. Defer dense support content and
  rich relationship UI.

### Q10 - Which map readability slices need save support?

- **Row:** `B6-MRD`.
- **Question:** Should threat watch sets persist through suspend, or should
  early MRD slices avoid save state?
- **Why it blocks planning:** The control row says early slices can build
  independent of suspend, but watch-set persistence depends on `B1-SUSPEND`.
- **Recommendation:** Plan early no-save slices first: layer precedence,
  hover-peek, path arrows, grid dim. Add watch-set save only after suspend state
  is real.

### Q11 - Who owns shared selector/input extraction?

- **Rows:** `B6-INPUT`, `UI-INSPECTION`, Band 4 convoy/shop plans.
- **Question:** Does Band 6 own the final `SelectionCursor`/input-context
  extraction, while Band 4 owns only the thin `PanelSelector` used by
  convoy/shop?
- **Why it blocks planning:** Convoy/shop need functional panels before full
  gamepad support. Building two selector stacks would create avoidable UI debt.
- **Recommendation:** Treat Band 4 `PanelSelector` as the first reusable panel
  selector. Band 6 then extracts/extends shared input ownership and More-Info
  navigation without replacing the Band 4 selector API.

### Q12 - Resolve the map sprite importer open decisions.

- **Row:** `B6-SPRITE-IMPORTER`.
- **Question:** Which importer scope, asset-id policy, and tested tool pipeline
  are accepted?
- **Why it blocks planning:** This row is still `Open decision`; the next action
  says to resolve IMP decisions before implementation.
- **Recommendation:** Do not draft the implementation plan until the importer
  register is resolved. Minimum useful scope should include headless parsing,
  deterministic output, asset-id validation, and clear fallback placeholders.

### Q13 - When does per-map override scope get a real plan?

- **Row:** `B6-PER-MAP-OVERRIDES`.
- **Question:** What concrete content case requires per-map overrides?
- **Why it blocks planning:** The row is Deferred and only exists because Band 3
  deliberately chose campaign-default-only for v1.
- **Recommendation:** Do not write a plan until a map needs it. When needed,
  settle override resolution order, revert timing, and save rows first.

## Band 7 - Optional After Stable Core

### Q14 - Which optional systems are actually selected?

- **Rows:** `B7-BWN`, `B7-ARENA`, `B7-BATTALION`,
  `B7-STATIONARY-WEAPONS`, `B7-PVP`.
- **Question:** Which optional systems are needed by the first stable campaign or
  demo?
- **Why it blocks planning:** These are designed, but optional. Writing plans for
  all of them before content need may create schedule noise.
- **Recommendation:** Only plan one when a content/demo use case exists. Arena
  can plan after death/economy are stable; stationary weapons only if maps need
  siege; battalions only if v1 scope revisits a narrow slice.

### Q15 - Forging still needs design.

- **Row:** `B7-FORGING`.
- **Question:** What is the player-facing forging model, cost/resource model,
  item-upgrade state, and shop/service UI?
- **Why it blocks planning:** The control row says `needs design`, unlike most
  Band 7 rows.
- **Recommendation:** Create a design/register pass before any implementation
  plan. Keep it post-core unless durability/weapon-upgrade content becomes v1.

### Q16 - What is the first AI recruitment pass?

- **Row:** `B7-AI-RECRUITMENT`.
- **Question:** What deterministic scripted purchase rule ships before smarter
  role/economy valuation?
- **Why it blocks planning:** The row says `needs research then implementation
  plan`.
- **Recommendation:** Research one small rule set first: affordable visible
  stock, authored priority tags, minimum reserve resources, spawn availability,
  and deterministic tie-breaks. Advanced role coverage belongs later.

## Band 8 - Post-v1 / Parked

### Q17 - What owner event un-parks each Band 8 row?

- **Rows:** `B8-ACTIVITIES`, `B8-PUBLIC-BUILDER`,
  `B8-CONTENT-RESYNC`, `B8-REMOTE-PLAY`, `B8-LAGUZ`,
  `B8-AWAKENING`, `B8-HEX`, `B8-PERCEPTION`, `B8-ML-EVAL`,
  `B8-VISION-PRO`.
- **Question:** What content/release decision moves a parked row into active
  planning?
- **Why it blocks planning:** Most rows explicitly say future triage or future
  plan. They should not consume implementation-plan time until scope changes.
- **Recommendation:** Keep Band 8 as review-gated. Activities need a template
  prototype decision before public scripting; public builder needs gameplay and
  package rules stable; content resync needs public authoring; remote play needs
  deterministic/suspend foundations; Laguz/Awakening need content adoption;
  hex/perception/ML/Vision Pro each need a specific owner-approved product case.

## Cross-Band Planning Questions

1. **Plan grouping:** Should Band 5 use the four grouped plans recommended in
   this review? Recommendation: yes, because conditions/lifecycle, action
   pipelines, loadout/action economy, and AI have separate risk profiles.
2. **V1 content floor:** Before writing Band 5 plans, define the minimum
   condition ids, skill effect ids, utility staff effects, and AI profiles that
   v1 maps actually require.
3. **UI ownership:** Panel selectors and effect forecasts must be shared assets
   of the UI layer, not private per-feature widgets.
4. **Open registries:** Every growable author vocabulary above must stay
   registry-backed: condition ids, skill/effect ids, source/style effects,
   target filters, shapes, AI profiles, panel/activity ids, resources, and
   import/status facts.

