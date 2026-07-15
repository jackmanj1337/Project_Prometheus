---
Type: register
Status: RESOLVED 2026-06-27
Last verified: 2026-06-27
Register: TCV-1..6
Resolved-in: 2026-06-27d
---

# Typed Campaign-Variable Store + Author-Exposed Tuning (F6 evolution) — Player-Facing Design + Open Questions

**Started:** 2026-06-27 (session 2026-06-27d). **RESOLVED 2026-06-27d (the consolidated pre-F1 foundation
walk).** Surfaced when the **#12 Difficulty** answer (`[DIF-5]`) and the **dialogue→victory/defeat
side-check** (the objective-extensibility pin) converged on one need: **F6 must become a *typed* variable
store.** This walk firms that store + the author-exposed tuning mechanism + parametric tag-scoped effects
+ the win/loss extensibility, **all as reuse** (the modifier system, `[REQ]`/`[REQ-16]`, and the F6 design
already exist). Owner = the F6 foundation, evolved. Branch `docs-reorg-2026-06-23`. Legend: **[OPEN]** /
**[RESOLVED]**.

> **Pre-F1 (timing guarantee):** schema-affecting (the store + the objective conditions that reference
> it) → **walked in the define-all sweep before the F1 lock (Phase B), hence before the Phase C triage.**

---

## Substrate reality (verified 2026-06-27d)
- **No flag store today** — `GameState` has only debug-aid flags; F6 designed-but-unbuilt; `[MET]`'s
  `flag` action + `[DLG]`'s `choice.set_flag` target a store that doesn't exist yet.
- **`ObjectiveCondition.type` is a closed enum** (`rout/defeat_boss/seize/escape/survive/protect/
  turn_limit`), phase-boundary-polled — no flag/predicate type.
- **The modifier system EXISTS** — `Unit.add_modifier(stat, delta, source)` / `remove_modifier` /
  `tick_modifiers`, read through `get_effective_stat()`. TCV-3 stat effects reuse it.
- **Tags partially exist** — `ClassData` has "loose semantic tags." TCV-3 extends, not greenfields.
- **`[REQ-16]`** is the fixed-point formula tree; it just needs a **variable source** (this store).

---

## [TCV-1] F6 flags → a typed variable store — **RESOLVED**
**Owner:** a **`CampaignVars` store** (evolves F6) of **typed variables — `bool` · `int` · `enum`** —
read/written by `[MET]` actions, `[DLG]` choices, `[REQ-16]` terms, and objective conditions. **Two
scopes:** **campaign** (persists across maps, the F6 story-flag role → save) and **map** (per-map
transient, like `map_events_fired` → reset each map). `string`/run-scope deferred until a consumer needs
them. Typed get/set API keyed by the registry (TCV-2); `[REQ-16]`'s deferred "flag-upstream / predicate-
bridge" pattern lands here.

## [TCV-2] Author-exposed tunable mechanism — **RESOLVED**
**One uniform mechanism:** a **registry entry per knob/variable** — `{id, type, default, exposed:
locked | start | mid_run, bounds | options}` — covering **both built-in `CampaignRules` knobs AND
author-defined custom variables** (the `[DIF-5]` insight). The New-Game pickers (`death_mode`, difficulty,
leveling) become the `start`-exposed built-in slice; `[DIF-4]` is a consumer. **Mid-run changes via BOTH**
(owner): a **player options/settings menu** (player adjusts `mid_run`-exposed vars within author bounds) +
a **`[MET]` `set_var` story action** (author-scripted changes). `locked` vars are author-fixed.

## [TCV-3] Custom variables → parametric, tag-scoped effects (reuse `[REQ]` for scoping) — **RESOLVED**
**Owner: scope effects via the existing `[REQ]` predicate system, not a bespoke tag matcher.** A "tagged"
set = **units matching a `[REQ]` predicate**; add a **group-membership predicate** ("member of
author-defined group X", `in_group`/`has_tag`) reading a **per-unit `groups`/tags field** (extends the
`ClassData` tags, `[TCV-3-tags]`). Effects:
- **Stat parametric effects** ("+x to all enemy stats", "+n to tagged enemies") = **`add_modifier`** (the
  existing system) applied **at spawn**, the delta a **`[REQ-16]` formula over a campaign variable**,
  scoped by a `[REQ]` predicate (faction / `in_group` / any). **Level adjustments** = a spawn-time level
  delta (re-applies growths) — the one effect heavier than a flat modifier.
- **Global tunables** (money rate, dialogue-check difficulty, loss-condition strictness) = variables
  **read by their consumers** (not modifiers) — the consumer multiplies/gates by the var.
Reuses the modifier system + `[REQ]` + `[REQ-16]`; the only new field = the per-unit group/tag list + the
`in_group` predicate.

## [TCV-4] Flag/predicate-driven objective conditions — **RESOLVED (both paths + event-driven)**
**Owner: BOTH paths** — **(A) declarative:** a new **flag/predicate-driven `ObjectiveCondition` type**
that reads `[TCV-1]` vars + `[REQ]` predicates (opens the closed enum; carries the `[DTH-10]`
`key_item_removed_from_map` custody objective); **(B) imperative:** a direct **`end_map: victory|defeat`**
`[MET]`/`[DLG]` action (scripted beats / dialogue-driven win-loss). **Re-check = event-driven** on the
triggering change (flag set / custody change / var change) **+ the existing phase-boundary poll as
backstop.** **Supersedes** the standalone objective-extensibility pin (`[DTH-10]` forward-pin + the atlas
A4 keystone) — both now RESOLVED here.

## [TCV-5] Scope / composition — **RESOLVED**
One consolidated walk. **Composes:** F6 (the store), `[REQ-16]` (formulas), `[REQ]` (predicate scoping +
the `in_group` tag predicate), `[EXT]` (variables/effects = an Option-A data composition), the **existing
modifier system**, `[CampaignRules]`/F4, `[DLG]`/`[MET]` (writers + `set_var`/`end_map`), the
**objective/win-loss system** (`[VIL-8]` + `ObjectiveCondition`), and `[DIF]` (death-mode/difficulty
selection riding on top). Build is **net-reuse** + the typed store + one predicate + one per-unit field.

## [TCV-6] Save / F1 schema reserve — **forward to Phase B (F1 lock)**
Reserve: the **typed variable store** (campaign-scope persisted; map-scope transient/reset), the
**player's exposed-tunable picks**, the **per-unit `groups`/tags field**, and the **objective-condition
predicate/flag references** (TCV-4). This is the schema surface that made the walk a pre-F1 must.

---

## Cross-refs
- **`[DIF-5]`** (difficulty tuning layers folded here) · **`[DTH-10]`** (custody objective → TCV-4
  declarative type) · **`[REQ-16]`** (formulas) + **`[REQ]`** (predicate scoping + new `in_group`
  predicate) · **`[EXT]`** · **F6** (the store this evolves) · **`[DLG]`/`[MET]`** (`set_var` + `end_map`)
  · **`[VIL-8]`** + `ObjectiveCondition` (the opened win/loss system) · the **modifier system** (`Unit.
  add_modifier`) · **`[DIF]`/`[BEA]`/`[PVP]`** (consumers of author-defined tuning values).
