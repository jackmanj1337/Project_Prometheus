---
Type: design
Status: Draft - owner review
Last verified: 2026-07-25
Track IDs: DISCUSS-CONVOY-SHOP-UX-2026-07-23; DISCUSS-PREP-HUB-UX-2026-07-24; DISCUSS-PREP-ACTIVITIES-UX-2026-07-24; DISCUSS-FORGING-UX-2026-07-24
---

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
  - **Derived, not ruled — flagged for EPUX-04/06/07 and the accessibility pass:** whether
    disabled entries stay keyboard/controller-focusable so the reason is reachable by
    screen reader rather than hover-only. Recommend focusable-but-not-activatable; not
    settled here.

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
  - The still-open focusability question (are disabled entries keyboard/controller
    focusable so the reason is screen-reader reachable?) is therefore a **shell-level**
    decision too. Still recommended focusable-but-not-activatable; deferred to EPUX-06/07
    and the accessibility pass.

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
  - **Open sub-questions, deferred to the persistence/economy implementation** (do not
    settle them here):
    1. Does a rollback **consume a rewind charge** from the decaying ledger, or is it free?
       Free unlimited rollback makes shop decisions costless — buy, read the receipt, roll
       back, re-buy differently — which is close to save-scumming by design.
    2. Does re-entry after a rollback **reuse the same RNG stream**? If not, any activity
       with randomness (arena, random forge outcome, stock refresh) becomes a reroll lever.
       See `rng_determinism_design_2026-06-11.md`.
    3. Snapshot cost on **web and console** targets, which is part of why the gate is
       author-chosen per activity rather than universal.

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

### [EPUX-10] Stacking and instance identity

- **A — Display every instance.** For: state is never hidden. Against: large convoys become
  noisy.
- **B — Stack by base definition only.** For: compact. Against: hides durability, forge,
  name, and bound-state differences.
- **C — Stack only entries with identical effective state; expand on demand.** For: compact
  without lying. Against: grouping key is more complex.
- **Recommendation: C.** Forged/named/bound entries are unique; identical unmodified
  instances may stack with aggregate count and durability summary.

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

## Owner questions — shop and economy

### [EPUX-13] Buy/sell organization

- **A — Separate activities.** For: simple lists. Against: duplicate context and travel.
- **B — Buy/Sell sibling tabs in one shop session.** For: familiar, retains shopper and
  filters. Against: tab state must be explicit for controller users.
- **C — One mixed list with action per item.** For: unified search. Against: price direction
  and ownership become visually ambiguous.
- **Recommendation: B**, with text labels, remembered tab per session, and explicit
  buy-cost versus sell-yield styling.

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

### [EPUX-20] Mixed benefit types

- **A — One long universal Training list.** For: one panel. Against: class EXP, stats,
  skills, sources, and recruits have different comparison needs.
- **B — Separate hardcoded facilities.** For: focused. Against: closed vocabulary and author
  proliferation.
- **C — One activity with author-defined labelled sections/tabs backed by registered benefit
  presenters.** For: open and organized. Against: needs fallback rendering for unknown types.
- **Recommendation: C.** Unknown registered types fail validation loudly; no engine enum.

### [EPUX-21] Repeat purchases and caps

- **A — Allow rapid repeat with no intermediate feedback.** For: fast. Against: accidental
  overspend.
- **B — Confirm every repeat.** For: safe. Against: tedious for EXP spending.
- **C — Hold/repeat or quantity stepper for divisible benefits; explicit confirmation for
  permanent discrete grants.** For: proportional. Against: benefit metadata must say whether
  it is divisible/repeatable.
- **Recommendation: C.** Always show remaining resource and effective cap live.

### [EPUX-22] Arena/mock-battle placement

- **A — Fold into Training Hall.** For: fewer activities. Against: combat setup/risk and
  reward loops differ from purchases.
- **B — Separate Arena activity sharing roster/forecast primitives.** For: honest mental
  model and room for lethal/safe/escalating rules. Against: one more hub entry.
- **C — Always launch from map nodes.** For: spatial fiction. Against: unnecessary campaign
  graph coupling.
