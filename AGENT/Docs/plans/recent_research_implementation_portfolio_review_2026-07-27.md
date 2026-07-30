---
Type: implementation plan
Status: Accepted — implementation portfolio
Last verified: 2026-07-27
Tracker: PLAN-RECENT-RESEARCH-SYSTEMS-2026-07-27
---

# Recent Research — Implementation Portfolio and Cross-Plan Review

**Managed by:** [`project_control_plane_2026-06-29.md`](project_control_plane_2026-06-29.md). The
cross-branch inventory and next-session ownership live in `coordination/tasks.json` under
`PLAN-RECENT-RESEARCH-SYSTEMS-2026-07-27`.

## 1. Scope and evidence rule

This portfolio covers research/discussion completed or materially resolved from 2026-07-23 through
2026-07-27. `coordination/tasks.json` is the inventory authority. Some source documents and plans are
currently present only on `agent/from-integration/campaign-data-research`; they were reviewed with
`git show` at that branch rather than assumed to exist in the current checkout. They must be
consolidated through the agent release flow before product implementation depends on them.

Verdicts mean:

- **Accepted plan:** implementation slices are sufficiently concrete; apply listed cross-plan
  amendments before or during the owning slice.
- **Plan supplied here:** accepted research lacked one integrated implementation sequence; this
  portfolio supplies the minimum slice/dependency/test contract.
- **Separate integrated plan:** detailed plan exists in this branch and this portfolio reviews its
  boundaries.
- **Deferred/no-build:** tracked research intentionally produces no V1 product slice.

## 2. Planning inventory

| Research/discussion stream | Authoritative source | Plan evidence | Review verdict |
|---|---|---|---|
| Economy ownership | `campaign_data_ownership_research_findings_2026-07-23.md` | `multi_owner_economy_implementation_plan_2026-07-23.md` on campaign-data branch | Accepted with custody/Convoy ownership amendment. |
| Pack-associated saves | same findings | `pack_associated_save_implementation_plan_2026-07-23.md` | Accepted with five-dimensional state, custody, event history, and atomic-workflow reservations. |
| Zero-content engine | same findings | `zero_content_engine_implementation_plan_2026-07-23.md` | Accepted with new Dialogue/activity/interaction/condition/stat-policy families added to extraction matrix. |
| Formula registries | same findings | `formula_registries_implementation_plan_2026-07-23.md` | Accepted after separating bounded numeric formulas from the shared Requirement registry and ordering `[REQ]` first. |
| Rule profiles | same findings | `rule_profiles_implementation_plan_2026-07-23.md` | Accepted; later policy presets reference validated registry ids rather than widening profile precedence. |
| Campaign Library UX | `campaign_library_ux_decisions_2026-07-24.md` and tracker completion record | No dedicated implementation plan | Plan supplied in §4. Source header is stale (“J–K pending”) and must be reconciled during consolidation. |
| Shared UI/UX architecture | `ui_ux_architecture_research_and_questions_2026-07-24.md` | No standalone build plan; tracked shared reuse pass | Plan supplied in §5 and adopted by every screen plan. |
| Prep Hub, activities, Convoy/Shop, forging | `prep_economy_bundle_comparative_research_and_questions_2026-07-25.md` | Older Band 4/6/7 plans plus pending `PLAN-PREP-ECONOMY-IMPLEMENTATION-2026-07-26` | Plan supplied/amended in §6; DRC adds Prison, Trade, provider Convoy, key-item and activity-patch requirements. |
| Text-entry strategy | three `text_entry_*_2026-07-26.md` packets and tracker rulings | Runtime rows exist; no single reviewed implementation plan | Plan supplied in §7. |
| Dialogue/recruit/capture and connected systems | DRC register plus CNV/DSP/STM amendments | Older DLG/RCR/RCV and partial plans are stale | Separate integrated plan: `dialogue_recruit_capture_integrated_implementation_plan_2026-07-27.md`. |

Deferred rows discovered by these passes—cloud/server sync investigations, full-library backup,
search/archive, wheel presenter, full campaign-editor UX, free-text dialogue, and arbitrary mini-game
runtime—remain separate tracker work. They are not silently pulled into V1 by this portfolio.

## 3. Campaign-data plan review amendments

### 3.1 Zero-content engine

The five-slice plan remains sound. Extend its catalogue/extraction matrix before schema freeze:

- conversations, profiles, commands/cues, text and asset bindings;
- requirement/predicate entries and bounded composition fixtures;
- condition/capability definitions and stat set/floor/cap effects;
- interaction definitions, spatial policies, convoy-provider profiles, extraction zones;
- campaign activity defaults/cadence/node patches and Prison activity definitions;
- aggression/disposition policies and objective selector/quantifier definitions.

