---
Type: plan
Status: Active — planning input for the scheduling/priority session
Last verified: 2026-06-23
---

# Feature Dependency Atlas & Foundations

**Started:** 2026-06-23 (session 2026-06-23l)
**Status:** Active planning input. Groups every planned feature/redesign by the **foundations it
relies on or modifies**, sizes each, and defines the **foundations** + their target end-shapes —
so the follow-on **scheduling/priority session** has a dependency-ordered map.
**Method note:** this is a **sizing + dependency atlas**, not a full technical plan per feature.
"How big is each feature" is answered by *size + what it depends on*; the deep per-feature
implementation plan is written when that feature is **scheduled**. Sizes are rough estimates.

**Size legend:** **S** ≤1 build phase · **M** 1–2 · **L** 3–4 · **XL** 5+ / feature-sized.
**Foundation state:** ✅ firmed (build pending) · 🟡 partial/stub · ❌ missing/not built · 🔧 built (needs additions).

---

## 1. Foundations layer (the bedrock everything rests on)

| # | Foundation | State | Rests on | What depends on it | End-shape decision |
|---|---|---|---|---|---|
| F1 | **Save schema / Campaign cluster** (`[CST]`, §2) | ✅ firming done, build pending | — | *everything* persists here | **Lock the reserved schema** (proficiency_xp, equipped-slot pointers, slot maps, pools, known_spells, story flags) before builds reserve ad-hoc |
| F2 | **Unified `ItemDef` + components** (`[IEQ]`) | ✅ firmed | F1 | accessories, consumables, spells, per-map items, story items, combat arts, forging | decided (composition) |
| F3 | **Proficiency / XP framework** (`[PXP]`) | ✅ firmed | F1, F4 | equip legality, spell-learn-by-threshold, training halls, bonus-EXP, arena | decided |
| F4 | **CampaignRules author-profile mechanism** | 🟡 ad-hoc | F1 | PXP ranks, flexible triangle, resource pools, difficulty modes | ✅ **decided 2026-06-23l: ONE generic "named author profile" mechanism** (end-shape in `design/foundations_end_shapes_2026-06-23.md`) |
| F5 | **ConditionManager / status system** (M8) | 🟡 stub | combat loop | status conditions UX, flexible-triangle conditions, poison/immunity tags, debuff staves, **capture `sleep`, style status (`[STY]`)** | ✅ decided 2026-06-23l: FULL author-extensible system · **pulled onto A1's critical path 2026-06-24k (`[STY-12]`)** — build the full system within/before A1 (capture + style status + buff/debuff staves all need it) |
| F6 | **Campaign-flag / story-state store** | ❌ missing | F1, F8 | story-item branching, recruit conditions, route/difficulty branching, village outcomes | ✅ **decided 2026-06-23l: generic flag/variable store** (end-shape in foundations doc) |
| F7 | **Resource pools** (stamina/mana/HP) | ❌ not built | F1, F2, F4 | spells-from-pool, combat arts, skill costs | ✅ **decided 2026-06-23l: standalone foundation** (`[CEX-1..4]`; CampaignRules pool types, author refill modes, restore items/Regen skills, gates weapon/spell/skill use) |
| F8 | **Map events / triggers** (`[MET]`) | ✅ firmed | grid/map | village, recruit, story branching, objectives | decided |
| F9 | **Hub / PHB option-panel framework** (`[PHB]`) | ✅ firmed | F1 | shop, arena, training halls, skirmish, recruit-prep | decided |
| F10 | **Secondary Movement / move-after-action** | ❌ not built | turn/action flow | Knight Ring, mounted QoL, rescue interaction | ✅ **decided 2026-06-24a: a parameterized SKILL (remaining\|flat) granted via the skill-grant mechanisms** (`[SMV-1..11]`; supersedes GDD_10 M10's automatic-mounted approach) |
| F11 | **Skill trigger/effect system** (GDD_05) | 🔧 built, needs effect_ids | combat loop | accessory effects, on-crossing grants, combat arts, gambits, many items | add effect_ids per feature (no new triggers — discipline) |
| F12 | **Dynamic skill grant/revoke** (`[SKL-4]`) | ❌ not built | F11, F6 | story-event skills, skill shops, skill items, skill-grants-skill, PXP-4 on-crossing | ✅ **decided 2026-06-23l: general grant/revoke API + Granted category** (`[SKL-1..6]`) |
| F13 | **Text indirection / localization-ready string layer** (`[MCH-6]`) | ❌ not built | F1 | dialogue, avatar/main-character names, relationship & recruit conversations, all UI text | ✅ **decided 2026-06-24g: ID-keyed templates + `unit_id` name lookup, no concatenation; Godot `tr()` when localized; convention now, multi-locale build deferred** |

**Critical-path reading:** F1 gates all persistence; F4/F5/F6/F7 end-shapes **decided 2026-06-23l**,
**F10 decided 2026-06-24a**, **F13 decided 2026-06-24g** → **all of F1–F13 now have decided
end-shapes; only F1's schema-lock pass + the builds remain.** F2/F3/F8/F9 decided and await build.

---

## 2. Feature atlas (grouped by primary foundation cluster)

### Cluster A — Items / Equipment / Economy  (F1·F2·F3·F9)
| Feature | Size | Needs | Status |
|---|---|---|---|
| `[IEQ]` composition build (ItemDef + components, staged) | **XL** | F1,F2 | firmed |
| `[PXP]` framework build (store, profiles, gain, training halls) | **L** | F1,F3,F4 | firmed |
| Convoy `[CNV]` · Shop `[SHP]` | **M** ea | F1,F9 | firmed |
| Forging (M10) | **M** | F2 | deferred |
| Per-map-use items (CEX-D) | **S** | F2 | **firmed 2026-06-24c** (`[CEX-13]`; pure recharge, `uses_per_map` + per-instance map counter) |
| Combat arts / weapon arts (#15) | **M** | F2,F7,F11 | **firmed 2026-06-24j** (`[STY-1..8]`; a **style** over a `[CEX-20]` source — unified source+style model, absorbs `[CEX-23]`) |
| Bonus-EXP (#18) · Arena (#14) | **M** ea | F3,F9 | DISCUSS |
| Weapon-source / equip model (CEX-B-foundation) | **L** | F1,F2 | **firmed 2026-06-24i** (`[CEX-20..23]`; two-source union, `equipped_source` ref, auto-fallback by priority, combo-select deferred) |
| Learned spells (CEX-B-application) | **M** | F1,F2,F7 | **firmed 2026-06-24i** (`[CEX-5..8]`; rides the weapon-source model — fold into Equip Weapon, per-source charge backend, ever-growing list v1) |
| Resource pools (CEX-A) | **M** | F1,F2 → *is* F7 | exploration |
| Story-item tracking (CEX-E) | **S** track / **XL** branch | F2 / F6 | **firmed 2026-06-24d** (`[CEX-14..16,18,19]`; tracking+locks+convoy now, mutation→MET, branching-state→F6) |

### Cluster B — Combat / Weapon mechanics  (F5·F11·F4)
| Feature | Size | Needs | Status |
|---|---|---|---|
| Status-condition build (M8) | **L** | → *is* F5 | designed |
| Flexible weapon triangle (CEX-C) | **M** + cond. slice | F4, F5(cond) | **firmed 2026-06-24b** (`[CEX-9..12,17]`; F4 `triangle` profile + reaver; conditions slice after F5) |
| Weapon effect_tags gaps (poison/heal_on_hit/ignores_def/always_hits) | **S** ea | F5,F11 | designed-gap |
| Item skill effect_ids (negate_effectiveness/negate_crit/permanent_stat/advance_proficiency) | **S** ea | F11 | checklisted (IEQ §2f) |
| Broken-weapon `[BWN]` · Stationary weapons `[STW]` | **S**/**M** | combat | firmed |
| Skill content M9b (per-skill UX) | **L** | F11 | partial |
| Skill-model expansion (personal / class-level / granted) `[SKL]` | **M** | F11,F12,F6 | firmed 2026-06-23l |

### Cluster C — Map / Tactical systems  (F8 + grid)
| Feature | Size | Needs | Status |
|---|---|---|---|
| Fog of War `[FOW]` · Destructible terrain `[DTR]` | **M** ea | grid | firmed |
| Doors/chests `[DCH]` · Map readability `[MRD]`/`[TUR]` | **S**/**M** | grid | firmed |
| Map events/triggers `[MET]` | **L** | grid → *is* F8 | firmed |
| Village / house visit (#11) | **M** | F8,F2 | Tier1 |

### Cluster D — Unit actions / movement  (action+turn flow, F10)
| Feature | Size | Needs | Status |
|---|---|---|---|
| Secondary Movement (#9) | **M** | turn flow → *is* F10 | Tier1 |
| Dancer / refresh (#8) | **M** | action flow | Tier1 |
| Utility staves (#10) | **M** | action flow, F5 | **firmed 2026-06-24k** (`[STY-13..15]`; staves = `[CEX-20]` sources w/ a `effect_kind`+`target_filter` axis, fold into source+style; buff/debuff ride F5) |
| Movement assists (#17) | **M** | action flow | DISCUSS |
| Rescue system (#6) | **L** | F10, CON | Tier1 |

### Cluster E — Roster / progression / campaign flow  (F1·F6)
| Feature | Size | Needs | Status |
|---|---|---|---|
| Recruit / Capture (#4/F) | **L** | F6,F8 | roster side firmed 2026-06-24h `[RCR]` (capture-carry → A2, conversation → A4) |
| Support system (#5/H2) | **XL** | F1 | GAP |
| Avatar / My Unit (#20) | **L** | F1 (roster/save/story cascade), F13 | firmed 2026-06-24g `[MCH]` |
| Difficulty modes + Casual/Phoenix (#12) | **M** | F4 | Tier1 |
| PvP / scenario (#7) | **M** | reuses standings | Tier1 |

### Cluster F — Big standalone systems
| Feature | Size | Needs | Status |
|---|---|---|---|
| Battalions / gambits (#16) | **L** | F11, action flow | **attack-side firmed 2026-06-24j** (`[STY-7]`; gambit = AoE **style** over a battalion-granted source, A1) · **battalion entity → A2** (`[STY-11]`, full 3H scope) |

### Cluster G — Infra / tooling / gates
| Feature | Size | Needs | Status |
|---|---|---|---|
| Save-cluster build `[CST]` | **L** | → *is* F1 | OPEN (technical) |
| Map sprite importer `[IMP]` | **M** | — | OPEN |
| Campaign self-contained packaging `[ICO]` | **M** | F1 | firmed |
| Legal/licensing `[LEG]` · Public-identity rename `[REN]` | **S** ea | — | OPEN (owner input) |

---

## 3. Build-order implications (for the scheduling session)
- **Define-all feature sweep first, THEN F1 (save schema)** (reprioritized 2026-06-24e; see §3b) —
  F1 can only lock a complete schema once every un-firmed feature's persistence is known, so the
  un-firmed-feature sweep is the blocker ahead of F1. F1 still precedes any cluster reserving fields
  ad-hoc.
- **The four undecided foundations gate the most:** F5 (conditions) unlocks Cluster B's richest
  half + flexible-triangle conditions; F6 (story-state) unlocks recruit/story/branching (Cluster E);
  F7 (pools) unlocks spells + combat arts; F4 (profile mechanism) is cheap and unlocks
  triangle/pools/difficulty uniformly — **F4 is the high-leverage, low-cost one to settle first.**
- **Decided foundations (F2/F3/F8/F9) just need scheduling**, not more design.
- **Cluster A is the in-flight build** (IEQ XL + PXP L) — the largest single commitment on the board.

## 3b. Target-firming roadmap (dependency order — owner 2026-06-23l; **reprioritized 2026-06-24e**)
The order in which we **define each un-firmed player-facing target** (the ⚠/✗ items). Each pass = a
firming walk like IEQ/PXP.

**Priority blocker (owner 2026-06-24e) — a full feature-definition sweep precedes the F1 schema-lock.**
F1 must reserve a *whole* save schema; every un-firmed feature that persists state would otherwise
force F1 to be re-opened. So we **define ALL remaining un-firmed targets first** (not just the
schema-heavy GAP/DISCUSS four), **then** lock F1, **then** build. The only work that runs ahead of /
beside this is the **next round of playtest results**; everything else is downstream of it. Chain:
**define-all sweep → F1 schema-lock → all builds.**

**Phase A — Define-all sweep (THE blocker; go through every un-firmed target).** Grouped by
**shared-system overlap (owner 2026-06-24e)** so features that touch the same system are firmed **in
sync** (design the shared schema/UX once, not N times). Two features deliberately straddle two
clusters (noted ⇄). Suggested order = **A3 first** (highest F1-schema risk), then A1, A2, A4, A5.

- **A1 — Combat capabilities & attack/target flow** *(shared: weapon-source enum `[CEX-20]`, action
  menu `[CEX-21]`, source+maneuver selection+targeting `[CEX-23]`, F7 pools, F11 triggers).*
  Learned spells / weapon sources (`[CEX-5..8, 20..23]` **firmed 2026-06-24i** — foundation =
  weapon-source/equip model, spells ride on it; combo-select `[CEX-23]` deferred to #15/#16) · Combat
  arts (#15) · Utility staves (#10) · **gambit attack/area side** of Battalions (#16 ⇄ A2). *Why sync:*
  all are
  "non-standard attack capability + charge/pool cost + possibly altered range/targeting" — they must
  share **one** select→preview→target pattern or the UI forks per feature. **This is now the
  `[STY]` source + style model (firmed 2026-06-24j/k)** — arts, gambits, non-lethal capture, **and
  utility/buff/debuff staves** are all *styles or `effect_kind`s* over a `[CEX-20]` source; building it
  closes the deferred `[CEX-23]`.
  **A1 DESIGN COMPLETE 2026-06-24n** (`[STY-1..17]` all resolved bar `[STY-11]` battalion-entity → A2;
  player flow + authoring surface in `design/source_style_player_and_authoring_2026-06-24.md`).
  - **A1 BUILD checklist (must clear before A1 closes):** (1) **revisit the `[CEX-22]` auto-equip
    fallback priority** — re-validate the order against the #15/#16 designs (don't auto-swap away from
    an intended art/style; maybe weigh range/Mt, not just slot order); (2) build the `[STY]` source+style
    pipeline (`[CEX-23]` combo-select) + the `effects`/`target_filter` source axis (`[STY-13]`/`[STY-16]`);
    (3) build AoE/multi-target (`[STY-9]`: shapes incl. `rectangle`; friendly-fire = broad filter) + the
    generalized "effect forecast" preview (`[STY-10]`: one panel, footprint + focused-target cycle);
    (4) **build the full F5 `ConditionManager`** (`[STY-12]` — on A1's critical path; unblocks capture
    `sleep` + style status + buff/debuff staves); (5) **extend the M14 faction model to the directed
    3-state relationship matrix** (`[STY-17]` — `are_hostile` → `relationship`; consumed by targeting +
    AI; reserve runtime relationship-overrides in F1).
- **A2 — Map action-economy & movement assists** *(shared: post-move action window, Secondary
  Movement F10, granted-action / carry state).* Dancer / refresh (#8; note the existing
  **Reinvigorate** ally-refresh skill) · Movement assists — shove/smite/pivot/swap (#17) · Rescue /
  carry-drop (#6) · **battalion deployment/action side** (#16 ⇄ A1). *Why sync:* all add or re-grant
  on-map actions through the F10 window; rescue + shove share displacement logic.
- **A3 — Roster identity & relationships** *(shared: roster + save — relationship ranks, custom
  avatar, recruited flags; relationship/conversation UI; F6 flags).* Relationship (#5) · Avatar / My
  Unit (#20) · Recruit/Capture (#4 ⇄ A4). *Why sync + do first:* Avatar is built on the relationship
  system; recruitment is often relationship/conversation-gated; all three **expand roster/save schema
  together** — the biggest F1 risk, so firm this cluster before the F1 lock. **Status (firmed
  2026-06-24f/g/h):** `[REL-1..9]` · `[MCH-1..8]` (+ new foundation **F13**) · `[RCR-1..7]` (roster
  side; capture-carry → A2, conversation → A4). **A3 roster/save schema is defined for the F1 lock;
  next cluster: A1.**
- **A4 — Story / event-driven map content** *(shared: MET `[F8]` + flag store `[F6]`).* Village (#11)
  · Recruit/Capture conversation+flag side (#4 ⇄ A3). *Why sync:* same trigger+flag plumbing; Recruit
  straddles roster (A3) and events (A4).
- **A5 — Campaign meta-rules & EXP/economy** *(shared: F4 CampaignRules, hub/PHB, EXP economy,
  death/permadeath rules).* Difficulty + Casual/Phoenix (#12) · Bonus-EXP (#18) · Arena (#14) · PvP
  (#7). *Why sync:* all ride F4 profiles and/or the hub + EXP/economy; Casual/Phoenix death rules and
  Arena death-risk share the permadeath-handling path.
- **Cross-cutting (content, not a cluster):** Per-skill UX (#M9b) — folds into the skill-system UI;
  arts/gambits (A1) surface there as skill-like entries, so do it alongside A1.

**Phase B — F1 save-schema lock** (the last foundation pass; can only close once Phase A is done so it
reserves a complete schema): proficiency_xp · equipped-**source** pointer (`[CEX-21]`) · accessory slot
maps · pools · known/**granted** list **(with per-source charge state `[CEX-6]`/`[CEX-20]`)** ·
**learned/equipped styles + the optional `style_id` attack half + per-style charge state (`[STY]`)** ·
**captured/`sleep` state (`[STY-6]`/`[RCR]`)** · **active-conditions state (type + duration) per unit
(full F5, `[STY-12]`)** · **runtime faction-relationship overrides (`[STY-17]`)** · story flags ·
`map_uses_remaining` · triangle profile selection · `ItemDef.story`+lock flags · **plus every field
Phase A surfaces.**

**Phase C — builds** (decided foundations F2/F3/F8/F9 + everything graduating from the sweep).

**Already firmed (the prior Wave-1, done):** flexible triangle `[CEX-9..12,17]` (2026-06-24b) ·
per-map items `[CEX-13]` (2026-06-24c) · story items `[CEX-14..16,18,19]` (2026-06-24d) · F7 pools
`[CEX-1..4]` (2026-06-23l) · F10 Secondary Movement `[SMV-1..11]` (2026-06-24a) · **weapon-source/equip
model + learned spells `[CEX-5..8, 20..23]` (2026-06-24i — closes the `[CEX]` register; all five
candidate-system clusters resolved).**

## 4. Foundation end-shapes
**Decided 2026-06-23l** (end-shapes in `design/foundations_end_shapes_2026-06-23.md`): **F4** = one
generic author-profile mechanism · **F5** = full author-extensible status system · **F6** = generic
campaign-flag/variable store · **F7** = resource pools (`[CEX-1..4]`). **Decided 2026-06-24a:**
**F10** = Secondary Movement as a parameterized skill (`[SMV-1..11]`). **Decided 2026-06-24g:**
**F13** = text indirection / localization-ready string layer (`[MCH-6]`). With F2/F3/F8/F9 already
settled, **every foundation F1–F13 now has a decided end-shape** — only F1's schema-lock pass remains
before builds. Each decided foundation graduates into its own register + build when scheduled.
