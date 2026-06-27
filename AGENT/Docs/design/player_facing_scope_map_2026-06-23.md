---
Type: design
Status: Active framing / driver
Last verified: 2026-06-23
---

# Player-Facing Feature Scope Map (Firming Driver)

**Started:** 2026-06-23
**Last verified:** 2026-06-23
**Status:** Active framing / driver — Planned firming work indexed here. **Navigation only, NOT a
second specification** (per DOC-005 the authoritative behavior lives in the owning GDD chapter; this
map only tracks *player-facing definition status* + points to owners).
**Purpose:** Drive the owner's sequencing decision (2026-06-23): **(1) finish defining all
player-facing features → (2) decide what the campaign builder gets to control → (3) decide how to
build it.** This is step (1)'s worklist. Builds on `GDD_Feature_Index.md` (the inventory) by adding a
**player-facing-firming lens** distinct from implementation status.

**Status legend (player-facing definition, NOT impl status):**
- **Firmed** — the player experience is fully specified (built or designed).
- **Designed** — player-facing behavior specified in a design/register, awaiting build.
- **Partial** — core firmed, but named sub-features are player-facing-undefined.
- **GAP** — player-facing behavior not yet defined → needs a firming pass (the worklist).
- **Out-of-scope (now)** — deferred beyond this pass.

---

## 1. Feature groups (from `GDD_Feature_Index.md`) × player-facing definition

| Feature group | P-F status | Owner / where defined | What's left to firm (the gap) |
| --- | --- | --- | --- |
| Combat calc & RNG | **Firmed** (target) | GDD_02 §Combat | none player-facing (two-RN = build/balance) |
| Weapon triangle & rank bonuses | **Firmed** (target) | GDD_04 | none player-facing |
| WEXP & equipment legality | **Re-firming** | GDD_04 → `[PXP-1..8]` | generalized into the unified Proficiency/XP Framework (campaign-rules rank profiles + names, group/bond item tracks, multi-source gain, on-crossing events); default profile non-breaking |
| EXP / leveling / promotion / reclass | **Firmed** | GDD_03, GDD_02 | none (modals exist) |
| Classes & class skills | **Firmed** (mechanic) | GDD_03, GDD_05 | content breadth = data, not a P-F mechanic gap |
| Terrain & movement | **Firmed** | GDD_06 | none |
| Objectives & map authoring | **Firmed** | GDD_06 | none |
| Faction scheduling + hotseat | **Firmed** | GDD_02 | none |
| Save / retry / suspend / rewind | **Firmed** | §2 firming A–J + `[CST-1..12]` | none (rewind *mechanic* = build) |
| UI / input / settings / accessibility | **Firmed / Designed** | GDD_07; input-mode design | gamepad reach = build, not P-F def |
| AI behavior | **Designed** | GDD_08; `[AIP-…]` + AI vision | difficulty-band UX surfaced, design-complete |
| Status conditions | **Designed** (M8) | GDD_02 §Status Conditions | minor UX check-backs only |
| **Skills (per-skill behavior)** | **Partial** | GDD_05; M9b content | **GAP: per-skill player-facing behavior/feedback for the content set (M9b)**; skill-MODEL (personal/class-level/granted categories + grant/revoke) **firmed 2026-06-23l `[SKL-1..6]`** (F12 grant/revoke API) |
| **Pair Up & Support** | **Partial** | GDD_05 | Pair Up firmed; **GAP: Support (H2) — ranks/affinity/convos/bonuses; Dual Strike/Guard/adjacent** |
| **Inventory / convoy / shops / economy** | **Partial / GAP** | GDD_04 | inventory/trade exist; **GAP: convoy (D), shop + economy (E)** |
| **Campaign flow & recruitment** | **Partial** | §2 firming; GDD_10 | flow firmed; **GAP: recruit mechanic (F)** |
| Online play | **Out-of-scope** | M15B (post-1.0) | — |

## 2. Player-facing systems designed-but-not-built (roadmap registers, not in the Feature Index yet)
All **Designed** (player-facing behavior specified), awaiting build — *not* gaps for this pass:
- Between-map **prep / deployment** screen (`[CST-5]`, firming C).
- **Fog of War / LoS** `[FOW-1..7]` · **Doors/chests** `[DCH-1..6]` · **Destructible terrain**
  `[DTR-1..8]` · **Map events/triggers** `[MET-1..9]` · **Stationary weapons** `[STW-1..6]`.
