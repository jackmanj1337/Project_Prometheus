---
Type: plan
Status: Active — waiting-work handoff; a candidate is outstanding, read §1 before starting
Last verified: 2026-08-21
Tracker: WINDOWS-PASS-READINESS-2026-08-20, PORTFOLIO-CODE-STATE-REVIEW-REBASELINED-2026-08-20, REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20, AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20, PACK-SCHEMA-FRESHNESS-CHECK-2026-08-21
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# What to work on while v0.7.8 is out — Handoff (2026-08-21)

Supersedes §3–§5 of [`v078_round_out_handoff_2026-08-20.md`](v078_round_out_handoff_2026-08-20.md),
which was written before the bundle existed. Its §1, §2 and §6 still stand and are not
repeated. This document exists because that handoff's recommendation order was made
without checking the dependency graph, and the graph changes the order.

## 1. The round is now genuinely out

The previous handoff said a candidate "is out". It had been **cut, not delivered** — there
was no bundle, the build shipped no campaign content, and the pack the checklist was
written against had stopped validating. All three are fixed; see
[`the readiness session note`](../../Session%20Notes/2026-08-21-00-20-00Z-v078-tester-bundle-readiness.md).

| | |
|---|---|
| Deliverable | `builds/tester/Project_Prometheus_v0.7.8_tester_bundle.zip` (SHA-256 `3dffaa25…`) |
| Build | `0.7.8` at `b14d4943`, stamp confirmed **baked into the exe**, not just claimed by the manifest |
| Release branch | `agent/playtest-release-v0.7.8`, tip `fb5a84c9` — now **contains `agent/integration`** |
| Pack shipped | `prometheus-proving-grounds` 0.1.0, from Pack_0 `17bfac3` |

**The boundary rules from the previous handoff's §1 are in force and unchanged:** returned
evidence preempts new work at the next green commit, repairs land on the release line and
never on `agent/integration`, and the outstanding artifact is never rebuilt, replaced, or
reinterpreted. If the round has returned, stop reading and triage it.

One topology note, because it removes a trap: `agent/integration` is now an **ancestor** of
the release branch. Product code is identical between them; the release line simply carries
extra documentation. So there is exactly one branch to stand on to see the whole round, and
a repair committed there is not silently missing the round's own context.

## 2. Do this first: `PORTFOLIO-CODE-STATE-REVIEW-REBASELINED-2026-08-20`

The previous handoff ranked this **third**, as the "biggest unblock, largest job". The
dependency graph says it should be first, and the reason is a sequencing one rather than a
matter of size.

`PREP-V1-S01` has four unmet dependencies. **Three of them are `in_review` rows that this
very round exists to verify** — `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` (checklist
§2), `UNMET-REASON-TEXT-TABLE-2026-08-20` (§3), and `DESIGN-OVERWORLD-CADENCE-2026-07-25`.
The round closes those or it does not; no amount of container work moves them.

The fourth is this review, and it is the **only one the round cannot close**. It is also
fully unblocked right now: its single dependency, `B3-REQ-F16-BUILD-2026-08-18-2026-08-19`,
is `completed`.

So the two orderings differ sharply in outcome:

- **Review now** → the round returns, three rows close, `PREP-V1-S01` unblocks the same day.
- **Review later** → the round returns, three rows close, and `PREP-V1-S01` is *still*
  gated on a review nobody ran. The round's value sits idle behind container work that
  could have happened in parallel.

It also gates `UIREC-V1-S01`, `TEXT-V1-S01` and `DRC-V1-S00` — four rows on one edge,
repointed from the superseded row.

Three deliverables: re-baselined evidence matrix, architecture collision report, corrected
dependency edges. **The one instruction worth restating**, because it is the entire point
of deliverable 2: *verify each shared contract by naming its consumers, not by confirming
the contract exists.* `RequirementSystem` shipped with a green suite, a full API, and no
production callers — reproducing the exact property that justified replacing what it
replaced. Check whether anything else in the portfolio is inert.

## 3. Cheap, and verified today: `REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20`

Two formula evaluators ship side by side against `B3-REQ`'s own instruction — *grow it or
replace it, but do not ship two*. Re-confirmed against the current tree rather than taken
from the previous handoff:

- the class lives at `scripts/registries/RequirementFormulaRegistry.gd`;
- its **only** reference anywhere outside its own file is
  `scripts/tests/test_formula_registries.gd:63`;
- there is no production caller.

A deletion and a test edit. Good work for a short sitting, and it removes a decoy the
portfolio review in §2 would otherwise have to reason about.

