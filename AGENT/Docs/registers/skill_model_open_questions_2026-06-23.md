---
Role: dated
Type: register
Status: RESOLVED 2026-06-23
Last verified: 2026-06-23
Register: SKL-1..6
Resolved-in: 2026-06-23l
---

# Skill Model Expansion — Personal / Class-Level / Granted Skills — Player-Facing Design

**Started:** 2026-06-23 (session 2026-06-23l)
**Status:** RESOLVED 2026-06-23l. Expands the skill system (GDD_05 owner) with **personal skills**,
**class-level-gated** skills, and a **dynamic grant/revoke** system driven by triggers. Connects to
F6 (story flags), shops (`[SHP]`), items (`[IEQ]` consumables), and `[PXP-4]` (on-crossing grant).
**Pattern:** mirrors `[IEQ]`/`[PXP]`. Legend: **[OPEN]** / **[RESOLVED]**.

---

## 1. State today (code-grounded)
- **`UnitData.skills`** — equippable, capped by `CampaignRules.max_skills` (player-managed).
- **`UnitData.earned_skills`** — every skill learned; `skills` is the equipped subset (prep swaps from it).
- **`UnitData.mastery_skills`** — earned, always-on, **no slot cost**, not removable (e.g. `s_rank_mastery`).
  Runtime/snapshot only (**not `@export`**). Aggregated as active by `SkillHandler` + `StatContributions`.
- **`ClassData.skill_unlocks: Dictionary`** — `level → skill_id` (one skill/level), granted at level-up
  (LevelUpScreen announces; PromotionScreen + UnitDetailsScreen display).

## 2. What this pass produced
The skill **category model** (what counts against the cap, what shows where), the class-skill
flags, and the dynamic grant/revoke API + its trigger sources.

---

## 3. Resolved decisions

### [SKL-1] Category model — **RESOLVED: equippable vs own-category (universal rule)**
**Universal rule:** a skill the player **can't unequip via the standard menu** lives in its **own
character-sheet category** and **does NOT count against `max_skills`**. The cap applies **only** to
player-managed **equipped** skills (`skills`, drawn from `earned_skills`).
Categories (each its own sheet section — `[SKL-3 layout]`): **Equipped** (capped) · **Personal** ·
**Class** (always-active variant) · **Mastery** · **Granted**.

### [SKL-2] Personal skills — **RESOLVED: authored, always-on, own slot**
New `UnitData.personal_skills: Array[String]` — authored per-unit, **always active**, own sheet
slot, **no cap cost**, **not** removable via the standard menu (changeable only by an explicit
grant/revoke trigger, SKL-4). A unit may have ≥1. Aggregated as active by `SkillHandler`.

### [SKL-3] Class skills — **RESOLVED: two author flags on each unlock**
Extend `ClassData.skill_unlocks`: value becomes a **list of entries** keyed by class level, each
`{ skill_id, retain_on_reclass: bool, requires_equip: bool }`:
- **`requires_equip = true`** → on unlock the skill enters `earned_skills` (player slots it; **counts**
  against the cap, like a normal earned skill).
- **`requires_equip = false`** → active in the **Class** sheet section while the unit qualifies; **no
  cap cost**.
- **`retain_on_reclass = true`** → kept after leaving the class (permanent, Awakening-style).
- **`retain_on_reclass = false`** → **class-innate** (Fates/3H-style): active only while in that class
  at/above the unlock level; lost on reclass.
- **Available class skills** = the current class's unlocks at/below the current class level.

### [SKL-4] Dynamic grant/revoke API + trigger sources — **RESOLVED**
A general **`grant_skill(unit, skill_id, category, duration)`** / **`revoke_skill(unit, skill_id)`**
on `SkillHandler` (or Unit). Trigger-granted skills land in the **Granted** category (own section,
no cap); a grant is **permanent OR duration-bound** (reuses the modifier duration vocabulary —
`x_turns` / `this_map` / until explicit revoke). Revoke is explicit or on expiry. **Trigger sources:**
- **Story events** → `[MET]` event action, reading/writing the **F6** campaign-flag store.
- **Shops** → a skill-purchase surface (`[SHP]`/`[PHB]` panel) → permanent grant.
- **Item use** → consumable effect_id **`grant_skill`** / **`revoke_skill`** (`[IEQ]`/ItemHandler).
- **Skill effect** → a `SkillData` effect_id `grant_skill`/`revoke_skill` on a trigger
  (e.g. `on_combat_end`, `on_kill`) — a skill that grants/removes a skill.
- **Attack effect** → `on_hit`/`on_kill` grant/revoke (e.g. inflict or steal a skill).
- **`[PXP-4]`** on-rank-crossing grant — already firmed; lands as a permanent grant/mastery.

### [SKL-5] Save / schema — **RESOLVED: reserve in §2 (F1)**
`personal_skills` (authored but revocable → persist) and `granted_skills` (dynamic, with durations →
persist across maps) are **campaign-save state** — reserve in the §2 schema (F1 lock). Class-skill
availability is **derived** (current class + level), not stored; must-equip class skills already
persist via `earned_skills`. **Note:** `mastery_skills` is currently snapshot-only (not `@export`) —
cross-map-persistent granted/personal skills need **real save persistence**, not just the snapshot.

### [SKL-6] GDD / code reconcile — **RESOLVED: lands with the build (DoD)**
`SkillHandler` active-skill aggregation extends to personal + class-active + granted; UnitDetailsScreen
gains the per-category sections; `ClassData.skill_unlocks` schema changes (value → entry list);
update GDD_05 (skills) + GDD_03 (class skills) + GDD_01 (UnitData/ClassData schema) + flip
`GDD_10_Roadmap`, same commit; add tests.

## 4. Notes
- **The grant/revoke API is shared infrastructure** (story/shops/items/skills/attacks/PXP all call it)
  → tracked as foundation **F12** in the atlas.
- **Reuses, doesn't reinvent:** mastery already proves "always-on, no-cap, aggregated"; this
  generalizes it into named categories + adds **revocation** + the new sources.
- **DoD:** GDD chapters + `GDD_Feature_Index` row + roadmap flip land **with the build**, not now.
