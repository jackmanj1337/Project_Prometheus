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
| F5 | **ConditionManager / status system** (M8) | 🟡 stub | combat loop | status conditions UX, flexible-triangle conditions, poison/immunity tags, debuff staves | ✅ **decided 2026-06-23l: FULL author-extensible system** (end-shape in foundations doc) |
| F6 | **Campaign-flag / story-state store** | ❌ missing | F1, F8 | story-item branching, recruit conditions, route/difficulty branching, village outcomes | ✅ **decided 2026-06-23l: generic flag/variable store** (end-shape in foundations doc) |
| F7 | **Resource pools** (stamina/mana/HP) | ❌ not built | F1, F2 | spells-from-pool, combat arts (charge), possibly gambits | **Build as a foundation** vs per-feature |
| F8 | **Map events / triggers** (`[MET]`) | ✅ firmed | grid/map | village, recruit, story branching, objectives | decided |
| F9 | **Hub / PHB option-panel framework** (`[PHB]`) | ✅ firmed | F1 | shop, arena, training halls, skirmish, recruit-prep | decided |
| F10 | **Canto / move-after-action** | ❌ not built | turn/action flow | Knight Ring, mounted QoL, rescue-canto interaction | scope (which classes/effects grant it) |
| F11 | **Skill trigger/effect system** (GDD_05) | 🔧 built, needs effect_ids | combat loop | accessory effects, on-crossing grants, combat arts, gambits, many items | add effect_ids per feature (no new triggers — discipline) |

**Critical-path reading:** F1 gates all persistence; F4/F5/F6/F7 are the **currently-undecided
foundations** that unlock whole feature clusters — they are the right subject for "deciding end
shapes." F2/F3/F8/F9 are decided and just await build.

---

## 2. Feature atlas (grouped by primary foundation cluster)

