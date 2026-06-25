---
Type: register
Status: RESOLVED 2026-06-25
Last verified: 2026-06-25
Register: AGT-1..13
Resolved-in: 2026-06-25j
---

# Action-Grant (Dancer / Reinvigorate) — Player-Facing Design + Open Questions

**Started:** 2026-06-25 (session 2026-06-25j). Second sub-cluster of **A2 — Map action-economy &
movement assists** (after the displacement primitive `[DSP-1..17]`; the **battalion entity `[STY-11]`**
is the remaining A2 pass). Branch `docs-reorg-2026-06-23`.

**Thesis.** Action-grant — the **Dancer / Reinvigorate** "give an ally another turn" mechanic (#8) — is
the **symmetric twin of F10 Secondary Movement** (`[SMV-1..11]`). Both ride the *same* drafted
`grant_extra_turn(unit, {can_move, can_act, is_self})` substrate; they differ only on three axes:

| axis | F10 Secondary Movement (`[SMV]`) | A2 Action-grant (this register) |
|---|---|---|
| `is_self` | true — re-grants the actor's own remainder | **false** — re-grants an **ally** |
| scope | move-only (`can_act:false`) | **full turn** (`can_act:true`, `[AGT-2]`) |
| trigger | passive (engine queries at action-resolution) | **activated** — a targeted turn action (`[AGT-1]`) |
| conferral | the existing skill-grant mechanisms | *the same* (`[AGT-4]`) |

So almost the whole SMV register transposes: action-grant is **a parameterized, activated skill** over
the same substrate and the same skill load/aggregate/persist stack, with **no bespoke engine subsystem**.

**Code-grounded substrate.** The engine's per-unit action economy is a three-value enum —
`TurnManager.UnitState { READY, MOVED, DONE }` (`scripts/core/TurnManager.gd:20`). A unit that commits
its turn is set `DONE` (`set_unit_state`, which also drives `set_done_appearance` + the auto-end-phase
check). `can_unit_act(unit)` already returns true for **READY or MOVED**, and `_refresh_faction_units`
already re-`READY`s a whole faction at phase start. **An action-grant is therefore just "set a
DONE/MOVED ally back to READY"** — the engine already performs this exact transition every phase; the
net-new work is only the *targeted activated skill* that triggers it for one ally mid-phase.

**Pattern:** mirrors `[SMV]`/`[STY]`/`[DSP]`. Legend: **[OPEN]** / **[RESOLVED]**.

> **Naming.** Player-facing skill name = **Reinvigorate** (the Bard/Heron "grant-an-ally-a-turn"
> ability, already named in `[SMV]`'s naming note). "Dancer" is the archetypal *class* that carries it.
> "Action-grant" is the internal mechanic name. Secondary Movement (`[SMV]`, self/move-only) and
> Reinvigorate (ally/full-turn) are the two faces of one substrate — kept distinct so neither name
> implies the other's behavior.

---

## 1. State today (code- + doc-grounded)
- **Not implemented.** No `reinvigorate`, `grant_action`, `dance`, or `grant_extra_turn` exists in
  `scripts/` or any `.tres` (grep clean — same finding as `[DSP]` §1 and `[SMV]` §1).
- **Action economy** = `TurnManager.UnitState {READY, MOVED, DONE}` + `set_unit_state` /
  `get_unit_state` / `can_unit_act` / `_refresh_faction_units` (`scripts/core/TurnManager.gd`). There is
  **no per-unit "actions taken this turn" counter today** — the enum tracks *state*, not *count*. The
  one author-tool below (`[AGT-7]`) adds that counter as net-new transient state.
- **`SkillData`** (`scripts/resources/SkillData.gd`) already carries `trigger`, `effect_id`,
  **`effect_params: Dictionary`**, `is_player_activated`, `max_uses_per_map/combat` — everything an
  activated, parameterized, targeted, use-capped skill needs. No new resource type.
- **GDD_10 M10** drafted `grant_extra_turn(unit, {can_move, can_act, is_self})` as the Extra-Turn
  substrate; `[SMV-5]` already builds Secondary Movement over it (self branch). This register defines the
  **ally branch** (`is_self:false`) of the *same* call — it does not add a second substrate.
- **A1 axes reused:** `[STY-16]` `target_filter` + `[STY-17]` directed relationship matrix gate who is a
  legal target (`[AGT-3]`); `[STY-10]` effect-forecast preview shows the grant (`[AGT-3]`).

## 2. What this pass produced
The activated/targeted skill shape (AGT-1/2/3), conferral (AGT-4), the caster-cost + refresh transition
(AGT-5/6), the **author-tunable anti-loop & balance levers** (AGT-7, owner call — *tools, not a baked
rule*: caps · rate-limit · resource cost · source scarcity), the composition/deferral set (AGT-8..12),
and **targeting cardinality** — single / multi-target / self (AGT-13). Surfaced **two forward-pins**: a
generic **action-rate-limit primitive** (`§5`) and a **non-combat-action EXP / proficiency path** (`§6`,
→ A5).

---

## 3. Resolved decisions

### [AGT-1] Action-grant = a parameterized, **activated** skill — **RESOLVED**
Reinvigorate is an ordinary `SkillData` with **`effect_id = "grant_action"`**, **`is_player_activated =
true`** (the player selects it from the ActionMenu and targets an ally), and all behavior in
**`effect_params`** (AGT-2/3). It reuses the skill load/aggregate/persist stack wholesale. This is the
mirror of `[SMV-1]` — the only structural difference is *activated + targeted* vs SMV's *passive +
self*. No new resource, no new trigger string.

### [AGT-2] Grant scope = a skill parameter; **default = full turn** — **RESOLVED** (owner call)
`effect_params.grant_mode ∈ { "full" (default), "move_only", "act_only" }`, mapping straight onto the
substrate flags:
- **`"full"`** (default) — `grant_extra_turn(target, {can_move:true, can_act:true, is_self:false})`. The
  classic Dancer/Heron: a complete fresh turn (move **and** action).
- **`"move_only"`** — `{can_move:true, can_act:false}`. Re-grants just a move (a "reposition an ally"
  support variant; the ally's branch of what SMV grants to self).
- **`"act_only"`** — `{can_move:false, can_act:true}`. Re-grants just an action (e.g. let an ally attack
  again without moving).

One mechanism, three behaviors selected per-skill (mirrors `[SMV-2]`'s one-skill-two-modes). **Default is
`full`** so a bare authored action-grant skill behaves like canonical Dance without boilerplate.

### [AGT-3] Target = an ally selection, relationship-gated, ranged-by-param — **RESOLVED**
Action-grant is an **activated targeted** skill, so it reuses A1's targeting axes rather than inventing
selection logic:
- **Legal target set** = units passing `effect_params.target_filter` (`[STY-16]`) **and** the
  `[STY-17]` relationship gate (default: same faction / non-hostile — you refresh allies, not enemies).
- **Range** = `effect_params.range` (default `1` = adjacent, classic Dance; authors may ship ranged
  Reinvigorate). Uses the same range/targeting machinery as other targeted skills.
- **Refresh validity** = the target must be a unit that has **already committed this turn** —
  `get_unit_state(target) != READY` (DONE or MOVED). Refreshing a still-READY ally is wasteful and
  disallowed. This is the note's *"re-granting an already-acted unit"* edge case, and it falls straight
  out of the state enum. (`target != caster` is the **single-target default**; self-targeting is an
  author opt-in — see `[AGT-13]`.)
- **Preview** = the `[STY-10]` effect-forecast panel shows the target and the granted scope; no RNG (the
  grant is deterministic — there is no accuracy stage, unlike `[DSP-13]`).

### [AGT-4] Conferral = the existing skill-grant mechanisms — **RESOLVED**
Identical to `[SMV-4]` — **no mechanic-specific grant code**:
- **`ClassData.skill_unlocks`** — the **Dancer / Bard** class carries Reinvigorate by default (author
  choice per class). Any class may carry it.
- **`[SKL-4]` grant/revoke API** — story (F6/`[MET]`), shops, skill-grants-skill, `[PXP-4]` on-crossing.
- **`[IEQ]` accessory effect_ids** — an accessory may grant a Reinvigorate skill to its holder.

### [AGT-5] Caster cost = a turn-ending action; composes with the caster's own SMV — **RESOLVED**
Casting Reinvigorate **is the caster's turn-ending action** — the dancer is set `DONE` after it resolves
(exactly like attack/staff/item). The economy is therefore **net "spend one to refresh one,"** which is
canon and the first natural brake on chains. Because Dance is a turn-ending action, it is an eligible
`secondary_move_actions` entry (`[SMV-3]`): a dancer who *also* holds Secondary Movement may
**dance-then-reposition**. No special case — the two skills compose through the existing action flow.

### [AGT-6] The refresh transition — **RESOLVED**
The `grant_action` effect calls `grant_extra_turn(target, …)` (AGT-2), which sets the target's
`UnitState` back to **READY** (`full`/`act_only`) or to a move-granted state (`move_only`). The refreshed
unit then re-enters the **active controller** (per M14 stage 5 — cursor/AI/hotseat, not hardcoded
MapCursor), replaying the normal action flow. **Action-economy invariant:** the transition is atomic and
re-grants exactly the authored scope — it never grants more than one pending action at a time.

### [AGT-7] Anti-loop & balance = **author tools, not a baked engine rule** — **RESOLVED** (owner call)
The degenerate case (Dancer A refreshes B, B refreshes A, forever) is **not** prevented by a hardcoded
"a granted turn can't grant" flag. Instead the engine provides a set of **general, author-tunable
levers** (none action-grant-specific); an author composes any subset to set the balance they want (the
famous A↔B loop is closed by *any one* of them):

1. **Per-unit "actions taken this turn" counter + refresh cap.** Net-new transient state: a
   `Unit.actions_taken_this_turn` counter, incremented on each turn-ending commit and **cleared in
   `_refresh_faction_units`** (the existing per-phase reset). An author sets a cap (e.g. via the
   action-grant skill's `effect_params.max_target_actions_per_turn`, or a `CampaignRules` default —
   `[AGT-12]`); a unit **at or over the cap is an invalid action-grant target** (`[AGT-3]` validity adds
   this test). Cap `1` ⇒ a unit may act once normally and be refreshed at most once per turn — the
   common balanced setting.
2. **Generic source-scoped action-rate limits** (`§5` forward-pin). The ability to cap *any* action from
   *any* source **per-phase / per-round / per-map** — a primitive **broader than action-grant** (it also
   serves "once per round" battalion gambits, limited staff uses, etc.). Action-grant is merely one
   consumer: an author caps "Dance" to N per round/phase from a given source. This is **not owned by this
   register** — it is pinned forward to the action/turn-flow foundation (`§5`).
3. **Resource cost on the action-grant skill.** Reinvigorate is an ordinary skill, so it carries the
   normal **multi-resource cost** axis (the `[STY]` composable cost model — uses/charges, an MP-like
   pool, HP, a per-map limited resource, an item charge). An expensive Dance throttles spam
   *economically* rather than by a hard rule: each refresh draws down a finite resource, so the chain
   ends when the resource does. Composes with the caps above. (`max_uses_per_map/combat` on `SkillData`
   is the simplest instance.)
4. **Source scarcity (access control).** The bluntest lever, and free given `[AGT-4]`: because
   action-grant reaches the roster only through the skill-grant paths, the author **controls how many
   units can do it at all** — author *one* Dancer and the total refreshes available per turn are capped
   at that single unit's action budget. No mechanism needed; scarcity of the *source* is itself the
   balance.

This keeps action-grant policy in authors' hands, matches how the displacement arc made every rule a
`CampaignRules` default (`[DSP-17]`), and avoids hardwiring a single anti-loop opinion into the engine.

### [AGT-8] Interaction with F10 Secondary Movement — **RESOLVED: fully composable, no special case**
A refresh simply re-`READY`s the target; the target's normal action flow then replays **including its own
Secondary Movement window** if it holds an SMV skill (`[SMV-5]`). A unit that used its SMV remainder, then
gets refreshed, gets a fresh turn *and* a fresh SMV window — consistent and intended. Nothing in F10
needs to know action-grant exists, and vice-versa.

### [AGT-9] Off-turn / reactive applicability = **on-turn only in v1; reserve a flag** — **RESOLVED** (owner call)
v1: action-grant fires **only on the caster's own active turn** (the caster spends their turn action).
**Reserve** a per-source `off_turn_grant` author flag (default **off**), mirroring `[DSP-12]`'s per-source
off-turn eligibility, for a future reactive "second wind." When that flag is built it inherits
`[DSP-12]`'s **non-interrupt** rule (an off-turn grant never interrupts an in-progress exchange).

### [AGT-10] AI action-grant — **RESOLVED (in principle); heuristic at AI build**
`EnemyAI` queries the **same** activated-skill capability; an enemy Dancer should refresh its most
valuable ally. The behavior heuristic is detailed when the AI work picks this up — no separate data
(mirror `[SMV-10]`).

### [AGT-11] Save / F1 reserve — **RESOLVED: skill grant persists; transient counters need an F1 confirm**
The skill grant itself persists via the existing `skills`/`earned_skills`/Granted paths (`[SKL-5]`) — **no
new persistent field for the skill** (mirror `[SMV-11]`). The net-new state is **transient per-turn**: the
`[AGT-7]`#1 `actions_taken_this_turn` counter (and any `§5` rate-limit counters), all **cleared at faction
refresh**. They need **no save field** *unless* the engine supports **suspend-mid-phase saves**, in which
case those counters must serialize so an anti-loop cap survives a save/reload mid-turn. **Flag for the F1
schema-lock:** confirm whether mid-turn save is in scope; if so, reserve the transient action-economy
counters.

### [AGT-12] Campaign-default + override — **RESOLVED**
Mirrors `[DSP-17]`: the action-grant tunables — `grant_mode` default, the `[AGT-7]`#1 refresh cap, the
`§5` rate-limit defaults — are **`CampaignRules` defaults overridable per source/skill** (resolution =
source/skill → campaign → framework). Authors set one sane default (e.g. "refreshable once per turn")
and let specific spicy skills opt out.

### [AGT-13] Targeting cardinality = single / multi / self — **RESOLVED**
Action-grant must support more than one-ally-at-a-time. Cardinality is **not a new subsystem** — it
reuses A1's targeting axes (the same the attack/effect pipeline already firmed), selected per-skill in
`effect_params`:
- **Single** (default) — one legal target per `[AGT-3]`.
- **Multi-target** — reuses the **`[STY-9]` AoE / multi-target footprint** (shapes incl. `rectangle`,
  plus the `target_filter` set). A "mass dance" / battlefield rally refreshes **every** unit in the
  footprint that passes the filter + `[AGT-3]` validity (`state != READY`). Each refreshed unit runs the
  refresh transition (`[AGT-6]`) independently; the `[AGT-7]` caps apply **per unit**. The `[STY-10]`
  preview shows the footprint and which units it will refresh — the existing AoE forecast, no new panel.
- **Self** — an author opt-in (`effect_params` lets `target_filter` **include the caster**), relaxing
  `[AGT-3]`'s `target != caster` default. A self-refresh is a **"second wind"**: the caster spends the
  action (→ `DONE` per `[AGT-5]`) and then re-grants *its own* just-spent turn. Distinct from `[SMV]`'s
  self-grant (which is passive + move-only); this is the activated, full-turn self case. Because it
  refreshes the actor with no second body involved, it is the **most loop-prone** shape and therefore the
  one that leans hardest on the `[AGT-7]` levers (the `actions_taken_this_turn` cap, a resource cost) —
  authors should not ship an uncapped, free self-refresh.

All three are the *same* `grant_action` effect over the *same* substrate; cardinality only changes which
units the effect enumerates. (`effect_params.targeting ∈ { single, area, self }`, with `area` carrying
the `[STY-9]` shape/filter payload.)

---

## 4. Build hand-off (when scheduled)
- **GDD owners at build:** GDD_05 (the `grant_action` effect_id + `effect_params`) · GDD_02 (the
  activated-skill targeting flow + the `actions_taken_this_turn` counter on the turn/action economy) ·
  GDD_03 (Dancer/Bard class default unlock) · GDD_10 M10 (reconcile Extra-Turn: the `is_self:false`
  branch of `grant_extra_turn`).
- **Reuses, doesn't add:** `SkillData` (params + `is_player_activated` + `max_uses_*` + the `[STY]`
  cost axis), the skill load/aggregate/persist stack, `grant_extra_turn` + the M14-stage-5 controller
  re-entry, the targeted-skill range/`target_filter`/`[STY-17]`/`[STY-10]` machinery, the **`[STY-9]`
  AoE footprint** for multi-target (`[AGT-13]`), `TurnManager`'s state enum + refresh.
- **Net-new code:** the `effect_id="grant_action"` resolution (single/`area`/`self` enumeration over the
  reused targeting axes), the `actions_taken_this_turn` transient counter (increment-on-commit +
  clear-in-`_refresh_faction_units`) and its cap test in target validity, Dancer/Bard `ClassData`
  default unlocks. (The `§5` rate-limit primitive is **separate** net-new work, owned by the action-flow
  foundation.)
- **DoD#1/#2 apply at build**, not at this firming (no behavior changed yet).

## 5. Forward-pin — generic "action-rate-limit" primitive (broader than A2)
The owner's anti-loop tool #2 (`[AGT-7]`) is **not action-grant-specific**: a way to cap **any** action
from **any** source on a **per-phase / per-round / per-map** basis. It also serves battalion **gambits**
(`[STY-7/11]`, "once per round"), limited utility-staff uses, signature moves, etc. **Pinned forward to
the action/turn-flow foundation** (it lives with `TurnManager`'s phase/round counters, not A2). Owner =
action-flow foundation + A5 `CampaignRules`; consumed by action-grant (`[AGT-7]`), battalions (`[STY-11]`,
the remaining A2 pass), and utility staves. To be firmed when the battalion entity or the foundation
pass picks it up; reserve any persistent rate-limit counters at F1 alongside `[AGT-11]`.

## 6. Forward-pin — non-combat-action EXP / proficiency path (→ A5 EXP economy)
**Confirm that non-combat support actions — Reinvigorate, and the wider `[STY]` non-attack effect set —
have a path to award EXP.** Code-grounded state today:
- **Level EXP plumbing exists and has precedent.** `Unit.add_exp(amount)` (`scripts/units/Unit.gd:610`)
  is the shared level-EXP path; **staff use already calls it** (`Unit.gd:482`,
  `add_exp(GameConstants.STAFF_HEAL_EXP)`). So a non-combat action *can* grant level EXP — what's
  missing is an **authored EXP amount for action-grant** (and other support actions): is Dance worth
  EXP, how much, and is it a `SkillData`/`CampaignRules` value rather than a `GameConstants` constant
  like `STAFF_HEAL_EXP`?
- **Proficiency EXP is the real gap.** `Unit.add_wexp(track, amount)` (`Unit.gd:1175`) is **weapon-track
  keyed** and combat-driven (`CombatResolver`). A Dance has **no weapon track**, so non-weapon skills
  have **no proficiency-EXP path today**. Decide whether non-weapon support actions earn any proficiency
  / skill-mastery progression at all, and if so on what track.

**Owner = A5 (EXP economy / Bonus-EXP #18 cluster)**; surfaced here because action-grant is the first
non-combat, non-staff action to raise it. **Not owned by this register** — pinned so the A5 EXP pass
generalizes the staff-EXP precedent into a "support-action EXP" rule (authored amount + proficiency
decision) rather than special-casing each action. Mirror-pinned in the atlas A5 bullet.

## 7. Reconcile-don't-relitigate
- Action-grant is the **`is_self:false` branch** of the *same* `grant_extra_turn` substrate `[SMV]` uses
  — **not** a second engine. Do not build a parallel refresh subsystem.
- Anti-loop is **author-tunable tools** (`[AGT-7]`), **not** a hardcoded "danced units can't dance" rule —
  this was the explicit owner call this session.
- The generic rate-limit primitive (`§5`) is **not** owned here; do not fold it into the action-grant
  effect. Action-grant only *consumes* it.
