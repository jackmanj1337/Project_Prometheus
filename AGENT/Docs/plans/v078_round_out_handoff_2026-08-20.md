---
Type: plan
Status: Active — next-session handoff; a candidate is outstanding, so read §1 before starting anything
Last verified: 2026-08-20
Tracker: WINDOWS-PASS-READINESS-2026-08-20, AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20, PORTFOLIO-CODE-STATE-REVIEW-REBASELINED-2026-08-20, REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20, OP-AWARE-THRESHOLD-REASONS-2026-08-20
Control plane: [Project Control Plane](project_control_plane_2026-06-29.md)
---

# v0.7.8 is out for the batched Windows round — Handoff (2026-08-20)

Written at the end of the session that built `UNMET-REASON-TEXT-TABLE-2026-08-20`, took
the owner's four readiness decisions, consolidated the build, and cut the candidate. It
replaces [`windows_pass_readiness_handoff_2026-08-20.md`](windows_pass_readiness_handoff_2026-08-20.md),
whose four questions are all answered.

**A candidate is outstanding. That changes the rules — §1 first.**

## 1. The boundary rules are back in force

The control plane states them and they resume the moment an artifact goes out:

> returned evidence preempts new work at the next green commit, repairs land on the
> release line and never on `agent/integration`, and the outstanding artifact is never
> rebuilt, replaced, or reinterpreted.

Concretely, for this round:

- **If the round has returned, triage it first.** Whatever §3 recommends is preempted.
- **Repairs go on `agent/playtest-release-v0.7.8`**, not `agent/integration`.
- **Do not re-export `v0.7.8`.** If something looks wrong with the artifact, that is a
  finding to record, not a reason to quietly rebuild the thing the owner is holding.

## 2. What went out, and how it was verified

| | |
|---|---|
| Branch | `agent/playtest-release-v0.7.8` at `b14d4943` (pushed) |
| Artifact | `builds/windows/Project_Prometheus/Project_Prometheus.exe` |
| Size / SHA-256 | 106,085,592 / `d143efb1ff27a7ed73af7767367d782a2cf02f327a823dcdeab8f35dbc21cd29` |
| Godot | `4.6.3.stable.official.7d41c59c4`, `--export-release`, `debug_controls: false` |
| Checklist | [`playtest_checklist_v0.7.8.md`](../playtests/playtest_checklist_v0.7.8.md) |
| Build record | [`playtest_build_v0.7.8.md`](../playtests/playtest_build_v0.7.8.md) |

**The stamp was verified, not assumed.** The manifest records version `0.7.8` at commit
`b14d4943`, matching `HEAD`, and `source_tree 0a0bd488` matching the full-test receipt
tree. v0.6.1 once shipped a v0.6.0 stamp because a missing build record silently skipped
the bake; this artifact is confirmed clean on that specific failure.

**Not tagged.** The round has not been played. A `vX.Y.Z` tag belongs at acceptance, not
at candidate cut.

### Housekeeping to not forget

`playtest_checklist_v0.7.8.md` is on `agent/integration`; **`playtest_build_v0.7.8.md` is
only on `agent/playtest-release-v0.7.8`** (two commits ahead of integration). The v0.6.1
round had the same split and it was resolved by merging the release evidence back so the
queue and the evidence read from one branch. Do that at acceptance rather than leaving a
build record readable only from the release ref — that is the same invisibility failure
the tracker rule exists to prevent.

## 3. Recommended work while the round is out

In priority order. All three are `planned`, none touches the outstanding artifact.

### 3a. `AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20` — recommended first

Cheap, and the evidence for *which half to build* arrived this session. The row's design
question was left open between a shared availability-list builder and a check that a
`disabled` `BaseButton` carries a reason. **Prefer the check.**

The reason is in how the sixth instance was found: writing the screen-reader checklist and
asking what Narrator would say on the Main Menu. Continue and Load Game were gated with no
reason at all — on the first screen of the game, months old, with no test asserting a
reason on either. A check would have caught that years-of-commits ago; a shared builder
only helps surfaces written *after* it lands, and every existing surface would still need
the same hand-application that has now happened six times.

Scope it as a test-time check over the shipped screens, not a runtime assertion.

### 3b. `REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20`

