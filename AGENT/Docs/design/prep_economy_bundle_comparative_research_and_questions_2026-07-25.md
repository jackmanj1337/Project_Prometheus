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

### [EPUX-07] Transaction result and failure feedback

- **A — Disable action only.** For: quiet UI. Against: inaccessible and opaque.
- **B — Modal error after attempted commit.** For: explicit. Against: interrupts browsing.
- **C — Disabled action plus inline reason; structured error modal only for unexpected
  commit failure.** For: preventative, testable, and low interruption. Against: needs a
  stable reason vocabulary.
- **Recommendation: C.** Minimum reasons: insufficient resource, missing material,
  destination full, cap reached, gate unmet, unsellable, invalidated quote, and save
  failure.

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

All recommendations above are research recommendations, not owner-ratified changes.
EPUX-01 through EPUX-28 should be walked in order. Questions that merely confirm an
existing register may be accepted as a batch; EPUX-14 is the only identified wording
clarification between earlier Shop and shopper-subject decisions.