- **Map readability / threat range** `[MRD-1..6]` + individual threat range `[TUR-1..4]`.
- **Broken-weapon degraded mode** `[BWN-1..5]`.

## 3. v1 player-facing scope (owner, 2026-06-23h) — broad definition

Each item still needs an A–J-style firming pass (player experience first, code-side after); this
section sets **what's in v1 and at what commitment level**, not the firmed behavior.

### 3a. Cross-cutting design decisions (owner)
- **NO wander-around area.** The **prep screen is the parameterized between-chapter hub**: the author
  declares **which option panels + theme are available at each node / location / time** (e.g. convoy,
  shop, arena, training hall, recruit, skirmish launch). **Expands the firmed §2 branch C** and revises
  C4's "empty for MVP" — prep becomes the host for author-gated option panels. (Authoring side feeds the
  later 4a–4e builder-authority pass: "which prep options does this node expose.")
  **→ FIRMED 2026-06-23k as `[PHB-1..7]`** (`registers/prep_hub_open_questions_2026-06-23.md`): flat
  panel list + cosmetic `theme`/`location_label`; **opt-in** per-node `prep_panels: [...]`; **`node_type`
  battle|hub as a first-class, author-switchable field** (build battle-nodes first, pure hub nodes the
  near-term next increment); **free-nav, single node-advance commit** (Begin Battle / Continue);
  **node-scoped** gating (per-panel `one_shot`/restock added with shop/economy; calendar = overworld-era);
  **immediate** transaction commit (no hub-suspend). Schema add: node gains `node_type` + `prep_panels` +
  `theme`/`location_label`.
- **Skirmish / grind encounters — IN.** Accessed via a prep option (NOT free-roam), with enemy rosters
  **auto-leveled / randomly-leveled**. Ties difficulty bands `[AIP-11]` (stat scaling) + EXP/economy
  balance. Supports optional grinding without an overworld.
- **Capture folds into Recruit (F)** — it's a recruitment mechanism, designed within that firming.

### 3b. The v1 worklist (commitment-tagged)

**FIRM — mechanics committed to v1 (define the behavior):**
1. **Convoy / inventory management (branch D)** — shared store, prep trade, on-map access, `max_inventory=8`.
   **→ FIRMED 2026-06-23k `[CNV-1..7]`** (`registers/convoy_inventory_open_questions_2026-06-23.md`):
   convoy = `Array[InventoryEntry]` (state-preserving), single shared store (absorbs `party_items`),
   author-defined `max_inventory` (enforced) + `convoy_capacity` (default unlimited), unrestricted prep
   trade across the controlled faction's roster, prep-only access in v1 (richer on-map access forward).
2. **Shop / economy (branch E)** — between-map buy/sell, gold sources/sinks, (forge later).
   **→ FIRMED 2026-06-23k `[SHP-1..5]`** (`registers/shop_economy_open_questions_2026-06-23.md`):
   resource-keyed buy/sell (multi-resource model, **gold-only in v1**), buy+sell (key unsellable), author
   per-shop stock (infinite qty, generic panel), prep shop→convoy / **battlefield shop**→unit+overflow
   (mechanic later w/ village/`[MET]`), v1 ledger = reward+sell / shop-buy.
3. **Items & equipment — ground-up review** *(owner-redirected from piecemeal equip — 2026-06-23)*.
   Re-derived the whole item/equipment/proficiency stack: weapons + WEXP are healthy; **equipment is
   half-built + model-split** (passive 4-field `InventoryEntry` bonus disconnected from `ItemData`,
   orphaned `until_unequipped`, stale `InventoryEntry.gd:21` header, named items exceed 4 fields).
   **→ FIRMED 2026-06-23l `[IEQ-1..9]`**
   (`design/items_equipment_unified_model_2026-06-23.md` + `registers/items_equipment_model_open_questions_2026-06-23.md`;
   **supersedes `[EQP-1..5]`**): **composition** model — one `ItemDef` base + optional
   `weapon`/`consumable`/`accessory` components (multi-component ships v1), `InventoryEntry` = thin instance →
   `def_id`; **per-component independent legality** (accessory = item-proficiency track + flags); **typed
   accessory slots** (slot_type + per-type capacity, campaign base + class override); conferral held|equipped|both;
   benefit tier table; modifier+effect-hook model wiring `until_unequipped`. **Staged build** (define → migrate
   weapons→consumables→accessories). Proficiency/ranks/XP owned by the **Proficiency/XP Framework**
   (`[PXP-1..8]`, `registers/proficiency_xp_framework_open_questions_2026-06-23.md` — campaign-rules rank
   profiles + names, group/bond item tracks, author-defined multi-source gain, on-crossing skill grants;
   revisits GDD_04 WEXP non-breakingly). Pairs w/ (1).
