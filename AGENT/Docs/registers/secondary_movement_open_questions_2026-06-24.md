---
Type: register
Status: RESOLVED 2026-06-24
Last verified: 2026-06-24
Register: SMV-1..11
Resolved-in: 2026-06-24a
---

# Secondary Movement (Move-After-Acting) — Player-Facing Design + Open Questions

**Started:** 2026-06-24 (session 2026-06-24a)
**Status:** RESOLVED 2026-06-24a. Firms **foundation F10** — *Secondary Movement*, the
move-after-acting mechanic that gates **Rescue (#6)** and the **Knight Ring** (`[IEQ]`). The owner's
keystone call: Secondary Movement is **not** a bespoke engine — it is a **parameterized skill**
granted through the **existing skill-grant mechanisms** (`[SKL-4]` grant/revoke,
`ClassData.skill_unlocks`, `[IEQ]` accessory effect_ids, F6 story grants, `[PXP-4]` on-crossing). The
only net-new engine piece is the **action-flow hook** that opens a remainder-move window after a
qualifying action. **Pattern:** mirrors `[IEQ]`/`[PXP]`/`[SKL]`. Legend: **[OPEN]** / **[RESOLVED]**.

> **Naming.** The player-facing term is **Secondary Movement** (descriptive for new players). A
> separate ally-refresh skill (Bard/Heron grant-an-ally-a-turn) is named **Reinvigorate** — the two
> are unrelated mechanics. (Full rename history is in session note 2026-06-24a.)

---

## 1. State today (code- + doc-grounded)
- **Not implemented.** GDD_02 §Known gaps lists "Secondary Movement / post-action remainder
  movement … a design target, **not** implemented." No `secondary_movement` skill id exists in
  `scripts/` or any `.tres` (grep clean).
- **Action flow** (`scripts/core/MapCursor.gd`): `unit_selected → UNIT_MOVED` (ActionMenu open)
  `→ action (attack/staff/item/wait) → DONE`. Secondary Movement inserts a **second movement window
  between the action and DONE**, terminating in Wait.
- **`SkillData`** (`scripts/resources/SkillData.gd`) already carries everything this needs:
  `trigger`, `effect_id`, **`effect_params: Dictionary`**, `max_uses_per_map/combat`,
  `is_player_activated`. No new resource type required.
- **GDD_10 M10** had drafted the remainder as an **automatic property of all mounted classes**
  (built on `grant_extra_turn(unit, {can_move:true, can_act:false, is_self:true})`) — **superseded
  here** by the skill-based model (SMV-4). M10 is an unbuilt milestone, so the supersede is docs-only.

## 2. What this pass produced
The skill-shaped definition (SMV-1..3), how it is conferred (SMV-4), the engine action-flow hook +
re-act rule (SMV-5/6), and the remaining detail/deferral set (SMV-7..11).

---

## 3. Resolved decisions

### [SMV-1] Secondary Movement = a parameterized skill — **RESOLVED**
Secondary Movement is an ordinary `SkillData` with **`effect_id = "secondary_movement"`** and a
**passive** `trigger` (the engine *queries* the holder's active skills at action-resolution; it is
not a dispatched trigger). All behavior is carried in **`effect_params`** (SMV-2/3). No new resource,
no new trigger string — reuses the skill load/aggregate/persist stack wholesale.

### [SMV-2] Movement model = a skill parameter — **RESOLVED**
`effect_params.movement_mode ∈ { "remaining", "flat" }`:
- **`"remaining"`** — budget = `move_stat − path_cost_spent_to_reach_the_action_tile` (terrain costs
  respected; acting from the start tile = full move). See SMV-7.
- **`"flat"`** — budget = `effect_params.flat_amount` (an author-set fixed number of tiles,
  independent of move already used).

One skill kind, two behaviors selected per-skill — so an author can ship "full remainder" cavalry
movement **and** a "move 2 after acting" minor variant from the same mechanism.

### [SMV-3] Trigger set = author-configurable — **RESOLVED**
`effect_params.secondary_move_actions: Array[String]` lists which **turn-ending action types** open
the window (e.g. `attack`, `staff`, `item`, `trade`, `shove`, `rescue`, `drop`). **Default**
(empty/unset) = **all turn-ending actions**. **Wait** never grants Secondary Movement (SMV-6). The
engine opens the window only if the just-performed action type ∈ `secondary_move_actions`.

### [SMV-4] Conferral = the existing skill-grant mechanisms — **RESOLVED**
Secondary Movement skills are granted through paths already firmed — **no mechanic-specific grant
code**:
- **`ClassData.skill_unlocks`** — mounted/flying classes carry the skill **by default** (author
  choice per class), realizing classic "mounted moves after acting" *without* hardwiring it to the
  movement type. Non-mounted classes can carry it too.
- **`[SKL-4]` grant/revoke API** — story events (F6/`[MET]`), shops, skill-grants-skill,
  `[PXP-4]` on-crossing — any of these can grant/revoke the skill (Granted category).
- **`[IEQ]` accessory effect_ids** — **Knight Ring** = an accessory whose effect_id grants a
  Secondary Movement skill to a non-mounted holder (the IEQ §2f checklist's move-after-action item,
  resolved here via skill-grant, not a bespoke movement flag).
**Supersedes** GDD_10 M10's "automatic for all mounted classes" subsection.

### [SMV-5] Action-flow hook (the one new engine piece) — **RESOLVED (design); build pending**
After a turn-ending action resolves and **before** the unit is marked `DONE`, the action flow:
1. Looks up whether the unit has an **active Secondary Movement skill** whose
   `secondary_move_actions` includes the just-performed action type (helper, e.g.
   `Unit.get_active_secondary_movement()`).
2. If so, opens a **remainder-move window** — reuse the existing movement-range computation with the
   budget (SMV-2) and the unit's current tile as origin — as a **new MapCursor state**
   (e.g. `UNIT_SECONDARY_MOVE`) between action-resolution and `DONE`.
3. The window terminates in **Wait only** (no ActionMenu, no second action — SMV-6). Choosing to
   move 0 tiles = Wait in place.
Implements over the existing `grant_extra_turn(unit, {can_move:true, can_act:false, is_self:true})`
substrate already drafted in GDD_10 M10 (which re-enters the **active controller** per M14 stage 5 —
AI/hotseat/cursor, not hardcoded MapCursor).

### [SMV-6] Re-act rule = Wait only — **RESOLVED**
The window **cannot open a second action** (no attack/staff/item after moving); it ends the unit's
turn in Wait. Standard for the mechanic; prevents move→act→move→act loops.

### [SMV-7] "Remaining" computation — **RESOLVED**
`"remaining"` budget = `move_stat − tiles_spent_reaching_the_action_tile` (the path cost actually
paid, terrain-weighted). Acting from the start tile (0 spent) ⇒ full `move`. The remainder window
respects normal movement-cost rules and impassable/ZoC constraints (whatever the base movement
range already enforces).

### [SMV-8] Rescue / carry interaction — **RESOLVED: defer to the Rescue (#6) firming**
Move-after-rescue, CON/weight penalties applied to the budget, and Pair-Up/Rescue exclusivity are
**owned by the downstream Rescue firming** (#6 explicitly depends on F10). This register fixes only
that **`rescue`/`drop` are eligible `secondary_move_actions`**; the weight-penalty math and carry
interactions are firmed there. *(Cross-ref OPEN in the Rescue firming.)*

### [SMV-9] Undo / cancel semantics — **RESOLVED**
Once the action is committed it **cannot be undone** (undo is only available before acting). The
window itself is **optional**: the player may move 0 (Wait in place). There is no "cancel the whole
turn" from inside the window.

### [SMV-10] AI Secondary Movement — **RESOLVED (in principle); detail at AI build**
`EnemyAI` queries the **same** `get_active_secondary_movement()` capability and should use the
remainder window to reposition (e.g. hit-and-retreat). The behavior heuristic is detailed when the
AI work picks this up; no separate data is needed.

### [SMV-11] Save reservation — **RESOLVED: none new**
Secondary Movement holds **no per-turn persistent state** beyond the skill grant itself, which the
skill stores (`skills`/`earned_skills`/Granted via `[SKL-5]`) already persist. **No new F1 save
field.** (Note for the F1 schema-lock: confirm Granted-category persistence covers item/story-granted
Secondary Movement skills.)

---

## 4. Build hand-off (when scheduled)
- **GDD owners at build:** GDD_05 (the `secondary_movement` effect_id) · GDD_02 (the
  `UNIT_SECONDARY_MOVE` action-flow state + remainder window) · GDD_03 (mounted classes' default
  unlock) · GDD_10 M10 (reconcile the Extra-Turn milestone: skill-based supersede).
- **Reuses, doesn't add:** `SkillData` (params), the skill load/aggregate/persist stack,
  `grant_extra_turn` + the M14-stage-5 controller re-entry, the base movement-range computation.
- **Net-new code:** the `effect_id="secondary_movement"` resolution,
  `Unit.get_active_secondary_movement()`, the `UNIT_SECONDARY_MOVE` MapCursor state + remainder
  window, and default unlocks on mounted `ClassData`.
- **DoD#1/#2 apply at build**, not at this firming (no behavior changed yet).

## 5. Reconcile-don't-relitigate
- **Supersede** GDD_10 M10 "Mounted-unit movement remainder" (automatic) → skill-based (SMV-4).
- Knight Ring (`[IEQ]` §2f) = an accessory effect_id that **grants a Secondary Movement skill**
  (SMV-4), not a bespoke movement flag — this resolves the IEQ §2f "move-after-action model gap" for
  the accessory side.
- Rescue weight/move interaction is **Rescue's** to firm (SMV-8), not relitigated here.
