---
Type: design
Status: Active — foundation end-shapes decided, initial designs
Last verified: 2026-06-23
---

# Foundations — End-Shape Sketches

**Started:** 2026-06-23 (session 2026-06-23l)
**Status:** Active. Initial end-shape designs for the foundations whose target shape the owner
**decided** this session (F4·F5·F6), plus the two still open (F7·F10). Companion to
`plans/feature_dependency_atlas_2026-06-23.md` (which sizes/groups the features resting on these).
**Not built or scheduled** — each graduates into its own register + GDD owner update when picked up.
The throughline (owner choices 2026-06-23l): **build each as ONE generic, author-extensible
mechanism**, not per-feature copies.

---

## F4 — Generic author-profile mechanism  *(end-shape: ONE generic mechanism)*

**Concept.** A single reusable "named author profile" registry in `CampaignRules` that every
system needing an author-tunable table plugs into — instead of each system inventing its own.

**End-shape we support.**
- A typed profile registry: `profiles[profile_type][profile_name] → profile_data`.
- **Profile types** (open set): `rank` (PXP), `triangle` (weapon hierarchy + effects), `pool`
  (resource pools), `difficulty`, … new types add without touching the mechanism.
- Each type ships a **default profile** that reproduces current hardcoded behavior (non-breaking).
- Consumers reference a profile by `(type, name)`; a resolver `CampaignRules.get_profile(type, name)`
  returns it (falling back to the default).

**Reuses / feeds.** Realizes `[PXP-3]` rank profiles as the first concrete type; then `[CEX-C]`
triangle, `[CEX-A]` pools, and difficulty modes are all *types* on the same mechanism.
**Save (F1):** the active profile selections + any per-save overrides persist with `CampaignRules`.
**Cost:** cheap, high-leverage — build once, every later author-table system reuses it.

---

## F5 — Status / condition system  *(end-shape: FULL, author-extensible)*

**Concept.** Build `ConditionManager` (today a stub) into a complete, data-defined status system.

**End-shape we support.**
- **`ConditionData`** definitions (author-extensible): `id`, `display`, **effect kind** (stat
  modifier / damage-over-time / action-lock like silence·sleep·berserk / tag), **tick model**
  (duration + when it decrements, reusing the modifier `duration_type` lifecycle), **stacking
  rule** (refresh / stack / ignore), **cleanse** behavior.
- The built-in set (poison, sleep, silence, berserk, stun) ships as default `ConditionData`;
  campaigns add their own.
- **Immunity** as a unit/accessory tag (`negate_condition`) + per-condition immunity checks.
- API: `apply_condition(unit, id, duration, source)`, tick at the right loop point, **sheet
  display** of active conditions.

**Reuses / feeds.** Stat-affecting conditions reuse `active_modifiers`; the duration/tick lifecycle
already exists. **Feeds:** `[CEX-C]` triangle condition-application, the poison/heal_on_hit weapon
tags, the condition-immunity accessory effect (`[IEQ]`/§2f), debuff staves, daunt-likes.
**Save (F1):** active conditions per unit persist (runtime state — reserve in §2).
**Cost:** L — a load-bearing system several features queue behind; do it once, properly.

---

## F6 — Campaign-flag / story-state store  *(end-shape: generic key→value store)*

**Concept.** A campaign-scoped key→value store (the missing piece behind all narrative branching).

**End-shape we support.**
- A typed store: `campaign_flags: { key → value }` where value ∈ bool / int / string,
  **campaign-scoped** and **save-persisted**.
- Read/write API: `get_flag(key, default)` / `set_flag(key, value)`.
- **Writers:** map events (`[MET]`), item use/holding (story items), recruit outcomes, training/
  arena results. **Readers:** `[MET]` trigger predicates, recruit conditions, route/difficulty
  branching, village outcomes, dialogue gating.

**Reuses / feeds.** Plugs into the `[MET]` trigger predicate vocabulary (a flag check becomes a
trigger condition). **Feeds:** story-item branching (`[CEX-E]` — tracking is independent and
already cheap; *branching* needs this), recruit/capture conditions (#4), route branching, quests.
**Save (F1):** the flag store is core campaign-save state — **reserve now**.
**Cost:** L, but it is the single unlock for the entire narrative-branching surface.

---

## Still open (decide next, or at scheduling)

### F7 — Resource pools  *(end-shape: TBD — see `[CEX-1..4]`)*
Whether pools are a standalone foundation (built before spells/combat-arts) vs grown per-feature;
the player/refill/authoring shape is drafted in `[CEX-A]` (`[CEX-1..4]`). Decide alongside the
learned-spell question (it depends on pools).

### F10 — Canto / move-after-action  *(end-shape: TBD)*
Scope: which classes/effects grant canto, and the action-flow shape (move → act → move-remainder).
Foundation for Knight Ring (`[IEQ]`), mounted QoL, and the rescue-canto interaction (#6).

---

## Next step
F4/F5/F6 end-shapes are decided — each becomes its own register + build when scheduled. F7/F10
remain. All of this feeds the **scheduling/priority session**, with the atlas
(`plans/feature_dependency_atlas_2026-06-23.md`) as the dependency-ordered map.
