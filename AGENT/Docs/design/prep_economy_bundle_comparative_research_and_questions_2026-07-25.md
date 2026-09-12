---
Role: dated
Type: register
Status: RESOLVED 2026-07-26 — EPUX-01..28 ratified across the 2026-07-25/26 owner walk
Last verified: 2026-08-17
Register: EPUX-1..28
Track IDs: DISCUSS-CONVOY-SHOP-UX-2026-07-23; DISCUSS-PREP-HUB-UX-2026-07-24; DISCUSS-PREP-ACTIVITIES-UX-2026-07-24; DISCUSS-FORGING-UX-2026-07-24
---

> **Filed as a register 2026-08-17 by `R1`.** This document carried 26 dated owner rulings while its
> header still read `Type: design` / `Status: Draft - owner review`, which kept `EPUX-01..28` out of
> [`REGISTERS.md`](../REGISTERS.md) for 22 days. Nothing below is changed by the re-filing — the
> rulings are as walked on 2026-07-25/26. See
> [`r1_plan_corpus_precedence_diff_2026-08-17.md`](r1_plan_corpus_precedence_diff_2026-08-17.md) §3
> for the mechanism and §5.1 for what the invisibility cost.

# Prep and Economy Bundle — Comparative Research and Owner Questions

## Scope and conclusion

This packet covers the entire between-battle bundle: the prep-hub container,
inventory/convoy, shops and the multi-resource wallet, Training Hall and adjacent
activities, and forging. It evaluates the already-resolved mechanical registers rather
than silently reopening them, then supplies the missing player-facing decisions.

**Recommended product shape:** one responsive, controller-first Prep Hub with an
author-ordered flat activity list, cosmetic location identity, a persistent wallet and
roster context, and one explicit node-advance action. Activities share presentation
contracts but keep domain services separate. Wide mode is list/detail; narrow or 200%
Menu Scale is sequential. Transactions quote before commit, mutate immediately, retain
stable selection, and explain every disabled action. Convoy is the inventory backbone;
Shop, Training, and Forge are thin consumers of the same transaction and forecast
language.

This combines the low navigation cost of classic Fire Emblem preparation menus with
the service breadth of Tellius/Triangle Strategy. A mandatory walkable Three Houses
monastery is rejected for v1: it makes authoring, controller traversal, responsive web
layout, and repeated transactions costlier without improving the tactical decision.

## Evidence and comparator findings

### Fire Emblem series

