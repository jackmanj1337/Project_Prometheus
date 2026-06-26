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
| F5 | **ConditionManager / status system** (M8) | 🟡 stub | combat loop | status conditions UX, flexible-triangle conditions, poison/immunity tags, debuff staves, **capture `sleep`, style status (`[STY]`)** | ✅ decided 2026-06-23l: FULL author-extensible system · **pulled onto A1's critical path 2026-06-24k (`[STY-12]`)** — build the full system within/before A1 (capture + style status + buff/debuff staves all need it) · **forward-reqs from `[REQ-14]`/`[REQ-15]`:** model a **potency/stack** dimension; **expose condition params introspectably**; carry a **lethal/floor** param (poison floors at 1 vs a killing condition); and provide a **next-resolution projection/preview API** ("will this tick kill or leave at 1 HP") shared by the damage-preview UI + the predicate machine · **forward-req from `[RDR]`/`[CVR]` (redirect/cover, 2026-06-26f):** expose a **uniform source-bearing `effect_applied(kind, magnitude, source, target, flags)` event** with a **`redirectable` flag** for the `CombatResolver` interceptor, and **store the source on every condition instance** (condition bounce + per-tick reflect) |
| F6 | **Campaign-flag / story-state store** | ❌ missing | F1, F8 | story-item branching, recruit conditions, route/difficulty branching, village outcomes | ✅ **decided 2026-06-23l: generic flag/variable store** (end-shape in foundations doc) |
| F7 | **Resource pools** (stamina/mana/HP) | ❌ not built | F1, F2, F4 | spells-from-pool, combat arts, skill costs | ✅ **decided 2026-06-23l: standalone foundation** (`[CEX-1..4]`; CampaignRules pool types, author refill modes, restore items/Regen skills, gates weapon/spell/skill use) · **consumer `[RDR-13]` (redirect/cover, 2026-06-26f):** `redirect` gates on + drains a pool via the generic `cost: {pool, amount(term), subject: holder\|granting_item}` clause (uses/charges · mana-cost · depleting barrier = `amount: absorbed_value`); works against existing HP/item-`uses` pools before author-defined pools land |
| F8 | **Map events / triggers** (`[MET]`) | ✅ firmed | grid/map | village, recruit, story branching, objectives | decided |
| F9 | **Hub / PHB option-panel framework** (`[PHB]`) | ✅ firmed | F1 | shop, arena, training halls, skirmish, recruit-prep | decided |
| F10 | **Secondary Movement / move-after-action** | ❌ not built | turn/action flow | Knight Ring, mounted QoL, rescue interaction | ✅ **decided 2026-06-24a: a parameterized SKILL (remaining\|flat) granted via the skill-grant mechanisms** (`[SMV-1..11]`; supersedes GDD_10 M10's automatic-mounted approach) |
| F11 | **Skill trigger/effect system** (GDD_05) | 🔧 built, needs effect_ids | combat loop | accessory effects, on-crossing grants, combat arts, gambits, many items | add effect_ids per feature (no new triggers — discipline) |
| F12 | **Dynamic skill grant/revoke** (`[SKL-4]`) | ❌ not built | F11, F6 | story-event skills, skill shops, skill items, skill-grants-skill, PXP-4 on-crossing | ✅ **decided 2026-06-23l: general grant/revoke API + Granted category** (`[SKL-1..6]`) |
| F13 | **Text indirection / localization-ready string layer** (`[MCH-6]`) | ❌ not built | F1 | dialogue, avatar/main-character names, relationship & recruit conversations, all UI text | ✅ **decided 2026-06-24g: ID-keyed templates + `unit_id` name lookup, no concatenation; Godot `tr()` when localized; convention now, multi-locale build deferred** |
| F14 | **Author-extensible stat model** (`[STM]`) | ❌ not built | F1, F4 | a Charisma/Charm stat, a Command/Authority proficiency for battalions (`[BAT-6]`/`[STM-2]`), author-defined campaign stats (legacy base stats kept) | 🔶 **NEWLY SURFACED 2026-06-25l — NOT yet firmed.** Direction: *evolution not rewrite* — the read path is already string-keyed + growths/caps are dicts, so add an `extra_stats` dict + a `CampaignRules` stat registry + a `get_effective_stat` fallback and de-hardcode the ~5 stat-list literals. **Ratify at the define-all sweep.** Plan in `registers/extensible_stat_model_open_questions_2026-06-25.md` |
| F16 | **Shared Requirement / Predicate system** (`[REQ]`) | ❌ not built | F6 + unit/convoy data; **`chance` → Package A `[PKGA]` + F4 profile** | dialogue branch gating (`[DLG-14]`), MET conditions (`[MET-4]`), tile-action requirements (`[VIL-6]`), recruit eligibility (`[RCR-4]`), accessory `req_flags` (`[IEQ]`), objective preconditions; **also a general persuade/steal/contest gate** | ✅ **SURFACED + FIRMED 2026-06-25r `[REQ-1..16]`.** One author-extensible `Requirement` = an all/any/not tree of typed predicates (flag · unit-id · class-level · proficiency · stat · skill/trait · item held/equipped/convoy), each a ~1-line read over an existing accessor; per-predicate **subject selector** (speaker/participant/unit/party); renders to text for "[Requires: X]". **`[REQ-9]`** reusable **value terms + a `compare(term op term)`** for two-dynamic-value comparisons (my STR > your DEF) — terms span **unit attributes AND item properties**; **`[REQ-11]`** **item references** (`equipped`/`held`/**`targeted`**, context-resolved) + the `[IEQ]`-grounded property vocab (mt/hit/wt/cost/family/`effect_tags`…) so compares/gates read equipped/held/targeted item stats (my weapon's Mt > yours; targeted item has armorslayer); **`[REQ-10]`** a **`chance` gate** skewed by a difference\|ratio of two terms via a CampaignRules **F4 skew profile** (linear/sigmoid/table), rolled through **RngService/Package A** (rewind-safe), **roll-once-and-latch** (rides `visited_trail`/F6). **`[REQ-12]`** HP/pools(`pct`)/per-map-ability-availability/STY-style-availability/identity sources; **`[REQ-13]`** four gap families — **spatial** (adjacency/distance/terrain/region) · **runtime-state** (acted/moved/paired/carried) · **`[REL]` support-rank** · **aggregate `count(set, req) op N`** (generalizes any/all); **`[REQ-14]`** `condition_potency`/`duration`/`count` over F5; **`[REQ-15]`** any `condition_param` + **F5-delegated outcome projection** (`would_kill`/`would_floor`/`next_tick_damage` — "will the poison kill or leave at 1 HP") → forward-reqs on F5 (params + lethal/floor + projection API). **`[REQ-16]` arithmetic value terms** (owner 2026-06-26): recursive **fixed-point (×1000)** math tree (`add/sub/mul/div/pow/min/max/abs/neg` + number-domain booleans `not/and/or/truthy`, `>0`=true) — derived numbers (STR+MAG > RES; A/B > C^D) + scaled effect magnitudes; **half-up rounding** (`floor/ceil` override), **required `on_zero`** on `div`, integer-exp `pow`; **comparisons/`xor` = named compositions**; **subsumes the REQ-10 skew `difference\|ratio`** (→ author custom contest curves, still pure); predicate-bridge **deferred** (flag-upstream pattern); **author-declared F4 complexity budget** (`max_formula_depth`/`max_formula_nodes`, full headroom, iterative evaluator + absolute safety ceiling); stays **Option A** (data tree, no pack code) = the **first `[EXT]` worked example**. **Net-simplifying** — replaces scattered ad-hoc condition code; reads reserved state (latch aside, no new save surface). **Author-extensibility `[EXT-1..6]` RESOLVED 2026-06-26 (register CLOSED):** model = **A ("A-plus": data-composition; B a narrow evidence-gated future exception)**, no-code preserved, structural load-validation, named-compositions + a primitive-request/contributor on-ramp (normal release cadence, 3-way triage). **"One model = A" was already the convergent design** — `[DLG-3]` effects/F5 self-describe as "mirroring the F4/F5 profile philosophy"; F4 profiles = the reference A impl (`table`=author curves as data); `[MET]` = declarative trigger→action composition (side-effects in engine primitives). **Determinism is per-OUTPUT-PATH:** decision/predicate = pure+fixed-point+PkgA · state-mutation = ordered engine primitives+PkgA RNG · presentation (DLG visuals) = exempt (gating rides REQ).** **Forward-req from `[RDR-12]` (redirect/cover, 2026-06-26f):** add an **`event` context subject** (binding the intercepted effect event — `kind`/`damage_class`/`magnitude`/`is_crit`/`range`/`source`/`condition_id`/`stacks`) so interceptor triggers + terms can read the incoming hit (`event.source` then chains into `[REQ-11]` weapon reads). Plan in `registers/requirement_predicate_system_open_questions_2026-06-25.md` |
| F15 | **Dialogue / Conversation system** (`[DLG]`/`[RCV-1]`) | ❌ not built | F13, F8, art pipeline, F16 | recruit conversations (`[RCV]`), village dialogue (`[VIL-4]`), support conversations (`[REL-6]`), main-character name-sub (`[MCH]`), story scenes | 🔶 **END-USER SHAPE FLESHED 2026-06-25q `[DLG-1..10]`** (rough shape surfaced 2026-06-25o). **One overlay** = layered **scene region** (background = map-transparent \| special-bg + animated portraits) over a **script-style chat-log**; **one renderer** (map-as-background collapses battle-vs-scene). **Data = a flat addressable entry list** (`line`/`choice`/`command`/`label`; background = a command; F13 keys). **Three-tier effects** (A character-expression / B portrait-transform flip·move·scale / C scene-wide rain·fog·flashback), each `loop\|once\|loop_until` (loop_until headline = mouth-flap until text finishes scrolling). **Branching choices** + author-configurable pacing (manual / skip-to-decision / auto). **Build staged** (v1 slice + full reserved); **authoring = plain data now + dedicated editor later**. **Stage = explicit-layer (`[DLG-12]`) speaker-independent stage elements (`[DLG-13]`** — can render animated non-speaking entities). **Reflect effect `[DLG-9]` RESOLVED** (two-mode `in_place|copy` live mirror + a fixed-pipeline interaction matrix; rotation = build-time investigate). All `[DLG-1..13]` RESOLVED. Plan in `registers/dialogue_conversation_system_open_questions_2026-06-25.md` |

**Critical-path reading:** F1 gates all persistence; F4/F5/F6/F7 end-shapes **decided 2026-06-23l**,
**F10 decided 2026-06-24a**, **F13 decided 2026-06-24g** → **F1–F13 all have decided end-shapes; only
F1's schema-lock pass + the builds remain.** F2/F3/F8/F9 decided and await build. **Two foundations
carry only rough/not-fully-firmed end-shapes, both to be ratified in the define-all sweep before F1
locks:** **F14 (stat model**, surfaced 2026-06-25l — adds the `extra_stats` + stat-registry save
surface; **optional**, degrades to the bounded "add one Charisma stat" `[STM-1]`) and **F15
(dialogue/conversation**, surfaced 2026-06-25o, **end-user shape fully fleshed 2026-06-25q
`[DLG-1..13]` — all RESOLVED** — unified overlay + entry-list format + three-tier effects + reflect
`[DLG-9]` + explicit layers `[DLG-12]` + speaker-independent stage elements `[DLG-13]` + branching +
mid-conversation save `[DLG-11]` + staged build + plain-data/editor authoring; **build deferred**). Both
are forward-compatible foundations whose *hooks/shape* are committed now and whose remaining details
(F14 v1 schema; F15 v1 build-slice + a rotation-feasibility investigate) are settled at/after the sweep.
**F16 (shared Requirement/Predicate system, `[REQ-1..8]`) surfaced + FIRMED 2026-06-25r** — an
author-extensible predicate vocabulary unifying dialogue gating + MET conditions + tile-action
requirements + recruit eligibility + `req_flags` + objective preconditions; reads reserved state, adds
no save surface; the author-extension registry rides F4 / the sweep. **Net-simplifying**, not new risk.

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
| Village / house visit (#11) | **M** | F8,F2 | firmed 2026-06-25n `[VIL-1..8]` — config over DTR object + MET runner + F6 + the interactive-trigger substrate |

### Cluster D — Unit actions / movement  (action+turn flow, F10)
| Feature | Size | Needs | Status |
|---|---|---|---|
| Secondary Movement (#9) | **M** | turn flow → *is* F10 | Tier1 |
| Dancer / refresh (#8) | **M** | action flow | Tier1 |
| Utility staves (#10) | **M** | action flow, F5 | **firmed 2026-06-24k** (`[STY-13..16]`; staves = `[CEX-20]` sources w/ an `effects`(set)+`target_filter` axis, fold into source+style; buff/debuff ride F5) |
| Movement assists (#17) | **M** | action flow | DISCUSS |
| Rescue system (#6) | **L** | F10, CON | Tier1 |

### Cluster E — Roster / progression / campaign flow  (F1·F6)
| Feature | Size | Needs | Status |
|---|---|---|---|
| Recruit / Capture (#4/F) | **L** | F6,F8 | roster side firmed 2026-06-24h `[RCR]`; **conversation side firmed 2026-06-25o `[RCV]`** (`talk`=a `[VIL-2]` config · trigger-agnostic `recruit` action · author-choice directionality · damage-forfeit=author-condition · pins dialogue F15); capture-carry → A2 |
| Support system (#5/H2) | **XL** | F1 | GAP |
| Avatar / My Unit (#20) | **L** | F1 (roster/save/story cascade), F13 | firmed 2026-06-24g `[MCH]` |
| Difficulty modes + Casual/Phoenix (#12) | **M** | F4 | Tier1 |
| PvP / scenario (#7) | **M** | reuses standings | Tier1 |

### Cluster F — Big standalone systems
| Feature | Size | Needs | Status |
|---|---|---|---|
| Battalions / gambits (#16) | **L** | F11, action flow | **attack-side firmed 2026-06-24j** (`[STY-7]`; gambit = AoE **style** over a battalion-granted source, A1) · **battalion entity firmed 2026-06-25k** (`[BAT-1..13]`; the **attached-augment** pattern — thin entity over reused Pair-Up attach + bonus-resolver + granted-source + rank-helpers; adjutant→Pair-Up, accessory→`[IEQ]`, Emblem = maximal config) · **content/lifecycle `[BAT-14..16]` OPEN** (bonus content, resource model, destruction + host-death disposition) → define-all sweep before F1; host-death rides the A5 death-disposition rule set |

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
  utility/buff/debuff staves** are all *styles or source `effects`* over a `[CEX-20]` source; building it
  closes the deferred `[CEX-23]`.
  **A1 DESIGN COMPLETE 2026-06-24n** (`[STY-1..17]` all resolved bar `[STY-11]` battalion-entity → A2;
  player flow + authoring surface in `design/source_style_player_and_authoring_2026-06-24.md`).
  - **A1 BUILD checklist (must clear before A1 closes):** (1) build the `[CEX-22]` auto-equip fallback
    **(revisited & firmed 2026-06-25):** persistent swap; **player-orderable source priority + equip
    history (MRU)** falling through unavailable sources; not range-aware by default; an **opt-in skill**
    makes it range-aware (picks the highest-priority source that permits a counter); reserve MRU +
    ordering in F1. Two **universal built-in sources**: `fists` (infinite 0-Mt floor that *can* fight) +
    `no_attack` (`[CEX-24]`, mandatory "Restrain" floor that *can't* initiate/counter, defaults to queue
    bottom); (2) build the `[STY]` source+style
    pipeline (`[CEX-23]` combo-select) + the `effects`/`target_filter` source axis (`[STY-13]`/`[STY-16]`);
    (3) build AoE/multi-target (`[STY-9]`: shapes incl. `rectangle`; friendly-fire = broad filter; **also the shared target-selector consumed by `[RDR]`/`[CVR]` redirect/cover**) + the
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
  side; capture-carry → A2, conversation → A4). **A3 roster/save schema is defined for the F1 lock.**

> **Cluster progress / next:** **A3 design ✅** (2026-06-24f/g/h) → **A1 design ✅** (2026-06-24i…
> 2026-06-25c; `[CEX-5..8,20..24]` + `[STY-1..17]`, only `[STY-11]`→A2) → **A2 design ✅
> (2026-06-25k):** displacement/carry sub-cluster `[DSP-1..17]` (2026-06-25e…i), action-grant
> sub-cluster `[AGT-1..13]` (2026-06-25j), **battalion entity architecture `[BAT-1..13]` (2026-06-25k)**
> — closing `[STY-11]`, the last A2 item. **Battalion content/lifecycle `[BAT-14..16]` re-OPENed
> 2026-06-25m** (bonus content, resource model, destruction + host-death disposition) — persistent-state
> details into the define-all sweep before F1; host-death rides the A5 death-disposition rule set.
> **Framing settled:** the battalion is **neither** merged into items
> **nor** fully bespoke — it is the canonical config of a generic **attached-augment** entity (thin
> `BattalionData` + `BattalionRegistry` over reused Pair-Up attach + bonus-resolver + granted-source +
> rank-helpers, `[BAT-1]`); adjutant → Pair-Up (`[BAT-8]`), accessory/bond-ring → `[IEQ]` (`[BAT-9]`),
> Emblem = the maximal config (`[BAT-7]`). Then A4 (incl. the `[STY-17]` provoke MET action), A5 (incl.
> the loadout cap + the `[AGT §6]` non-combat-action EXP pin, now also pricing battalion-EXP `[BAT-6]`)
> → **F1 schema-lock (Phase B).**
- **A4 — Story / event-driven map content** *(shared: MET `[F8]` + flag store `[F6]`).* **DESIGN ✅
  COMPLETE 2026-06-25p.** Village (#11 — **firmed 2026-06-25n `[VIL-1..9]`**) · Recruit/Capture
  conversation+flag side (#4 ⇄ A3 — **firmed 2026-06-25o `[RCV-1..6]`**) · **a `[MET]` action that sets
  a faction relationship + AI "provoke" transitions** (`[STY-17]` dynamic neutral→hostile — **firmed
  2026-06-25p `[PRV-1..7]`**) · Capture-victory objective type (`[VIL-9]`, closes the `[DSP]` pin).
  *Why sync:* same trigger+flag plumbing; Recruit straddles roster (A3) and events (A4).
  > **A4 keystone (2026-06-25n):** the Village walk pinned the shared **interactive-trigger
  > substrate** `[VIL-2]` — a *player-initiated* MET trigger fired from a `TileActions`/action-menu
  > entry (sibling to Seize/Escape). **Visit + Recruit `talk` (`[RCR-3]`) + reserved `shop`/`activate`
  > are its configs.** The **`shop` + `activate` interactive-trigger configs** (the on-map *mechanic*
  > for the `[SHP-4b]` battlefield-shop — economic rule already firmed — + a generic `activate` for
  > levers/switches, partly overlapping `[DCH]` doors/chests) were not walked in A4; **FOLDED INTO A5
  > (owner call 2026-06-25q)** — see the A5 bullet. Each is just another `[VIL-2]` config. Recruit's
  > conversation side reuses the substrate, doesn't re-invent. Also pinned: the
  > `TileActions` **discovery-list + required-characteristics + author-hideable (secret)** extension
  > `[VIL-6/7]`, and the **objective removal-disposition rule** `[VIL-8]` (Rout/Eliminate key on
  > hostile-to-player presence; escape/story-removal = author `pass|fail`) — a **forward-pin to the
  > objective system**, co-owning the A5 death/removal-disposition path and absorbing the `[DSP]`
  > Capture-victory pin.
  > **A4 recruit side (2026-06-25o, `[RCV-1..6]`):** `talk` = a `[VIL-2]` config; the `recruit` action
  > is **trigger-agnostic** (talk/village/turn/flag) over the `[RCR-3]` API; directionality = author's
  > choice (`directed | symmetric`); damage-forfeit = author-composed condition, no engine rule. The
  > walk pinned **dialogue as new foundation F15** (rough end-shape: a conversation = id-referenced
  > `line`/reserved-`choice`/reserved-`command` entries played by a `dialogue` MET action; data format
  > + hook now, presentation deferred) — shared by recruit/village/support/MCH/story.
  > **A4 provoke side (2026-06-25p, `[PRV-1..7]`):** one `set_relationship(from,to,stance,scope)`
  > primitive over the `[STY-17]`-reserved store; the **`set_relationship` MET action** + a reactive
  > **`provoke_on_attacked`** stance flag are its two callers (not two systems). Store = **two layers**
  > (faction-pair edges + per-unit overrides) × **two scopes** (map default + campaign). Full 3-state
  > set (provoke/make-peace/ally-mid-battle); counter-regardless-of-stance kept; AI reads fresh per
  > activation. Distinct from `[RCR-1]` recruit `team` flip. AI initiate behavior firms with the AI pass.
- **A5 — Campaign meta-rules & EXP/economy** *(shared: F4 CampaignRules, hub/PHB, EXP economy,
  death/permadeath rules).* Difficulty + Casual/Phoenix (#12) · Bonus-EXP (#18) · Arena (#14) · PvP
  (#7) · **the style/source loadout cap (forget/swap, `requires_equip`)** (`[CEX-7]`/`[STY-3]`; pinned
  2026-06-25c — sits with `CampaignRules.max_skills`). *Why sync:* all ride F4 profiles and/or the hub +
  EXP/economy; Casual/Phoenix death rules and Arena death-risk share the permadeath-handling path.
  - **Death-inventory disposition rule set (NEW — pinned 2026-06-25h).** An **optional `CampaignRules`
    profile** governing what happens to a unit's carried + equipped inventory when it dies. Modes
    (author default + per-case overrides): `to_convoy` (no loss) · `lost` (destroyed) · `drop_on_tile`
    (recoverable pickup) · `transfer_to_killer` (loot). **Single disposition path:** route **all** death
    causes through one `handle_death` inventory step — today only `CombatResolver` calls
    `unit.handle_death()`; non-combat deaths (F5 condition/poison ticks, hazard terrain, the `[DSP-14]`
    `force_onto_invalid` ring-out, scripted/event death) must funnel through the same hook.
    **Edge cases the rule set must define:** (1) **death out of combat** (no exchange); (2) **death
    without a clear killer** — `transfer_to_killer` has no recipient → falls back to the profile's
    no-killer disposition; (3) **death holding a Key Item** — Key-Item **locks** (`[CEX-14..16]`)
    **override** disposition: a Key Item is **never `lost`** (always recovered to convoy / re-granted)
    even under a harsh profile; (4) **no convoy on this map** → `to_convoy` fallback (pending stash /
    drop-on-tile); (5) **Casual/Phoenix** (#12) — a returning unit gets its inventory back (it isn't
    truly dead); (6) **PvP/skirmish** — no permanent loss; (7) **simultaneous deaths** (AoE wipe; **also `[RDR-8]` redirect/dying-thorns** — owner the **snapshot-then-resolve** rule: apply all HP, collect all at 0, run disposition in a deterministic order, mutual kills both die; a redirect kill credits the **holder** even if dead, for EXP/objectives) —
    per-unit resolution + drop ordering; (8) **enemy death** — loot/`drop_on_tile` incl. the
    "droppable-item enemy" case; (9) **death while carrying** (`[DSP-5]`) — the carried unit drops per
    DSP, the carrier's own inventory follows this rule. *Owner:* **A5** (rides F4 + the permadeath path);
    *composes* `[IEQ]`/`[CNV]` (inventory/convoy) · `[CEX-14..16]` (Key-Item locks) · #12 (Casual/Phoenix)
    · `[DSP-14]` (a trigger). **Save/F1:** if `drop_on_tile` persists, reserve a per-map dropped-item
    stash; else no new state beyond convoy.
  - **Non-combat-action EXP / proficiency path (NEW — pinned 2026-06-25j, from `[AGT]`).** Confirm +
    generalize a **support-action EXP rule** so non-combat actions (Reinvigorate/`[AGT]`, the `[STY]`
    non-attack effect set) can award progression. Code-grounded: the **level-EXP plumbing exists** —
    `Unit.add_exp()` is shared and **staff use already calls it** (`STAFF_HEAL_EXP`), so the open part is
    an **authored EXP amount per support action** (a `SkillData`/`CampaignRules` value, not a hardcoded
    constant). **Proficiency EXP is the gap:** `add_wexp(track,…)` is **weapon-track keyed**, so
    non-weapon skills have no proficiency path — decide whether support actions earn skill-mastery
    progression at all, and on what track. *Owner:* **A5** (EXP economy / Bonus-EXP #18); *composes* the
    staff-EXP precedent. Generalize rather than special-case each action. (Detail in
    `registers/action_grant_open_questions_2026-06-25.md` §6.)
  - **`shop` + `activate` interactive-trigger configs (FOLDED IN — owner call 2026-06-25q).** The
    shop/convoy/trade *economics* are firmed (`[SHP-1..5]`/`[CNV-1..7]`, 2026-06-23k); A5 now owns the
    **on-map mechanic**: the **`shop`** config (the `[SHP-4b]` battlefield-shop access — a unit visits a
    shop tile, buy→unit + overflow→convoy) and a generic **`activate`** config (levers/switches/objects;
    reconcile with `[DCH]` doors/chests). Both are just more **`[VIL-2]`** interactive-trigger configs
    over the existing substrate — a small walk. *Why here:* battlefield-shop is economy + hub-adjacent.
- **Cross-cutting (content, not a cluster):** Per-skill UX (#M9b) — folds into the skill-system UI;
  arts/gambits (A1) surface there as skill-like entries, so do it alongside A1.

**Phase B — F1 save-schema lock** (the last foundation pass; can only close once Phase A is done so it
reserves a complete schema): proficiency_xp · equipped-**source** pointer (`[CEX-21]`) · accessory slot
maps · pools · known/**granted** list **(with per-source charge state `[CEX-6]`/`[CEX-20]`)** ·
**learned/equipped styles + the optional `style_id` attack half + per-style charge state (`[STY]`)** ·
**captured/`sleep` state (`[STY-6]`/`[RCR]`)** · **active-conditions state (type + duration) per unit
(full F5, `[STY-12]`)** · **runtime faction-relationship overrides (`[STY-17]`/`[PRV-6]` — two layers: faction-pair edges + per-unit overrides; two scopes: map + campaign)** · **per-unit equip
history (MRU) + player source-ordering (`[CEX-22]`)** · **mid-conversation resume
`conversation_resume = {conversation_id, cursor, visited_trail?}` for "between speaker" suspend (`[DLG-11]`; dialogue branch state otherwise rides F6)** · story flags ·
`map_uses_remaining` · triangle profile selection · `ItemDef.story`+lock flags · **the battalion attach
+ endurance/rank state + the `[BAT-16]` disband/exhausted + attached-vs-pooled status (`[BAT-11]`/`[BAT-16]`)** · **(if F14/`[STM]` is taken) `UnitData.extra_stats` + the
`CampaignRules` stat registry (`[STM-3]` §3)** · **plus every field Phase A surfaces.**

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