## 4. `AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20` — buildable, but read this first

The previous handoff recommended this **first**. It is still worth building and its design
question is settled, but it carries a caveat that handoff did not state: **its dependency
`SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17` is `in_review`, and this round is its
verification.**

That does not block the build — the ruling is already shipped in code, and the guard is a
test-time check over shipped screens, not a consumer of the round's answer. It does mean
the row **cannot be closed** until its dependency closes. Build it if you want the win;
just do not expect to mark it done this week.

The design question is answered, and the evidence is worth keeping: **prefer the check over
a shared availability-list builder.** The sixth instance of the defect was found by writing
the screen-reader checklist and asking what Narrator would say on the Main Menu — Continue
and Load Game were gated with no reason at all, on the first screen of the game, months
old, with no test asserting a reason on either. A check would have caught that years of
commits ago; a builder only helps surfaces written *after* it lands, and every existing
surface would still need the hand-application that has now happened six times.

Scope it as a test-time check over the shipped screens, not a runtime assertion.

## 5. New: `PACK-SCHEMA-FRESHNESS-CHECK-2026-08-21`

Same shape as §4, one layer down, and **no longer hypothetical**.

Nothing verifies that a shipped campaign pack still validates against the engine it ships
beside. Both Proving Grounds packs sat broken for roughly two weeks across two schema
changes — `magic_weapon_requires_uses_mag` (`76ce4096`) and self-contained pack skills
(`c11e9488`) — reporting `adapter valid: false`, 31 errors, and loading **nothing**
(`classes=0 maps=0 campaigns=0`). No suite, hook or CI check noticed. It surfaced only
because someone tried to hand one to a tester.

The tool already exists and already returns the right verdict: `scripts/tools/validate_pack.gd`.
What is missing is anything that **runs** it over the checked-in packs on a cadence the
engine's own changes cannot outrun.

Watch the cross-repo seam before designing it: the packs live in
`Project_Prometheus_Campaign_Pack_0` and `_FE`, so a check inside `Project_Prometheus` can
only reach them through the workspace checkout, and a check inside a pack repo cannot see
the engine schema at all. That asymmetry is the whole design problem.

## 6. What NOT to start, and why

- **`PREP-V1-S01`** — four unmet dependencies, three of which only the round can close.
  Starting it means building a gated surface before the rulings about gated surfaces are
  checkable.
- **`SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19`** — status `blocked`, on `[ANN-5]`,
  which is literally §1 of the checklist in the tester's hands. Guessing the answer wastes
  the session either way: if Narrator already reads the reason the row shrinks to "verify
  and improve the wording", and if it does not, the mapping is real work.
- **`IMPL-FOG-RENDER-2026-08-02`** — unmet dependency (`IMPL-FOG-VISION-AMBUSH-2026-08-02`
  is `in_review`) *and* it is a visual-pass row. Building it now means it misses this round
  and waits for the next one regardless.
- **`IOS-DEVICE-PWA-VERIFICATION-2026-08-03`, `MOBILE-WEB-UX-GAPS-2026-08-03`,
  `DEDICATED-TOUCH-CONTROLS-2026-08-03`** — these want a phone or touch device, not a
  Windows desktop. They need their own device session; none blocks `PREP-V1-S01`.
- **Anything touching the outstanding artifact**, including a "harmless" re-export. If
  something looks wrong with the exe, that is a finding to record, not a reason to rebuild
  the thing the owner is holding.

## 7. Recommended order

1. `PORTFOLIO-CODE-STATE-REVIEW-REBASELINED-2026-08-20` — the only unblock the round cannot
   deliver, and it gates four rows.
2. `REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20` — small, and clears a decoy out of (1)'s way.
3. `PACK-SCHEMA-FRESHNESS-CHECK-2026-08-21` or `AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20`
   — same shape, either order; the guard cannot be *closed* this round, the pack check can.

**None of the three branches exist yet.** Start them from `agent/integration` with
`scripts/agent-start-task.sh`; the slugs are already recorded on the rows.

## 8. When the round returns

Triage preempts everything at the next green commit. Repairs go on
`agent/playtest-release-v0.7.8`. At acceptance, tag `v0.7.8` at **`b14d4943`** — the commit
baked into the BUILD STAMP, not the branch tip, which has since moved for documentation
only — and merge the release evidence back so the queue and the evidence read from one
branch.

Two questions on the checklist are for the owner and need no build:
`V076-RETURN-RESIDUE-2026-08-16` carries both.
