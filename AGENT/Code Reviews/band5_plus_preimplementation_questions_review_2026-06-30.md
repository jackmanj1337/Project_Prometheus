---
Role: dated
---

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

## Walkthrough Decisions (2026-07-01)

Owner walkthrough with the agent, settling questions one at a time. V1 scope was
reframed this session: **v1 = Band 5 + Band 6 completion, plus bug fixes and a UI
polish pass.** Bands 7-8 remain optional/parked.

- **Q1 - DECIDED.** Build one combined condition + lifecycle substrate now. V1
  floor = poison, sleep/stun, silence, berserk, plus Restore/Panacea cure hooks
  and the `until_unequipped` / `until_end_of_map` / fixed-N duration modes.
  Silence's action-blocking must be a **general capability-gating primitive**:
  conditions suppress named capability tags (e.g. `attack`, `staff_use`,
  `skill_use`, `move`, `trade`) that actions declare they require. Sleep
  suppresses all; berserk overrides target selection rather than suppressing.
  Adding a condition or a gated capability must stay pure data (no engine edit).
- **Q2 - DEFERRED to a fresh session.** The v1 effect manifest cannot be
  finalized until the v1 demo campaign is designed, because the campaign defines
  which effects are actually consumed. The demo campaign has not been written; it
  will be authored to showcase everything coded, targeting at least one
  player-facing feature per code feature (see the demo-campaign design goal). Come
  back to Q2 (and the `on_level_up` unwired-trigger resolution) after that design
  pass. Default disposition for unconsumed placeholders remains prune-not-carry;
  `on_level_up` is a must-resolve engine trigger, not deferrable content.

- **Q3 - DECIDED.** V1 action-grant slice = single-target, full-turn ally
  refresh. Parameters: range, target filter (same-faction / non-hostile), a
  **named** grant mode (default `refresh_full_turn`), one-refresh-per-unit cap,
  suspend-safe counters, effect-forecast display. AoE / remote / self-refresh are
  wanted eventually but ship as authored extensions on the same pipeline, not in
  v1. Build the refresh on the shared effect pipeline (Q5), express AoE later as a
  shape (Q5 shape registry), and make the anti-loop cap a general per-unit
  per-turn action-budget guard rather than a dance-specific flag.

- **Q4 - DECIDED.** One loadout panel shell with registry-backed category
  adapters (skills, styles, granted sources). Ship the skills adapter first so
  `B5-SKILLS-EFFECTS` is not blocked on `B5-SOURCE-STYLE`; styles/sources plug
  into the same shell + caps logic when Source+Style lands. Each category
  declares its own cap-rule predicate and row renderer (count vs weight vs slot
  differ), so the shell iterates categories rather than hardcoding the three. A
  later category (e.g. battalions) is a registration, not a panel edit.

- **Q5 - DECIDED.** Plan the full Source+Style substrate in one pass: source/style
  model, effect registry, target-filter registry, shape registry (interface now;
  single-tile = a 1-tile shape), cost/projection hooks (must read the Band 2
  resource ledger / projection layer, not embed their own economy), and a
  generalized effect-forecast that renders damage and non-damage outcomes. Prove
  it with exactly two consumers: one hostile style and one utility staff. Gambits,
  capture-carry, and broad AoE content are later consumers of the finished
  pipeline. A larger **preset library for casual authors** is planned but is
  later content built ON the registries, not engine work — presets compose
  existing effect/filter/shape primitives (aligns with the [EXT] author model).

- **Q6 - DECIDED.** V1 utility-staff archetype set (drives Q5 registries; exact
  ids are demo-campaign-gated like Q2):
  - Heal - HP restoration (baseline utility consumer).
  - Restore / Cure - condition removal; the concrete producer that proves Q1's
    Restore/Panacea cure hooks end-to-end.
  - Rescue - positional board mutation; touches Band 2 occupancy (watch
    occupied/illegal-tile and rescue-capacity edge cases).
  - Condition-inflicting staff (e.g. Sleep/Silence) - hostile-targeted utility
    that exercises Q1's condition **apply** path through the staff pipeline, with
    a hit/resist contest routed through the **F16 Requirement/contest primitive
    (`[REQ-10]`)**, not a bespoke roll.
  Repair (Hammerne) deferred unless durability/broken-weapon content is v1. Four
  archetypes = stat restoration, condition removal, positional mutation, and
  condition application; content breadth (Fortify, Physic, Warp, etc.) is later
  data on Q5's pipeline.

