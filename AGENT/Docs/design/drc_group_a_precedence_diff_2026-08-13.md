---
Role: dated
Type: design
Status: Accepted — precedence diff; the `DRC-19..24` owner walk completed 2026-08-13
Last verified: 2026-08-13
Tracker: DISCUSS-RECRUIT-CAPTURE-UX-2026-07-23
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# `DRC-19..24` (Group A) — Precedence Diff Before the Owner Walk

> **The walk is complete (2026-08-13).** All six questions are ruled and the rulings live in the
> register's *"Owner rulings, 2026-08-13 (third walk — Group A)"* section, not here. Every
> disposition below was followed except §7's expectation that `DRC-23` would need only
> confirmation: it was ruled outright, and **more narrowly than this document recommended** —
> the transition patches the five dimensions and nothing else, with `[AIP]` profile and scripted
> orders moved to the effect system and bundled into the recruitment presets. §4 and §6 were
> recorded as debts as suggested.

Companion to [`skf_drc_precedence_diff_2026-08-13.md`](skf_drc_precedence_diff_2026-08-13.md),
whose §3 was written to travel with the deferred recruitment/capture half. This document is the
mandatory `DOC-014` check for **Group A only** — the state-model spine, `DRC-19..24` — run before
any of it goes to the owner.

**Sources diffed.** `RCR-1..7`, `RCV-1..6`, `REQ-1..16`, `DLUX-1..16`, `EPUX-02/06/24`, `CAU-4`,
and the `DRC-1..18` rulings of 2026-08-13 (`DRC-9`, `DRC-11`, `DRC-13`, `DRC-14`, the two-primitive
transaction ruling).

## Bottom line

**The headline correction is to the earlier diff itself.** §3 item 4 states that the `RCR`/`RCV`
reopening *"is already propagated … no action needed."* That is true at the **register banner**
level and false at the **item** level. `RCR-1` and `RCR-5` carry supersession banners; `RCR-2`,
`RCR-3`, `RCR-4` and `RCR-7` carry none, and `RCV-4` still names `[RCR-1]`'s faction flip and
`[RCR-2]`'s flag **by name** as the contract its `recruit` action calls. A banner on a register
header does not reconcile the items underneath it — this is the same one-directional propagation
failure the whole precedence exercise exists to catch.

Of the six Group A questions: **three already carry July provisional rulings** (`DRC-19`, `DRC-21`,
`DRC-24`) and need confirmation, not re-litigation; **three are unruled** (`DRC-20`, `DRC-22`,
`DRC-23`). One item — `RCR-4` — turns out to have been **closed by `REQ` in June**, not by `DRC`,
and simply never got its banner. One genuinely new conflict surfaced: `DRC-20` and `DRC-13` now
describe two different owners for the same activation seam.

---

## 1. `RCV-4` and `RCR-3` contradict `DRC-20` outright

`RCV-4` (RESOLVED 2026-06-25o) defines the `recruit` MET action as calling *"the firmed
`recruit(unit)` transition API (`[RCR-1]` faction flip → persistent roster + `[RCR-2]`
`recruited:<id>` flag)."* `RCR-1` is explicitly superseded; `RCV-4` cites it anyway.

This is not merely stale wording. A single-arity `recruit(unit)` **cannot express what `DRC-21`
already ruled for v1**: a `map_end` recruitment requires an explicit expiry outcome, and a permanent
one does not. The arity carries no room for `duration` or `expiration_outcome`, so the ruled v1
scope is unrepresentable in the API `RCV-4` points at.

`DRC-20` option B — the typed transition `{target_affiliation, target_controller, roster_policy,
duration, expiration_outcome, activation_policy}` — is the replacement, and `DRC-20` is unruled.
**Disposition: `DRC-20` must be ruled, and `RCV-4`/`RCR-3` amended to name whatever it settles.**

## 2. `RCR-3`'s seam is inverted under the five-dimensional model

`RCR-3` splits ownership as *"roster = state + API; MET (A4) = trigger + action"* — the roster side
owns the `recruit()`/`capture()` transition API.

Under `DRC-19`'s ruled five dimensions, that transition mutates `affiliation_id`,
`tactical_side_id`, `controller_id` and `custody_status` as well. **Four of the five dimensions the
API writes are not the roster's.** `roster_status` is one dimension among five, so a roster-owned
API is the lower layer reaching up into the higher one.

This is the inverted-dependency anti-pattern the project has now found seven times, and it is
structurally identical to `DRC-33`'s map-end-borrows-from-the-dialogue-runner inversion amended
2026-08-13. **Disposition: an owner question, narrow — the authoritative transition service owns
the transition; the roster is a consumer of it. `RCR-3`'s hand-off contract is then re-expressed,
not discarded.**

## 3. `RCR-2`'s auto-set `recruited:<id>` flag has no defined setter under the ruled model

`RCR-2` auto-sets an `F6` flag on recruitment, deliberately distinct from roster membership:
membership answers *"is X in my army"*, the flag answers *"did the player recruit X"* for story
branching. **That justification survives** — the two questions really are different.

