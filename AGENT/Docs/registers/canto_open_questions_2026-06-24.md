---
Type: register
Status: RESOLVED 2026-06-24
Last verified: 2026-06-24
Register: CAN-1..11
Resolved-in: 2026-06-24a
---

# Canto (Move-After-Acting) — Player-Facing Design + Open Questions

**Started:** 2026-06-24 (session 2026-06-24a)
**Status:** RESOLVED 2026-06-24a. Firms **foundation F10** — *canto*, the move-after-acting
("movement remainder") mechanic that gates **Rescue (#6)** and the **Knight Ring** (`[IEQ]`). The
owner's keystone call: canto is **not** a bespoke engine — it is a **parameterized skill** granted
through the **existing skill-grant mechanisms** (`[SKL-4]` grant/revoke, `ClassData.skill_unlocks`,
`[IEQ]` accessory effect_ids, F6 story grants, `[PXP-4]` on-crossing). The only net-new engine piece
is the **action-flow hook** that opens a remainder-move window after a canto-triggering action.
**Pattern:** mirrors `[IEQ]`/`[PXP]`/`[SKL]`. Legend: **[OPEN]** / **[RESOLVED]**.

> **Naming.** Across the repo (scope-map #9, atlas F10, GDD_02 "post-action remainder movement",
> GDD_03 mounted row) **"Canto" = move-after-acting** — the FE-canonical meaning, firmed here.
> GDD_10 M10's earlier "Canto skill" (an *ally-refresh*: Bard/Heron grant-an-ally-a-turn) is the
> **misnomer**; this firming **renames** it to **Reinvigorate** (a refresh-family skill; the musical
> connotation is dropped from the code; promos Resonance/Battle Cry/Reverberate unchanged) so "Canto"
> is reserved for the remainder mechanic.

---

## 1. State today (code- + doc-grounded)
- **Not implemented.** GDD_02 §Known gaps lists "Canto / post-action remainder movement … a design
  target, **not** implemented." No `canto` skill id exists in `scripts/` or any `.tres` (grep clean).
- **Action flow** (`scripts/core/MapCursor.gd`): `unit_selected → UNIT_MOVED` (ActionMenu open)
  `→ action (attack/staff/item/wait) → DONE`. Canto inserts a **second movement window between the
  action and DONE**, terminating in Wait.
- **`SkillData`** (`scripts/resources/SkillData.gd`) already carries everything canto needs:
  `trigger`, `effect_id`, **`effect_params: Dictionary`**, `max_uses_per_map/combat`,
  `is_player_activated`. No new resource type required.
- **GDD_10 M10** had drafted the remainder as an **automatic property of all mounted classes**
  (built on `grant_extra_turn(unit, {can_move:true, can_act:false, is_self:true})`) — **superseded
  here** by the skill-based model (CAN-4). M10 is an unbuilt milestone, so the supersede is docs-only.

## 2. What this pass produced
The skill-shaped definition of canto (CAN-1..3), how it is conferred (CAN-4), the engine
action-flow hook + re-act rule (CAN-5/6), and the remaining detail/deferral set (CAN-7..11).

---

## 3. Resolved decisions

### [CAN-1] Canto = a parameterized skill — **RESOLVED**
Canto is an ordinary `SkillData` with **`effect_id = "canto"`** and a **passive** `trigger`
(the engine *queries* the holder's active skills at action-resolution; it is not a dispatched
trigger). All canto behavior is carried in **`effect_params`** (CAN-2/3). No new resource, no new
trigger string — reuses the skill load/aggregate/persist stack wholesale.

### [CAN-2] Movement model = a skill parameter — **RESOLVED**
`effect_params.movement_mode ∈ { "remaining", "flat" }`:
- **`"remaining"`** — budget = `move_stat − path_cost_spent_to_reach_the_action_tile` (classic FE;
  terrain costs respected; acting from the start tile = full move). See CAN-7.
- **`"flat"`** — budget = `effect_params.flat_amount` (an author-set fixed number of tiles,
  independent of move already used).

One skill kind, two behaviors selected per-skill — so an author can ship "full remainder" cavalry
canto **and** a "move 2 after acting" minor canto from the same mechanism.

### [CAN-3] Trigger set = author-configurable — **RESOLVED**
`effect_params.canto_actions: Array[String]` lists which **turn-ending action types** open the
canto window (e.g. `attack`, `staff`, `item`, `trade`, `shove`, `rescue`, `drop`). **Default**
(empty/unset) = **all turn-ending actions**. **Wait** never grants canto (CAN-6). The engine opens
the window only if the just-performed action type ∈ `canto_actions`.

### [CAN-4] Conferral = the existing skill-grant mechanisms — **RESOLVED**
Canto skills are granted through paths already firmed — **no canto-specific grant code**:
- **`ClassData.skill_unlocks`** — mounted/flying classes carry a canto skill **by default** (author
  choice per class), realizing classic "mounted = canto" *without* hardwiring it to the movement
  type. Non-mounted classes can carry it too.
- **`[SKL-4]` grant/revoke API** — story events (F6/`[MET]`), shops, skill-grants-skill,
  `[PXP-4]` on-crossing — any of these can grant/revoke a canto skill (Granted category).
- **`[IEQ]` accessory effect_ids** — **Knight Ring** = an accessory whose effect_id grants a canto
  skill to a non-mounted holder (the IEQ §2f checklist's canto item, resolved here via skill-grant,
  not a bespoke movement flag).
**Supersedes** GDD_10 M10's "automatic for all mounted classes" subsection.

### [CAN-5] Action-flow hook (the one new engine piece) — **RESOLVED (design); build pending**
After a turn-ending action resolves and **before** the unit is marked `DONE`, the action flow:
1. Looks up whether the unit has an **active canto skill** whose `canto_actions` includes the
   just-performed action type (helper, e.g. `Unit.get_active_canto()`).
2. If so, opens a **remainder-move window** — reuse the existing movement-range computation with the
   canto budget (CAN-2) and the unit's current tile as origin — as a **new MapCursor state**
   (e.g. `UNIT_CANTO`) between action-resolution and `DONE`.
3. The window terminates in **Wait only** (no ActionMenu, no second action — CAN-6). Choosing to
   move 0 tiles = Wait in place.
Implements over the existing `grant_extra_turn(unit, {can_move:true, can_act:false, is_self:true})`
substrate already drafted in GDD_10 M10 (which re-enters the **active controller** per M14 stage 5 —
AI/hotseat/cursor, not hardcoded MapCursor).

### [CAN-6] Re-act rule = Wait only — **RESOLVED**
The canto window **cannot open a second action** (no attack/staff/item after canto-moving); it ends
the unit's turn in Wait. Standard FE; prevents move→act→move→act loops.

### [CAN-7] "Remaining" computation — **RESOLVED**
`"remaining"` budget = `move_stat − tiles_spent_reaching_the_action_tile` (the path cost actually
paid, terrain-weighted). Acting from the start tile (0 spent) ⇒ full `move`. The remainder window
respects normal movement-cost rules and impassable/ZoC constraints (whatever the base movement
range already enforces).

### [CAN-8] Rescue / carry interaction — **RESOLVED: defer to the Rescue (#6) firming**
Canto-after-rescue, CON/weight penalties applied to the canto budget, and Pair-Up/Rescue
exclusivity are **owned by the downstream Rescue firming** (#6 explicitly depends on F10). This
register fixes only that **`rescue`/`drop` are eligible `canto_actions`**; the weight-penalty math
and carry interactions are firmed there. *(Cross-ref OPEN in the Rescue firming.)*

### [CAN-9] Undo / cancel semantics — **RESOLVED**
Once the action is committed it **cannot be undone** (standard FE — undo is only available before
acting). The canto window itself is **optional**: the player may move 0 (Wait in place). There is no
"cancel the whole turn" from inside the canto window.

### [CAN-10] AI canto — **RESOLVED (in principle); detail at AI build**
`EnemyAI` queries the **same** `get_active_canto()` capability and should use the remainder window to
reposition (e.g. hit-and-retreat). The behavior heuristic is detailed when the AI work picks this up;
no separate canto data is needed.

### [CAN-11] Save reservation — **RESOLVED: none new**
Canto holds **no per-turn persistent state** beyond the skill grant itself, which the skill stores
(`skills`/`earned_skills`/Granted via `[SKL-5]`) already persist. **No new F1 save field.** (Note
for the F1 schema-lock: confirm Granted-category persistence covers item/story-granted canto skills.)

---

## 4. Build hand-off (when scheduled)
- **GDD owners at build:** GDD_05 (the `canto` effect_id + the renamed **Reinvigorate** skill) · GDD_02
  (the `UNIT_CANTO` action-flow state + remainder window) · GDD_03 (mounted classes' default canto
  unlock) · GDD_10 M10 (reconcile the Extra-Turn milestone: Sing rename + canto-as-skill supersede).
- **Reuses, doesn't add:** `SkillData` (params), the skill load/aggregate/persist stack,
  `grant_extra_turn` + the M14-stage-5 controller re-entry, the base movement-range computation.
- **Net-new code:** the `effect_id="canto"` resolution, `Unit.get_active_canto()`, the `UNIT_CANTO`
  MapCursor state + remainder window, and default canto unlocks on mounted `ClassData`. (The
  `effect_id="canto"` resolution + Sing→**Reinvigorate** rename are GDD_05/M10 docs work, no built code.)
- **DoD#1/#2 apply at build**, not at this firming (no behavior changed yet).

## 5. Reconcile-don't-relitigate
- **Rename** GDD_10 M10 "Canto skill" (ally-refresh) → **Reinvigorate**; promos unchanged.
- **Supersede** GDD_10 M10 "Mounted-unit movement remainder" (automatic) → canto-as-skill (CAN-4).
- Knight Ring (`[IEQ]` §2f) = an accessory effect_id that **grants a canto skill** (CAN-4), not a
  bespoke movement flag — this resolves the IEQ §2f "canto/M11 model gap" for the accessory side.
- Rescue weight/canto interaction is **Rescue's** to firm (CAN-8), not relitigated here.
- **Live-doc rename done:** GDD_10 M10 (skill + checklists), GDD_05 starting-skill example, GDD_02
  known-gap, GDD_03 mounted row. **Deferred follow-up:** the parked corpus under
  `GDD/Content Expansion/Old_Deferred/` (`homebrew_classes_only.md`, `classes.md`, `skills.md`) still
  uses "Canto" for the ally-refresh — **sweep to Reinvigorate when that content is un-deferred**, not
  now (out of scope for this firming; it is not the live build spec).