- **Q7 - DECIDED.** V1 AI = single-ply deterministic scorer. For each unit,
  enumerate legal (action + target + weapon/source) tuples and score by a weighted
  sum of registry-backed terms, best-with-stable-tie-breaks. V1 terms: immediate
  projected outcome (reuses Q5 projection), survival danger, objective pressure,
  author profile weights. **Scorer terms are a registry from day one** (not a
  fixed 4-term sum), and AI profiles are `AIProfileDef` data (registry, not an
  enum per `[AIP]`); activation order is author-selectable. Band 7 then ADDS
  perception/role/economy terms and multi-ply `search_depth` as new registered
  scorers + richer data - same engine. Reuses the same forecast the player sees so
  AI and UI never diverge. Single-ply is knowingly baitable; the Band 7 valuation
  brain (`[VAL-*]`/`[PER-*]`) is the answer, profile weights partly compensate.

  ---
  *Band 5 (Q1-Q7) fully settled above. Q2 effect-manifest content is the only
  remaining Band 5 gate, and it is demo-campaign-dependent.*

- **Q8 - DECIDED.** One campaign-sharing plan, two slices: package export/import
  first, then a `CampaignStatusRecord` carry-forward slice on top (so import gets a
  real second consumer and the compat/manual-import UI is built once). Status
  facts and import rules stay **data-driven via TCV/resources** - a carry-forward
  fact ("surviving units, gold, chosen flag X") is authored data the engine reads,
  not a fixed struct of named fields; import compatibility is predicate data.
  Targets the self-contained per-campaign pack model (bundle the whole pack incl.
  user art; no shared-base assumption) per the reframed campaign content model.

- **Q9 - DECIDED.** Build the minimal relationship substrate; the v1 demo will
  show off some supports and the roster is small, so support content is cheap.
  Minimal = pair graph (unit<->unit bond levels), data-driven rank profile
  (`RelationshipProfileDef`, C/B/A thresholds as data), gain caps (per-map /
  per-action, anti-grind, baked in from slice 1), and optional conversation-unlock
  hooks fired via TCV conditions ("pair X at rank B") through the existing
  event/dialogue system - no bespoke relationship-scripting engine. Dense support
  trees and rich relationship UI (support logs, affinity grids) deferred. Small
  roster means fuller pairwise coverage is affordable later without engine change.

- **Q10 - DECIDED.** Sequence MRD by save-dependency. No-save slices first (layer
  precedence, hover-peek, path arrows, grid dim) - pure view state recomputed per
  frame from board state, independent of `B1-SUSPEND`. Threat-watch-set
  persistence is the only save-touching slice and trails until suspend state is
  real. Hold the "view state recomputes, only watch-sets persist" line - early
  slices must not cache derived state that quietly grows a save dependency.
  Overlay layers are a **precedence-ordered registry**, not a hardcoded z-order
  `match`, so new overlays (danger tiles, healing zones, objective markers)
  register with a precedence value rather than editing render order.

- **Q11 - DECIDED.** Split the shared_selector_extraction_design's three
  components across the bands rather than moving the whole section. The Band 4
  `PanelSelector` (convoy Slice 4) is already specced panel-generic (kbd+mouse
  focus/selection/cancel/disabled-rows/focus-changed signal; narrow API; DoD#2
  test that convoy AND shop consume it) - keep it. **Pull Component 1 (the pure
  `SelectionCursor` `RefCounted` core) forward into Band 4 and build
  `PanelSelector` ON it**, so there is exactly one navigation core (fixes the
  two-stack risk; the plans currently treat the two as separate). Components 2 & 3
  (input-context owner/arbiter "Rebuild C" + joypad wiring) **stay in Band 6**:
  they are gated on the input-mode-architecture + gamepad-layer keystone that
  convoy/shop neither need nor should wait on, and their real consumers
  (`UnitDetailsScreen`, `AttackPreview`, `HUD` terrain) are not Band 4 features.
  "Both ship in v1" removes release pressure but not dependency ordering - bands
  are dependency layers, not release buckets; keep convoy/shop landable and
  testable (kbd+mouse) independent of the input rebuild. Band 6 EXTENDS (never
  replaces) the `PanelSelector` API and adopts the same cursor core across the
  three More-Info surfaces. Input contexts stay a registry/stack the engine reads.
  Follow-up when plans are next touched: note in the Band 4 convoy/shop plans and
  `shared_selector_extraction_design` that `PanelSelector` builds on
  `SelectionCursor` and that Component 1 lands in Band 4.

- **Q12 - DEFERRED (register held).** The `IMP-1..6` recommendations were reviewed
  and all six read as sound (exported settings tied to `TILE_SIZE`; emit
  `SpriteFrames` data only + `Sprite2D`->`AnimatedSprite2D`; raw->`assets/`,
  generated->`data/`; pure `RefCounted` + headless test; class-keyed selection
  with `unit_id` override later; Priority-1 scope). But the owner is **holding the
  register flip** until asset needs and sourcing are firmer - the licensing gate
  `[LEG-4]` (committed art must be CC0/OGA-BY) means the tool's real inputs must be
  known first. Do NOT ratify `IMP-1..6` or draft `B6-SPRITE-IMPORTER` until asset
  sourcing is decided. Pivoting instead to the campaign-data asset-group taxonomy
  + storage format (see below), which is the upstream decision the importer serves.

