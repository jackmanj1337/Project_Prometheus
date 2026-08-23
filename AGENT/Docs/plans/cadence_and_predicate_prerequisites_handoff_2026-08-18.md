---
Role: dated
Type: plan
Status: Active — next-session execution handoff; build the B3 predicate foundation before cadence
Last verified: 2026-08-19
Tracker: DESIGN-OVERWORLD-CADENCE-2026-07-25, B3-REQ-F16-BUILD-2026-08-18-2026-08-19
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# Cadence and Predicate Prerequisites — Handoff (2026-08-18)

## Next session — the assignment

**Build `B3-REQ` / F16, including the minimum prerequisites that are genuinely absent. Do not start
the cadence engine.** The session ends with a shared requirement evaluator that works without a map,
renders structured unmet reasons, and has one non-breaking bridge for existing battle objectives.

Start from current `agent/integration` with the workspace launcher:

```bash
scripts/agent-work --repo Project_Prometheus start --tool codex \
  --slug b3-req-f16 --area engine/requirement-predicate \
  --path scripts/req --path scripts/autoloads/RequirementSystem.gd \
  --path scripts/resources/CampaignRules.gd --path scripts/autoloads/RegistryManager.gd \
  --path scripts/tests/test_requirement.gd --path scripts/tests/test_formula_evaluator.gd \
  --path project.godot
```

Before accepting those paths, re-check the coordination registry. Expand the claim only for the
prerequisite files selected by the preflight below; do not silently take a path another row owns.

### Preflight verdict as of `agent/integration` `4d7f9b63` (2026-08-19)

- `B2-REGISTRY` is **implemented**. `RegistryManager`, `RegistryCatalog`, the open-registry tests,
  and the control-plane row all agree. It is not a blocker and needs no new tracker row.
- `B3-TCV` is **not implemented**. `CampaignManager.campaign_vars` is an untyped dictionary;
  `CampaignVarDef.gd`, `CampaignVars.gd` and `test_campaign_vars.gd` do not exist. Slice 5 cannot
  honestly claim typed variable predicates until Slice 4's definition/store seam exists.
- `B3-TEXT` is **not implemented**. The existing `scripts/ui/text_entry/` service handles player
  input; it is not the stable text-key registry required by `REQ-5`.
- The control plane contains a stale cycle: its `B3-TCV` row names `B3-REQ`, while the Band 3
  plan's explicit bootstrap order requires `B3-TCV` **before** `B3-REQ`. Follow the plan: TCV is a
  producer for REQ, not a consumer. Correct the control-plane row and tracker graph in the same
  session before implementation.

### Required session shape

1. Register dedicated `B3-TCV` and `B3-TEXT` build rows in `coordination/tasks.json`; make
   `B3-REQ-F16-BUILD-2026-08-18-2026-08-19` depend on both. Do not hide prerequisite builds inside
   the REQ row merely to preserve a one-session label.
2. Build the minimum complete `B3-TCV` Slice 4 and text-key seam required by Slice 5. Each is a
   separately green commit. The text seam may be narrow, but it must resolve keys and fail loud;
   hardcoded English inside predicate evaluators is not an acceptable substitute.
3. Build Slice 5 in vertical commits: data/schema and validation; formula evaluator; predicate
   registry/context/evaluation; render-to-text; existing-objective bridge.
4. Run the full suite, update the affected GDD and roadmap status in the behavior-changing commit,
   record the exact branch/commit/test result on all three tracker rows, and push the feature branch.
5. Stop. Do not implement cadence triggers, prep availability adapters, the overworld surface, or
   any other downstream consumer in this session.

If the prerequisite work cannot fit safely in one session, the correct stopping point is a pushed,
green TCV/text prerequisite branch with `B3-REQ` still `planned`. It is not acceptable to weaken
typing, localization, or `REQ-8` compatibility to make the REQ checkbox close.

Two sessions, both surfaced by the `CVS` walk
([session note](../../Session%20Notes/2026-08-18-22-10-00Z-convoy-shop-cvs-walk.md)), both sitting
in front of `PREP-V1-S01` — the first slice of the prep/economy build and therefore of v0.8.0's
second half.

They are handed off together because **B's platform prerequisites come first and A depends on B**:
the registry base already exists, while typed variables and text indirection do not. The cadence
engine's predicate triggers are `REQ` predicates, so building A first would fork a second predicate
evaluator. Run **B, then A** — or run A's *design* half in parallel with B's build, but do not let
A's build start first.

| | Session | Tracker row | Blocks |
|---|---|---|---|
| **A** | Cadence engine spec + overworld traversal surface | `DESIGN-OVERWORLD-CADENCE-2026-07-25` | `PREP-V1-S01` |
| **B** | `B3-REQ` / F16 — build the shared requirement/predicate system | `B3-REQ-F16-BUILD-2026-08-18-2026-08-19` (**new**) | A, `PREP-V1-S01`, and eight other tracks |

## 0. One correction to carry in, before either session starts