What does not survive is the setter condition, because `DRC-21` created a case `RCR-2` never
anticipated: a `map_end` guest recruitment **is a recruitment that produces no roster membership**.
Does it set `recruited:<id>`? Undecided. Three readings are all defensible (only permanent sets it;
every transition sets it; a separate durable flag from the membership one).

There is also a leak hazard. `DRC-24` ruled membership commits *"when the atomic conversation/action
journal commits"*, and `DRC-9` ruled a conversation **is** a staged transaction so nothing leaks
into a save by construction. An `F6` flag written outside that staged transaction reintroduces
exactly the leak `DRC-9` closed structurally. **Disposition: an owner question with a strong
default — the flag is written inside the staged transaction, and its setter condition needs
deciding.**

## 4. `RCR-4` was closed by `REQ` in June, not by `DRC` — it is missing a banner

`RCR-4` puts recruit firing-conditions on the MET trigger, *"reusing MET's condition system + F6."*

`REQ-1..16` (RESOLVED 2026-06-25r / 2026-06-26) already absorbed this. It names *"`[RCR-4]` recruit
eligibility"* among the surfaces it unifies, and rules *"one evaluator + one display path"*, with
`[RCR-4]` recruit eligibility firing-conditions → `Requirement`s stated explicitly in its
cross-reference list. `RCR-4` carries no banner recording that.

This matters beyond housekeeping: `REQ`'s **display path** is what supplies the reason string that
`DRC-11`'s 2026-08-13 ruling requires — the tactical map is a fifth `EPUX-02` availability surface
with a visible-disabled default carrying an authored reason. Had `RCR-4`'s MET-condition split
stood, there would be no reason string to display and the fifth-surface ruling could not be
honoured. **Disposition: closed by precedence. Not an owner question — a banner `RCR-4` owes to
`REQ`.**

## 5. `DRC-20`'s `activation_policy` duplicates `DRC-13`'s registry — the new conflict

`DRC-13` was ruled 2026-08-13: Talk, recruit and capture action-economy costs are **presets in one
open interaction-policy registry**, the same registry `DRC-30` ruled for Trade, with the v1 Talk
preset `end_activation`.

`DRC-20` option B proposes `activation_policy` as **a field on the transition**. `DRC-22` then asks
the same question from the other side — when a newly controlled unit becomes actionable — and its
option C offers authors a `refresh/preserve/end` choice, which is registry vocabulary.

So one seam is described in three places. They are not quite the same axis: `DRC-13`'s registry
governs the **actor's** cost of performing the interaction, while `DRC-22` governs the **target's**
activation state after control changes. But `DRC-20`'s transition field spans both, and shipping a
transition-level `activation_policy` alongside a registry preset means two data locations can
disagree about one unit's turn.

**Disposition: a genuine new owner question, and it should be put before `DRC-20`, `DRC-22` and
`DRC-23` are each ruled, because it decides where their answers are stored.**

## 6. `RCR-7` / `RCV-6` save reservations are undersized

`RCR-7` reserves the roster-membership entry, the `recruited:<id>` flags, and unit
eligibility/reward fields; `RCV-6` adds nothing beyond it and flags `conversations_seen` on demand.

`DRC-19`'s five dimensions, `DRC-21`'s expiry data (*"all transitions and expiry data ride the
normal save/Rewind ledger"*) and custody state are **all save-bearing and none are reserved**. The
reservation list simply predates the model. **Disposition: not an owner question — a consequence
to record once Group A's answers land, then carried into the plan re-derivation.**

## 7. Already-ruled items the walk must not reopen

- **`DRC-19`** — five dimensions, provisionally accepted 2026-07-27, including the ten-scenario
  minimum matrix. Confirm; do not re-open the dimensional model.
- **`DRC-21`** — v1 is `permanent` + `map_end` with a mandatory expiry outcome, identity and
  unpatched runtime state preserved, expiry grants no bonus action, and a stated disposition
  precedence. Confirm against the two-primitive transaction ruling.
- **`DRC-24`** — `roster_status = member` on journal commit, no `pending_member` in v1,
  survival-dependent joins use `guest` + a later permanent transition. Confirm against `DRC-9`'s
  staged-transaction structure, which is what now makes it safe.
- **`RCV-3`** — `directed | bidirectional`; the rename landed 2026-08-13. Nothing owed.
- **`RCR-6`** — recruited units may be main characters. Untouched by the model change.

---

## Suggested walk order

1. **§5 first** — where activation policy lives, because `DRC-20`, `DRC-22` and `DRC-23` all store
   their answers somewhere and this decides where.
2. **`DRC-20`** — the typed transition, which §1 shows is forced by the already-ruled `DRC-21`.
3. **`DRC-22`**, then **`DRC-23`** — both specializations of `DRC-20`'s shape.
4. **§2** (transition-service ownership) and **§3** (the `recruited:<id>` setter), both narrow.
5. **Confirm `DRC-19`, `DRC-21`, `DRC-24`** against whatever 1–4 changed.
6. **Record §4 and §6** as banner/reservation debts for the plan re-derivation.
