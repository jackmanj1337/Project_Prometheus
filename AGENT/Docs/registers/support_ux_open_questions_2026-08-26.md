---
Role: dated
Type: register
Status: OPEN — SUPUX-1..10 awaiting owner walk
Last verified: 2026-08-26
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

### [SUPUX-1] Where is the relationship system entered? — **OPEN**

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

### [SUPUX-2] How is the complete graph presented? — **OPEN**

Choose between a pair list, a unit-first partner list, or a node graph. Recommendation: unit-first
partner list with a pair-detail pane; a literal complete node graph becomes unreadable on Compact.

### [SUPUX-3] How much progress is disclosed? — **OPEN**

Choose exact points/thresholds, a bounded progress meter, or rank-only disclosure. Recommendation:
meter plus current/next rank and named contributing sources; keep raw points in optional detail.

### [SUPUX-4] How do rank readiness and optional conversations interact? — **OPEN**

Decide whether a written conversation must be viewed before rank activation, whether conversation-
less crossings activate immediately, and how both states are labelled without implying missing
content.

### [SUPUX-5] How are directional proximity bonuses explained? — **OPEN**

Decide the pair-detail preview, current-range indication, two directions, stacking, and next-rank
delta without collapsing REL-7 into one symmetric bonus.

### [SUPUX-6] What announces progress and readiness? — **OPEN**

Decide map-end summary, lightweight in-map feedback, badge/toast categories, and notification
settings while reusing the existing combat-feedback vocabulary rather than creating a parallel
channel.

### [SUPUX-7] How are caps and exclusive top rank communicated? — **OPEN**

Decide when per-map cap state and top-rank exclusivity appear, how a blocked edge reads, and whether
the chosen exclusive partner is reversible if campaign rules permit it.

### [SUPUX-8] What happens when a unit is unavailable? — **OPEN**

Decide dead, captured, departed, unrecruited, hidden-identity, and temporarily unavailable states;
preserve spoiler/redaction contracts and authored conversation validity.

### [SUPUX-9] What sorting and filtering are required? — **OPEN**

Decide unread/ready/closest-to-rank/name/deployment filters and whether inaccessible pairs appear.

### [SUPUX-10] What is the Compact and input contract? — **OPEN**

Decide pane collapse, focus return, controller traversal, touch targets, and direct deep-link
behavior using the existing responsive and input vocabulary.
