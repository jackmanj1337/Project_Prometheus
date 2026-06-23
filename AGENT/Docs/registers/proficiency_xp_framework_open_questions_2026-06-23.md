---
Type: register
Status: RESOLVED 2026-06-23
Last verified: 2026-06-23
Register: PXP-1..8
Resolved-in: 2026-06-23l
---

# Proficiency / XP Framework (weapons + items) — Player-Facing Design + Open Questions

**Started:** 2026-06-23
**Status:** RESOLVED 2026-06-23l. A unified XP/rank framework spanning **weapons AND items**,
firmed alongside the items/equipment composition model. Realizes the item-proficiency track
that `[IEQ-3]` referenced and resolves the gain-source `[IEQ-3]` deferred.
**Source:** owner expansion during the `[IEQ]` review (2026-06-23l) — generalize XP/rank from
per-weapon-use into an author-configurable framework with group + bonded item tracks.
**Intentionally revisits firmed weapon WEXP** (GDD_04 SET-004 thresholds, RULE-004 gain
timing, the hardcoded S-rank→`s_rank_mastery`) — kept **non-breaking via a default profile**.
**Pattern:** mirrors `[IEQ]`. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

---

## 1. State today (code-grounded — verified 2026-06-23l)
- **Storage:** `UnitData.weapon_wexp: Dictionary`, `@export`, keyed by the fixed
  `GameConstants.VALID_WEXP_TRACKS` (sword/lance/axe/bow/elemental_magic/light/dark/staff/
  beaststone/dragonstone). Numeric totals only.
- **Ranks derived, not stored:** `GameConstants.WEXP_RANK_THRESHOLDS` = E0/D100/C200/B300/A400/S500;
  rank letters E–S are hardcoded constants.
- **Gain:** `Unit.add_wexp(track, amount)` on **valid weapon use** (`Unit.gd:481`);
  `amount × SkillHandler.get_wexp_multiplier` (discipline), clamped to the **class cap**
  (`ClassData.get_weapon_wexp_cap`). Crossing into S **hardcodes** appending `s_rank_mastery`.
- **CampaignRules:** `CampaignRules.gd` exists (per-save rule bundle, `make_default()`) — the
  home for author-configurable profiles. `Unit.add_exp(amount)` (`Unit.gd:610`) is the **single**
  class-EXP entry point. Action vocab: `ActionMenu` (attack/staff/item/wait/trade) + `TileActions`
  (seize/escape/shop/visit/activate).

## 2. What this pass produced
The unified track model, campaign-rules rank profiles + names, on-crossing event hooks, and
the author-defined multi-source XP-gain model — for weapons and items alike.

---

## 3. Resolved decisions

### [PXP-1] Storage — **RESOLVED: one unified store**
A single **`UnitData.proficiency_xp: Dictionary`** keyed by **track-id**; `weapon_wexp` migrates
in (staged). One gain/threshold code path, one save field, one config surface. Track-ids namespace
the three kinds (PXP-2).

### [PXP-2] Track identity — **RESOLVED: three kinds, item declares its track(s)**
- **weapon-family** (existing: `sword`, `lance`, … — unchanged ids).
- **item-group** (new, author-defined: e.g. `shield` → "skill with shields"). Shared by all
  items declaring that group.
- **item-bond** (new, specific item: keyed off its def, e.g. `bond:<def_id>` → "bond with a relic").
An item component declares its `proficiency_tracks` — a group id and/or its self-bond; an item
may feed **both** a group and a bond at once.

### [PXP-3] Rank profiles = campaign rules — **RESOLVED: named per-track profiles**
`CampaignRules` holds **named rank profiles**, each = an ordered list of `{name, threshold}`
(both the **threshold values AND the rank names** are authored). Each **track references a profile**
by name. The **default profile** reproduces today's E0/D100/C200/B300/A400/S500 (non-breaking).
A campaign may add custom profiles (e.g. relics use a "Bond I–V" profile while swords use E–S).
Replaces the hardcoded `WEXP_RANK_THRESHOLDS` + rank-letter literals; `weapon_rank_for_wexp` /
`minimum_wexp_for_rank` read the resolved profile instead of the constant.