- **CAMPAIGN ASSET TAXONOMY + FORMAT - DECIDED (new, replaces the held Q12
  scope).** Builds on the already-locked self-contained pack model (`[ICO-1..6]`):
  art in the package not the save, raw-loaded (no `.import`), referenced by
  `String` path/id via a shared `AssetResolver` with fallbacks. The "no `.import`"
  rule forces two format tiers:
  - **Tier 1 - Media/art (raw-loaded):** unit/map sprite sheets, tilesets, icons
    (item/weapon/resource/effect/condition/skill), portraits, backgrounds
    (dialogue/prep/banner), UI skin (panel styleboxes/button atlas) = **PNG**
    (JPG allowed for opaque backgrounds); fonts = **TTF/OTF**; audio = **OGG
    Vorbis** (WAV allowed for short SFX).
  - **Tier 2 - Structured data (schema-validated via `DataManager`):** content
    resources (weapons/items/classes/skills/conditions/effects/styles), campaign
    graph, rules, `MapData`, labels/localization, registry display metadata
    (`label_key`/`icon`/`help_key`), pack manifest (id/version/`forked_from`/
    `builder_content_version`/`format_version`) = **JSON, canonical** (owner
    decision). JSON is the single on-disk + loaded source of truth (same family as
    save JSON + integrity hash); the built-in default palette may be authored as
    `.tres` in-editor and serialized to JSON at build, but user packs are pure
    JSON. Cost accepted: build JSON<->Resource load/validate per content type
    (DataManager validator culture already exists).
  - **Proposed pack layout:** `user://campaigns/<pack_id>/` with `manifest.json`,
    `data/`, `art/{icons,portraits,backgrounds,sprites,tilesets,ui}/`, `fonts/`,
    `audio/{music,sfx}/`.
  - **Extensibility:** asset groups are registry-backed (a new group registers a
    resolver + fallback chain, no engine edit); fallback chain per the UI-designs
    review (missing icon -> text row, missing portrait -> silhouette, etc.).
  - **Follow-ups:** (a) a dedicated asset-format design note + update
    `campaign_save_expectations...` / `content_pack_compatibility_resync_contract`
    and regenerate the docs index; (b) **spike to verify the Godot 4 runtime
    raw-load API for OGG audio and TTF fonts from `user://` in an exported build**
    (PNG via `Image.load_from_file` is confirmed; audio/font loader seam is not).

- **Q13 - DECIDED (firmed, no longer deferred; v1 option, may slot later in v1).**
  Per-map overrides are IN v1 with a **3-layer rule resolver** (highest wins):
  mid-map (triggered) overrides > per-map rules > campaign rules/defaults.
  - **Per-map override lifecycle:** begins on node/map selection, ends on map
    clear OR cancel.
  - **Triggered (mid-map) override:** carries a `revert_scope` parameter -
    either revert to defaults at end of map, OR permanently change the campaign
    defaults.
  - **Suspend:** per-map override state, active mid-map overrides, and any
    permanent campaign-default mutations all survive a suspend save.
  - **Implication 1 - extends, not replaces, the story-flip seam.** The mid-map
    triggered override IS Band 3's `apply_rule_flip` (`[CST-4/6/11]`), now with a
    `revert_scope` param and as the top layer of the resolver. So Band 3 must
    build the **3-layer resolver**, not just leave a seam (upgrades the earlier
    "leave the seam" rec). Respect existing mandate(locked)/default/`protected_
    fields` semantics.
  - **Implication 2 - campaign rules become mutable runtime state.** "Permanently
    change campaign defaults" means the save must persist the **current effective
    campaign defaults** (or a patch-log of permanent changes), not just a
    reference to the authored campaign. Net-new F1 save schema that **overlaps
    Q8's `CampaignStatusRecord`** - unify into one "mutable campaign state" store
    rather than two carry-forward mechanisms.

- **Q14 - PARTIALLY DECIDED.** Optional Band 7 systems selected by demo intent:
  - **Arena - likely selected** for the demo; still gated on death + economy
    being stable first (it consumes both).
  - **Stationary/emplaced weapons - likely selected** for the demo (siege / fixed
    emplacement tactics).
  - **Battalions, BWN - not selected**; plan only if a map/mode later needs them.
  - **PvP (`B7-PVP`) - not committed**, but the multi-prepper prep-screen handling
    is a design topic to settle separately (see PvP Prep note below). Each selected
    system is a consumer of existing primitives (arena = map-type + reward hook +
    combat/economy; emplaced = map-object + weapon), so selection is composition,
    not new engine.

