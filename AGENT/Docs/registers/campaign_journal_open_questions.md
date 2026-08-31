---
Role: dated
Type: register
Status: RESOLVED — `CJ-1..22` authored and walked 2026-08-30; rulings `[CJ-S1]`..`[CJ-S38]`
  (sub-question sweep included)
Last verified: 2026-08-30
Register: CJ-1..22
Tracker: CAMPAIGN-JOURNAL-DESIGN-2026-08-30
---

# Campaign Journal, Notifications, Quests, and Side Objectives — Research and Owner Questions

This packet researches one mixed player need: **remember what changed, understand what can be
done, and reach the relevant place without hunting through unrelated screens**. It does not assume
that every message, battle objective, and quest should share one runtime object.

The research conclusion is a deliberately split design:

1. one persistent **Campaign Journal / activity-record service** owns campaign-scale actionable
   and historical records, including quests, opportunities, reminders, bounties, relationship
   readiness, and disclosed stock refreshes;
2. one **notification router** owns transient presentation and player category settings, whether
   the source is a journal transition, combat feedback, a rule flip, or another system event; and
3. battle-local primary and optional objectives remain in the existing objective system. They may
   emit a campaign journal result through an adapter, but the journal does not evaluate tactical
   victory, defeat, or per-turn progress.

This is one lifecycle model where the job is genuinely shared, plus two presentation/evaluation
boundaries where combining the jobs would duplicate existing systems. No implementation is
authorised by this register.

## Research method and confidence

The required comparison set is complete: **Breath of the Wild**, **Fire Emblem: Three Houses**,
and six additional games. Four of the additional games are turn-based tactics titles: **XCOM 2**,
**Triangle Strategy**, **Tactics Ogre: Reborn**, and **Into the Breach**. **The Witcher 2** and
**Marvel's Midnight Suns** add broader journal and campaign-cadence evidence.

Rows distinguish directly documented or visible behaviour (**observed**) from a Prometheus design
conclusion (**inference**). Sources are official publisher pages/manuals where they answer the
question; community references fill UI details that official marketing omits. This packet does
not infer a game's internal architecture from its interface.

## Comparative findings