The `CVS` session note says "the shared condition/predicate registry the cadence model assumes does
not exist in campaign scope". **That is true of the code and false of the design.** `REQ-1..16` is
`RESOLVED` (2026-06-25r / 2026-06-26) and specifies the whole system — boolean tree, typed
predicates, subject selectors, value terms, fixed-point arithmetic, render-to-text, save treatment,
consumer reconciliation. `B3-REQ` owns the build and
[`band3_core_authoring_foundations_implementation_plan_2026-06-30.md`](band3_core_authoring_foundations_implementation_plan_2026-06-30.md)
**Slice 5** specifies the files, the canonical JSON serialization and the tests.

Neither session may re-derive any of that. Session B is an **implementation** session against a
ratified spec, not a design walk.

## 1. What made this a handoff rather than a note

Three defects in the graph, each of which hides the same work:

1. **`B3-REQ` had no tracker row.** It is a control-plane Track ID with a fully specified plan slice
   and it appears in `coordination/tasks.json` **only inside two completed rows' prose**. That is
   the invisibility failure `AGENTS.md` names — open work recorded only in a plan is invisible to
   anyone not reading that plan. A row is created with this handoff.
2. **`PREP-V1-S01` depends on the wrong thing for its predicates.** Its dependency list names
   `ENGINE-PREDICATE-UNMET-REASON-2026-07-26`, which is `completed` — closed by precedence on
   2026-08-13 because `REQ` owns predicate descriptors and `[EPUX-07]` ratified the reason contract.
   So the row's only predicate edge points at a **closed design row**, and nothing in the graph makes
   it wait for the predicate *code*. Fixed with this handoff by adding the new row to its
   dependencies.
   **And the same hole is wider than one row:** `B3-TCV` and `B3-TEXT` are unbuilt and have no
   tracker rows. `B2-REGISTRY`, however, is implemented; the earlier handoff incorrectly grouped it
   with the missing rows. The next session must create the two real prerequisite rows and dependency
   edges before writing implementation code.
3. **`DESIGN-OVERWORLD-CADENCE` is parked at `S13`** — Stage D residue — in
   [`research_and_discussion_sequencing_2026-08-13.md`](research_and_discussion_sequencing_2026-08-13.md),
   while `PREP-V1-S01` depends on it. The first build slice is blocked by a row scheduled last. The
   sequencing plan is claimed by `RESEARCH-SEQUENCING-2026-08-13-2026-08-13`; this is reported there,
   not edited here.

## 2. Session B — `B3-REQ` / F16, the shared requirement/predicate system

**Read first:** `REQ-1..16` in
[`requirement_predicate_system_open_questions_2026-06-25.md`](../registers/requirement_predicate_system_open_questions_2026-06-25.md),
then Slice 5 of the Band 3 plan. Slice 5 already lists the files to create
(`scripts/req/Requirement.gd`, `Predicate.gd`, `ValueTerm.gd`, `FormulaEvaluator.gd`,
`scripts/autoloads/RequirementSystem.gd`, the `CampaignRules` budget fields, the two test suites) and
the canonical v1 JSON projection. Build that.

Also read Slice 4 (`B3-TCV`) and the `B3-TEXT` slice before branching. Slice 5's typed-variable and
render-to-text promises are not optional subfeatures; they establish its build order.

### Measured code state (verify before assuming any of it still holds)

- **`ObjectiveConditionRegistry`** is the only working predicate registry and it is **battle-scoped**:
  `evaluate(cond: ObjectiveCondition, for_group: String, game_state: Node) -> bool`. Its shape is the
  right one — entries loaded from `res://engine_data/registries/objective_conditions`, with separate
  validation, display and evaluation handler tables — but its evaluation context is a live map.
- **`RequirementFormulaRegistry`** is a static `evaluate(definition, facts, depth) -> FormulaResult`
  with `MAX_DEPTH = 8` and **no production callers — only `test_formula_registries.gd`**. It is the
  closest thing to `REQ-16` that exists, and it is the natural seed of `FormulaEvaluator.gd`. Decide
  deliberately whether it is grown or replaced; do not leave two.
- **`AutosaveTriggerRegistry`** (`register` / `dispatch` / `has_trigger`) is the precedent shape for
  a small engine-side registry, and `CampaignManager.dispatch_autosave_trigger()` shows the calling
  convention.
- Campaign-scope state a predicate must read already exists on `CampaignManager`: `campaign_flags`,
  `campaign_vars`, `cleared_node_ids`, `current_node_id`, carry-forward facts, and
  `CampaignStatusStore`.

### The one thing Slice 5 does not settle, and this session must

**How a predicate is evaluated when there is no `game_state`.** Every consumer below evaluates in
prep, on the node graph, or in a menu. `RequirementFormulaRegistry`'s fact-dictionary shape suggests
the answer — build the context, hand it to the evaluator — but the existing
`ObjectiveConditionRegistry` consumers pass a live node, so the two have to be reconciled rather
than left side by side. `REQ-8` (consumer reconciliation, non-breaking) is the ratified constraint:
existing objective conditions keep working.

