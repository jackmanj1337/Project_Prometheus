---
Type: register
Status: OPEN — owner walk not yet started
Last verified: 2026-08-08
Register: CAU-1..10
---

# Combat Actions UX — Owner Questions

Companion research:
[`combat_actions_ux_research_2026-08-08.md`](../design/combat_actions_ux_research_2026-08-08.md).
All mechanics named here are already governed by their mechanical registers. These questions
settle presentation and interaction only.

### [CAU-1] One action menu or family submenus? — **OPEN**

Recommendation: one action menu ordered by availability, with source selection inside an entry;
split into a submenu only when two or more sources of that family are currently usable.

### [CAU-2] Target-first or destination-first displacement? — **OPEN**

Recommendation: target first, then destination when the rule admits more than one legal result.
Auto-advance when exactly one destination exists.

### [CAU-3] How are area actions previewed? — **OPEN**

Recommendation: tint affected tiles and outline every currently-visible affected unit; the
confirmation panel lists predicted outcomes per target without revealing hidden occupants.

### [CAU-4] When is confirmation required? — **OPEN**

Recommendation: always confirm actions that spend a limited resource, change two or more units,
or require a destination; preserve the existing direct-confirm path for ordinary attacks.

### [CAU-5] How is uncertainty written? — **OPEN**

Recommendation: show bounded outcomes and their cause (`May move 1–2 tiles: collision rule`),
never a single exact result the resolver cannot guarantee.

### [CAU-6] Do non-strike actions use attack choreography? — **OPEN**

Recommendation: no. Use distinct registered choreography kinds; share CFB callouts and logging,
not the run-in/impact motion.

### [CAU-7] What does cancellation restore? — **OPEN**

Recommendation: Back unwinds one selection stage at a time, returning to the action menu only
after source, target, and destination selections are cleared; no resource is reserved meanwhile.

### [CAU-8] How are carry state and refreshed state shown afterward? — **OPEN**

Recommendation: persistent unit-corner/status-detail evidence, following `[CFB-6]`; the transient
callout announces the event but is never the only proof of continuing state.

### [CAU-9] Where do costs and item mutations appear? — **OPEN**

Recommendation: in the confirmation summary as before→after values, then in the unified CFB log.
Do not encode durability loss only as colour or a disappearing inventory row.

### [CAU-10] What is the controller focus order? — **OPEN**

Recommendation: action → source (if needed) → target → destination/area → confirmation, with Back
reversing that exact order and focus returning to the previously selected map unit after cancel.