| Game | Observed player-facing behaviour | Useful precedent | Limitation / warning |
|---|---|---|---|
| **The Legend of Zelda: Breath of the Wild** | Nintendo directs a lost player to the Adventure Log, where the selected main challenge states what to do next. The log separates main and side quests; a quest can project a marker onto the map. The official guide also notes optional challenges that never enter the log. [Nintendo play guide](https://www.nintendo.com/jp/zelda/botw/guide/index.html), [official-guide overview](https://www.piggyback.com/online-guide/the-legend-of-zelda/en/), [Adventure Log reference](https://zelda.fandom.com/wiki/Adventure_Log) | A persistent return point, small top-level taxonomy, and explicit tracked destination support resuming after time away. | A log is not proof that every optional activity belongs in it. One tracked marker also avoids map noise but hides other opportunities until the player returns to the log. |
| **Fire Emblem: Three Houses** | The campaign advances on a calendar with a bounded set of days; exploration, teaching, battles, quests, paralogues, and support conversations share that cadence. Nintendo describes support as important and exploration as a major source of story/world information; its update notes confirm quests, calendar surfaces, support-conversation readiness, and separately saved side-story progress. [Nintendo overview](https://www.nintendo.com/au/news-and-articles/fire-emblem-three-houses-101/), [Nintendo update notes](https://en-americas-support.nintendo.com/app/answers/detail/a_id/46816/~/how-to-update-fire-emblem%253A-three-houses), [campaign/calendar overview](https://en.wikipedia.org/wiki/Fire_Emblem%3A_Three_Houses) | A shared campaign-time vocabulary can make deadlines, conversations, facilities, and missions understandable together. | Many heterogeneous prompts competing for each free day create checklist pressure. A calendar is a cadence view, not automatically a good history/archive view. |
| **XCOM 2: War of the Chosen** | The Geoscape is a campaign command surface: the player advances time while research, engineering, missions, faction activity, and hostile Dark Events progress. The manual presents the Geoscape as a map with faction and mission markers rather than a prose quest journal. [official manual](https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/593380/manuals/XCOM2_WOTC_ONLINE_MANUAL_SHEET_ENG.pdf?t=1728669045) | Countdown and threat information belongs beside the campaign clock and destination, with interruptions when player attention is required. | Turning every timer into a quest would erase the distinction between a project, a threat, and a mission. Constant modal interruptions also fragment planning. |
| **Triangle Strategy** | Story decisions shape route and recruitment. Distinct side-story icons appear on the world map, separate from campaign-critical story icons; character stories can unlock from hidden conviction and progression requirements. [Nintendo game overview](https://www.nintendo.com/au/games/nintendo-switch/triangle-strategy/), [side-story UI observation](https://www.nintendolife.com/guides/triangle-strategy-tips-and-battle-tactics-walkthrough-tactical-points-phases-kudos-quietuses-guide), [unlock reference](https://game8.co/games/Triangle-Strategy/archives/369839) | Separate icon/state categories preserve “optional story now available” without pretending it is a conventional objective checklist. | Hidden requirements protect discovery but frustrate deliberate pursuit. Showing locked future rows, totals, or names would also leak route and recruit spoilers. |
| **Tactics Ogre: Reborn** | The Warren Report combines people, events, news, and replayable story information. Reading a report topic can itself reveal or unlock a location. The game also has branching story routes rather than one fixed checklist. [Square Enix overview](https://amp.square-enix-games.com/en_US/news/tactics-ogre-reborn-preview), [Warren Report feature summary](https://www.gematsu.com/2022/11/tactics-ogre-reborn-details-warren-report-side-stories-relics-and-more-classes) | A journal entry can be both lore/history and an authored discovery trigger, and a replay/archive can coexist with actionable information. | Hiding required progression behind “read this report” makes opening a menu an opaque gameplay gate. Prometheus should never require a record to be marked read before its world effect becomes true unless an author explicitly stages a conversation/event that way. |
| **Into the Breach** | Each battle exposes a short set of mission objectives and their separate rewards. Optional objectives can appear during the battle (for example a time pod), but they resolve with that mission and contribute to the island outcome; they are not campaign quests. [mission/objective reference](https://intothebreach.fandom.com/wiki/Missions), [Subset Advanced Edition overview](https://new.subsetgames.com/itb_ae.html) | Battle-local optional objectives should remain visible beside tactical state, with explicit success/reward and no journal ceremony during the fight. | Persisting every turn-by-turn objective update would flood a campaign journal and duplicate the battle HUD/results screen. |
| **The Witcher 2** | The manual's Journal contains quests plus locations, characters, monsters, crafting, tutorials, alchemy, glossary, and retrospections. Quest rows distinguish tracked, completed, failed, and newly updated states. [official manual](https://cdn.steamstatic.com/steam/apps/20920/manuals/The%20Witcher%202%20Manual%20-%20English.pdf?t=1659618473) | One shell can host several record families while retaining family-specific views, filters, and lifecycle icons. Completed and failed history remains inspectable. | A universal journal easily becomes a dumping ground. New/update badges across every tab need acknowledgement rules or they become permanently noisy. |
| **Marvel's Midnight Suns** | The campaign alternates tactical missions and Abbey time. Mission types expose different objectives; between missions, dialogue, Hangouts, gifts, compliments, and requests advance friendships and unlock combat benefits. [PlayStation/Firaxis tips](https://blog.playstation.com/2022/12/01/top-tips-to-get-ready-for-marvels-midnight-suns-out-december-2/), [2K DLC progression example](https://support.2k.com/hc/en-us/articles/13307115860499-Marvel-s-Midnight-Suns-How-to-Unlock-Dlc) | Relationship readiness, personal requests, missions, and daily opportunities can share a campaign planning surface without sharing evaluation code. | Daily-message volume can turn authored character moments into chores. “Available now” and “expires now” must not look identical, and non-expiring opportunities should not be assigned false urgency. |

### Cross-game conclusions

1. **The useful unification is a shared record envelope, not one content type.** Strong examples
   group heterogeneous knowledge under one shell but keep quests, lore, people, threats, and
   battle objectives recognisable.
2. **Lifecycle and attention are separate axes.** `active/completed/failed` describes the record;
   `new/updated/unread/pinned` describes the player's relationship to its presentation. Combining
   them makes “read” accidentally complete gameplay.
3. **Countdowns need a named clock.** “Three chapters,” “two deployments,” and “after a predicate
   becomes true” are not interchangeable. A generic integer with a UI label would lie.
4. **Discovery is not an empty locked row.** Route-exclusive characters, quests, and destinations
   should be absent until revealed. A revealed but gated opportunity may remain visible with a
   reason under the existing Prometheus availability contract.
5. **Battle-local optional objectives are a different scale.** They need immediate progress and
   reward feedback. Only their accepted campaign consequence belongs in persistent history.
6. **One transient message is not one persistent record.** Combat callouts and phase banners may
   need notification routing without journal persistence; a quiet journal update may need no toast.

## Prometheus precedence and reuse audit

The following is measured against `agent/integration` at the task base plus the resolved design
registers named below. “Reuse” means consume the existing owner; it does not mean move that owner
into the journal.

| Existing or planned owner | Current job | Reuse / expansion | Explicit non-ownership |
|---|---|---|---|
| `RequirementSystem` and `[REQ-2]` | Open boolean predicates, structured unmet reasons, and localized rendering in campaign/prep/menu contexts. | Journal activation, completion, failure, visibility, and action availability may reference the same authored requirements and reason envelope. | Do not build quest-specific condition switches or a second unmet-reason vocabulary. |
| `CadenceEngine` and `[CVS-S6..S7]` | Open counter/predicate trigger families, edge ticks, latches, active state, and opaque subscriptions. Stock already consumes this design. | Journal reminders and deadlines reference cadence trigger ids and render only author-approved disclosed clocks. Add a new trigger family through the registry only when the clock itself is new. | The cadence engine does not own quest text, lifecycle, rewards, notification priority, or per-consumer “seen” state. |
| `ObjectiveConditionRegistry`, `ObjectiveCondition`, `TurnManager` | Open tactical victory/defeat conditions, evaluation, and concise objective display. Existing types include rout, seize, defeat boss, escape, survive/defend, protect, and turn limit. | Optional battle objectives should use the same open handler shape and tactical context. Results may emit one stable campaign outcome/fact and one journal summary. | The journal never polls map units or decides battle victory/defeat. Do not coerce a campaign bounty into `ObjectiveCondition` before a battle exists. |
| `CampaignData` graph, campaign nodes, battle result actions, and `MutableCampaignState` | Campaign routing and authored permanent facts/rule patches. | Journal entry lifecycle can be activated or resolved by campaign transitions and may deep-link to known nodes/activities. Quest consequences still commit through the existing transaction/result-action owners. | A journal record is not a second campaign graph and does not directly mutate gold, roster, rules, or routing. |
| `CampaignManager`, `SaveManager`, `SaveData`, `SaveCodec` | Active campaign state, transactional saves, package identity, and migrations. | Persist journal lifecycle and attention state inside the campaign save envelope with stable ids; derive replay-safe notifications from transitions, not on load. | No separate journal save file or global cross-pack journal. One self-contained pack is active at a time `[ICO-1..6]`. |
| `EventBus` | Shared runtime events including combat, phase, fog, results, rewards, and campaign rule flips. | Notification routing can subscribe to stable domain events; a journal service can emit one entry-transition event for projections. | Do not make the signal bus the durable journal. Signals are occurrences, not saved records. |
| Combat feedback `[CFB-1..18]` | Ordered combat-event presentation and category settings. `[CFB-12]` already establishes player-facing notification-category controls. | Reuse its category/settings vocabulary and renderer boundary for combat sources. A general notification router may broaden the same pattern outside combat. | Journal preferences must not silently change combat choreography; persistent history is not a combat log. |
| Rule flip notification | Existing four-second transient presentation of `campaign_rule_flipped`. | Route through the shared notification presentation seam later; optionally journal only author-declared campaign-significant changes. | Do not persist every rule flip automatically; map-scope reverts would create misleading permanent history. |
| Availability and accessibility `[EPUX-02/04/07]`, `[RPD-15]`, `[ANN-1..5]` | Hidden-versus-gated contract, focusable disabled reasons, native Godot accessibility mapping. | Journal rows and actions inherit the same shell treatment. Dynamic updates use accessible names/descriptions/live regions only after the native validation required by `[ANN-5]`. | No bespoke TTS or journal-only disabled treatment. Transient visual feedback cannot be the sole carrier of required information. |
| Relationship UX `[SUPUX-1..10]` | Shared pair record, readiness, replay, spoiler treatment, and deep-link return contract. | Relationship readiness writes or updates a persistent journal entry that deep-links to the same pair record. | The journal does not own relationship points, ranks, conversations, replay, or pair validity. |
| Shop stock `[CVS-S5..S8]` | Shared stock entity and cadence-backed restock; disclosure is author-enabled and limited to human-readable counter clocks. | A disclosed future refresh may create/update a reminder; a fired refresh may create a result notification and history entry. | The journal does not calculate stock or translate arbitrary predicates into invented countdown prose. |
| Responsive shell, `ModalScreen`, `FocusNavigator`, `[L10N-7]` | Wide/Compact layout, focus/scroll restoration, controller/touch traversal, and localization extent. | Journal uses one data source across Wide and Compact; deep-link Back returns to the exact originating row/surface. | No separate Compact journal model, no mouse-only affordance, and no text baked into icons. |
| Campaign editor `[CEUI/CEUI-S]`, GDD 11 | Pack authoring shell, validation, previews, and open-registry extension points. | Eventually author records, lifecycle requirements, destinations, and notification policy in the pack; preview transitions and spoiler visibility. | This research does not add editor widgets before the runtime/data contract is ruled. A fixture is not pack adoption. |

### Recommended responsibility model

```text
domain owners                       durable shared record             projections

relationships ─┐                                                   ┌─ Journal screen
shop cadence ──┼─ transition request ─> Campaign Journal service ──┼─ badges/history
campaign graph ┤                         (saved lifecycle + attention)└─ deep links
bounty/quest ──┘                                  │
                                                  └─ transition event ─┐
combat/objectives ─ direct presentation event ────────────────────────┼─> Notification router
rule flips/fog/etc ─ direct presentation event ───────────────────────┘   (channel/category/queue)

battle objective registry ── evaluates battle state ──> results/receipt ──> optional journal summary
requirements/cadence ── evaluate reusable authored conditions/clocks; neither renders the shell
```

The **Campaign Journal service** is the only new domain owner proposed by the research. It owns a
stable record id, family, source reference, authored localized presentation, discovery state,
lifecycle, optional actionable destination, optional disclosed cadence reference, and attention
state. “Quest,” “opportunity,” “reminder,” and “history” are profiles/views over that envelope,
not separate engines.

The **notification router** is a presentation coordinator, not a durable gameplay system. It
chooses allowed channel, category, queue/coalescing, urgency, and accessible presentation from an
already-committed event. It never completes a quest or changes campaign state.

The **battle objective system remains separate** because it evaluates live tactical facts at
turn/combat/action boundaries and already owns win/loss semantics. Optional objectives expand that
registry/result envelope; they do not become campaign journal records mid-evaluation.

## Provisional record contract for the owner walk

This is a discussion shape, not a locked schema. Names are descriptive rather than implementation
commitments.

```gdscript
{
  "id": "stable_pack_local_id",
  "family": "quest | opportunity | reminder | relationship | bounty | information",
  "source": {"kind": "relationship_pair | shop | campaign_node | authored", "id": "..."},
  "presentation": {"title_key": "...", "body_key": "...", "icon_id": "..."},
  "visibility_requirement": {},
  "activate_requirement": {},
  "complete_requirement": {},
  "fail_requirement": {},
  "cadence_ref": "optional_existing_trigger_id",
  "cadence_disclosure": "none | remaining | due_at",
  "destination": {"kind": "screen | pair | campaign_node | map_location", "id": "..."},
  "notification_policy": {"category": "...", "on": ["activated", "updated", "due", "resolved"]}
}
```

Saved runtime state should be smaller: stable id, lifecycle, discovered/activated/resolved
transition facts, attention state, pin state, and any immutable snapshot required to keep history
truthful after authored names or world state change. Requirements, text, and destinations remain
pack data unless a compatibility migration explicitly snapshots them.

## Owner questions

### `[CJ-1]` What is the top-level player-facing name and promise?

- **A — Campaign Journal:** history plus actionable records; broad enough for relationships,
  rumors, quests, and reminders.
- **B — Quest Log:** immediately understood, but falsely implies every row is a task.
- **C — Campaign Feed:** fits recency, but weakens deliberate lookup and completed history.
- **Recommendation: A.** Use **Campaign Journal** as the shell; use **Quests**, **Opportunities**,
  **Reminders**, and **History** as views, not competing top-level systems.

### `[CJ-2]` Which records belong in the persistent journal?

Choose whether persistence is author-declared, category-defaulted, or automatic for every
notification. **Recommendation:** author/domain-declared with safe family defaults. Never persist
every notification automatically. Persist campaign-scale actionable facts and meaningful outcomes;
leave strike callouts, phase banners, ordinary cap changes, and repeated tactical progress out.

### `[CJ-3]` Is “quest” a separate engine or a profile over the shared record lifecycle?

**Recommendation:** profile. A quest has authored objectives/stages and usually rewards, but its
visibility, activation, completion, failure, destination, attention, save, and history needs are
the same shared record job. Consequences still commit through campaign transactions/result actions.

### `[CJ-4]` Which lifecycle states are canonical?

Choose the minimum vocabulary. **Recommendation:** `undiscovered`, `available`, `active`,
`completed`, `failed`, `expired`, and `withdrawn`, with `archived` as a view/attention choice rather
than gameplay lifecycle. `updated`, `new`, `unread`, and `pinned` are separate attention fields.

### `[CJ-5]` Who may transition a record?

Choose polling, source-issued transition requests, or journal-owned evaluation at safe boundaries.
**Recommendation:** journal evaluates authored requirements/cadence at named safe campaign
boundaries and accepts idempotent source requests. It emits a transition only after the source
transaction commits. UI read/unread state never drives gameplay transitions.

### `[CJ-6]` How do multi-step quests compose?

Choose nested steps in one record, separate linked records, or campaign-node reuse.
**Recommendation:** one parent record with ordered authored stages, each using the shared
requirement/destination shape; branch consequences remain in `CampaignData`. Split into linked
records only when stages must appear independently in filtering/history.

### `[CJ-7]` What discovery and spoiler rule applies?

**Recommendation:** inherit `[SUPUX-8]` and `[EPUX-02]`. Undiscovered content is absent from rows,
counts, search, filters, map markers, accessibility trees, and completion totals. Revealed authored
content whose current requirement is false may be visible and gated with a localized reason.

### `[CJ-8]` Are total counts ever shown?

**Recommendation:** counts cover discovered records only during play. Campaign-completion totals
may expose a denominator only if the pack explicitly opts in after terminal completion; otherwise
route-exclusive and secret content stays uncounted.

### `[CJ-9]` How are clocks represented and disclosed?

**Recommendation:** reference `CadenceEngine` trigger ids; never store a generic journal countdown.
Disclosure is authored and must name its unit (“2 deployments,” “next chapter”). Predicate clocks
show a requirement reason, not a fake time estimate. `[CVS-S7]` remains precedent.

### `[CJ-10]` How do due, overdue, expired, failed, and withdrawn differ?

**Recommendation:** `due` is attention on an active record; `expired` means a disclosed opportunity
ended because its clock passed; `failed` means an authored failure condition occurred; `withdrawn`
means the source intentionally removed it without blaming the player. “Overdue” exists only for a
still-actionable soft target and must never be inferred after expiry.

### `[CJ-11]` What deserves a transient notification?

Choose all transitions, family defaults, or author lists. **Recommendation:** family defaults plus
author opt-in/out per transition. Activation, material update, approaching disclosed deadline, and
resolution are eligible; repeated progress is coalesced and silent by default. Urgent never means
modal unless immediate input is genuinely required.

### `[CJ-12]` How are notification categories and settings organised?

**Recommendation:** extend `[CFB-12]`'s player-facing category pattern without merging combat and
campaign preferences. Suggested campaign categories: quests/objectives, relationships,
facilities/stock, opportunities/reminders, and campaign/world changes. Each supports all,
milestones only, or transient off; persistent journal state remains intact.

### `[CJ-13]` What queue/coalescing rule applies?

**Recommendation:** one router queues by priority and presentation boundary, coalesces repeated
source updates, and offers a “N more updates” summary that opens the journal. Never allow multiple
toasts to cover battle forecast, dialogue choices, results, or another modal.

### `[CJ-14]` What is the default journal view and ordering?

**Recommendation:** **Needs attention** first (due soon, newly available, materially updated), then
active pinned, other active, and recent outcomes. Offer family, status, location, source, and text
filters. Do not mix completed history into the active default merely because it is recent.

### `[CJ-15]` What does acknowledgement mean?

**Recommendation:** opening the relevant record clears `new/updated`; dismissing a toast alone does
not. “Mark all seen” changes attention only. It never activates, completes, archives, or withdraws
gameplay content.

### `[CJ-16]` How do pinning, deep links, and map markers work?

**Recommendation:** several records may be pinned in the journal, but each presentation context
sets a small marker budget and explains overflow. A deep link resolves through a destination
registry and preserves origin for Back. Unavailable/hidden destinations fail closed without
revealing names or coordinates.

### `[CJ-17]` What persists in completed/failed history?

**Recommendation:** keep outcome, resolved campaign time, source, and the player-facing title/body
needed to remain truthful. Preserve optional conversation replay through its owning archive. Do not
keep every progress tick or tactical log line.

### `[CJ-18]` How do save/load, rewind, and replay avoid duplicate notifications?

**Recommendation:** save lifecycle and attention state transactionally with campaign state. Load
restores silently. Notify only for a new committed transition id/sequence; never re-emit because a
predicate is already true after load. Imported/older saves run an idempotent reconciliation pass
that records state without presenting a wall of historical toasts.

### `[CJ-19]` Where is the boundary with battle-local optional objectives?

**Recommendation:** optional objectives use `ObjectiveConditionRegistry`-style validation,
evaluation, display, and results. The HUD owns live progress; Map Results owns reward/failure. A
campaign-significant outcome may append one journal result or update its parent bounty/quest after
the battle transaction commits. No per-turn mirroring.

### `[CJ-20]` How are bounties and campaign quests connected to a battle?

**Recommendation:** the campaign record names requirements and an optional encounter/destination;
the encounter authors its own tactical primary/optional objective ids. A binding maps the committed
battle outcome back to the campaign record. Neither side copies the other's conditions.

### `[CJ-21]` What is the Compact/controller/touch/accessibility contract?

**Recommendation:** Wide may show filter/list/detail together; Compact presents list then detail.
Rows are fully tappable, controller order matches visual order, filters do not steal focus, and Back
restores exact row/scroll/origin. State/urgency never relies on color or icon alone. Dynamic
announcements use Godot native accessibility after `[ANN-5]` validation; persistent text always
remains available when transient feedback is off.

### `[CJ-22]` What authoring and validation contract is required before implementation?

**Recommendation:** stable pack-local ids; localized text keys; open family and destination
registries; validated requirement/cadence references; transition-conflict and unreachable-state
diagnostics; spoiler-safe preview contexts; and explicit notification/persistence policies.
Validation rejects duplicate ids and invalid references within the one active self-contained pack.
The capability cannot close as completed until a campaign pack authors it through
`select_campaign()` and it is played.
---

## Owner rulings

Walked 2026-08-30. Rulings are `[CJ-S*]` and are recorded as they are taken. Four rulings
**depart from this packet's own recommendation** and are marked as such; the recommendation text
above is left unedited so the departure stays legible.

### Section 1 — ownership and scope (`CJ-1..3`, `CJ-19..20`)

- **`[CJ-S3]` — `CJ-3` → profile.** A quest is a profile over one shared record lifecycle, not a
  second engine. Authored objectives/stages and rewards are quest-shaped content; visibility,
  activation, completion, failure, destination, attention, save and history are the shared record
  job. Consequences still commit through the existing campaign transaction/result-action owners
  (`MutableCampaignState.carry_forward_facts`). This is the pivot ruling: it collapses the
  journal-version/quest-version fork that would otherwise have doubled `CJ-4..18`.
- **`[CJ-S1]` — `CJ-1` → A. Campaign Journal.** The shell is the **Campaign Journal**; **Quests**,
  **Opportunities**, **Reminders** and **History** are views over it, never competing top-level
  systems. Families are an **open registry** — the same extension shape as
  `ObjectiveConditionRegistry` and the cadence trigger families — because the pack author, not the
  engine, decides what families a campaign has. A fixed main/side taxonomy is rejected. A
  zero-content pack must produce an empty, clean journal.
- **`[CJ-S2]` — `CJ-2` → author/domain-declared with safe family defaults.** Each family carries a
  sane persistence default and an author may opt an individual record in or out. A notification is
  **never** persisted merely because it was routed. Strike callouts, phase banners, ordinary cap
  changes and repeated tactical progress stay out of history.
- **`[CJ-S19]` — `CJ-19` → extend the objective resource, as its own build row.** Battle-local
  optional objectives stay in the objective system, but this is an **extension, not reuse**: see
  `[CJ-S24]`. The extension adds an optional-objectives bucket alongside
  `MapData.victory_conditions` / `defeat_conditions`, a per-condition reward/receipt, and progress
  display that is not victory/defeat — reusing the existing registry's validate/evaluate/display
  handler shape. The HUD owns live progress; Map Results owns reward/failure. No per-turn mirroring
  into the journal.
- **`[CJ-S20]` — `CJ-20` → binding, not copying.** The campaign record names its requirements and an
  optional encounter/destination; the encounter authors its own tactical objective ids. A binding
  maps the **committed** battle outcome back to the campaign record after the map transaction
  commits. Neither side copies the other's conditions. `RequirementSystem.evaluate_objective_condition`
  is the existing precedent for this direction of bridge.

### Section 2 — lifecycle and discovery (`CJ-4..8`, `CJ-10`)

- **`[CJ-S4]` — `CJ-4` → seven states.** Canonical saved lifecycle is `undiscovered`, `available`,
  `active`, `completed`, `failed`, `expired`, `withdrawn`. `archived` is a view/attention choice and
  never a gameplay state. `new`, `updated`, `unread` and `pinned` are **separate attention fields**,
  so no query has to join lifecycle and attention to answer either one.
- **`[CJ-S5]` — `CJ-5` → journal evaluates at named safe boundaries, and accepts idempotent source
  requests.** The journal evaluates authored requirements and cadence at named campaign boundaries;
  sources (shop, relationships, campaign graph) may push idempotent transition requests. A
  transition is emitted only **after** the source transaction commits. Polling is rejected — it
  re-derives state that must be transactional and makes `[CJ-S18]` unachievable. UI read/unread
  state never drives a gameplay transition.
- **`[CJ-S6]` — `CJ-6` → one parent record with ordered authored stages.** Each stage uses the
  shared requirement/destination shape. Branch consequences remain in `CampaignData`. Split into
  linked records only when a stage must appear independently in filtering and history.
- **`[CJ-S7]` — `CJ-7` → inherit the shipped gate vocabulary.** Discovery and gating reuse
  `RequirementSystem`'s `GATE_VISIBLE_DISABLED` / `GATE_HIDDEN_UNTIL_MET`, not a journal-local rule.
  Undiscovered content is absent from rows, counts, search, filters, map markers, accessibility
  trees and completion totals. Revealed authored content whose requirement is currently false may be
  visible and gated with a localized reason from `render_reason`.
- **`[CJ-S8]` — `CJ-8` → discovered-only, always. DEPARTS from the recommendation.** The packet
  recommended an opt-in denominator after terminal completion; the owner ruled **no denominator
  ever**. Counts cover discovered records only, at every point in the campaign, including after
  terminal completion, and a pack may not opt in. Consequence: the journal has no
  completion-percentage affordance at all, and the Compendium is now the only surface that could
  ever carry a total — which must be ruled there separately (`[CJ-S26]`).
- **`[CJ-S10]` — `CJ-10` → four distinct end-shapes.** `due` is **attention on an `active` record**,
  not a state. `expired` means a disclosed opportunity ended because its clock passed. `failed`
  means an authored failure condition occurred. `withdrawn` means the source intentionally removed
  it without blaming the player. "Overdue" exists only for a still-actionable soft target and is
  never inferred after expiry.

### Section 3 — cadence and presentation (`CJ-9`, `CJ-11..16`)

- **`[CJ-S9]` — `CJ-9` → cadence trigger ids; disclosure form is engine-determined.** A record
  references an existing `CadenceEngine` trigger id and never stores its own countdown. Disclosure
  is authored and must name its unit. This is **enforced by the engine, not by policy**:
  `CadenceEngine._evaluate_counter` holds `value` and `threshold`, so a counter trigger can disclose
  "2 deployments"; `_evaluate_predicate` holds only a requirement and has nothing to count, so a
  predicate clock discloses a **requirement reason** and a numeric estimate is structurally
  impossible to produce. `[CVS-S7]` remains precedent. Journal records use campaign-level trigger
  ids and `CampaignManager.get_cadence_tick`; they do **not** use `cadence_subscriptions`, which are
  per-node.
- **`[CJ-S11]` — `CJ-11` → family defaults plus per-transition author opt-in/out.** Activation,
  material update, approaching disclosed deadline and resolution are eligible. Repeated progress is
  coalesced and silent by default. Urgent never means modal unless immediate input is genuinely
  required. This is the direct control on the Three Houses / Midnight Suns chore-volume failure.
- **`[CJ-S12]` — `CJ-12` → categories extend `[CFB-12]`; and the router builds under the CFB row
  first.** Campaign categories reuse `[CFB-12]`'s player-facing category pattern **without merging**
  combat and campaign preference sets: quests/objectives, relationships, facilities/stock,
  opportunities/reminders, campaign/world changes. Each supports all / milestones only / transient
  off, and turning transients off never alters persistent journal state or combat choreography.
  **Sequencing:** because `[CFB-12]` has no code (`[CJ-S25]`), the router is built as CFB's
  infrastructure with combat as consumer one and the journal as consumer two. The journal build
  depends on it.
- **`[CJ-S13]` — `CJ-13` → one priority queue with coalescing and a summary.** The router queues by
  priority and presentation boundary, coalesces repeated source updates, and offers an
  "N more updates" summary that opens the journal. It never allows a toast to cover the battle
  forecast, a dialogue choice, results, or another modal.
- **`[CJ-S14]` — `CJ-14` → attention-first ordering.** Default order is **Needs attention** (due
  soon, newly available, materially updated), then active pinned, then other active, then recent
  outcomes. Family, status, location, source and text filters are offered. Completed history is not
  mixed into the active default merely because it is recent.
- **`[CJ-S15]` — `CJ-15` → acknowledgement is attention-only.** Opening the relevant record clears
  `new`/`updated`; dismissing a toast alone does not. "Mark all seen" changes attention only — it
  never activates, completes, archives or withdraws gameplay content. This is the explicit guard
  against the Tactics Ogre failure where opening a menu is a progression gate.
- **`[CJ-S16]` — `CJ-16` → multi-pin, per-context marker budget.** Several records may be pinned in
  the journal, but each presentation context sets a small marker budget and explains overflow. A
  deep link resolves through a destination registry and preserves origin for Back. Unavailable or
  hidden destinations fail closed without revealing names or coordinates.

### Section 4 — persistence and input (`CJ-17..18`, `CJ-21`)

- **`[CJ-S17]` — `CJ-17` → ids only, re-render live. DEPARTS from the recommendation.** The packet
  recommended snapshotting player-facing text at resolution; the owner ruled that history stores
  **outcome, resolved campaign time, source and ids**, and re-renders title/body live from pack
  data. Smallest save, always correctly localized, and it composes with `[CJ-S18]`: history is
  derived, so a rewind removes the entry rather than stranding prose. **Accepted cost:** a pack
  revision rewrites the wording of already-completed history. Acceptable while a pack is under
  authoring; this needs an author-facing note before packs are distributed.
- **`[CJ-S18]` — `CJ-18` → committed transition ids, silent restore, and nothing survives a rewind.
  AMENDED by the owner.** The packet's recommendation is adopted and extended: a notification for an
  event that was rewound, or lost by reloading an earlier save, must not remain in the log.
  - Journal lifecycle, attention **and discovery** live **only** inside `save.campaign`. No
    `user://` sidecar, no autoload state that outlives a load. Loading any save therefore restores
    that save's journal wholesale and an orphan entry is **unrepresentable** — the guarantee comes
    from having nowhere else to store one, not from a cleanup pass someone must remember to run.
  - The mid-map rewind ledger is map-scoped by construction (`SaveData._validate_ledger`: a
    between-map document may not carry one). Because `[CJ-S19]`/`[CJ-S20]` append the campaign
    outcome only **after** the map transaction commits, a mid-map rewind is structurally incapable
    of orphaning a journal record.
  - The router queue is transient and never persists. On load or rewind it is flushed, and any
    in-flight toast naming a record absent from the restored state is dropped.
  - Notify only on a **new committed transition id**; the sequence counter saves with the record, so
    a reload replays no history and a genuinely new transition after the load still fires. Never
    notify because a predicate happens to be true after load.
  - Imported or older saves run an idempotent reconciliation pass that records state without
    presenting a wall of historical toasts.
- **`[CJ-S21]` — `CJ-21` → one data source, shell contracts inherited.** Wide may show
  filter/list/detail together; Compact is list-then-detail from the same data source — no separate
  Compact model. Rows are fully tappable, controller order matches visual order, filters never steal
  focus, and Back restores exact row/scroll/origin via `FocusNavigator`/`ModalScreen`. State and
  urgency never rely on colour or icon alone, and no text is baked into an icon (`[L10N-7]`).
  Dynamic announcements use Godot native accessibility only after `[ANN-5]` validation; persistent
  text remains available when transient feedback is off.

### Section 5 — authoring gate (`CJ-22`)

- **`[CJ-S22]` — `CJ-22` → closes only on real pack authoring, played.** Required: stable pack-local
  ids; localized text keys; open family and destination registries; validated requirement and
  cadence references; transition-conflict and unreachable-state diagnostics; spoiler-safe preview
  contexts; explicit notification and persistence policies. Validation rejects duplicate ids and
  invalid references within the one active self-contained pack. **The capability cannot close as
  completed until a campaign pack authors it through `select_campaign()` and it is played. A fixture
  is not pack adoption.**

### Corrections to this packet's reuse audit

Measured against `agent/integration` at the task base while walking. These change what the audit
above claims, and each is carried as its own consequence.

- **`[CJ-S23]` — cadence state never round-trips through a save. Pre-existing bug; recorded, not
  fixed.** `CampaignManager.capture_campaign_state()` returns a `"cadence"` key,
  `restore_campaign_state` reads it, and `SaveData` reserves and normalizes it — but neither
  `GameState.capture_campaign_save` nor `GameState.capture_suspend_save` copies it into
  `save.campaign`. Every save/load resets counters, latches, ticks and `last_fired` to zero. This
  already breaks shop restock (`[CVS-S6..S8]`) today, and it would make `[CJ-S9]` disclosure and
  `[CJ-S18]` replay-safety rest on a lie. The owner ruled **record it, do not fix it in this
  session**. No disclosed clock may ship before it is fixed.
- **`[CJ-S24]` — the objective system is an extension target, not a reuse target.**
  `ObjectiveCondition` is a flat resource authored on `MapData.victory_conditions[group]` /
  `defeat_conditions[group]` and evaluated by `TurnManager.check_victory_conditions`. It has **no**
  optional flag, **no** reward field, and no evaluation path that is not win/loss. The audit row
  claiming optional objectives "use the same open handler shape" understates this. Sized as its own
  build row under `[CJ-S19]`.
- **`[CJ-S25]` — `[CFB-12]` is design-only; the router has no base to extend.** Nothing in
  `scripts/` references combat-feedback categories or notification settings. The entire shipped
  notification surface is `RuleFlipNotification.gd` — one four-second toast with a `_generation`
  counter. The router is therefore new infrastructure, and `[CJ-S12]` sequences it under CFB so it
  is not built twice.
- **`[CJ-S26]` — `CampaignStatusRecord` cannot be the discovery carrier in its then-current
  terminal-single-record shape. SUPERSEDED 2026-08-31 by `[CMP-S24]`–`[CMP-S31]`.**
  `CampaignManager.export_completion_status_record` fires only when `is_campaign_complete()`, and
  `CampaignStatusStore` writes to `user://campaign_status`. It is a terminal, cross-run artifact
  **outside** the save envelope, so it would survive exactly the rewinds and reloads `[CJ-S18]`
  forbids surviving. The 2026-08-30 ruling therefore kept that implementation terminal-only. The
  joint follow-up replaced it with an engine collection of exported run records: selected records
  and a materialized relevant union are copied into the run/save at New Game or a safe mid-game
  import boundary, while the run separately accumulates Compendium discovery. The external store
  still never carries the save-timeline Journal. See the cited Compendium rulings for export ids,
  query access, spoiler-aware exports and the run-start/live projection split.
- **`[CJ-S27]` — name collision to avoid.** `DRC-V1-S06` already reserves **ActionJournal** for the
  domain-neutral atomic action journal (the staged-transaction consumer). The player-facing
  **Campaign Journal** of `[CJ-S1]` is a different system and must not reuse that class name or its
  vocabulary in code.

### Open sub-questions, swept and ruled (same session, 2026-08-30)

A completeness sweep over the rulings above found eleven residues: sentences a ruling deferred,
parameters it left unquantified, and two questions the packet never asked at all. All are ruled
here. Where a sub-ruling changes one above, it says so.

- **`[CJ-S28]` — the journal is available everywhere; unreachable deep links are gated, not hidden.
  THE PACKET NEVER ASKED THIS.** The Campaign Journal opens from `OverworldScreen`, `PrepScreen`
  **and** `MapMenu`, with the same rows and the same actions in each. A **deep link** is a row's
  "take me there" action: it resolves a destination and navigates, preserving origin so Back returns
  to the exact row and scroll position (`FocusNavigator`/`ModalScreen`). A link whose destination is
  unreachable from the current surface — a shop or campaign node while a battle is in progress —
  renders `GATE_VISIBLE_DISABLED` with a localized reason from `render_reason`. This needs **no**
  suspend-or-refuse machinery: it is one destination-reachability predicate expressed in the gate
  vocabulary `[CJ-S7]` already adopted. Hiding such links instead was rejected — the player loses
  the cue that the destination exists.
- **`[CJ-S29]` — the named safe boundaries, named.** `[CJ-S5]` deferred this list; it is: campaign
  **node entry**, **node exit/clear**, **after the battle transaction commits**, **prep entry**, and
  **every save point**. The first three are where `evaluate_cadence()` already runs. Because a save
  point is included, saving can transition a record, so the ordering is fixed: **evaluate first,
  capture second**, and evaluation is **idempotent** so re-saving never re-fires. With `[CJ-S18]`'s
  committed-transition-id rule this is save-scum safe — a repeated save produces no repeated
  transition and no repeated notification.
- **`[CJ-S30]` — the destination registry is a new engine-owned open registry, pack-extensible.**
  It mirrors `ObjectiveConditionRegistry`: the engine ships the `screen`, `pair`, `campaign_node`
  and `map_location` kinds, packs register more, and validation rejects an unresolvable destination
  id at authoring time. Folding destinations into `CampaignData` was rejected because relationship
  pairs and screens are not campaign nodes and would have nowhere to live. This is the concrete
  form of `[CJ-S22]`'s "validated destination references".
- **`[CJ-S31]` — three priority levels; family default, author override.** `info`, `attention`,
  `urgent` (names indicative, semantics binding). The family registry entry sets the default and an
  author may raise or lower it per transition — the same shape as `[CJ-S11]`. A numeric
  author-assigned priority was rejected: it carries no shared meaning, so two packs' "50" would
  differ. `urgent` still never implies modal unless immediate input is genuinely required.
- **`[CJ-S32]` — families declare their own policy. AMENDS `[CJ-S2]`.** The owner ruled that the
  engine ships **no hardcoded per-family persistence defaults**. Persistence rules — and by
  extension notification policy and priority default — are **declared by the family's registry
  entry**. The engine's job is to *require* a declaration at validation time, not to choose one.
  The lifecycle split proposed during the walk (full lifecycle for quest/bounty/relationship,
  outcome-only for opportunity/reminder/information) is therefore **the sample pack's
  configuration**, not an engine default, and is recorded here only as a worked example. This makes
  `[CJ-S2]`'s phrase "safe family defaults" mean *the sample pack's defaults*, and it is the same
  open-registry stance as `[CJ-S1]`.
- **`[CJ-S33]` — the marker budget is fully author-configurable; validation warns, never blocks.
  AMENDS `[CJ-S16]`.** `[CJ-S16]` said each presentation context "sets a small marker budget"; the
  owner ruled the pack sets it, with no engine default and no engine cap. Pack validation emits a
  **warning** above a threshold ("this pack allows N markers on the overworld") and the pack still
  ships. The warning catches the bury-your-own-map typo without the engine overriding the author.
  Overflow explanation from `[CJ-S16]` still binds at whatever budget the author sets.
- **`[CJ-S34]` — each cadence counter declares a localized unit key.** `[CJ-S9]` requires a disclosed
  clock to name its unit but did not say where the unit comes from. The **counter definition**
  carries an L10N key naming what it counts ("deployments", "chapters"), and disclosure renders
  N + unit. **Validation requires the key whenever disclosure is enabled**, so a disclosed clock
  cannot ship unnamed. Authored free text was rejected — it would pull the unit into `TEXT-06`'s
  free-text rules and make localization the pack's problem; a closed engine vocabulary was rejected
  because a pack counting something the engine never imagined could not disclose it.
- **`[CJ-S35]` — one Notifications settings page, two groups.** A single `SettingsScreen` page hosts
  a combat group and a campaign group. One router, one place to look. Grouping is **not** merging,
  so `[CJ-S12]`'s rule that combat and campaign preference sets stay distinct is unaffected.
- **`[CJ-S36]` — optional-objective rewards reuse the existing receipt channel.** The reward for an
  optional objective commits through the existing `EventBus.reward_committed(receipt)` signal, which
  `MapResultsScreen` already consumes (`TurnManager` is the existing emitter). No parallel reward
  path is built for `[CJ-S19]`.
- **`[CJ-S37]` — the code-level names are `CampaignJournalService` and `CampaignJournalEntry`.
  COMPLETES `[CJ-S27]`.** Code and player-facing vocabulary agree. The `ActionJournal` collision
  flagged in `[CJ-S27]` is resolved by the `Campaign` prefix: `DRC-V1-S06`'s `ActionJournal` is the
  domain-neutral atomic action journal and is a different system. Reviewers must not treat the two
  as related because both contain "Journal".
- **`[CJ-S38]` — `[CJ-S17]` owes an author-facing note.** Because history stores ids and re-renders
  live, a pack revision rewrites the wording of already-completed history. This is acceptable while
  a pack is under authoring and surprising once packs are distributed, so the future journal
  implementation row owes a note in the authoring documentation saying so. Recorded here because no
  implementation row exists yet; it must not be lost when one is opened.

## Recommended walk order

**SPENT 2026-08-30.** This order was followed and the walk is complete; see **Owner rulings**
above. Retained as the record of how the register was sequenced.

Walk by dependency rather than screen order:

1. **Ownership and scope:** `CJ-1..3`, `CJ-19..20`.
2. **Lifecycle and discovery:** `CJ-4..8`, `CJ-10`.
3. **Cadence and presentation:** `CJ-9`, `CJ-11..16`.
4. **Persistence and input:** `CJ-17..18`, `CJ-21`.
5. **Authoring gate:** `CJ-22`.

The first decision should be `[CJ-3]`. If quests become a second engine, nearly every later
question forks into “journal version” and “quest version,” creating the duplicate job this research
was asked to avoid.