- **Recommendation: B.** Triangle Strategy's Tavern/Mock Battle separation supports this.

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

### [EPUX-24] Forge/shop relationship

- **A — Separate transaction cores and panels.** For: independent implementation. Against:
  duplicated quote/commit/rollback bugs.
- **B — Forge is a shop row type.** For: reuse. Against: instance mutation, repair, rename,
  and point allocation fit poorly into stock semantics.
- **C — Shared atomic transaction core, separate thin panels, with transforms optionally
  presented in either.** For: one cost/trade-in contract and honest domain UX. Against:
  requires a deliberate common command model.
- **Recommendation: C.** Retains FRG-20.

### [EPUX-25] Forge item picker scope

- **A — Unit inventory only.** For: simple ownership. Against: forces convoy shuffling.
- **B — Convoy only.** For: centralized. Against: hides equipped/held candidates.
- **C — All faction-owned eligible instances, showing holder and equipped state.** For:
  efficient and complete. Against: modifying equipped gear needs clear consequence copy.
- **Recommendation: C**, filtered to eligible instances and preserving stable instance IDs.

### [EPUX-26] Repair, transform, and upgrade presentation

- **A — One mixed operation list.** For: compact. Against: numeric allocation and recipe
  transforms have different interaction shapes.
- **B — Upgrade and Modify sibling views; Modify contains Repair/Transform recipes.** For:
  matches the existing draft and keeps forecasts legible. Against: one navigation layer.
- **C — Separate facilities.** For: thematic. Against: unnecessary fragmentation.
- **Recommendation: B.** In narrow mode, item → mode → operation/details is sequential.

### [EPUX-27] Rename behavior

- **A — Automatic +N suffix only.** For: safe and searchable. Against: loses a classic forge
  personalization feature.
- **B — Free player rename.** For: expressive and FE precedent. Against: moderation,
  diagnostics, search, and controller text-entry costs.
- **C — Automatic canonical name plus optional player alias stored separately.** For: both
  identity and expression. Against: two displayed names need rules.
- **Recommendation: C**, with alias optional, length-limited, locally stored, and never used
  as identity or validation input.

### [EPUX-28] Reversal/reset

- **A — Permanent only.** For: simplest economy and save model. Against: experimentation is
  risky.
- **B — Free undo.** For: friendly. Against: destroys resource decisions and complicates
  already-used weapons.
- **C — Operations permanent by default; authors may offer explicit reset/rebase recipes
  with disclosed costs/outcomes.** For: flexible and data-driven. Against: reset semantics
  must be defined per operation.
- **Recommendation: C**, but no reset recipe in the first slice.

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

**Real-time cadence: deferred (post-v1).** A real-time-hours base is intentionally left out
of v1. It breaks the otherwise deterministic, offline model (needs a trusted clock,
system-clock-rollback tamper handling, and offline-accrual rules) and would make tests
non-deterministic. The schema **defines** it, but it ships disabled behind a mockable /
injectable clock seam, to land as its own slice later. Actions-, chapters-, deployments-,
hours-played-, and predicate-based cadence are all deterministic and save-friendly.

**Save/load:** cadence state is durable — counter values, latched predicate states,
consumed/played flags, and each node's current variant pointer all persist in the save.

## Prep hub structure, convoy, and shops (owner-ratified 2026-07-25)

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

Recommendations are research recommendations unless marked **OWNER RULING**. The walk is
in progress (started 2026-07-25). Ratified so far:

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
  Immediate transaction persistence is unchanged. Three sub-questions deferred to the
  persistence/economy implementation: rewind-charge cost, RNG reuse on re-entry, snapshot
  cost on web/console.
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

Still open: EPUX-09, EPUX-10, EPUX-12, EPUX-13, EPUX-15, EPUX-17, EPUX-19..28
(16 questions). Several merely confirm an existing register and may be accepted as a batch
when the walk resumes. **The entire hub and shared-interaction block (EPUX-01..07) is now
closed** — what remains is inventory/convoy (09/10/12), shop (13/15/17), Training-Hall and
activities (19..22), and forging (23..28).