- **Shadow Dragon** puts deployment, map inspection, inventory, convoy, armory,
  reclassing, save, and Fight in one Battle Preparation menu. Inventory supports trade,
  convoy deposit/withdrawal, a global item list, merge, and unload; forging spends gold,
  previews adjusted variables, permits renaming, and is limited to one visit per prep.
  This is strong evidence for a compact shell, explicit Fight/Continue, global item
  search, bulk unload, and preview-before-forge. Source: [Nintendo's official Shadow
  Dragon manual, pp. 24–25](https://www.nintendo.com/eu/media/downloads/games_8/emanuals/nintendo_ds_21/Manual_NintendoDS_FireEmblemShadowDragon_EN.pdf).
- **The Sacred Stones** allows shop purchases to be sent to the supply convoy. That
  validates overflow/shared-storage routing as a first-class transaction outcome rather
  than an error-only afterthought. Source: [The Sacred Stones instruction
  booklet](https://www.videogamemanual.com/gba/Fire%20Emblem%20-%20The%20Sacred%20Stones%20%28USA%29.pdf).
- **Awakening** exposes buy, sell, and forge through non-battle world-map shop stops,
  with special merchants appearing on the map. This supports author-scoped service
  availability without requiring every service to live on every prep node. Source:
  [Fire Emblem Awakening electronic-manual mirror](https://manualzz.com/doc/3344762/nintendo-fire-emblem--awakening-user-manual).
- **Three Houses** deliberately makes between-battle development spatial: the player
  freely roams Garreg Mach to nurture students and undertake assignments. This can make
  character/world context tangible, but it also adds traversal between repeated service
  operations. Use its location identity and character framing, not mandatory spatial
  navigation. Source: [Nintendo's official Three Houses overview](https://www.nintendo.com/au/games/nintendo-switch/fire-emblem-three-houses/).
- The Tellius base pattern groups conversations, shop/forge, convoy, skills/supports,
  bonus EXP, and battle departure in one between-map base. Its lesson is breadth behind
  a stable hub, not that every activity should share implementation state.

### SRPG Studio and maker ecosystems

- **SRPG Studio** treats base scenes, shops, stock, weapons/items, and events as
  author-configurable editor concepts and exposes JavaScript plugins. The official
  manual is distributed by SapphireSoft and links its web help/API. This supports
  author-defined activity descriptors plus engine-owned primitives, while warning that
  plugin-specific behavior must not leak into the core schema. Source:
  [SapphireSoft's SRPG Studio Official Manual listing](https://steamcommunity.com/sharedfiles/filedetails/?id=1486850828).
- Maker projects often inherit FE-style finite lists and modal menus because those are
  cheap to author and test. Project Prometheus should preserve that low authoring cost,
  but add stable IDs, responsive compositions, explicit focus regions, and structured
  failure reasons rather than copying engine-era UI limitations.

### Fire Emblem ROM hacks and fangames

- **Vision Quest** demonstrates that hacks value expanded and even partitioned convoys;
  its author explains that separate convoy partitions can later merge, and community
  discussion records list/convoy edge cases caused by that customization. The useful
  lesson is that storage ownership must be explicit and tested; UI must not assume one
  global party when campaigns can split factions. Source: [Vision Quest author response
  on Fire Emblem Universe](https://feuniverse.us/t/fe8-complete-fire-emblem-vision-quest-v3-by-pushwall-1-oct-22/3815/1910).
- ROM hacks such as Vision Quest and Sacred Echoes are repeatedly valued for quality-of-
  life improvements layered onto familiar GBA interaction. The project should therefore
  keep FE-recognizable verbs (Give, Take, Trade, Store, Sell, Forge) while improving
  filtering, forecasting, controller focus, and failure explanations rather than
  inventing opaque vocabulary.
- A hack's technical ceiling is not a target: fixed convoy slots, missing responsive
  layouts, and list bugs are constraints to learn from, not behaviors to reproduce.

### Similar tactical RPGs

- **Triangle Strategy** centralizes ally conversation, shops, character and weapon
  strengthening, and mock battles in its Encampment. This is the closest comparator for
  the proposed bundle: one hub, several focused services, and optional practice combat.
  Source: [official Triangle Strategy product description](https://store.steampowered.com/app/1850510/TRIANGLE_STRATEGY/).
- Tactics Ogre's world/shop structure and crafting systems show the benefit—and cost—of
  deep material recipes. Material economies can create long-tail goals, but they also
  produce inventory and recipe-management overhead. Keep materials data-compatible but
  outside the minimum v1 forge slice.

## Existing decisions retained

The following remain sound: opt-in node activities; cosmetic hub theme; free navigation
with one explicit advance; immediate transaction persistence; faction-scoped convoys;
per-instance item state; author-defined inventory/convoy caps with unlimited convoy as
default; buy and sell; resource-keyed quotes; author-defined stock; shopper-aware gates;
two-scope Training costs; author-composed Training offers; operation-overlay forging;
and quote/commit equality. Proposed changes below are labelled **revision**.

## Owner questions — hub and shared interaction

### [EPUX-01] Hub navigation model

- **A — Flat activity list.** For: fastest repeated use, cheapest authoring, predictable
  controller focus, naturally responsive. Against: weaker sense of place; many panels can
  become a long list.
- **B — Named-location map/menu.** For: stronger campaign identity and grouping. Against:
  adds a navigation layer and authoring burden; location metaphors can poorly fit unusual
  campaigns.
- **C — Walkable scene.** For: strongest character/world presence and event discovery.
  Against: highest art, accessibility, testing, and traversal cost; particularly poor for
  repeated shopping and 200% UI scale.
- **Recommendation: A with cosmetic location art/label and optional groups.** Retains
  [PHB-1]. Scene-backed activities remain an optional registered activity type, never the
  mandatory shell.
- **OWNER RULING (2026-07-25): A, extended to two layers.** The node *interior* is the
  flat activity list (A), and each node authors its own list (opt-in node activities,
  already retained). Added on top: an **optional, author-enabled Fire Emblem Awakening-style
  overworld map** for moving *between* nodes, with strict linear node-advance as the default
  and fallback. On the overworld, players **may revisit cleared nodes**. This turns "one
  explicit node-advance action" into an author-selected traversal mode. Revisit, re-entry
  behavior, and the general cadence engine it requires are specified in the new
  "Node traversal and cadence model" section below.

### [EPUX-02] Availability presentation

- **A — Show every engine-known activity disabled when absent.** For: advertises future
  systems. Against: leaks engine capability into campaign authorship and clutters small
  campaigns.
- **B — Show only node-authored activities; show authored-but-gated entries disabled with
  a reason.** For: respects opt-in authorship while explaining reachable goals. Against:
  authors must distinguish absent from gated correctly.
- **C — Hide all unavailable entries.** For: cleanest list. Against: players cannot learn
  what a flag/resource could unlock.
- **Recommendation: B.** Absence is authorial; disabled is an explainable current-state
  gate.
- **OWNER RULING (2026-07-26): B, scoped to all four surfaces, with an author-set
  gate presentation.** Three parts:
  1. **Two-state rule.** *Absent* (the campaign never authored the entry) → **hidden**;
     it does not exist for this campaign. *Gated* (authored, predicate currently false)
     → **shown disabled with a reason**. Absence is authorial; a gate is an explainable
     current state. This is already the behaviour the ratified prep-hub section describes
     for the absent half ("non-battle nodes hide the battle-only entries"; "only panels
     the campaign actually uses appear") — EPUX-02 generalizes it and adds the gated half.
  2. **Uniform across all four availability surfaces:** the top-level node menu, the
     Explore subject picker, the Explore per-subject activity list, and the Manage Roster
     panel registry. One rule to author, learn, and test; no surface-specific exceptions.
  3. **Gate presentation is a per-entry authoring property** — `visible-disabled-with-reason`
     (**default**) or `hidden-until-met`. Same predicate either way; only the presentation
     of an *unmet* predicate differs. The default preserves discoverability (a player can
     learn that a flag or resource would unlock something); `hidden-until-met` exists
     because "authored, gated, and **secret**" is a real authorial intent that plain B
     cannot express — a story-locked shop or a hidden forge whose disabled label would
     otherwise spoil a deliberate reveal.

  **Implications.**
  - Predicates need a **reason surface**, not just a boolean: the open predicate registry
    must be able to return a player-facing unmet-reason string for the disabled label.
    A predicate that cannot explain itself can only be authored `hidden-until-met`.
  - `hidden-until-met` must not become the lazy default in authoring templates/tooling;
    the authoring default stays visible-disabled.
  - ~~**Derived, not ruled — flagged for EPUX-04/06/07 and the accessibility pass:** whether
    disabled entries stay keyboard/controller-focusable so the reason is reachable by
    screen reader rather than hover-only. Recommend focusable-but-not-activatable; not
    settled here.~~
    **RULED 2026-07-26 by `[EPUX-07]`: focusable but not activatable.** See the owner ruling
    in *Prep-hub and shared-surface rulings* below — *"disabled entries are focusable, not
    activatable … Settles the question deferred from `EPUX-02` and `EPUX-04`"* — and the
    `EPUX-07` ratification line in the same section. A disabled entry takes focus so the unmet
    reason is reachable by keyboard, controller and screen reader rather than hover-only;
    activating it does nothing.

    > **Correction 2026-08-17 by `R1`.** This annotation previously read *"`EPUX-06` and
    > `EPUX-07` were the deferral targets named here and neither ever ruled it, so this sat
    > open from 2026-07-26 until the `RPD` walk reached it."* **That was wrong**, and the
    > ruling it denied was already in *this document* when the annotation was written — present
    > in the 2026-07-29 revision, 200 lines below. `[RPD-15]` re-ruled it identically on
    > 2026-08-13 and the corpus then adopted the later ID as the source. `[RPD-15]` stands and
    > is cited downstream; **`[EPUX-07]` has precedence in time**. See
    > [`r1_plan_corpus_precedence_diff_2026-08-17.md`](r1_plan_corpus_precedence_diff_2026-08-17.md)
    > §5.1; carried into `R3` as a duplicate-mechanism candidate.

### [EPUX-03] Wide/narrow composition

- **A — One fixed two-pane layout.** For: simplest mental model. Against: fails narrow web
  viewports and 200% Menu Scale.
- **B — Separate desktop and mobile scenes.** For: each can be tuned. Against: behavior,
  focus, and action availability drift.
- **C — One controller/state model with wide list/detail and narrow sequential
  compositions.** For: preserves state and supports all targets. Against: requires an
  explicit reflow contract and more layout tests.
- **Recommendation: C.** Reuses accepted UI-ARCH-02; choose by measured content width,
  not platform name.
- **OWNER RULING (2026-07-26): C, confirming UI-ARCH-02, plus a pane-budget contract.**
  One presentation controller/state model; wide list/detail and narrow sequential
  compositions selected by **measured content width**, never a platform or device name;
  selected record and focused region preserved across the transition. 200% Menu Scale can
  force the narrow composition at a nominally wide viewport, so narrow is never a
  "mobile-only" path.

  **Pane budget for the Explore chain.** The ratified structure creates a chain the
  original framing did not consider — node menu → Explore → subject picker → activity list
  → activity panel. It maps onto the two compositions as follows:
  - **Default: at most two panes, pairing adjacent levels** (subject | activity-list, then
    activity-list | panel as the player descends). Never three panes: a third collapses at
    200% Menu Scale and steals width from the terminal panel, which is the content that
    needs it most.
  - **Full-width escape hatch.** A panel may declare that it wants the entire available
    width, and the shell then presents it **alone**, dropping the companion pane; the
    parent level stays reachable by back/breadcrumb instead of remaining on screen.
    Intended for content-dense panels — shop grids, the forge before/after comparison,
    Map Preview, and the global item-first view (bulk organization/search).
  - The declaration is a property of the **panel type in the registry** (its content
    shape), not a per-campaign authoring knob — campaign authors do not make layout
    decisions.
  - It is a **preference, not an override**: it only has meaning when there is room for
    two panes at all. In the narrow composition everything is already sequential, so the
    preference is moot. Taking or releasing the full width must preserve selection and
    focus exactly as an ordinary wide↔narrow transition does.

### [EPUX-04] Shared screen shell

- **A — Every panel bespoke.** For: maximum thematic freedom. Against: repeated bugs and
  inconsistent controls.
- **B — One universal domain-aware screen.** For: maximal reuse. Against: becomes a closed
  switch and couples unrelated schemas.
- **C — Shared presentation primitives with domain-owned adapters/actions.** For: stable
  list/detail/focus/forecast behavior without a hardcoded activity enum. Against: adapter
  contracts need discipline.
- **Recommendation: C.** Stable record IDs, query callbacks, action descriptors, and
  domain-owned services.
- **OWNER RULING (2026-07-26): C, confirming UI-ARCH-01, with availability gating promoted
  to a shell primitive.** Shared presentation primitives (list/detail, focus, selection,
  forecast) keyed by an opaque stable record id; domain managers keep ownership of records
  and mutations; queries and actions travel as callbacks/signals and action descriptors, so
  no campaign schema is embedded in the shared layer and no hardcoded activity enum appears.
  Option B is the closed type-switch this project treats as a smell.

  **Gating belongs to the shell, not to adapters.** EPUX-02 ratified one availability rule
  across all four surfaces (absent hides / gated shows disabled-with-reason, with a
  per-entry `visible-disabled-with-reason` | `hidden-until-met` presentation). That
  uniformity is only enforceable if the shell evaluates and renders it. Therefore:
  - The shared shell owns predicate evaluation, the hidden-vs-disabled decision, the
    disabled visual treatment, and the placement of the unmet-reason text.
  - A domain adapter supplies only **the predicate and its player-facing unmet-reason
    string** (see `ENGINE-PREDICATE-UNMET-REASON-2026-07-26`) plus the per-entry gate
    presentation. It does not decide how a gated entry looks.
  - Consequence: four adapters cannot drift into four different disabled treatments, and
    the EPUX-02 ruling is testable in one place rather than four.
  - The focusability question (are disabled entries keyboard/controller focusable so the
    reason is screen-reader reachable?) is therefore a **shell-level** decision too.
    **RULED 2026-07-26 by `[EPUX-07]`: focusable but not activatable** (restated 2026-08-13 as
    `[RPD-15]`, which extended it explicitly to all five availability surfaces). Because gating
    is a shell primitive per this ruling, focus traversal is implemented once in the shell and
    inherited by all five surfaces, not per adapter.

    > **Correction 2026-08-17 by `R1`.** This annotation previously read *"This paragraph's
    > deferral target — `EPUX-06/07` and the accessibility pass — never ruled it; the `RPD` walk
    > did."* `[EPUX-07]` ruled it eighteen days earlier, in this document. Same correction as
    > `[EPUX-02]` above.

  The full-width panel preference from the EPUX-03 pane-budget contract is likewise a shell
  primitive: panel types declare the preference, the shell honours it and preserves
  selection/focus across the change.

### [EPUX-05] Wallet and context visibility

- **A — Wallet only inside cost rows.** For: minimal chrome. Against: comparison and
  planning require opening entries.
- **B — Persistent party resources; selected-unit pools/stats in contextual details.**
  For: balances global planning with low clutter. Against: header space pressure.
- **C — Show every resource at all times.** For: complete. Against: author-defined wallets
  can grow without bound.
- **Recommendation: B**, with overflow into a labelled Resources detail/popover.

### [EPUX-06] Confirmation policy

- **A — Confirm every transaction.** For: safe. Against: severe repetition cost.
- **B — Never confirm.** For: fast. Against: costly/unique operations become easy mistakes.
- **C — Confirm consequence-heavy operations; ordinary reversible/repeatable purchases
  commit directly after an explicit action.** For: proportional safety. Against: requires
  consequence metadata.
- **Recommendation: C.** Confirm unique items, destructive sells, stat/skill grants,
  transforms, and operations consuming rare items; allow a campaign/setting stricter mode.
- **OWNER RULING (2026-07-26): C, author-declared and rule-driven, plus an optional exit
  review with rollback.** Consequence-heavy operations confirm; ordinary repeatable
  purchases commit directly after an explicit action.

  **What marks an operation as needing confirmation — authored, never hardcoded.**
  - The **author declares** it on the action itself. There is no engine-side enum of
    "consequence-heavy operation types"; that would be the closed type-switch this project
    rejects, and would require an engine edit for every new operation to become safe.
  - In addition, authors may write **declarative threshold/filter rules** evaluated against
    the transaction — e.g. *"any purchase costing more than X of resource Y in this shop
    requires confirmation."* Rules are scopeable (this shop / this node / campaign-wide).
  - Both forms are **predicates**, so this reuses the same registry that already serves
    availability gating (EPUX-02) and unmet reasons (EPUX-07). One predicate mechanism now
    answers three questions: *may I see it, why not, and must I confirm it.* A new
    confirmation rule is authored, never coded.

  **Strictness is a floor, raise-only.** A **player** setting may raise strictness globally
  (up to confirm-everything) as an accessibility/safety preference, and authors may mark
  specific operations always-confirm. Neither may lower a declared consequence class below
  its authored default.

  **Optional exit review with rollback (owner-added).** Transactions still commit
  immediately — the retained *immediate transaction persistence* decision is unchanged, and
  no staging layer, stock reservation, or quote/commit divergence is introduced.
  - **Author-chosen per activity type:** the registry declares which activities carry an
    exit gate, so a large shop can have one while a quick training hall does not.
  - On **entering** a gated activity the engine takes a **snapshot** (a rewind point on the
    existing persistence/ledger machinery, not a new mechanism).
  - On **leaving**, the player sees a **review receipt** — what was done and the net
    resource change — and may either acknowledge it or **roll back to the entry snapshot**,
    discarding everything done inside that activity.
  - This gives true back-out without a staged cart: dependent operations still work (buy a
    weapon, then forge it), because everything really did commit.
  **Sub-questions resolved by the owner (2026-07-26).** All three landed on machinery that
  already exists in the unified persistence design — see
  `AGENT/Docs/plans/persistence_undo_unified_handoff_2026-07-15.md`.

  1. **Rollback restores the RNG stream.** A rollback rewinds RNG state to the entry
     snapshot, so replaying identical actions yields identical outcomes and rollback is
     never a reroll lever. This is **not a new guarantee** — the handoff's "Determinism —
     the real anti-scum" section already states that every ledger snapshot carries the RNG
     timeline and that rewinding or reloading restores RNG-at-that-point. Receipt rollback
     simply inherits it.
  2. **…but authors are warned off putting rollback on RNG-based activities.** Determinism
     removes the *luck* dimension only for **identical** replays; as the handoff puts it,
     "only DIFFERENT choices change results". Inside an RNG-bearing activity the player can
     trivially make a different choice — fight a different arena opponent, re-roll a forge
     — so the guarantee does not protect these the way it protects a battle. Therefore:
     **a non-blocking campaign-builder warning when an exit gate is enabled on an
     RNG-bearing activity type.** Model it on the existing safety-rule-2 warning (durable
     `mid_map` saves vs finite rewind), and per **DoD#2** land the automated check *with*
     the feature, modelled on `AGENT/Docs/check_docs.py`.
  3. **Receipt rollback does not consume a rewind charge — charges are battle-only.**
     `rewind_charges_per_map` is already per-map, and `undo_activations` / `undo_rounds`
     are within-map ledger budgets. Rewind charges exist as a **convenience for casual
     players who would otherwise save-scum anyway**, and are **disableable for a harder
     experience** — already expressible today as the `rewind_charges_per_map = 0`
     ironman-style preset. Receipt rollback is a separate, uncharged mechanism.
  4. **Intended scope: bulk purchase and sale.** The receipt gate exists for shops and bulk
     transactions, not for grants, transforms, or RNG activities. This is the design intent
     behind the author warning in (2) and behind the gate being author-chosen per activity.

  **Snapshot retention — exactly one, discarded on acceptance.** Only a single entry
  snapshot is kept at a time, and accepting the receipt discards it. Consequences:
  - Bounds snapshot cost on **web and console** targets, which is why the gate is
    author-chosen per activity rather than universal.
  - **Invariant: at most one exit-gated activity may be open at a time.** The ratified
    Explore structure already satisfies this (the player is inside one activity panel at a
    time), but if nesting is ever introduced the inner gate must be **refused** rather than
    silently replacing the live snapshot and destroying the outer rollback.
  - The snapshot needs a **trigger the current design does not have**: the autosave trigger
    list ships `battle_start` / `battle_end` / `shop_exit`, all of which fire on *exit*.
    Rollback needs an **entry** snapshot, so a new activity-entry trigger is required.
    **Owner-approved 2026-07-26** — the entry snapshot is an ordinary autosave on a new
    activity-entry trigger, not a bespoke mechanism.
  - It is a transient auto document with its own `rule_id` and its own pool, so the hard
    invariant that an autosave never overwrites a manual save continues to hold.
  - **Crash/quit needs no special case (owner, 2026-07-26).** A live snapshot surviving an
    unclean exit is handled by the existing **relaunch-and-resume** path: the player resumes
    where they were, with the snapshot still live and rollback still offered. No
    rollback-on-reload flow, and no snapshot-dropping rule, is required.

### [EPUX-07] Transaction result and failure feedback

- **A — Disable action only.** For: quiet UI. Against: inaccessible and opaque.
- **B — Modal error after attempted commit.** For: explicit. Against: interrupts browsing.
- **C — Disabled action plus inline reason; structured error modal only for unexpected
  commit failure.** For: preventative, testable, and low interruption. Against: needs a
  stable reason vocabulary.
- **Recommendation: C.** Minimum reasons: insufficient resource, missing material,
  destination full, cap reached, gate unmet, unsellable, invalidated quote, and save
  failure.
- **OWNER RULING (2026-07-26): C, on ONE unified reason contract shared with EPUX-02.**
  Prevention first: an action the player cannot take is **disabled with an inline reason**;
  a structured error modal appears **only for an unexpected commit failure**. This already
  matches the EPUX-11 ruling, where a full destination fails *before* commit with
  "destination full" and no partial mutation.

  **One reason contract, not two.** The eight minimum reasons — insufficient resource,
  missing material, destination full, cap reached, gate unmet, unsellable, invalidated
  quote, save failure — are members of the **same** shell-level reason contract as the
  EPUX-02 predicate unmet-reason (`ENGINE-PREDICATE-UNMET-REASON-2026-07-26`); "gate unmet"
  *is* that reason. A parallel transaction-only vocabulary would mean two mechanisms, two
  visual treatments, and two test surfaces answering the player's single question "why can't
  I do this" — precisely what promoting gating into the shell (EPUX-04) was meant to prevent.
  As with gating, the **shell** owns the presentation; adapters supply the reason.

- **OWNER RULING (2026-07-26) — disabled entries are focusable, not activatable.** Settles
  the question deferred from EPUX-02 and EPUX-04. Disabled entries **remain in the focus
  order** so their reason is reachable by keyboard, controller, and screen reader;
  confirming does nothing (or re-announces the reason) rather than performing the action.
  A disabled control whose reason is reachable only by pointer hover is the "inaccessible
  and opaque" failure option A is rejected for. This is a **shell-level** behaviour, so it
  is implemented and tested once for all four availability surfaces.

## Owner questions — inventory and convoy

### [EPUX-08] Primary organization axis

- **A — Unit first, then inventory.** For: supports outfitting a chosen roster member.
  Against: poor global duplicate/shortage view.
- **B — Item first, then holder/destination.** For: excellent global management. Against:
  weaker character loadout flow.
- **C — Unit-first default plus global All Items/Convoy sibling view.** For: covers both
  Shadow Dragon-style loadout and global search. Against: two view states to preserve.
- **Recommendation: C.** Preserve selected unit, item, filter, and scroll independently.

### [EPUX-09] Transfer interaction

- **A — Command verbs Give/Take/Trade.** For: familiar and controller-safe. Against: more
  steps for bulk organization.
- **B — Drag and drop.** For: direct for mouse/touch. Against: poor controller and
  accessibility semantics.
- **C — Verb-first authoritative path with optional drag/drop shortcut.** For: parity and
  speed. Against: two input paths must share one mutation command.
- **Recommendation: C.** Drag/drop never bypasses validation or forecast.
- **OWNER RULING (2026-07-26): A for v1; drag/drop is a post-v1 option.** v1 ships command
  verbs only — familiar, controller-safe, and the smallest surface. C stays the *target*
  shape rather than being rejected: the verb path is built as the authoritative mutation
  command from the start, so a later drag/drop layer is an additive input adapter over that
  same command and never a second mutation path. Nothing in v1 may assume a pointer.

### [EPUX-10] Stacking and instance identity

- **A — Display every instance.** For: state is never hidden. Against: large convoys become
  noisy.
- **B — Stack by base definition only.** For: compact. Against: hides durability, forge,
  name, and bound-state differences.
- **C — Stack only entries with identical effective state; expand on demand.** For: compact
  without lying. Against: grouping key is more complex.
- **Recommendation: C.** Forged/named/bound entries are unique; identical unmodified
  instances may stack with aggregate count and durability summary.
- **OWNER RULING (2026-07-26): C.** Entries stack only when their *effective* state matches;
  forged, aliased, bound, and durability-differing instances stay distinct and any stack
  expands on demand. This is a prerequisite for the forging block, not a peer of it — it is
  what makes per-instance forge overlays (EPUX-23..28) and stable instance IDs (EPUX-25)
  displayable without lying to the player.

### [EPUX-11] Capacity overflow

- **A — Reject when the selected unit is full.** For: explicit control. Against: blocks
  purchases/rewards and causes avoidable retry loops.
- **B — Always route overflow to faction convoy and report it.** For: resilient and matches
  existing direction. Against: can surprise players.
- **C — Prompt for destination every time.** For: maximum control. Against: repetitive.
- **Recommendation: B**, with a visible “Sent to Convoy” result and an author rule for
  campaigns without convoy access.
- **OWNER RULING (2026-07-25): B, with terminal handling defined.** Overflow routes to the
  faction convoy. When the convoy has a finite cap and is full: **player-initiated** buys and
  transfers **fail before commit** with the "destination full" reason (no partial mutation);
  **unavoidable acquisitions** (battle drops, story grants) go to a **pending-items tray**
  resolved before leaving prep (author policy, default hold-pending). For campaigns with the
  convoy disabled, the fallback is the per-unit-only cascade in "Prep hub structure, convoy,
  and shops".

### [EPUX-12] Bulk operations

- **A — None in v1.** For: smallest implementation. Against: late-game maintenance scales
  poorly.
- **B — Unload All only.** For: proven FE operation and bounded scope. Against: does not
  solve equipping many units.
- **C — Multi-select/batch move, auto-equip, optimize.** For: maximum speed. Against:
  opaque automation and large validation surface.
- **Recommendation: B for v1**, plus deterministic “Restock consumables” later; avoid a
  black-box Optimize command.
- **OWNER RULING (2026-07-26): B for v1, with two named deterministic bulk operations.**
  No multi-select, no auto-equip, no Optimize. Both operations below are player-directed and
  fully reported — never silent.
  - **Send All to Convoy** *(v1)*. Iterates the source inventory **one item at a time in
    order**, so the outcome is deterministic and partially-completed state is always a valid
    state. Two terminal conditions:
    - **Convoy full** → the operation **halts** at that item and reports what moved and what
      did not. Consistent with the EPUX-11 fail-before-commit rule: each individual move is
      atomic, and the halt leaves no partial item.
    - **Non-transferable items** (key/quest/plot-locked instances) are **excluded from the
      operation up front** rather than halting it — ineligibility is known before the first
      move, so it is a filter, not a failure. The result reports them as "kept: not
      transferable" using the EPUX-07 unified reason contract.
  - **Resupply** *(named to avoid collision with EPUX-16 shop restock)*. Deterministically
    swaps an item in a unit's inventory for a matching item of **higher remaining
    durability** drawn from the convoy. Matching is by base definition **plus** identical
    effective state (the EPUX-10 stacking key), so Resupply never silently trades away a
    forged, aliased, or bound instance for a plain one. Reports every swap.
- **Spun out (not part of EPUX-12): inventory-holding as a gate predicate.** Activities and
  **Start Battle** must be gateable on whether an item is held, with an author-chosen
  **scope**: held by *any deployed unit*, by *a named unit*, or *in the convoy*. This is a
  predicate in the shared condition registry rather than a bulk-operation feature, which
  means it is simultaneously an availability gate (EPUX-02), a confirmation-threshold rule
  (EPUX-06), and a cadence trigger — one registration, four consumers. Tracked as
  `ENGINE-ITEM-HELD-PREDICATE-2026-07-26`.

## Owner questions — shop and economy

### [EPUX-13] Buy/sell organization

- **A — Separate activities.** For: simple lists. Against: duplicate context and travel.
- **B — Buy/Sell sibling tabs in one shop session.** For: familiar, retains shopper and
  filters. Against: tab state must be explicit for controller users.
- **C — One mixed list with action per item.** For: unified search. Against: price direction
  and ownership become visually ambiguous.
- **Recommendation: B**, with text labels, remembered tab per session, and explicit
  buy-cost versus sell-yield styling.
- **OWNER RULING (2026-07-26): B.** One shop session with Buy/Sell sibling tabs; the shopper
  and the active filters survive the tab switch. Text labels, not icon-only. Because Explore
  is subject-first, the session **inherits** its subject rather than asking for one — the
  shopper is chosen before the shop opens, and the tabs sit inside that established context.
  Tab state must be explicit and focusable for controller users.

### [EPUX-14] Shopper selection and purchase destination

- **A — Prep purchases always to convoy.** For: simple bulk buying. Against: adds another
  step when outfitting a unit and conflicts with shopper-aware prices.
- **B — Require a shopper; send to shopper with convoy overflow.** For: one rule across prep
  and battlefield shops. Against: slows bulk purchasing and can make shopper-dependent
  pricing feel compulsory.
- **C — Shop declares bulk-convoy or shopper mode; shopper mode uses overflow.** For: fits
  both use cases and authorship. Against: two modes to explain/test.
- **Recommendation: C.** This clarifies the existing SHP-4/SAC-6 tension rather than
  changing the transaction core.
- **OWNER RULING (2026-07-25): resolved by giving the convoy an owner.** For v1 the convoy
  has a **pricing subject** — author picks the **quartermaster or the main character** — used
  as the buyer when bulk-buying-as-the-convoy. This removes the null-shopper case entirely, so
  there are no longer two modes to reconcile: purchases always have a subject (the convoy-owner
  by default; a chosen deployed unit optionally). The owner is a pricing/identity subject
  **only**, never an access gatekeeper — losing them never bricks the convoy. Details, plus the
  gatekeeper/respawn variant that stays parked, are in "Prep hub structure, convoy, and shops".

### [EPUX-15] Stock categories and filtering

- **A — Author-created separate shop types.** For: strong flavor. Against: fragments UI and
  hardcodes vocabulary.
- **B — One mixed list only.** For: simplest. Against: long stocks become difficult.
- **C — One generic stock with derived filters/categories and search where text input is
  practical.** For: scalable and data-driven. Against: requires metadata completeness.
- **Recommendation: C.** Categories are presentation facets, never engine shop enums.
- **OWNER RULING (2026-07-26): C, filters only — no free-text search in v1.** One generic
  stock with categories/filters **derived from item metadata**; they are presentation facets,
  never engine shop enums. Free-text search is cut from v1 so every stock surface behaves
  identically on every input method rather than degrading on controller. Search returns
  post-v1 in the same tranche as EPUX-09 drag/drop — both are pointer-and-keyboard
  affordances layered over an input-agnostic v1, not features v1 is missing.

### [EPUX-16] Limited stock and cadence

- **A — Infinite stock only.** For: no persistence/cadence complexity. Against: cannot
  author scarce rewards or restocking economies.
- **B — Always finite.** For: meaningful scarcity. Against: bookkeeping burden and hostile
  defaults for simple campaigns.
- **C — Author-defined quantity/cadence; default infinite.** For: scalable and preserves
  current v1 simplicity. Against: finite stock needs saved counts and clear restock copy.
- **Recommendation: C**, but ship the first playable slice with infinite stock.
- **OWNER RULING (2026-07-25): C, pulled forward and generalized.** Because revisitable
  overworld nodes (EPUX-01 ruling) require a defined second-visit behavior, stock cadence
  can no longer be deferred: shop nodes persist stock and restock on an author-defined
  cadence, defaulting to infinite/non-scarce so simple campaigns stay simple. Stock is now
  one subscriber of the general cadence engine in the "Node traversal and cadence model"
  section below.

### [EPUX-17] Dynamic price disclosure

- **A — Show final price only.** For: uncluttered. Against: shopper traits and modifiers feel
  arbitrary.
- **B — Always show full formula.** For: transparent. Against: overwhelming and may expose
  author internals.
- **C — Show base→final price and concise reason chips; detailed breakdown on demand.** For:
  honest and readable. Against: requires author-facing labels for modifiers.
- **Recommendation: C.** Never require players to reverse-engineer hidden Charm/member
  pricing.
- **OWNER RULING (2026-07-26): split by pane — final price in the list, full formula in the
  detail panel.** The stock list shows the **final price only**, so browsing stays scannable
  and every row is the same shape. The **selected item's More Info panel** carries the **full
  price formula** alongside that item's stats, effects, and description — one place where
  everything known about the selected item lives, rather than a separate pricing affordance.
  This is neither A nor C-with-chips: nothing is hidden (B's transparency is fully available)
  but nothing is crowded into the list either.
  - It fits the EPUX-03 pane budget exactly: list and detail are **adjacent levels** of one
    Explore chain, which is the sanctioned two-pane pairing. In narrow mode the detail panel
    is the next sequential step, and the price formula travels with it.
  - It reuses the established **More Info** pattern rather than inventing a pricing surface —
    same shape as `terrain_more_info_paging_design_2026-06-19.md`.
  - This is what makes EPUX-14's pricing subject legible: when the convoy owner and a chosen
    shopper see different prices for one item, the reason is one step away and attached to
    the item, not an unexplained number in a list.
  - Author-facing labels are still required for every price modifier, since the breakdown
    names them.

## Owner questions — Training Hall and activities

### [EPUX-18] Training selection order

- **A — Unit first, then eligible offers.** For: immediate before/after forecast and clear
  ineligibility. Against: comparing one offer across the roster takes more navigation.
- **B — Offer first, then eligible units.** For: good when pursuing a specific benefit.
  Against: less natural for character development.
- **C — Two symmetric modes.** For: powerful. Against: doubles state and instruction cost.
- **Recommendation: A**, with a “Compare Roster” secondary action for the selected offer.

### [EPUX-19] Benefit forecast

- **A — Result text only.** For: compact. Against: hides caps and downstream effects.
- **B — Before→after primary values plus cost, cap, gate, and any equip/loadout consequence.**
  For: decision-complete. Against: benefit adapters must provide typed preview data.
- **C — Full character sheet preview.** For: exhaustive. Against: too dense for routine use.
- **Recommendation: B**, with More Details opening the existing unit inspection surface.
- **OWNER RULING (2026-07-26): B, mirroring the EPUX-17 split.** The offer list shows result
  and cost only; the **selected offer's detail panel** carries before→after primary values,
  cost, cap, gate, and any equip/loadout consequence. Shop pricing and benefit forecasting
  therefore use **one pattern** — scannable list, everything-known-about-the-selection in the
  adjacent detail pane — rather than two conventions the player has to learn separately.
  Benefit adapters must supply typed preview data; More Details opens the existing unit
  inspection surface.

### [EPUX-20] Mixed benefit types

- **A — One long universal Training list.** For: one panel. Against: class EXP, stats,
  skills, sources, and recruits have different comparison needs.
- **B — Separate hardcoded facilities.** For: focused. Against: closed vocabulary and author
  proliferation.
- **C — One activity with author-defined labelled sections/tabs backed by registered benefit
  presenters.** For: open and organized. Against: needs fallback rendering for unknown types.
- **Recommendation: C.** Unknown registered types fail validation loudly; no engine enum.
- **OWNER RULING (2026-07-26): C.** One activity; the author defines labelled sections/tabs;
  each benefit type renders through a **registered benefit presenter**. No engine enum of
  benefit types — unknown registered IDs fail validation loudly *before* the player enters
  the panel. Note this governs the inside of a single hall only: authors who want hard
  separation already have it, since each themed hall is its own Explore service gated by its
  own per-subject predicate.

### [EPUX-21] Repeat purchases and caps

- **A — Allow rapid repeat with no intermediate feedback.** For: fast. Against: accidental
  overspend.
- **B — Confirm every repeat.** For: safe. Against: tedious for EXP spending.
- **C — Hold/repeat or quantity stepper for divisible benefits; explicit confirmation for
  permanent discrete grants.** For: proportional. Against: benefit metadata must say whether
  it is divisible/repeatable.
- **Recommendation: C.** Always show remaining resource and effective cap live.
- **OWNER RULING (2026-07-26): quantity stepper, generalized into a shared quantity
  primitive.** Not hold-to-repeat: one stepper, one quote, one commit, one ledger entry.
  - **Affordance:** a numeric field with **repeat arrow buttons**, so holding an arrow scrolls
    the *quantity*, never the *purchase*. Nothing commits until the player confirms.
  - **Starts at 1**, the overwhelmingly common case.
  - **Stepping backwards from 1 wraps to the effective maximum** — a one-input path to "buy as
    many as I can" without a separate Max button or a long hold.
  - **The effective maximum is live and is the minimum of** what current resources afford,
    what destination space accepts (unit capacity, then convoy per EPUX-11), and the benefit's
    own cap. It is recomputed as the wallet and destination change, so the wrap target is
    always genuinely purchasable — the stepper can never offer a quantity that would fail at
    commit. Remaining resource and effective cap stay visible live.
  - **This is one shared primitive, not a Training-Hall feature.** The **item shop and the
    unit-benefit shop use the same quantity control and the same live-maximum rule**, so
    buying eight vulneraries and buying eight points of class EXP are the same interaction.
    That also means the shop gains quantity purchasing, which the shop questions never
    settled on their own. Divisibility/repeatability stays benefit metadata; a non-divisible
    benefit simply presents no stepper.
  - Confirmation is unchanged: EPUX-06 already made it an authored property with predicate
    thresholds, so "confirm this permanent grant" needs no special case here.

### [EPUX-22] Arena/mock-battle placement

- **A — Fold into Training Hall.** For: fewer activities. Against: combat setup/risk and
  reward loops differ from purchases.
- **B — Separate Arena activity sharing roster/forecast primitives.** For: honest mental
  model and room for lethal/safe/escalating rules. Against: one more hub entry.
- **C — Always launch from map nodes.** For: spatial fiction. Against: unnecessary campaign
  graph coupling.
- **Recommendation: B.** Triangle Strategy's Tavern/Mock Battle separation supports this.
- **OWNER RULING (2026-07-26): B, generalized — any Explore activity may be placed on a map.**
  The arena is a separate registered activity (not a Training Hall offer type), and the
  question of *where* it lives is answered once for every activity rather than per activity:
  **placement on a map node is a general property of an Explore activity**, not a shop-only
  capability. Shops were merely the first case walked.
  - An activity may be reachable from **Explore**, from an **on-map event node**, or **both**,
    at author choice, and both surfaces may reference **one shared activity definition and its
    state** — the generalization of "stock is a first-class named entity" from EPUX-16.
  - Shared state depletes/advances across surfaces, exactly as shared stock does. Cadence
    (restock, variant advance, availability) applies to the shared entity, not per frontend.
  - The **reason-keyed inactive presentation** already defined for on-map shops — gated/secret
    → hidden, proximity → browse-only, preview → scouting view — is likewise promoted to
    apply to **any** on-map activity.
  - Subject resolution differs by surface and is already specified: on-map = the adjacent
    unit; prep = the convoy pricing subject or a chosen unit.
  - This removes option C as a separate answer: "always launch from map nodes" is now just an
    authoring choice within one model.

## Owner questions — forging

### [EPUX-23] v1 forge operation

- **A — Fixed +N authored upgrade.** For: smallest proof, clear controller UI, easy balance.
  Against: less expressive than the resolved allocation/transform ambition.
- **B — Budgeted stat allocation.** For: player expression and Tellius precedent. Against:
  more complicated caps, undo, pricing, and narrow-layout controls.
- **C — Transform recipe.** For: clear item progression and simple outcome. Against: proves
  replacement, not per-instance overlay resolution.
- **Recommendation: A for the minimum slice**, while keeping B/C as registered operations.
  This confirms the earlier FRG-17 lean.
- **OWNER RULING (2026-07-26): all three ship before v1, in the order A → C → B.** This is a
  sequencing ruling, not a scope cut: the forge operation registry carries fixed upgrade,
  transform recipe, and budgeted allocation by v1. The order is chosen so each step proves
  the next one's hard part:
  1. **A — fixed +N upgrade.** Proves the per-instance overlay and the effective-stat
     resolver behind the simplest possible UI. Confirms the FRG-17 lean.
  2. **C — transform recipe.** Proves consumption/replacement and the material trade-in path
     over the EPUX-24 shared transaction core, which the shop already exercises.
  3. **B — budgeted stat allocation.** Last, because it is the heaviest: caps, per-point
     pricing, narrow-layout controls, and the most demanding overlay resolution. By the time
     it lands, both the resolver and the transaction core are proven.
  Ordering only — none of the three is optional, and the registry must not privilege A in its
  shape.

### [EPUX-24] Forge/shop relationship

- **A — Separate transaction cores and panels.** For: independent implementation. Against:
  duplicated quote/commit/rollback bugs.
- **B — Forge is a shop row type.** For: reuse. Against: instance mutation, repair, rename,
  and point allocation fit poorly into stock semantics.
- **C — Shared atomic transaction core, separate thin panels, with transforms optionally
  presented in either.** For: one cost/trade-in contract and honest domain UX. Against:
  requires a deliberate common command model.
- **Recommendation: C.** Retains FRG-20.
- **OWNER RULING (2026-07-26): C.** One shared atomic quote/commit/rollback core; forge and
  shop are separate thin panels over it; transforms may be presented in either. Retains
  FRG-20. This is the same instinct as the EPUX-21 shared quantity primitive — the common
  command model that ruling started is the model this core formalizes, not a second one.

### [EPUX-25] Forge item picker scope

- **A — Unit inventory only.** For: simple ownership. Against: forces convoy shuffling.
- **B — Convoy only.** For: centralized. Against: hides equipped/held candidates.
- **C — All faction-owned eligible instances, showing holder and equipped state.** For:
  efficient and complete. Against: modifying equipped gear needs clear consequence copy.
- **Recommendation: C**, filtered to eligible instances and preserving stable instance IDs.
- **OWNER RULING (2026-07-26): none of the above as written — the forge is subject-scoped,
  exactly like the shop.** The picker's reach is not a forge-specific policy; it falls out of
  the subject-first Explore model, so the forge needs no scope rule of its own.
  - **Subject = the convoy** (pricing subject: quartermaster or main character) → the picker
    reaches **convoy inventory**, quoted at that subject's prices.
  - **Subject = a unit** → the picker reaches **that unit's own items**, quoted at that unit's
    prices.
  - The subject therefore determines **reach and pricing together**, which is precisely the
    EPUX-14 rule already ratified for shops. One sentence covers both services.
  - **Accepted cost:** forging a weapon held by unit X while acting as the quartermaster
    requires moving it to the convoy first, or entering the forge as unit X. This is the
    deliberate trade for consistency; EPUX-12's Send All to Convoy makes the staging cheap.
  - **Convoy-disabled cascade is automatic:** the convoy is already not a selectable Explore
    subject there, so the forge is simply per-unit-only. No extra rule.
  - Eligibility filtering and **stable instance IDs** are retained from the recommendation,
    as is clear consequence copy when the chosen instance is equipped.

### [EPUX-26] Repair, transform, and upgrade presentation

- **A — One mixed operation list.** For: compact. Against: numeric allocation and recipe
  transforms have different interaction shapes.
- **B — Upgrade and Modify sibling views; Modify contains Repair/Transform recipes.** For:
  matches the existing draft and keeps forecasts legible. Against: one navigation layer.
- **C — Separate facilities.** For: thematic. Against: unnecessary fragmentation.
- **Recommendation: B.** In narrow mode, item → mode → operation/details is sequential.
- **OWNER RULING (2026-07-26): sections plus registered presenters, mirroring EPUX-20 — not
  B.** For a selected item the forge shows **one operation list grouped into labelled
  sections**, each operation rendered by its **registered presenter**. Rejecting B avoids a
  third navigation level (item → mode → operation), which the EPUX-03 pane budget caps at two
  adjacent panes, and avoids hardcoding an Upgrade/Modify split the operation registry does
  not otherwise need. New operation kinds slot in without a shell change, and the forge reuses
  the presentation pattern already ratified for mixed benefit types instead of inventing a
  second one.

### [EPUX-27] Rename behavior

- **A — Automatic +N suffix only.** For: safe and searchable. Against: loses a classic forge
  personalization feature.
- **B — Free player rename.** For: expressive and FE precedent. Against: moderation,
  diagnostics, search, and controller text-entry costs.
- **C — Automatic canonical name plus optional player alias stored separately.** For: both
  identity and expression. Against: two displayed names need rules.
- **Recommendation: C**, with alias optional, length-limited, locally stored, and never used
  as identity or validation input.
- **OWNER RULING (2026-07-26): automatic canonical naming in v1; the alias waits on a text-
  entry strategy.** v1 ships the automatic canonical name only (`Iron Sword +2`) — searchable,
  safe, unambiguous in diagnostics, and requiring no text input. C's two-name model stays the
  target rather than being rejected; it is gated on the research row below, not dropped.
- **Spun out: text-entry strategy research** (`RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26`).
  Player rename hit the same wall as EPUX-15's free-text search — text entry is impractical on
  a controller — so rather than paying that cost twice, the underlying capability gets decided
  once. Investigate a **native touch/controller-friendly on-screen keyboard**, acceptable even
  with a **limited character set**, and a **setting** that selects among:
  - spawn the in-game on-screen keyboard,
  - summon the **OS/system** keyboard, or
  - assume a **hardware keyboard** is attached.
  Whatever this resolves to unblocks the whole deferred text tranche together — forge alias
  (EPUX-27), shop/stock free-text search (EPUX-15) — and any future text input, so it should
  be researched as an input-layer capability rather than as a forge feature.

### [EPUX-28] Reversal/reset

- **A — Permanent only.** For: simplest economy and save model. Against: experimentation is
  risky.
- **B — Free undo.** For: friendly. Against: destroys resource decisions and complicates
  already-used weapons.
- **C — Operations permanent by default; authors may offer explicit reset/rebase recipes
  with disclosed costs/outcomes.** For: flexible and data-driven. Against: reset semantics
  must be defined per operation.
- **Recommendation: C**, but no reset recipe in the first slice.
- **OWNER RULING (2026-07-26): C, with the EPUX-06 conflict resolved — the exit review receipt
  IS the undo window.** "Permanent by default" was ambiguous once EPUX-06 ratified an optional
  author-chosen exit receipt with rollback to an activity-entry snapshot: on a receipt-bearing
  forge, operations were simultaneously permanent and freely revertible. Resolution:
  **permanent means permanent *after the receipt is accepted*.** Within a forge visit the
  player may revert to the entry snapshot; on acceptance every operation is final. This is one
  coherent rule rather than two competing ones, and it needs no forge-specific exception in a
  mechanism just made uniform.
  - Forging is **deterministic**, so it is an ideal receipt activity — the EPUX-06 warning
    about RNG-bearing activities does not apply to it.
  - An author who wants no take-backs simply **does not enable the receipt** on that forge;
    the existing per-activity-type choice already expresses this.
  - Operations remain **permanent by default** in the sense that matters: there is no free
    undo *after* the visit. Authors may still offer explicit **reset/rebase recipes** with
    disclosed costs and outcomes for later reversal, and reset semantics are defined per
    operation.
  - **No reset recipe ships in the first slice**, per the recommendation.

## Node traversal and cadence model (owner-ratified 2026-07-25)

This section captures a model ratified while walking EPUX-01. It resolves EPUX-01 and
EPUX-16 and adds an engine mechanism (overworld traversal + node cadence) that was not in
the original packet.

### Traversal layers

- **Interior (per node):** flat activity list (EPUX-01 A), authored per node.
- **Between nodes:** an optional, author-enabled Awakening-style **overworld map**. Default
  and fallback is strict linear node-advance. Linear vs. free-roam is a per-campaign
  authoring choice, backed by the same campaign-graph data.
- **Revisit:** when the overworld map is enabled, players may return to cleared nodes.

**Owner clarification (2026-08-19):** the overworld is a **responsive canvas screen**. Its
surrounding chrome follows the shared UI size classes, while the graph region uses canvas pan/zoom
behaviour. Revisiting a cleared node re-enters that node's prep hub; activities remain reachable
through the hub rather than through a second revisit-only navigation path.

### Re-entry defaults (all author-overridable)

- **Shop nodes:** persist stock between visits; restock on an author-defined cadence;
  default to infinite/non-scarce.
- **Battle & story nodes:** one-shot by default; author may mark repeatable (Awakening
  skirmish tiles vs. story chapters).
- **Event nodes:** fire-once by default; author may mark re-fireable.

These defaults make free revisit safe: no accidental XP/gold farm unless an author opts in.

### Cadence as a general node-scheduling trigger

Cadence is not a shop-only timer. A node's state advances on **triggers**, and any node
property may subscribe: **available activity set**, **battle target**, **activity
variant/version**, and **stock**. This follows the open-registry principle — cadence is a
data-driven trigger node descriptors reference, not per-feature timers.

**Trigger families**

- **Counters (monotonic — only increase):**
  - `chapter_reached: <chapter_id>` — fires once at a named story-chapter milestone.
  - `chapters_elapsed: N` — a count of story chapters, in `every N` (repeating) and
    `after N` (one-time) forms.
  - `deployments_total: N` — cumulative unit deployments across the campaign, in `every`
    and `after` forms.
  - `hours_played: N` — accumulated in-game playtime.
- **Predicates (state conditions, from the shared condition/predicate registry):** e.g.
  `roster_power >= X`, `unit_in_roster(X)`. Reusing the existing objective/AI condition
  registry means any future predicate becomes a cadence trigger for free.

**Latching**

- Counters latch inherently (they cannot go backward).
- Predicates **latch by default**; an author may set a **reversible** flag.
- **Reversible governs future access/availability only.** Content already consumed is
  permanent: a viewed interlude stays in the player's history and a completed one-shot does
  not reopen, even if the gating predicate later becomes false.

Worked examples:
- *Shop upgrade* — counter, latching → stays upgraded even if a unit later dies.
- *Recruitment-gated backstory interlude* — predicate `unit_in_roster(X)`, reversible → if
  the unit permanently dies/leaves, the interlude locks **if unplayed**; if already seen it
  remains in history. A permadeath-aware narrative gate.

**Composition:** multiple triggers may drive one node (OR'd together).

**Revisit evaluation:** entering a revisited node evaluates cadence so changes earned elsewhere are
visible, but the revisit itself advances no chapter or deployment counter. A later battle launch is
a real deployment event and advances deployment cadence normally.

**Real-time cadence: deferred (post-v1).** A real-time-hours base is intentionally left out
of v1. It breaks the otherwise deterministic, offline model (needs a trusted clock,
system-clock-rollback tamper handling, and offline-accrual rules) and would make tests
non-deterministic. The schema **defines** it, but it ships disabled behind a mockable /
injectable clock seam, to land as its own slice later. Actions-, chapters-, deployments-,
hours-played-, and predicate-based cadence are all deterministic and save-friendly.

**Save/load:** cadence state is durable — counter values, latched predicate states,
consumed/played flags, and each node's current variant pointer all persist in the save.

## Prep hub structure, convoy, and shops (owner-ratified 2026-07-25)

> **Amended 2026-08-13 by the `RPD-1..18` walk** —
> [`responsive_prep_deployment_open_questions_2026-08-12.md`](../registers/responsive_prep_deployment_open_questions_2026-08-12.md).
> This section already answered three `RPD` questions and constrained eight more, but `RPD` was
> written without citing it, so the walk had to re-derive them. What the walk **added** on top of
> this section: **Map Preview is a canvas** governed by `UBS-4`'s rule (surfaces occupy the canvas
> region, never the control band), which strengthens `[EPUX-03]`'s full-width escape hatch without
> amending it; the **auto-fill-then-swap** placement model gains its gesture (select-then-select,
> committing on the second selection, no confirm — a swap is reversible so it earns no `CAU-4`
> tag); **Manage Roster's panel registry projects a quick card** via a `quick` flag rather than a
> hardcoded action set; and **subject-memory tiering generalizes to the deployment plan** (firm
> within a visit, best-effort across, per-slot fallback). Nothing in this section is reversed.

Ratified while walking the pack with the owner. Resolves EPUX-14 and EPUX-11 and expands the
prep-hub structure well beyond the original EPUX-01..07 shell questions. It also resolves
EPUX-05, EPUX-08, and EPUX-18 by implication (see end of section).

### Top-level node menu

An author-default set of entries; each is gated by a per-node predicate, and authors may gate
or extend the set. Non-battle nodes hide the battle-only entries.

- **Explore** — subject-first services (below).
- **Manage Roster** — army configuration (below); on a battle node it also picks who deploys.
- **Map Preview** *(battle nodes)* — scout the map and place deployed units (below).
- **Save**.
- **Move to Next Primary Story Chapter** — main-path progression.
- **Start Battle** *(battle nodes)* — engage this node's encounter.

### Explore — subject-first services

Explore asks the player to pick a **subject** (a unit, or the convoy), then shows every
activity that subject is eligible for. Eligibility is a **per-subject predicate** (open
registry), so themed training halls, class-locked arenas, and faction-gated shops are just
predicates — no hardcoded eligibility enum. Services include shops, themed training halls,
arena, and forge.

- **Subject memory:** remembered **firmly within a prep visit**; **best-effort across visits**,
  falling back to the first available subject if the remembered one died or left. Provisional —
  flagged for playtest refinement.
- **Per-unit activity budget = an optional per-unit resource.** Not a special system: it is an
  author-defined per-unit resource in the wallet that activities deduct via the normal cost
  vector, so "out of budget" is just the existing "insufficient resource" failure reason.
  **Default: none** (undefined resource = unlimited activities). When an author enables it, the
  **default refill is at the end of each deployment** (a cadence trigger; per-visit/per-chapter
  are cadence alternatives).

### Manage Roster — army configuration

An **open registry of roster-config panels**; only panels the campaign actually uses appear
(no hardcoded FE-feature enum). Panels include: convoy contents and the **global item-first
view** (item search / bulk organization), inter-unit trading, item use, class change, equipped
skills, combat arts, battalions, bond rings, and so on. On a **battle node** it also holds
**deployment selection** (which units deploy).

- **Explore vs. Manage Roster** = **acquire (services)** vs. **configure (the army you own)**.
- **Class change is one engine operation with an author-chosen delivery surface:** a paid
  service at a location (Explore), a roster-config option (Manage Roster), or an item effect
  (Master Seal-style). This pattern generalizes — one primitive, multiple author-selected
  surfaces (healing, skill-learning, etc.).

### Map Preview — scouting and placement

Inspect the map, deployed enemy units, and on-map events (shops, arenas, villages), and place
deployed units.

- **Deployment placement (where):** the author **numbers start positions**; the engine
  **auto-fills them from the deployment roster in order**; the player may **swap**. Placement is
  never a mandatory chore. This is the "where" half of deployment; Manage Roster is the "who".

### Advance actions

- **Start Battle** — shown only on a node with an unresolved battle.
- **Move to Next Primary Story Chapter** — the "leave and proceed along the main path" action,
  gated behind clearing any mandatory battle.

### Convoy model

- **Owner = pricing subject only** (author picks quartermaster or main character), the default
  buyer for bulk-buy-as-convoy. Never an access gatekeeper; losing the owner never bricks the
  convoy (pricing falls back to a neutral default). Gatekeeper + respawn-with-penalty stays
  parked as a possible later advanced mode.
- **Battlefield convoy access is an aura effect**, reusing the existing aura-skill radius
  machinery: it grants a convoy-access action to allied units within radius X of the bearer
  (the bearer always has it; X=0 = bearer only, X=1 = bearer + adjacent). The distance metric
  **reuses the game's existing weapon-range / movement metric** — it does not invent its own.
  Mid-battle convoy access is skill-gated this way; **prep-time access is universal** (the base
  is always open).
- **Capacity:** default **unlimited**. With a finite cap: player buys/transfers fail before
  commit ("destination full"); unavoidable acquisitions go to a **pending-items tray** resolved
  before leaving prep (author policy, default hold-pending).
- **Disabled (author toggle) → per-unit-only storage.** Cascade: unit-full **hard-blocks** with
  a reason; shops fall back to **shopper-only buy-to-unit** (pricing subject = the shopper); the
  convoy is not a selectable Explore subject; convoy-access auras become inert and the authoring
  tools **warn at author time** if a no-convoy campaign includes convoy-access skills.

### Shops and stock

- **Stock is a first-class named entity.** Multiple shop frontends — an **on-map storefront**
  and an **Explore-tab shop** — may reference the **same stock** (author option, or each may own
  its own).
- **Shared finite stock depletes across surfaces**, and restock cadence (the EPUX-16 engine)
  applies to the shared pool. Shopper-aware pricing resolves **per surface**: on-map = the
  adjacent unit; prep = the quartermaster or chosen unit.
- **On-map event inactive presentation is reason-keyed** (author-defined, open presets):
  - **Gated / secret** (conditions unmet) → default **nothing/hidden** (secret shops).
  - **Proximity** (visible but no valid adjacent unit) → default **browse-only, no purchase**.
  - **Preview** (viewed from Map Preview pre-battle) → the same view, framed as scouting.

### Resolved by implication

- **EPUX-05** (persistent party resources + per-unit pools in context) — confirmed; the energy
  budget lives in the per-unit pool.
- **EPUX-08** (unit-first default + global item view) — satisfied: Explore is subject-first and
  Manage Roster carries the global item-first view.
- **EPUX-18** (unit-first training selection) — satisfied: Training Hall is entered through
  Explore's subject-first flow.

## Cross-bundle implementation order

1. Shared responsive activity shell and stable presentation state.
2. Wallet/resource presentation and structured quote/failure vocabulary.
3. Per-instance inventory plus faction convoy and transfer commands.
4. Shop thin panel over stock/query/transaction services.
5. Training Hall offer adapters and before/after forecasts.
6. Arena/other activity panels as separate registered consumers.
7. Forge instance picker, operation registry, effective-stat resolver, and thin panel.

The shell may be prototyped early, but each slice must leave the game usable and must
not pre-author hardcoded activity, currency, benefit, category, or forge-operation enums.

## Validation matrix

- Keyboard, mouse, touch, and controller reach every action without domain mutation
  shortcuts.
- Wide, narrow, 100%, and 200% Menu Scale preserve selection and focused region.
- Quote equals commit; stale quotes fail without partial resource/item mutation.
- Save/load preserves wallet, convoy entries, holders, forge operations, aliases, stock
  counts/cadence when enabled, and Training purchase counts when enabled.
- Split-faction campaigns never show or mutate another faction's convoy or wallet.
- Every disabled action has readable text, not color/icon-only meaning.
- Bulk operations are deterministic and report every overflow/failure.
- Unknown author registry IDs fail validation before the player enters the panel.

## Decision status

Recommendations are research recommendations unless marked **OWNER RULING**. The walk ran
2026-07-25 to 2026-07-26 and is **COMPLETE — all 28 questions are ratified.** Nothing in this
packet is awaiting an owner decision. Ratified:

- **EPUX-01 — ratified** (A + optional overworld map, revisitable nodes); see "Node
  traversal and cadence model".
- **EPUX-02 — ratified** (B: absent hides, gated shows disabled-with-reason; uniform across
  all four availability surfaces; per-entry author-set gate presentation defaulting to
  visible-disabled).
- **EPUX-03 — ratified** (C, confirming UI-ARCH-02: one controller, wide/narrow by measured
  content width) **+ pane-budget contract**: at most two panes pairing adjacent levels of the
  Explore chain, with a registry-declared full-width preference for content-dense panels.
- **EPUX-04 — ratified** (C, confirming UI-ARCH-01: shared primitives + domain-owned
  adapters) **+ availability gating promoted to a shell primitive**, so the EPUX-02 rule is
  implemented and tested once instead of per-adapter.
- **EPUX-06 — ratified** (C, with confirmation **authored** on the action plus declarative
  threshold rules, both as predicates; player/author strictness is raise-only) **+ an
  optional author-chosen exit review receipt with rollback to an activity-entry snapshot**.
  Immediate transaction persistence is unchanged. All three sub-questions were resolved
  2026-07-26: rollback restores the RNG stream (inheriting existing determinism) but authors
  are warned off RNG-bearing activities; receipt rollback is **uncharged** because rewind
  charges are battle-only and already disableable via `rewind_charges_per_map = 0`; exactly
  one snapshot is kept and discarded on acceptance, which bounds cost and implies at most one
  gated activity open at a time.
  - **Boundary clarified 2026-08-13 (`[TSV-21]`):** "raise-only" governs the **per-action
    confirmation prompt**, which stays author-controlled and cannot be weakened by a player.
    The **exit review receipt is a separate mechanism** — review and rewind, not
    confirmation — so a player setting *may* auto-accept receipts without breaching this
    rule. A store also declares whether it offers a receipt at all; where it does not, there
    is no reversal, and permanence is immediate rather than on acceptance.
- **EPUX-07 — ratified** (C, on **one unified reason contract** shared with EPUX-02 rather
  than a parallel transaction vocabulary) **+ disabled entries are focusable-but-not-
  activatable**, settling the question deferred from EPUX-02/04.
- **EPUX-16 — ratified** (author-defined cadence, default infinite; folded into the cadence
  engine).
- **EPUX-14 — ratified** (convoy owner as pricing subject; no gatekeeping).
- **EPUX-11 — ratified** (overflow to convoy; full-cap terminal handling: fail-before-commit
  for buys, pending-items tray for unavoidable acquisitions).
- **EPUX-05 / EPUX-08 / EPUX-18 — resolved by implication** via the hub-structure ruling.
- **New engines/structure ratified:** node traversal + cadence engine; the full prep-hub
  top-level menu (Explore / Manage Roster / Map Preview / Save / Move to Next Primary Story
  Chapter / Start Battle); the convoy model (pricing-subject owner, battlefield convoy-access
  aura, capacity + pending-items tray, disabled-convoy cascade); shared shop stock; and the
  per-unit energy budget as an optional wallet resource.

Ratified 2026-07-26 (the remaining 16):

- **EPUX-09 — ratified** (A for v1, command verbs only; drag/drop post-v1 as an additive
  adapter over the same authoritative mutation command).
- **EPUX-10 — ratified** (C: stack only on identical effective state).
- **EPUX-12 — ratified** (B plus **Send All to Convoy** and **Resupply**, both deterministic,
  player-directed, and fully reported) **+ spun out** `ENGINE-ITEM-HELD-PREDICATE-2026-07-26`.
- **EPUX-13 — ratified** (B: Buy/Sell sibling tabs; the session inherits its subject).
- **EPUX-15 — ratified** (C, **filters only** — free-text search cut from v1).
- **EPUX-17 — ratified** (final price in the list, **full formula in the selected item's More
  Info panel**) — establishes the list/detail split reused by EPUX-19.
- **EPUX-19 — ratified** (B, mirroring the EPUX-17 split).
- **EPUX-20 — ratified** (C: author-labelled sections + registered benefit presenters).
- **EPUX-21 — ratified** (quantity stepper, **generalized into a shared quantity primitive**
  used by the item shop and the unit-benefit shop alike; starts at 1, steps backward to a
  live effective maximum).
- **EPUX-22 — ratified** (B, **generalized**: map placement is a property of *any* Explore
  activity).
- **EPUX-23 — ratified** (all three operations ship before v1, in the order **A → C → B**).
- **EPUX-24 — ratified** (C: shared atomic transaction core, thin panels; retains FRG-20).
- **EPUX-25 — ratified** (**subject-scoped like the shop**: the subject determines reach *and*
  pricing; not the flat all-faction view of option C).
- **EPUX-26 — ratified** (**sections + registered presenters**, mirroring EPUX-20 — not B's
  sibling views, which would breach the EPUX-03 pane budget).
- **EPUX-27 — ratified** (automatic canonical naming in v1; alias gated on
  `RESEARCH-TEXT-ENTRY-STRATEGY-2026-07-26`, not dropped).
- **EPUX-28 — ratified** (C, with the EPUX-06 conflict resolved: **the exit review receipt is
  the undo window** — permanent means permanent *after acceptance*).

**Cross-cutting outcomes of this half of the walk**, which matter more than any single answer:

- **A shared quantity primitive** (EPUX-21) spanning item shop and benefit shop — this gave
  the shop quantity purchasing, which none of the shop questions settled on their own.
- **A shared transaction core** (EPUX-24) that the quantity primitive already presupposes.
- **Map placement generalized off shops onto every Explore activity** (EPUX-22), taking the
  shared-definition/shared-state pattern and the reason-keyed inactive presentation with it.
- **Subject-first scoping generalized off shops onto the forge** (EPUX-25), so subject
  determines reach and pricing for both.
- **One list/detail presentation convention** (EPUX-17 → EPUX-19) and **one sections+presenters
  convention** (EPUX-20 → EPUX-26), each now used by two services instead of one.
- **A deferred "pointer and keyboard" tranche** — drag/drop (EPUX-09), free-text search
  (EPUX-15), and forge alias (EPUX-27) — deliberately grouped so v1 degrades on no input
  method, and unblocked as a set by the text-entry research row.

**Next: implementation planning.** No question in this packet remains open; the follow-on work
is the cross-bundle implementation order above plus the two spun-out rows.
