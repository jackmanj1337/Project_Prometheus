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

## F7 — Resource pools  *(end-shape: DECIDED 2026-06-23l — standalone foundation)*

**End-shape we support** (firmed via `[CEX-1..4]`):
- **Pool types** = a `CampaignRules` profile (rides the F4 mechanism); per-unit **max** from class
  (per-unit override later). A component **or skill** declares a `{pool, amount}` cost; multi-pool
  costs allowed. Pools gate **weapon/spell use + skill activation** in v1 (movement later).
- **Player surface:** pool bar on the unit sheet + combat/action preview; cost shown **pre-commit**;
  empty pool greys the capability.
- **Refill = author-selected mode** (a `CampaignRules` refill profile): per-map reset (v1 default)
  **vs** "persist until the author refills" (climactic back-to-back battles). Plus **restoration
  items** (`restore_pool` consumable effect_id — a "mana vulnerary", mirrors `heal_flat`) and
  **Regen skills** (pool-over-time, mirrors Renewal).
- **Gates:** the learned-spell system (`[CEX-B]`) and combat arts (#15) — both ride pools.
**Save (F1):** current pool values persist only under non-reset refill modes — reserve a per-unit
pool-state slot.

## F10 — Secondary Movement / move-after-action  *(end-shape: DECIDED 2026-06-24a — a parameterized skill)*

**End-shape we support** (firmed via `[SMV-1..11]`):
- Secondary Movement = an ordinary **`SkillData`** (`effect_id="secondary_movement"`, passive) —
  **no bespoke engine**. Behavior lives in `effect_params`: **`movement_mode ∈ {remaining, flat}`**
  (+ `flat_amount`) and an author-configurable **`secondary_move_actions`** set (which turn-ending
  actions open the window; default = all; Wait never does).
- **Conferral = the existing skill-grant mechanisms** (`ClassData.skill_unlocks` — mounted classes
  carry it by default; `[SKL-4]` grant/revoke; `[IEQ]` accessory effect_ids = **Knight Ring**; F6
  story grants; `[PXP-4]` on-crossing). **Supersedes** GDD_10 M10's "automatic for all mounted."
- **One new engine piece:** an action-flow hook (`UNIT_SECONDARY_MOVE` MapCursor state) that, after a
  qualifying action and before `DONE`, opens a remainder-move window (reuses the movement-range
  computation + `grant_extra_turn` substrate), ending in **Wait only** (no second action).
**Naming:** the player-facing term is **Secondary Movement** (the unrelated Bard/Heron ally-refresh
skill is **Reinvigorate**). **Save (F1):** none new — the skill grant already persists.

## F13 — Text indirection / localization-ready string layer  *(end-shape: DECIDED 2026-06-24g — convention now, build deferred)*
Spun out of the Main Character / Avatar firming (`[MCH-6]`). **End-shape:** all author-facing
story/UI text is **ID-keyed templates with named placeholders**; **unit references use `unit_id`**,
resolved to a display name **at render time** via a lookup; **no sentence concatenation** (word order
is language-specific). Resolution uses **Godot's native translation** (`tr()` / `TranslationServer`,
CSV/PO tables) when localized; **per-campaign-pack string tables** (fits the self-contained content
model). **Adopt the convention NOW, defer the multi-locale build** — retrofitting hardcoded/
concatenated text later is the expensive part; authoring it right from the first line is near-free.
**Enforcement (DoD#2):** the `check_docs.py` linter for hardcoded display names / concatenation lands
**when the dialogue/story-text data format is built** — there is no target data to lint yet, so this
is an **explicit deferral, not a skip**. **Save (F1):** none new (display names already keyed by
`unit_id`). **Forward:** pluralization (`tr_n`), gender/pronoun variants, text expansion (German
~+30%), CJK fonts, RTL, and the avatar **free-text-name** grammar edge (declension/gender languages).

## Still open (decide next, or at scheduling)

*(none — all foundations F1–F13 now have decided end-shapes; only F1's schema-lock pass remains.)*

---

## Next step
F4/F5/F6/F7/F10 end-shapes are all decided — each becomes its own register + build when scheduled.
**All foundations F1–F13 are now decided**; only F1's schema-lock pass remains before builds. All of
this feeds the **scheduling/priority session**, with the atlas
(`plans/feature_dependency_atlas_2026-06-23.md`) as the dependency-ordered map.
