---
Type: register
Status: OPEN
Last verified: 2026-06-27
Register: TCV-1..6
Resolved-in: —
---

# Typed Campaign-Variable Store + Author-Exposed Tuning (F6 evolution) — Open Questions (PINNED, not yet firmed)

**Started:** 2026-06-27 (session 2026-06-27d). **Status: a PINNED EXPLORATION** — surfaced when the
**#12 Difficulty** answer (`[DIF-5]`) and the **dialogue→victory/defeat side-check** (the
objective-extensibility pin) **converged on the same need: F6 must become a *typed* variable store.**
Captures the **consolidated scope + directions**; **not owner-ratified design yet** — to be **walked as
one pre-F1 foundation pass** (owner 2026-06-27d: "fold into one typed campaign-variable store walk").
Owner = the F6 foundation, evolved. Rides F1 (schema) + F4 (`CampaignRules`) + F16 (`[REQ-16]`). Branch
`docs-reorg-2026-06-23`. Legend: **[OPEN]** / **[ASKED]** / **[RESOLVED]**.

> **Why pre-F1 (the timing guarantee):** this is **schema-affecting** (the typed-variable store + the
> objective conditions that reference it). It **MUST be walked in the define-all sweep, before the F1
> schema-lock (Phase B) — hence before the Phase C evaluation/triage session** (owner 2026-06-27d). It
> cannot wait for the triage.

---

## Substrate reality (verified 2026-06-27d)
- **No flag store today.** `GameState` has only debug-aid flags; F6 is designed-but-unbuilt and `[MET]`'s
  `flag` action + `[DLG]`'s `choice.set_flag` both target a store that doesn't exist yet.
- **`ObjectiveCondition.type` is a closed enum** (`rout/defeat_boss/seize/escape/survive/protect/
  turn_limit`, `scripts/resources/ObjectiveCondition.gd`), evaluated by `TurnManager.
  check_victory_conditions` (→ `EventBus.map_victory/defeat`), **phase-boundary-polled** — no
  flag/predicate/event-driven type.
- **`[REQ-16]`** already gives a fixed-point arithmetic value-term tree; **variables feeding formulas**
  is exactly its shape — but it needs a **variable source** to read (this store).

## Scope (the five threads this walk must firm)

## [TCV-1] F6 flags → a **typed** variable store — **[OPEN]**
Generalize the boolean flag store to **typed campaign/map variables** (bool · int · enum · maybe string),
read/written by `[MET]` actions, `[DLG]` choices, `[REQ-16]` terms, and objective conditions. Decide:
scope levels (campaign vs map vs run), persistence (rides F6/save), and the read/write API. *Direction:*
the store is the single home; `[REQ-16]`'s deferred "predicate-bridge / flag-upstream" pattern points
here.

## [TCV-2] Author-exposed tunable mechanism (built-in knobs **and** custom variables) — **[OPEN]**
**One uniform mechanism** (the `[DIF-5]` insight): any **built-in `CampaignRules` knob** *or*
**author-defined custom variable** is declarable as **author-locked** or **player-exposed**, with an
**exposure timing** (campaign-start and/or **mid-run**) and **author bounds/options** (range or enum).
The New-Game pickers (`death_mode`, difficulty, leveling) become the built-in slice of this; `[DIF-4]`
selection is a consumer. Decide the declaration format + the mid-run change surface (a settings/options
menu vs a story event).

## [TCV-3] Custom variables → **parametric, tag-scoped effects** — **[OPEN]**
Author-defined variables drive **parametric modifiers**: the owner's examples — **"+x to all enemy
stats"**, **"+n levels to tagged enemies"** — plus money rates, dialogue-check difficulty, loss-condition
strictness. Needs: a **unit/entity tag system** (confirm/extend), a **spawn-time modifier hook** (apply
at instantiation), and **`[REQ-16]` formulas** (stat = base + var) as the computation. Decide the effect
vocabulary + scoping (global / faction / tag) + where it applies (spawn vs live recompute).

## [TCV-4] Flag/predicate-driven objective conditions (absorbs the objective-extensibility pin) — **[OPEN]**
The **closed `ObjectiveCondition` enum** must open so win/loss can be **flag/predicate-driven** — the
shared unlock for **(a)** a **dialogue-driven victory/defeat** (a `[DLG]` `command`/`[MET]` action ending
the map or setting a win/lose flag), **(b)** the **`[DTH-10]` `key_item_removed_from_map` custody
objective**, and **(c)** any flag-driven win/lose. **Two paths (choose in the walk):** **(A) declarative**
— migrate the enum toward **F16 predicates** / add a `flag_set`/predicate type, reading TCV-1; **(B)
imperative** — a direct **`end_map: victory|defeat`** action. Plus the **re-check timing** (phase-poll vs
event-driven on flag/custody change). *Supersedes the standalone objective-extensibility pin* (DTH-10
forward-pin + atlas A4 keystone), now folded here.

## [TCV-5] Scope / sequencing / composition — **[OPEN → fixed by owner]**
**One consolidated pre-F1 walk** (owner). **Composes:** F6 (the store), `[REQ-16]` (formulas), `[EXT]`
(author-extensibility model — variables/effects are an Option-A data composition), the tag system,
the modifier system, `[CampaignRules]`/F4, `[DLG]`/`[MET]` (writers), the **objective/win-loss system**
(`[VIL-8]` + `ObjectiveCondition`), and `[DIF]` (the death-mode/difficulty selection that rides on top).

## [TCV-6] Save / F1 schema reserve — **forward to Phase B (F1 lock)**
Reserve: the **typed variable store** (campaign/map/run scopes), the **player's exposed-tunable picks**,
and the **objective-condition predicate/flag references** (TCV-4). This is the schema surface that makes
the walk a **pre-F1** must.

---

## Cross-refs
- **`[DIF-5]`** (difficulty tuning layers folded here) · **`[DTH-10]`** (custody objective needs the open
  enum) · **`[REQ-16]`** (arithmetic terms read these variables) · **`[EXT]`** (the extensibility model) ·
  **F6** (the store this evolves) · **`[DLG]`/`[MET]`** (variable writers + the `end_map`/`set_flag` hook)
  · **`[VIL-8]`** + `ObjectiveCondition` (the win/loss system that opens up).