### [PXP-4] On-crossing events — **RESOLVED: per-threshold triggers**
A profile (or track) declares **on-crossing triggers**: crossing into rank R fires an event.
v1 event vocab: **`grant_skill`** (appends to earned/mastery skills, reusing the existing grant
path) — extensible later (stat unlock, flag set, etc.). The hardcoded **S→`s_rank_mastery`**
becomes a `grant_skill` trigger on the **default profile's** S threshold (behavior preserved,
no longer special-cased in `add_wexp`).

### [PXP-5] Gain sources — **RESOLVED: author-defined combination, track-default + per-item override**
A **track** defines default gain-sources + amounts; an **item** may override. Each source carries
an author amount. The four sources (opt into any subset):
- **`active_use`** — per valid use of the item's active capability (weapon attack, staff use,
  consumable use, accessory activation). Today's weapon model, generalized. Hook: existing use path.
- **`class_exp_share`** — XP awarded to the held/equipped item's track(s) **when the unit gains
  class EXP**. Hook: `Unit.add_exp` enumerates the unit's qualifying item tracks. Amount = a flat
  value or a fraction of the class-EXP gained (author knob).
- **`per_map_carry`** — held/equipped for the **whole map** → granted on map completion. Hook:
  map-completion (TurnManager), enumerate tracks carried start-to-finish.
- **`action_gated`** — held/equipped while taking **specified actions** (author lists which, from
  the ActionMenu/TileActions vocab). Hook: action execution awards per qualifying action.
Defaults preserve weapon behavior: weapon tracks default to **`active_use`** only.

### [PXP-6] Caps — **RESOLVED (by rec): profile ceiling + preserved weapon class caps**
A track's rank ceiling = its profile's top threshold. **Weapon class caps** (`ClassData`
per-track caps, e.g. cap at A) are **preserved** as an existing override (reconcile-don't-break).
Item tracks default uncapped-to-profile-ceiling; an optional per-track/class cap is later growth.
_(Owner may revisit item-track caps.)_

### [PXP-7] Reconciliation / migration / GDD — **RESOLVED: lands with the staged build (DoD)**
- Default `CampaignRules` profile reproduces current values so existing `.tres`/saves behave
  identically; `LEGACY_WEXP_TRACKS` (fire/thunder/wind→elemental_magic) migration preserved.
- Revisits GDD_04 (SET-004 thresholds → default profile; RULE-004 gain → `active_use` default;
  `s_rank_mastery` hardcode → default-profile `grant_skill` trigger) and GDD_03 (class caps) —
  update those sections + flip `GDD_10_Roadmap` **with the build** (DoD#1), and land the
  CampaignRules-profile check in `check_docs.py`/validators (DoD#2).

### [PXP-8] Save / schema — **RESOLVED: reserve in §2**
`UnitData.proficiency_xp` replaces `weapon_wexp` in the save schema; `CampaignRules` gains the
rank profiles + gain-source config (per-save). Reserve both now, fill on build.

## 4. Notes
- **Connection to `[IEQ]`:** IEQ-3 legality reads ranks from this framework (accessory =
  item-group/bond track + `req_flags`); IEQ-3's "gain source deferred" is now resolved here;
  IEQ-5 effect grants + PXP-4 `grant_skill` both reuse the skill system.
- **Staged build:** profiles + unified store first (default profile = current behavior), then
  migrate weapon gain to the source model, then item tracks/groups/bonds. Protects healthy
  weapon code (~15 weapon call sites + `add_wexp`/`get_active_wexp`).
- **Reconcile-don't-relitigate elsewhere:** weapon triangle/families (GDD_04), `break_behavior`
  (`[BWN]`). The S-rank **bonus** (SET-005, +10Hit/+5Crit/+1Dmg) is combat-application (GDD_02),
  separate from the S-rank **mastery skill grant** generalized here.
- **DoD:** GDD_03/04 + `GDD_Feature_Index` + roadmap flip land **with the build**, not now.