Every family must remain declarative; handlers, authority checks, journals, transitions, and
presenters are engine code. The base-pack closure walk must include all new references.

### 3.2 Formula registries versus requirements

The formula plan currently lists “requirement/predicate” as a formula family. Implement one shared
Requirement registry (`B3-REQ`) instead. Numeric formula registries may expose pure value terms that
requirements call, but must not create a second boolean composition language, subject binder, or
unmet-reason format. Ordering:

```text
registry/session foundation → shared Requirement schema/runtime
→ numeric range/cost/hit formula adoption → dialogue/objective/activity consumers
```

### 3.3 Pack-associated saves

Add these mutable families to the canonical snapshot/codec review:

- unit five-dimensional state and recruit duration/expiry;
- custody/carry records and campaign Prison roster;
- relationship graph, activity/cadence state, transition/event history;
- registered condition/capability/stat-constraint state;
- mid-map Trade/Convoy partial-action marks and carry attachments.

Do not store V1 in-progress Conversation or map-end journals. Saving restarts those atomic workflows
from the preceding committed checkpoint. Immutable conversations, profiles, policies, requirements,
and objective definitions remain pack ids, not copied save data.

### 3.4 Economy and rule profiles

Convoys and custody are scoped by structured owner refs, never player color. Trade moves item
instances between unit holders and does not touch wallets. Map-end prisoner transfer targets the
custody owner's configured convoy and uses its normal safe overflow/failure policy. Explore/Prison
costs use quote/commit through wallets. Rule profiles may select registered policy preset ids, but
must not add a live precedence layer beyond resolved default → mandate/node/mid-map behavior.

## 4. Campaign Library implementation plan

### Outcome

Deliver the accepted library model over package/campaign/run/save identities with no-content boot,
install/import/export/recovery diagnostics, and shared record-screen architecture.

### Slices

1. **Library read model and controller.** Build immutable stable-id records for installed packages,
   campaigns, campaign status, runs, saves, compatibility, validation, and repair actions. Keep
   selection/focus/filter state outside row widgets.
2. **Wide/narrow list-detail shell.** Use one controller with wide simultaneous composition and narrow
   drill-in composition; preserve selection and scroll across resize/menu scale. Implement native GUI
   focus, explicit region transitions, primary/secondary actions, controller help, and empty/loading/
   invalid states.
3. **First-run and package lifecycle.** No-pack guidance, file picker/import, validating/staging/
   installing/replacing flows, collision handling, disabled invalid packs, and actionable bounded
   diagnostics. No partial activation.
4. **Campaign/New Game/profile flow.** Campaign detail, rules/profile disclosure, mandates, status-
   record import choice, launch validation, and atomic run creation.
5. **Run/save flow.** Campaign-grouped runs and manual/auto saves, compatibility/fingerprint display,
   missing-pack disabled state, load/rename/delete-to-trash/export, and recovery actions.
6. **Transfer and backup surfaces.** Portable save, clean pack, status record, and full backup remain
   distinct typed operations with explicit summaries and transactional import/restore.
7. **Hardening and playtest.** Malformed/hostile packages, path-safe diagnostics, privacy, menu scale,
   keyboard/controller/touch, first-run/no-pack, install/update/missing-pack, export/import, and
   failure-injection rollback.

### Tests and documentation

Headless tests own record projection, stable selection, action availability/reasons, lifecycle state
machine, compatibility, transactions, and hostile inputs. Windows visual passes own composition,
focus, readable diagnostics, file picker return, and menu scaling. Update GDD 01/07, author/player
guides, save/pack schemas, Feature Index, GDD 10, and Control Plane with behavior slices.

## 5. Shared UI/UX architecture implementation plan

This is a foundation used by Library, Prep, Convoy, Shop, Forge, Training, Prison, and text entry:

1. Define pure `RecordScreenState` with stable selected ids, active region, filter/sort/presenter mode,
   and restoration rules.
2. Define controller-owned read models and action descriptors `{id,label,availability,reason,
   confirmation,severity}`; widgets render and emit intents only.
3. Provide wide/narrow composition adapters sharing the same controller/state.
4. Provide list/detail/action components with native focus, explicit region entry/exit, persistent
   primary action and contextual secondary menu.
5. Add presenter/input contracts for keyboard, controller, pointer, touch, menu scale, localization,
   modal focus trapping, and test hooks.