`RequirementFormulaRegistry` still ships beside `FormulaEvaluator` against `B3-REQ`'s own
instruction — *grow it or replace it, but do not ship two*. The legacy class has exactly
one reference in the project (`test_formula_registries.gd:63`) and no production caller, so
this is a deletion with a test edit, not a migration.

### 3c. `PORTFOLIO-CODE-STATE-REVIEW-REBASELINED-2026-08-20` — biggest unblock, largest job

It now carries the four dependency edges repointed from the superseded row, so it gates
`PREP-V1-S01`, `UIREC-V1-S01`, `TEXT-V1-S01` and `DRC-V1-S00`. Three deliverables:
re-baselined evidence matrix, architecture collision report, corrected dependency edges.

One instruction from the re-scope is worth restating because it is the whole point of
deliverable 2: **verify each shared contract by naming its consumers, not by confirming
the contract exists.** `RequirementSystem` shipped with a green suite, a full API, and no
production callers — reproducing the exact property that justified replacing what it
replaced. `UNMET-REASON-TEXT-TABLE` was deliberately built with a live consumer for that
reason; the review should check whether anything else in the portfolio is inert.

## 4. What is NOT recommended, and why

- **`PREP-V1-S01`** — still gated on §3c and on the `[ANN-5]` answer this round produces.
  Starting it now means building a gated surface before the ruling about gated surfaces is
  checkable and before the announcement channel is decided.
- **`IMPL-FOG-RENDER-2026-08-02`** — buildable, but it is a visual-pass row and the host is
  about to be busy. Building it now means it misses this round and waits for the next one
  anyway; there is no cost to sequencing it right after the return.
- **`OP-AWARE-THRESHOLD-REASONS-2026-08-20`** — newly created, deliberately backlogged. See
  §5.

## 5. Open items carried forward

**`OP-AWARE-THRESHOLD-REASONS-2026-08-20`** (new this session). `class_level`,
`proficiency` and `stat` take an `op` with six values and default to `gte`; the shipped
fallback sentences are phrased for that default, so *"Requires level {n} or higher."* is
wrong for an `lt` requirement. Authors have `presentation.override_text_key` today, which
is why it is a limit rather than a defect. **The relevant trap:** `test_text_db`'s coverage
walk asserts every registered key *renders*, not that it renders *correctly*, so it stays
green straight through this and cannot be leaned on.

**Two questions for the owner are on the checklist**, not answerable by anyone else:

1. The v0.7.6 note that stops mid-word — *"browser cancel is fine, but I think that when a
   download was canceled then the "*. Something was observed and never written down.
2. Whether shipping deliberately-broken save files would make the two migration checks
   that returned *"not sure how to test this"* actually testable. That is a checklist
   testability gap, not a tester failure, and asking again unchanged will return the same
   answer. Both live on `V076-RETURN-RESIDUE-2026-08-16`.

**Three rows still want a host but were deliberately kept off this round**, and they need a
phone or a touch device rather than a Windows desktop:
`IOS-DEVICE-PWA-VERIFICATION-2026-08-03`, `MOBILE-WEB-UX-GAPS-2026-08-03`,
`DEDICATED-TOUCH-CONTROLS-2026-08-03`. They need their own device session; none blocks
`PREP-V1-S01`.

## 6. Mechanics learned this session, so the next cut is not a discovery exercise

Three gates each refused the export until satisfied. In order:

1. **The full-test receipt must match the exact exported commit AND tree.** Any commit made
   after the test run invalidates it — including the build-record commit itself. So
   `scripts/run-full-tests.sh` is the *last* thing before the export, not the first.
2. **`--mode release` requires `--build-stamp` text containing the short commit** and
   refuses without it.
3. **The export refuses to overwrite an existing output directory.** The previous shipped
   artifact was moved to `builds/windows/Project_Prometheus_v0.7.7_archived` rather than
   force-overwritten; do the same rather than passing `--force` at a shipped build.

And two test-harness facts from the text-table build, both of which produced a confidently
wrong result first:

- Inside a `SceneTree` script's `_init()` the root `Window` is **not** in the tree —
  `is_inside_tree()` is false, absolute lookups return `null`, and queued `_ready()` calls
  have not run. `await process_frame` is load-bearing for any autoload-wiring test.
- **A runtime error in `_init()` aborts before `quit(1)`, so the suite exits 0.** Read the
  output for `SCRIPT ERROR` and the `=== Results:` line; the exit code alone will report a
  broken suite as a pass.