- **PvP PREP SCREENS (multi-prepper) - DESIGNED 2026-07-01** (separate from
  committing `B7-PVP`; near-term topology is local **hotseat** - networked play =
  `B8-REMOTE-PLAY`, parked, needs deterministic/suspend foundations).
  - **Structural model:** prep is a **"prep session" iterating an ordered list of
    side-descriptors** `{controller: human|AI, roster_source, deployment_zone}`.
    Single-player = 1 human side (+ AI sides skip prep); PvP = 2 human sides
    iterated sequentially with a handoff/curtain between consecutive human sides;
    co-op later = 2 human sides same faction. Driven by a list of sides, not a
    hardcoded 1P-vs-2P branch (open-registry). Reuses the existing per-side prep
    panel; net-new = the session controller, per-side scoping (each side sees only
    its own roster + zone), draft screen, and the curtain.
  - **Roster source = shared draft pool (owner decision).** Author defines a pool
    + budget/points cap; each player drafts an army under the cap, then deploys.
    Adds a draft screen before deploy + points validation.
  - **Secrecy = zones public, placements hidden (owner decision).** Both players
    can see WHICH tiles each side may deploy to (deployment zones are public on the
    map), but NOT which unit ended up on which tile - unit->tile placement (and
    likely drafted composition) is hidden until battle start. Lighter than full
    fog: prep secrecy needs only sequential hotseat + a curtain during draft/deploy
    + reveal-all at battle start; in-battle fog is a separate optional concern.
  - **Dependencies surfaced:** map needs **per-faction deployment zones**
    (per-side start-tile sets), not one shared start set; hotseat suspend saves the
    whole prep-session state as one file (single machine).
  - **Minor open point:** confirm whether a player's drafted roster *composition*
    is revealed pre-battle or hidden with placements (lean: hidden - keep the
    curtain over draft too, zones stay public).

- **Q15 - DECIDED (elevated).** The demo WILL include forging, so `B7-FORGING`
  moves from parked to a **near-term full design pass** (open a `FORGE` register
  before any implementation plan). This makes forging effectively demo/v1-adjacent
  content despite being a Band 7 row - flag for a control-plane status bump. The
  design pass must settle: (1) upgrade model (stat bumps / new tiers / both),
  (2) cost/resource model via the `ResourceLedger`, (3) **item-upgrade state -
  forged items are per-instance state** (a +2 Iron Sword must persist through
  save / convoy / trade), (4) shop/service UI where forging lives. **Dependency to
  verify now:** the item/equipment model must be able to carry **per-instance
  upgrade state** (not just per-type item defs) - confirm `B4-IEQ` leaves room for
  this even though forging builds later. When built: a service applying registered
  upgrade effects to an item instance, tiers/costs as data (no hardcoded forge
  table).

- **Q16 - DECIDED (deferred, research-only).** The demo does not need AI-side
  recruitment/purchasing immediately, so `B7-AI-RECRUITMENT` stays research-only,
  no implementation plan yet. When it lands: a **deterministic scripted rule set**
  (affordable visible stock, authored priority tags, minimum reserve resources,
  spawn availability, deterministic tie-breaks) gated on Band 4 economy being
  stable - not the role/economy valuation brain. Priority tags + reserve rules are
  author data (an AI-recruitment profile, same idiom as `AIProfileDef` in Q7); the
  later valuation pass ADDS scoring terms to the same profile rather than replacing
  the rule engine.

- **Q17 - DECIDED (all parked).** Nothing in v1 (Band 5+6) touches Band 8; keep
  every row review-gated with its specific un-park trigger: `B8-ACTIVITIES`
  (side-activity template/prototype decision; still parked), `B8-PUBLIC-BUILDER`
  (gameplay + package rules stable), `B8-CONTENT-RESYNC` (public authoring exists),
  `B8-REMOTE-PLAY` (deterministic + suspend foundations proven; also gates
  networked PvP), `B8-LAGUZ`/`B8-AWAKENING` (a content pack adopts the mechanic),
  `B8-HEX` (product decision for hex maps), `B8-PERCEPTION` (specific fog/masking
  product case - NOT pulled in by PvP secrecy, which is reveal-at-battle-start;
  un-parks WITH the Band 7 AI brain as its keystone), `B8-ML-EVAL` (research/eval
  milestone), `B8-VISION-PRO` (after web release ships). Each stays a consumer of
  existing seams, so parking costs nothing structurally; each must land as a
  registry when un-parked, never an engine special-case.

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