6. Adopt vertically in one real screen before general extraction; do not refactor every current menu
   speculatively.

Tests cover reducer/controller purity, stable ids under reorder/refresh, focus restore, wide↔narrow
transition, disabled reasons, modal routing, input parity, and 100–200% scale. Each consumer retains
domain state and transactions; this foundation owns presentation state only.

## 6. Prep, Explore, economy, inventory, and forging implementation plan

The older Band plans remain useful for ItemDef/InventoryEntry migration, Shop quote/commit, Training
benefits, relationships, and Forge service. Apply the ratified EPUX decisions and DRC amendments in
this order:

1. **Prep shell and activity resolution.** Add campaign activity defaults, cadence patches, and node
   add/remove/override patches; build top-level Prep with Explore, Manage Roster, Map Preview, and
   authored advance actions.
2. **Shared record-screen components.** Adopt subject-first Explore and list/detail/action patterns;
   support deployable members and camp followers without duplicating subject models.
3. **Inventory/convoy core.** Finish instance-preserving convoy and per-faction owner refs, capacity,
   safe overflow, key-item availability/restriction/fallback, filters and transfer transactions.
4. **On-map inventory interactions.** Deliver FE7 Trade and designated-provider Convoy through the DRC
   integrated plan; Prep management remains unrestricted for the controlled faction.
5. **Shop and wallets.** Land owner-ref wallets and atomic quote/commit/refund before Shop UI. Build
   shopper/destination selection, stock/cadence, price disclosure, bulk quantity primitive, and
   receipt/failure feedback.
6. **Explore activities and Training.** Generic availability/requirements/cost/result contract;
   subject-first Training Hall and benefit providers; map-placement as an activity property; activity
   entry snapshot/exit receipt/rollback where authored.
7. **Forge.** Reuse item picker and transaction core; subject-scope the selected item; point-allocation
   upgrade and repair; no V1 rename; transparent formula/cap/quote preview; non-mergeable instances.
8. **Prison.** Add the DRC custody roster/activity only after Dialogue, requirements, relationships,
   inventory disposition, and activity resolution exist.

Cross-bundle gates: wallet/storage migrations cannot land without every live consumer; activity
rollback restores RNG and refuses nested gates; dynamic stock/cadence and node activity patches use
one scheduler vocabulary; item and wallet transactions never mutate during preview.

## 7. Text-entry implementation plan

### V1 contract

Text entry is optional convenience for naming, never a required route for other V1 features. One
entry-mode registry selects presenters; a presenter receives a constrained request and emits edits or
submit/cancel intents. It has no direct save/domain authority.

### Slices

0. **Windows input ownership and FileDialog first adopter.** Before changing behavior, instrument
   a Windows build to measure filename focus and the arrival order of `window_input`, `_input`,
   `_shortcut_input`, built-in cancel, and close requests. Replace the direct handler-call test with
   a dispatched physical-Escape regression. Add one text-entry session/coordinator that owns
   printable input and physical Escape before caller dismissal: first Escape exits filename editing
   to the file list; a later Escape closes the dialog. Keep mapped controller Cancel distinct from
   physical Escape and preserve Z/X typing. This slice fixes the shipped v0.5.8 defect without
   requiring the custom keyboard presenters to exist first.
1. **Request/result and sanitization.** Define purpose, initial text, max graphemes/bytes, allowed
   character profile, normalization, multiline, privacy/logging, submit/cancel, and localized errors.
   Escape all player/pack text before BBCode rendering and retain archive preflight resource denial.
2. **Entry-mode registry and setting.** Ship `grid` and `hardware`; reserve `system` with no backend.
   Default by input-device detection: touch/gamepad → grid, physical keyboard → hardware. Store only
   the mode setting, never raw draft text unless the caller owns it.
3. **Grid presenter.** Explicit row/column model, one licensed JSON ASCII layout, candidate-select
   action reserved, focus independent of GridContainer's injected navigation, responsive wide/narrow
   layout, menu-scale and controller/touch parity.
4. **Hardware presenter.** Render no keyboard; consume physical key/text events through the same edit
   model and show purpose/limits/errors/actions.
5. **Caller adoption.** Use only for naming surfaces approved by the minimize-free-text rule. Forge
   rename stays out of V1; campaign/run/unit naming callers opt in independently.
6. **Platform seam and later modes.** Keep system-OS keyboard adapter boundary for Steam scheduling;
   wheel presenter remains separate post-research work and no prediction dictionary ships in V1.