### Cluster A — Items / Equipment / Economy  (F1·F2·F3·F9)
| Feature | Size | Needs | Status |
|---|---|---|---|
| `[IEQ]` composition build (ItemDef + components, staged) | **XL** | F1,F2 | firmed |
| `[PXP]` framework build (store, profiles, gain, training halls) | **L** | F1,F3,F4 | firmed |
| Convoy `[CNV]` · Shop `[SHP]` | **M** ea | F1,F9 | firmed |
| Forging (M10) | **M** | F2 | deferred |
| Per-map-use items (CEX-D) | **S** | F2 | exploration |
| Combat arts / weapon arts (#15) | **M** | F2,F7,F11 | DISCUSS |
| Bonus-EXP (#18) · Arena (#14) | **M** ea | F3,F9 | DISCUSS |
| Learned spells (CEX-B) | **XL** | F1,F2,F3,F7 | exploration |
| Resource pools (CEX-A) | **M** | F1,F2 → *is* F7 | exploration |
| Story-item tracking (CEX-E) | **S** track / **XL** branch | F2 / F6 | exploration |

### Cluster B — Combat / Weapon mechanics  (F5·F11·F4)
| Feature | Size | Needs | Status |
|---|---|---|---|
| Status-condition build (M8) | **L** | → *is* F5 | designed |
| Flexible weapon triangle (CEX-C) | **M** + cond. slice | F4, F5(cond) | exploration |
| Weapon effect_tags gaps (poison/heal_on_hit/ignores_def/always_hits) | **S** ea | F5,F11 | designed-gap |
| Item skill effect_ids (negate_effectiveness/negate_crit/permanent_stat/advance_proficiency) | **S** ea | F11 | checklisted (IEQ §2f) |
| Broken-weapon `[BWN]` · Stationary weapons `[STW]` | **S**/**M** | combat | firmed |
| Skill content M9b (per-skill UX) | **L** | F11 | partial |

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
| Canto (#9) | **M** | turn flow → *is* F10 | Tier1 |
| Dancer / refresh (#8) | **M** | action flow | Tier1 |
| Utility staves (#10) | **M** | action flow | Tier1 |
| Movement assists (#17) | **M** | action flow | DISCUSS |
| Rescue system (#6) | **L** | F10, CON | Tier1 |

### Cluster E — Roster / progression / campaign flow  (F1·F6)
| Feature | Size | Needs | Status |
|---|---|---|---|
| Recruit / Capture (#4/F) | **L** | F6,F8 | GAP |
| Support system (#5/H2) | **XL** | F1 | GAP |
| Avatar / My Unit (#20) | **L** | F1 (roster/save/story cascade) | DISCUSS |
| Difficulty modes + Casual/Phoenix (#12) | **M** | F4 | Tier1 |
| PvP / scenario (#7) | **M** | reuses standings | Tier1 |

### Cluster F — Big standalone systems
| Feature | Size | Needs | Status |
|---|---|---|---|
| Battalions / gambits (#16) | **L** | F11, action flow | DISCUSS |

### Cluster G — Infra / tooling / gates
| Feature | Size | Needs | Status |
|---|---|---|---|
| Save-cluster build `[CST]` | **L** | → *is* F1 | OPEN (technical) |
| Map sprite importer `[IMP]` | **M** | — | OPEN |
| Campaign self-contained packaging `[ICO]` | **M** | F1 | firmed |
| Legal/licensing `[LEG]` · Public-identity rename `[REN]` | **S** ea | — | OPEN (owner input) |

---

## 3. Build-order implications (for the scheduling session)
- **F1 (save schema) first** — lock the reserved fields before any cluster reserves them ad-hoc.
- **The four undecided foundations gate the most:** F5 (conditions) unlocks Cluster B's richest
  half + flexible-triangle conditions; F6 (story-state) unlocks recruit/story/branching (Cluster E);
  F7 (pools) unlocks spells + combat arts; F4 (profile mechanism) is cheap and unlocks
  triangle/pools/difficulty uniformly — **F4 is the high-leverage, low-cost one to settle first.**
- **Decided foundations (F2/F3/F8/F9) just need scheduling**, not more design.
- **Cluster A is the in-flight build** (IEQ XL + PXP L) — the largest single commitment on the board.

## 3b. Target-firming roadmap (dependency order — owner 2026-06-23l)
The order in which we **define each un-firmed player-facing target** (the ⚠/✗ items). ⚠ first
(deps now decided), then ✗ in dependency order. Each pass = a firming walk like IEQ/PXP.

**Wave 0 — open foundations (gate the most, do first):**
- **F1** save-schema lock (reserve fields) · **F7** resource pools end-shape (`[CEX-1..4]`; gates
  spells + combat arts) · **F10** canto scope (gates rescue + Knight Ring).

**Wave 1 — ⚠ ready now (deps decided):**
- Flexible weapon triangle (`[CEX-9..12]`; deps F4✓/F5✓) · Per-map-use items (`[CEX-13]`; dep IEQ✓) ·
  Learned spells (`[CEX-5..8]`; after F7) · Story items (`[CEX-14..16]`; tracking now, branching after F6) ·
  Per-skill UX (M9b content).

**Wave 2 — ✗ v1 worklist (dependency-ordered):**
- Difficulty modes (#12; dep F4✓) · Dancer (#8) · Movement assists (#17) · Utility staves (#10) ·
  Canto (#9=F10) → Rescue (#6) · Recruit/Capture (#4; after F6) · Village (#11; MET✓+F6) ·
  Support (#5; large standalone) · PvP (#7) · Arena (#14) · Bonus-EXP (#18) ·
  Combat arts (#15; after F7) · Battalions (#16) · Avatar (#20).

## 4. Foundation end-shapes
**Decided 2026-06-23l** (end-shapes in `design/foundations_end_shapes_2026-06-23.md`): **F4** = one
generic author-profile mechanism · **F5** = full author-extensible status system · **F6** = generic
campaign-flag/variable store. With F2/F3/F8/F9 already settled, the **remaining open foundations are
F7** (resource pools — decide with the learned-spell question, `[CEX-A]`) **and F10** (canto scope).
Each decided foundation graduates into its own register + build when scheduled.
