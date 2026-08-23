---
Role: dated
Type: register
Status: RESOLVED 2026-06-27
Last verified: 2026-06-27
Register: LDC-1..9
Resolved-in: 2026-06-27d
---

# Loadout Cap (skills / styles / granted sources) — A5 — Player-Facing Design + Open Questions

**Started:** 2026-06-27 (session 2026-06-27d). **Fifth A5 sub-item** (after `[DTH]`, `[DIF]`, `[AGT §6]`,
`[BEA]`). Resolves the **style/source loadout cap** pinned to A5 from `[CEX-7]` + `[STY-3]` (2026-06-25c).
**Confirm-and-generalize**, not new design. Branch `docs-reorg-2026-06-23`. Legend: **[OPEN]** /
**[ASKED]** / **[RESOLVED]**.

---

## Substrate reality (the pattern already exists for skills)
The skills system **already implements** the earned-superset / equipped-subset / cap pattern this walk
generalizes:
- **`UnitData.earned_skills`** = the ever-growing superset · **`UnitData.skills`** = the equipped subset,
  capped by **`GameState.max_skills`** (`_max_equipped_skills`, `Unit.gd:1090`) · **`mastery_skills`** =
  always-on, no slot.
- **`[SKL-3]` `requires_equip`**: `true` → enters `earned_skills`, **counts against the cap**; `false` →
  passive (Class-sheet active while qualifying), **no slot**.
- `_learn_skill` (`Unit.gd:903`) **auto-equips if a slot is free, else** keeps it earned-but-unequipped.

`[CEX-7]`/`[STY-3]` already specified that the cap on styles/granted-sources **reuses this mechanism**
(`requires_equip` + earned/equipped subset). This register just firms the generalization.

---

## [LDC-1] Mechanism = generalize the skills earned/equipped/cap pattern to styles + sources — **RESOLVED**
One pattern across all three cap-bound categories: an **ever-growing earned superset** → an **equipped
subset** drawn from it → a **cap**. Styles (`[STY-3]` `learned_styles`/`equipped_styles`) and **granted
sources** (`[CEX]` known/granted list) adopt the exact skills shape. No new machinery.

## [LDC-2] Caps = separate author-configurable per-category CampaignRules knobs — **RESOLVED**
**Owner:** **separate per-category caps**, each a `CampaignRules` knob — `max_skills` (exists) +
**`max_styles`** + **`max_sources`** (names indicative). Independent balance; matches the existing
`max_skills`. **Not** a unified slot pool (rejected — conflates categories + complicates balance).
*(These are **base** values — `[LDC-8]` makes them criteria-modifiable, and `[LDC-9]` partitions the
style cap per author-defined `style_group`.)*

## [LDC-3] Slot-bound vs passive = reuse `[SKL-3]` `requires_equip` across all three — **RESOLVED**
Every cap-bound item (skill/style/granted source) carries **`requires_equip`**: `true` = competes for a
category slot (must be equipped to use); `false` = always-on/passive, **no slot** (the `mastery_skills`/
passive-class-skill behavior). One flag, three categories.

## [LDC-4] Earn-at-cap behavior = auto-equip if room, else earned-unequipped — **RESOLVED**
Keep the existing `_learn_skill` behavior, generalized: a newly earned cap-bound item **auto-equips if a
category slot is free, else enters the earned superset unequipped** (the player equips it later in prep).
**No forced swap on earn** — earning is never blocked or destructive.

## [LDC-5] forget / swap = swap freely in prep; permanent forget is optional + author-gated — **RESOLVED**
**Owner:** the **earned superset is never lost** — the player **re-equips a different subset freely in
prep** (swap). A **permanent `forget`** (discard an earned item to free a slot — respec/rare) is an
**optional author-enabled capability, OFF by default**. No forced/irreversible loss in the default game.