Tests cover grapheme/byte limits, normalization, disallowed characters, empty/cancel policy, BBCode
escaping, presenter parity, device switching, focus/navigation, layout validation/licensing, menu
scale, and no raw text in logs. The FileDialog test dispatches the real event path rather than
calling its handler directly. Steam release documentation retains the automatic OSK requirement.

## 8. Dialogue/custody integrated-plan review

The integrated plan is accepted for dependency review with these mandatory gates:

- `[REQ]` and UnitTransitionService precede Dialogue actions and custody objectives.
- ConditionManager cannot remain a stub when Incapacitate/carry locks ship.
- ActionJournal must be domain-neutral and prove all-or-none behavior before Dialogue depends on it.
- TurnManager result emission must move behind the atomic map-end resolver before Capture/Extract
  objectives can ship.
- Save and zero-content plans must adopt the new mutable/immutable family boundaries first.
- Trade/Convoy cannot create a second item-instance ledger or infer ownership from `team`/color.
- Prison is last: it composes earlier systems and should contain almost no unique mechanics.

## 9. Portfolio dependency order

```text
Consolidate accepted research/plans onto integration
  → zero-content inactive session + pack/save identity
  → shared registries + Requirement + UI state foundations
  → formula/wallet/item/unit-state/condition foundations
  → campaign library and Prep shell vertical adopters
  → spatial/carry/Trade/Convoy + Dialogue journal/presenter
  → Talk/recruit/objectives/map-end
  → Explore/Prison
  → migration, author tools, Windows/end-to-end release review
```

Parallelism is safe only between slices with disjoint state authority. UI composition can proceed
against immutable fixtures while codecs/services build, but integration waits for real contracts.
Dialogue presentation can proceed against inert conversations while ActionJournal builds. Product
branches merge into `agent/integration`; research-branch documents must not be treated as landed code.

## 10. Completion review checklist

Every implementation plan or owning slice must name:

- authoritative decisions and superseded assumptions;
- exact current code touchpoints and state owner;
- schema/codec/migration and pack-family changes;
- low-code authoring, validation, diagnostics, and fixtures;
- player flow, accessibility, input, localization, and menu-scale behavior;
- preview/commit/rollback, RNG, Save/Retry/Rewind, and failure atomicity;
- automated tests and hostile/malformed cases;
- Windows visual/playtest evidence and export/package validation;
- GDD, roadmap, feature-index, control-plane, save-manifest, and author-guide updates;
- explicit V1 exclusions and compatible post-v1 seams.

No product row is “plan-ready” if any applicable item is absent or only implied by another feature's
plan.

## 11. Review verdict and remaining owner gates

The plans are coherent enough to enter owner review, but not product implementation. The audit found
no unsolved data-model contradiction after applying the amendments in this portfolio and the
integrated Dialogue/custody plan. All four scope and sequencing gates are now resolved.

**Owner ruling 2026-07-27 — shared foundations accepted with narrow domain adapters.** Implement
Requirement, ActionJournal/StateView, SpatialTargetQuery, and UnitTransitionService as shared,
deliberately small mechanical contracts. Domain consumers retain their own filters and gameplay
policy through narrow adapters; shared services must not absorb Talk eligibility, heal rules,
objective policy, dialogue semantics, or other feature-specific decisions.

**Owner ruling 2026-07-27 — strict V1 cuts accepted with compatibility seams.** Keep atomic
Conversation restart from the preceding checkpoint, one licensed ASCII grid plus hardware text
entry, an initially narrow Campaign Library, and Prison as the final composition slice. Include only
the schema/interface seams required to avoid a known future data or save incompatibility; do not
implement speculative checkpointing, extra layouts, advanced Library operations, or early Prison
substitutes behind those seams.

**Owner ruling 2026-07-27 — umbrella epics with executable slice rows.** Track Campaign Library,
shared UI, Prep/economy, and Dialogue/custody as umbrella epics, but create a separately claimable
row for every accepted implementation slice with explicit dependencies and evidence gates. Shared
foundations receive one executable row each and are dependencies of consumers rather than duplicated
inside multiple epics.

**Owner ruling 2026-07-27 — foundation-first release tranche with one thin gameplay proof.** The
first release-facing Windows milestone combines zero-content/package-save foundations and a thin
Campaign Library/Prep vertical slice with one campaign-authored, non-mutating gameplay interaction.
Use that interaction to prove Requirement, targeting, UI presentation, and pack-data boundaries; do
not pull recruitment, capture, custody, map-end resolution, or Prison into this tranche.

All other findings are implementation constraints or sequencing facts and do not need another design
walk. Create executable tracker rows from the accepted plan slices, then close the umbrella planning
row before product implementation begins.