4. **Recruit — green→player (branch F)** — Talk/Recruit action + roster-join UX; **includes Capture** as
   a recruit mechanism. (D-D prerequisite.)
5. **Support system (branch H2)** — ranks/affinity/conversations/combat bonuses. Large.
6. **Rescue system (branch H3)** — carry/drop, weight/CON, secondary-movement interaction; Pair-Up/Rescue exclusivity prior.
7. **PvP / scenario mode** — standalone non-campaign match (reuses the preserved standings renderer).
   **DESIGN RESOLVED 2026-06-27d → `[PVP-1..8]`** (a bring-your-own-army **PvP campaign**: hub + map
   selector + freeform buy phase reusing the prep panels on an author budget; best-of-N; social-contract
   trust per ratified D18; build-dep = training-hall #19 + M15 hotseat). Scopes the deferred D20(b).
8. **Dancer / refresh** (Tier 1) — a unit action that grants an ally another action; M10 Extra-Turn is the
   activation substrate, the Dance *action/unit* is the new design.
9. **Secondary Movement** (Tier 1) — move-again-after-action; interacts with Rescue (6). **FIRMED
   2026-06-24a `[SMV-1..11]` (= foundation F10):** a parameterized **skill**
   (`effect_id="secondary_movement"`, `movement_mode remaining|flat`, author `secondary_move_actions`)
   granted via the skill-grant mechanisms (mounted classes carry it by default; Knight Ring grants
   it). Build pending.
10. **Utility staves** (Tier 1) — Warp / Rescue / Hammerne (+ the M8 Restore/offensive staves); teleport/repair utility.
11. **Village / house visit** (Tier 1) — visit-tile → item/gold/recruit, **enemy can raze it** (time
    pressure); composes over Map Events `[MET]` + doors `[DCH]` but is its own visit action + razable pattern.
12. **Difficulty modes + Casual/Phoenix permadeath variants** (Tier 1) — player-facing mode selection +
    Casual (dead units return after chapter) / Phoenix (revive next turn); rides `CampaignRules` + `[AIP-11]` bands.
13. **Skirmish encounters** (per 3a) — author-gated prep option; auto/random-leveled rosters.

**DISCUSS & PLAN — in v1 consideration, design discussion before commit:**
14. **Arena** — risk gold/EXP for combat (grind/gamble); a prep-hub option; ties economy (2) + bonus-EXP (18).
15. **Combat arts / weapon arts** — spend durability/charge for a special attack (Three Houses–style).
16. **Battalions / gambits** (± adjutants) — attached unit granting bonuses + an AoE gambit; pair-up-adjacent.
17. **Movement assists** — reposition / shove / swap / pivot (ally-positioning actions).
18. **Bonus-EXP award** — award banked EXP to chosen units (Tellius/3H); ties skirmish/economy/training.
19. **Training halls (NEW — owner 2026-06-23h)** — a prep-hub option where a character **spends
    resources** to obtain **NON-TRANSFERABLE** per-character benefits: **class XP · weapon XP · stat
    bonuses · skills · other effects**. A character-investment sink (distinct from convoy/items, which are
    transferable). **Proficiency-XP slice FIRMED 2026-06-23l `[PXP-9]`**: a PHB option panel granting
    authored `{track, xp_amount, resource cost}` into the unified `proficiency_xp` store (on-crossing
    skill grants fire; shares `advance_proficiency` with the Arms Scroll item). Still open for the
    *other* benefit types (class XP / stat / skill purchase), resource type, caps, gating. Relates to
    bonus-EXP (18), arena (14), shop/economy (2). **NOW ON THE PRE-F1 LIST (owner 2026-06-27d) → must be
    designed in the define-all sweep before the F1 lock:** it is the `[PVP-3]` buy-phase dependency AND
    adds persistent per-character state (purchased stat bonuses / skills / class-XP) the F1 schema must
    reserve. Atlas A5 sweep bullet.

**INVESTIGATE feasibility:**
20. **Avatar / "My Unit"** (owner: "look into the possibility") — player-created unit (name / class /
    stats / portrait). Feasibility Qs: does the roster/`UnitData` model support an author-less,
    player-built unit; reuse of existing reclass/level systems; save-vs-campaign binding; story role
    (avatar-as-lord?). **Action: a feasibility dive, then decide in/out.**

**LIGHTER — ride build milestones (no standalone firming):**
21. Skill content per-skill UX (M9b) + status-condition UX check-backs (M8).
22. **Candidate systems (NEW — owner 2026-06-23l, exploration)** — initial designs + feasibility/scope
    drafted in `design/candidate_systems_2026-06-23.md`; player-interaction questions OPEN in
    `[CEX-1..16]` (`registers/candidate_systems_open_questions_2026-06-23.md`). Five: **(A)** shared
    resource pools (stamina/mana/HP costs) · **(B)** Three Houses-style learned spells (no inventory
    slot; per-map uses or pool) · **(C)** author-flexible weapon triangle (custom hierarchy + stat/
    condition effects) · **(D)** per-map-use items (recharging consumables) · **(E)** story/plot-item
    tracking. Each reuses existing machinery; firming order = the **pending priority re-eval**. Shared
    deps surfaced: `ConditionManager` (stub) trending foundational; A underpins B; E's branching needs
    a campaign-flag/story-state store (not built).
23. **Side-content minigames (INVESTIGATE feasibility — owner 2026-06-27d, "look into")** — optional
    diversions such as a **casino** (gold gambling), **fishing**, a **multi-battle garden/arena variant**,
    and similar. **Most would be `[PHB]` prep-panel activities** (siblings of shop/arena/training-hall)
    and therefore **also on-map-placeable via the `[SAC]`/`[VIL-2]` dual-surface** (a casino tile, a
    fishing spot). Reuse-leaning: gambling rides the gold ledger (`[SHP]`/`[CNV]`); a multi-battle garden
    reuses `[BEA]` arena combat; rewards ride the EXP/economy. **Action: a feasibility/scope dive per
    minigame, then decide in/out** — none designed or scheduled. Pinned in the `[PHB]` panel-set note.

### 3c. Deferred / out of v1 (from the genre scan, not chosen)
2nd-gen children units (Awakening) · fatigue (Thracia) · biorhythm (Tellius) · durability-free weapons
(Fates) · Triangle Attack. (Revisit post-v1 if wanted.)

## 4. Sequencing (owner, 2026-06-23) + how this feeds the builder
1. **Firm the §3 v1 worklist** (this pass) — so the full player-facing surface is defined. **The
   prep-as-hub decision (§3a) is foundational** — many FIRM/DISCUSS items (shop, arena, training hall,
   recruit, skirmish) hang off it as author-gated prep option panels, so firm the hub framing early.
   DISCUSS-and-plan items (14–19) need a design conversation before their behavior is firmed;
   INVESTIGATE (20, avatar) needs a feasibility dive before it's in or out.
2. **Then** the **campaign-builder authority pass** (the deferred 4a–4e authoring contract in
   `campaign_save_expectations_and_foundations_2026-06-23.md` §4): for each firmed feature, decide what
   a campaign author may **include / configure / exclude / mandate** — incl. **which prep option panels a
   node exposes** (§3a). This map's feature list becomes that pass's checklist.
3. **Then** implementation (rides §2 + Package A execution).

**Not gated by Package A** (that gates §2 *execution*). DoD: firming docs are planning artifacts; each
cluster's GDD chapter + `GDD_Feature_Index` row update + roadmap status flip land **with its build**, not
during firming (the firming output is a player-facing design doc + a decisions register, per the §2 pattern).