## [LDC-6] Management UI = a `[PHB]` prep panel; prep-only — **RESOLVED**
Loadout management = a **`[PHB]` prep panel** generalizing the existing skill-equip UI to cover skills +
styles + granted sources. **Prep-only** — loadout is not an on-map activity, so it is **NOT** part of the
`[PHB]` dual-surface on-map-placeable set (unlike shop/arena/etc.).

## [LDC-7] Save / F1 — **forward to Phase B (F1 lock)**
**No new per-unit save surface beyond what's already reserved:** the equipped subsets (`skills`, the
`[STY]` `equipped_styles`, the `[CEX]` granted/known list with per-source charge state) + earned supersets
are **already in the Phase B reserve list**. The **base caps are `CampaignRules` data** (campaign config,
not per-unit save). `requires_equip` is authored data on the skill/style/source definition. *(A
**persistent** cap modifier from a consumed item — `[LDC-8]` — is per-unit state → reserve a small
`cap_modifiers` store at the F1 lock; a *held*-item or class-derived modifier is recomputed, not stored.)*

## [LDC-8] Per-criteria cap overrides = criteria-gated modifiers (reuse REQ-16/modifier machinery) — **RESOLVED**
**Owner:** caps are **resolved per-unit values**, not flat constants — `cap = base (CampaignRules) +
author-defined criteria-gated modifiers`. Each modifier carries a **`[REQ]`/F16 criteria predicate**
(class tier, item held, trait, flag, …) + a **delta or absolute value**, reusing the **same
modifier/`[REQ-16]` machinery** as stat modifiers / `[TCV-3]` parametric effects (no bespoke cap system).
Examples: *tier-3 class → skill cap +2*; *training manual → style cap +2*.
- **Both shapes:** a **held/derived** modifier is active while its criteria hold (recomputed on read —
  equip/class/flag change); a **consumed-item permanent** increase is stored as a persistent per-unit
  modifier (`[LDC-7]` reserve). Author's choice per effect.
- **Resolution:** deterministic — sum additive deltas onto the base, an absolute `set` overrides
  (highest `set` wins); define order once in the resolver. Per-`[LDC-9]` style-group, overrides target a
  specific group (e.g. +2 to the `fire_magic` cap).
- **Cap-shrink edge:** if a cap **drops** (item unequipped, reclass out of tier 3) leaving a unit
  **over-cap**, the excess **auto-moves to earned-unequipped** (deterministic order; flagged for the
  player to re-pick in prep) — **never lost**, consistent with `[LDC-5]`.

## [LDC-9] Style caps are partitioned per author-defined `style_group` — **RESOLVED**
**Owner:** style caps are **per-source partition**, not one global `max_styles` — *a sword-style limit is
independent of a fire-spell-style limit*. **A style declares a `style_group`** (author-defined: authors
group as granular or coarse as they like — `sword_arts`, `fire_magic`, or `physical`/`magic`); **caps are
per-group** and **counting/sorting groups styles by `style_group`**. A style with no group falls in a
default/global group. The `[LDC-8]` overrides apply per-group. *(The same partition pattern is available
to **granted sources** if an author wants per-source-type source caps — offered, not required; styles are
the asked case.)* Composes `[STY-3]` (the style's source type-gate).

---

## Cross-refs
- **`[CEX-7]`** (granted-source loadout cap, deferred → here) · **`[STY-3]`** (style loadout cap +
  `style_group` source type-gate, deferred → here) · **`[SKL-3]`** (`requires_equip` mechanism reused) ·
  **`[PHB]`** (the management panel) · **`CampaignRules`** (`max_skills`/`max_styles`/`max_sources` bases).
- **`[LDC-8]` cap modifiers** reuse **`[REQ-16]`/`[REQ]`** predicates + the **modifier system** /
  **`[TCV-3]`** parametric effects — caps are derived values like stats, not constants.
- **Out of scope:** item inventory (`max_inventory`) + accessory slots (`[IEQ]`) are a *separate* cap
  system — the loadout cap covers **abilities** (skills/styles/sources), not carried items.