### Consumers waiting on this, so the API is designed once for all of them

Cadence triggers (session A), `[EPUX-02]` activity availability evaluated in the shell per
`[EPUX-04]`, `[EPUX-07]`'s unified unmet-reason string — which is `REQ-5`'s render-to-text and is
the reason `ENGINE-PREDICATE-UNMET-REASON` could be closed by precedence — `[DSX-S21]`'s pending-tray
prep-exit gate, per-node `prep_panels` gating (`PHB`), shop `stock_gate` (`SAC`), `[CVS-S2]`'s
per-instance key-item properties where an author gates on them, and `[DRC-30]`'s provider policy.

**Exit criteria:** `test_requirement.gd` and `test_formula_evaluator.gd` green; one existing
objective condition migrated or explicitly bridged per `REQ-8`; a predicate evaluated from prep with
no map loaded; and a rendered unmet-reason string produced through `REQ-5`. In addition, the new
`test_campaign_vars.gd` and text-key missing-reference tests are green, the TCV/REQ graph is acyclic,
and no second formula evaluator or free-form campaign-variable store was introduced.

## 3. Session A — the cadence engine and the overworld map

**Read first:** `EPUX` §Node traversal and cadence model in
[`prep_economy_bundle_comparative_research_and_questions_2026-07-25.md`](../design/prep_economy_bundle_comparative_research_and_questions_2026-07-25.md).
That model is **owner-ratified and complete** — trigger families, latching, composition, real-time
deferral, save treatment. This session does not reopen it; it turns it into a specification and a
build.

### A1 — Finish the fold (the row's own outstanding item)

[`prep_economy_implementation_plan.md`](prep_economy_implementation_plan.md) §4.7 and the
`PREP-V1-S01` slice carry the model at **summary level only**. What a builder still cannot read
anywhere:

- the **trigger descriptor schema** — the authored shape of `chapter_reached`, `chapters_elapsed`,
  `deployments_total`, `hours_played` in their `every N` / `after N` forms, and of a predicate
  trigger referencing a `REQ` `Requirement`;
- the **evaluation points** — when counters tick and when triggers are evaluated (node advance,
  prep entry, activity exit, save load), which decides whether a restock can land mid-visit;
- the **subscriber binding format** — how a node property names the trigger it subscribes to, for
  all four subscribers (available activity set, battle target, activity variant, stock), including
  the **restock cadence reference `[CVS-S6]` has now defined**: entity-level with a per-entry
  override, tick resets by default, increment-to-ceiling author-selectable, re-roll out of v1;
- the **durable state shape** — counter values, latched predicate states, consumed/played flags and
  the per-node variant pointer, against the `f1_save_schema_manifest`;
- the **clock seam** — the mockable, injectable interface real-time cadence ships disabled behind.

### A2 — Build the overworld traversal surface (owner ruling, 2026-08-18)

**The map surface is in v1.** Nothing owns it today: §4.7 and the plan's overview sentence mention
the optional author-enabled map, and no slice or row builds it.

What exists already, measured — this is a surface and a revisit rule, not a data model:
`CampaignNode` carries `node_id`, `next_node_ids` and `is_terminal()`; `CampaignManager` carries
`current_node_id`, `cleared_node_ids`, `get_pending_successor_options()`,
`choose_pending_successor()`, `commit_pending_result()` and `capture_/restore_campaign_state()`.

What is missing: the map screen itself; navigation **back into cleared nodes** (today advance is
forward-only through successor options); the per-campaign linear-vs-free-roam authoring flag; and
the re-entry defaults that make free revisit safe — shops persist stock and restock on cadence,
battle and story nodes one-shot unless marked repeatable, events fire-once unless re-fireable.

**Scope boundary to hold:** the map is a *screen*, so it is bound by the responsive programme and
the size classes, and it must not grow a second node-advance path beside
`CampaignManager.prepare_pending_advance()` / `launch_prepared_node()`. One advance, two entry
points.

### Decisions settled by the owner in session A (2026-08-19)

1. The overworld is a **responsive canvas screen**: shared size-class-responsive chrome surrounds a
   graph region governed by canvas pan/zoom behaviour.
2. Revisiting a cleared node **re-enters its prep hub**; activities keep the ordinary hub path.
3. Revisit performs a cadence evaluation but advances **no** chapter or deployment counter. A
   subsequently launched battle is a real deployment event and advances deployment cadence.

## 4. Order, and what is explicitly out of scope

1. **B**, because A's predicate triggers are `REQ` predicates.
2. **A1**, which is specification and can overlap B's build.
3. **A2**, the surface.
4. Then `PREP-V1-S01` is unblocked on this axis.

Out of scope for both: re-roll restock (`[CVS-S6]`, post-v1 with `RNG`/determinism), real-time
cadence (`EPUX`, post-v1 behind the clock seam), and any re-litigation of `REQ-1..16` or the `EPUX`
cadence model.
