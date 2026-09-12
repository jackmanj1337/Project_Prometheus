---
Role: dated
Type: register
Status: RESOLVED — SUPUX-1..10 owner-ruled
Last verified: 2026-08-30
Register: SUPUX-1..10
Tracker: DISCUSS-SUPPORT-UX-2026-07-23
---

# Relationship UX — Owner Questions

These questions consume `[REL-1..9]`; they do not reopen its complete graph, gain sources, authored
rank profile, directional proximity bonuses, optional conversations, per-map cap, or optional
exclusive top rank. Player-facing copy says **relationship**, reserving **support** for Pair Up.

## Comparative research basis

- Fire Emblem's recurring pattern is C/B/A-style ranks, an optional S rank in romance-enabled
  entries, rank-up conversations, and stronger combat bonuses at higher ranks.
  [Series overview](https://fireemblem.fandom.com/wiki/Support)
- Awakening grows relationships through adjacent combat and Pair Up, then exposes conversations
  between battles. This unifies narrative and mechanics but makes threshold opacity costly.
  [Nintendo overview](https://www.nintendo.com/en-gb/Support/Legacy-system/Fire-Emblem-Awakening-772119.html),
  [mechanics reference](https://serenesforest.net/awakening/characters/supports/support-basics/)
- Three Houses adds social sources outside battle, increasing reach but also increasing the need
  to explain why a pair advanced.
  [Game overview](https://en.wikipedia.org/wiki/Fire_Emblem%3A_Three_Houses)
- Triangle Strategy's character stories use hidden conviction requirements rather than pair
  relationships. It is useful negative precedent: hidden narrative gates preserve surprise but
  prevent deliberate pursuit.
  [Character-story guide](https://game8.co/games/Triangle-Strategy/archives/369839)

Applied to `[REL]`: the complete graph needs roster-level discovery; directional bonuses still
need a unit-local projection; progress must distinguish rank readiness, conversation readiness,
and immediate conversation-less crossings; and exclusive-rank blocking must be visible before a
player spends effort against a capped edge.

### [SUPUX-1] Where is the relationship system entered? — **RESOLVED 2026-08-30**

- **A — Roster-level Relationships hub plus unit-detail projection and contextual readiness
  shortcuts.** The hub discovers the whole graph and unread conversations; unit detail explains
  the selected unit's partners and directional benefits; notifications deep-link to the relevant
  pair. Against: three entry paths must resolve to one shared state.
- **B — Unit detail only.** Keeps relationships close to character inspection. Against: finding an
  unread conversation or comparing the roster becomes a unit-by-unit hunt.
- **C — Roster-level hub only.** One complete authority. Against: relationship bonuses disappear
  from the screen where a player is already evaluating a unit.
- **Recommendation: A.** The complete graph and sparse conversations require global discovery,
  while REL-7's per-unit directional payload requires local inspection. The shortcut is navigation,
  not a third model: all three open the same pair record.

**Decision: A.** Relationships have a roster-level hub, a unit-detail projection, and contextual
readiness shortcuts. Every entry path opens the same pair record; none owns separate relationship
state.

### [SUPUX-2] How is the complete graph presented? — **RESOLVED 2026-08-30**

Choose between a pair list, a unit-first partner list, or a node graph. Recommendation: unit-first
partner list with a pair-detail pane; a literal complete node graph becomes unreadable on Compact.

**Decision:** Use a unit-first partner list with a pair-detail pane. Wide layouts may present the
list and detail together; Compact presents them sequentially with both views reading the same pair
record. Do not build a separate node-graph representation.

### [SUPUX-3] How much progress is disclosed? — **RESOLVED 2026-08-30**

Choose exact points/thresholds, a bounded progress meter, or rank-only disclosure. Recommendation:
meter plus current/next rank and named contributing sources; keep raw points in optional detail.

**Decision:** The default pair view shows a bounded progress meter, current and next ranks, and the
named sources that contribute progress. Exact points and thresholds remain available in optional
detail rather than dominating the primary view.

### [SUPUX-4] How do rank readiness and optional conversations interact? — **RESOLVED 2026-08-30**

Decide whether a written conversation must be viewed before rank activation, whether conversation-
less crossings activate immediately, and how both states are labelled without implying missing
content.

**Decision:** When a rank has an authored conversation, reaching its threshold makes that rank
ready and viewing the conversation activates it. A conversation-less crossing activates
immediately and is labelled **Rank Increased**, never as missing content. Authors choose one of two
first-play modes for an authored conversation: **autoplay on reach** (queued for the next safe
presentation boundary) or **external trigger**, which keeps the rank ready until campaign logic
presents it. The Relationships hub exposes readiness but does not bypass an external trigger.
After first presentation, either kind enters a replay archive. Replay is read-only and never
re-applies rank activation or other effects.

### [SUPUX-5] How are directional proximity bonuses explained? — **RESOLVED 2026-08-30**

Decide the pair-detail preview, current-range indication, two directions, stacking, and next-rank
delta without collapsing REL-7 into one symmetric bonus.

**Decision:** Pair detail presents both directions explicitly: **Unit A → Unit B** and **Unit B →
Unit A**, each with required range, current bonus, next-rank delta, and stacking rule. Deployment
and battle inspection show whether the directional bonus is currently in range. Active bonuses
also participate in the existing stat-detail attribution: every affected stat names the partner,
relationship rank, direction, and applied amount as its source. Do not collapse the pair into one
symmetric bonus or leave its contribution inside an unexplained total.

### [SUPUX-6] What announces progress and readiness? — **RESOLVED 2026-08-30**

Decide map-end summary, lightweight in-map feedback, badge/toast categories, and notification
settings while reusing the existing combat-feedback vocabulary rather than creating a parallel
channel.

**Decision:** Use layered feedback through shared channels: a lightweight in-map gain indicator,
an aggregated map-end relationship summary, and a prominent readiness notification. Players may
select all relationship feedback, milestones/readiness only, or transient feedback off. Results
and history remain inspectable regardless of the transient setting.

Readiness also writes a persistent entry to a shared **Campaign Journal**, not a relationship-only
log. That surface must support heterogeneous actionable and informational entries such as “these
two people have a conversation,” “stocks refresh in three chapters,” and “Village A placed a
500-gold bounty on a local dire-wolf pack.” Entries therefore need a stable source, player-facing
text, lifecycle/state, optional destination or deep link, and optional campaign-time countdown.
Relationship readiness deep-links to the shared pair record decided by SUPUX-1. Transient settings
do not erase persistent journal entries. The journal's general contract is broader follow-up work
and must receive its own tracker row before this discussion closes.

### [SUPUX-7] How are caps and exclusive top rank communicated? — **RESOLVED 2026-08-30**

Decide when per-map cap state and top-rank exclusivity appear, how a blocked edge reads, and whether
the chosen exclusive partner is reversible if campaign rules permit it.

**Decision:** Limits are visible before they block progress. Pair detail shows the per-map gain
limit, current cap state, and when that limit resets. It also shows exclusive-top-rank eligibility
before commitment. Choosing an exclusive partner requires confirmation that names the affected
alternatives and states clearly whether the campaign's authored rule makes the choice reversible.
A capped edge reads **Map gain limit reached**, not as unexplained stalled progress.

### [SUPUX-8] What happens when a unit is unavailable? — **RESOLVED 2026-08-30**

Decide dead, captured, departed, unrecruited, hidden-identity, and temporarily unavailable states;
preserve spoiler/redaction contracts and authored conversation validity.

**Decision:** Preserve a known pair record while applying state-specific presentation and
eligibility. Temporarily unavailable units remain visible with progress paused and an expected
return when known. Captured or departed states appear only after the story reveals them. Dead
units retain relationship history and replay while progression is unavailable under the current
state. The UI never calls a relationship permanently closed: campaign state may later change.
Authored conversations remain available only while their validity conditions pass.

Characters the player has not met are hidden entirely: no silhouette, placeholder, reserved row,
count, searchable name, or other evidence may reveal them. After a character has been revealed,
later unavailability uses the treatments above. A campaign's hidden-identity/redaction contract
still controls which revealed identity and portrait may be shown.

### [SUPUX-9] What sorting and filtering are required? — **RESOLVED 2026-08-30**

Decide unread/ready/closest-to-rank/name/deployment filters and whether inaccessible pairs appear.

**Decision:** Default ordering is conversation-ready/unread, rank-ready, closest to next rank,
then alphabetical. Filters cover ready or unread, deployed/current party, can currently gain
progress, temporarily unavailable, rank, and name/search. Known relationships that cannot
currently progress remain reachable through **History/Unavailable**; none is labelled permanently
closed. Unmet characters remain absent under every sort, filter, count, and search.

### [SUPUX-10] What is the Compact and input contract? — **RESOLVED 2026-08-30**

Decide pane collapse, focus return, controller traversal, touch targets, and direct deep-link
behavior using the existing responsive and input vocabulary.

**Decision:** Wide layouts may show unit list, partner list, and pair detail together. Compact
drills down through **unit → partner → pair detail**, one view at a time. Back restores the exact
originating row, focus, and scroll position. Controller traversal follows visual order without
focus traps; touch uses the project's standard minimum target size and makes each row fully
tappable. Notification and Campaign Journal deep links open pair detail directly, and Back returns
to the link's source rather than an arbitrary Relationships screen. Conversation replay returns
focus to the pair record.
