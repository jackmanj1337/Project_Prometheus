# Session Note - 2026-08-21

## Branch context

- Branch: `agent/from-integration/portfolio-code-state-review`
- Base branch: `agent/integration`
- Base SHA: `8c62bf166bd05cffa43359e8454d51aa84e399d9`
- Coordination Work ID: `PORTFOLIO-CODE-STATE-REVIEW-REBASELINED-2026-08-20`

Picked up [`v078_waiting_work_handoff_2026-08-21.md`](../Docs/plans/v078_waiting_work_handoff_2026-08-21.md)
and answered its §1 question first: **the round has not returned.** The checklist has zero
checked boxes, no commit exists after the handoff, and `WINDOWS-PASS-READINESS-2026-08-20`
is still `in_progress`. The owner confirmed the bundle is verified but **not yet handed
over** — which gates nothing here. So the preemption rule did not fire, and this session ran
item 1 of the handoff's order: the re-baselined portfolio review.

## What was done

Deliverables 1–3 of the re-scope, in
[`portfolio_code_state_review_2026-08-21.md`](../Docs/plans/portfolio_code_state_review_2026-08-21.md).
Measured against `agent/integration` `8c62bf16`, not a working checkout.

### The method finding, which came first and changed the rest

The re-scope's one restated instruction was *verify each shared contract by naming its
consumers, not by confirming the contract exists.* Applied literally, that method is wrong
in **both directions** in this codebase, and both were hit before any finding was recorded:

- **False negative.** `RequirementSystem` *is* consumed — `CadenceEngine.gd:169` calls
  `evaluate`. But `CadenceEngine.gd` never contains the string `RequirementSystem`: the
  handle arrives as a dictionary entry from `CampaignManager.gd:453` and is invoked as
  `requirement_system.call("evaluate", …)`. Grep the class name and the consumer is
  invisible. It is also a real coupling defect — renaming `evaluate` breaks at runtime, not
  at parse time.
- **False positive.** A naive scan of all 131 production `class_name`s and autoloads
  returned **11** inert contracts. Autoloads are reached by `/root/<Name>` strings, Resource
  subclasses by `script_class` in `.tres`, and `WebTestBridge` from JavaScript via
  `window.__prometheus_test_bridge`. After filtering those, **4** survive.

Reporting the raw 11 would have been the whole failure this review exists to prevent.

### Deliverable 1 — evidence matrix, 39 slices

The correction that matters: **four of six `TEXT-V1` slices are already built** — request /
sanitization / BBCode escaping, the entry-mode registry, and both presenters all ship, and
`TEXT-V1-S01` is one of the four rows this review gates. The family's real gap is `S05`,
which has **zero production callers**: nothing constructs a `TextEntryRequest` or calls
`TextEntryService.begin()`. The only production references to the service at all are two
copies of the same `_text_entry_owner_active()` guard.

`PREP-V1-S01`'s stated blocker is **stale in the reader's favour** — `TextDB` *is* an
autoload and 25 `req.*` keys ship, so that dependency is satisfied in code. Its other two
claims still hold: V070-10 is unrepaired (line numbers drifted to `:97-110`) and
`PrepActivityRegistry` is inert.

`DRC-V1` is uniformly unbuilt with accurate starting state. Two §8 gates measured: `TurnManager`
still emits results directly, and `ConditionManager` is worse than "a stub" — 37 lines with
**zero references anywhere in the repository**, not even a test.

### Deliverable 2 — collision report

Three new collisions beside the re-scope's three:

- **`PrepActivityRegistry` + `PrepActivityDef` are inert**, and this is the consequential
  one: `B3-PHB-REGISTRY` is `completed` and is a dependency of `PREP-V1-S01`, yet the
  registry's only non-test reference is a **comment** and `PrepScreen.gd` uses neither.
  Third instance of a foundation shipping with an API, a green suite and no adopter.
- **`ControllerService` + `ControllerWebBridge` are inert on `agent/integration`.** The
  browser shell waits for `setBridge(fn)`; only `install()` calls it; nothing but the test
  suite calls `install()`. Stated precisely because it is easy to overstate: the wiring
  *exists*, on `agent/from-integration/mobile-controller-web-wiring`, which is 27 ahead and
  **502 behind**. It is a statement about the integration line, not a defect to fix here.
- **Three independent lazy-`TextDB` resolvers** with three silent bare-key fallbacks, two
  carrying comments saying they duplicate the third. The sharper half is coverage:
  `test_text_db.gd:55` walks `all_text_keys()`, which enumerates **predicates only**, so the
  `menu.*` and `overworld.*` keys have nothing asserting they exist.

An honest negative is recorded too: every *other* registry has real production consumers, so
the inert-foundation defect is bounded, not endemic.

### Deliverable 3 — dependency edges

Graph is mechanically clean — no cycles, no dangling ids, and the superseded review row's
four edges are correctly repointed. All four previously flagged producer/consumer inversions
verified paid **by transitive-path check**, not by reading the prose claiming they were.

**A fifth inversion, one layer out, and live.** `PREP-V1-S02` builds the `[DSX-S1..S3]`
distribution shell and names four out-of-epic consumers in prose; none was ordered after it.
Three edges added (`SYS-BATTALIONS`, `B5-SKILLS-CONDITIONS`, `B4-PREP-MAP-DEPLOYMENT`), each
verified cycle-safe first. The fourth is held for the owner:
`B4-IEQ-ITEMS-EQUIPMENT-2026-07-23` is **`in_progress` with zero dependencies**, so it can
build a loadout surface today ahead of the shell it must adopt — but adding the edge places
active work behind an unbuilt slice, which is a scheduling call rather than a mechanical fix.

## Commits

Ownership is in `CLAIMS.tsv`.

Two documents and one control-plane entry, all docs-only; no product code was touched. The
re-scope permits evidenced in-scope fixes and three are now clearly warranted — the
`PrepActivityRegistry` adoption question, the duplicated `TextDB` resolvers, and V070-10's
one-line reparent — but each belongs to an owning row and the round is outstanding, so they
are recorded as findings rather than applied.

## Gates

- `python3 AGENT/Docs/check_docs.py` — **PASS, all 46 checks.**
- `coordination/check_tasks.py` — **OK, 451 tasks valid, no conflicts.**
- Dependency edits re-verified after writing: all three rows carry their full expected
  dependency sets, and a fresh cycle walk over all 451 rows returns none.
- `bash run_tests.sh` — **PASS.** Checked past the exit code per the recorded harness trap:
  **0** `SCRIPT ERROR` lines, **132** `=== Results:` lines, **0** of them reporting a
  non-zero failure count.

**A reporting gap in the harness, found while doing that check and benign.** Five suites
print `(no summary)`: `test_requirement`, `test_formula_evaluator`, `test_campaign_cadence`,
`test_web_test_bridge`, `test_zero_content_export_gate`. The first three cover the exact
contracts this review examined, so they were run individually rather than assumed —
`test_requirement` emits `=== Requirement results: 0 failed ===` and exits 0. The cause is
that `run_one()` greps for the literal `"Results"` (`run_tests.sh:141`) while these suites
print lowercase `results`. **Pass/fail is decided by exit code, so nothing is falsely green**
— only the visible tally under-reports. Not rowed: it is a one-word harness fix belonging to
whoever next touches `run_tests.sh`, and inventing a row for it would be noise.

**One process failure worth recording, because it destroyed data before it was caught.**
`agent-update-task.sh --depends-on` **REPLACES** the dependency list; it does not append —
`--help` says so and I did not read it first. The first three calls silently dropped one
edge from `B5-SKILLS-CONDITIONS` and **three** from `B4-PREP-MAP-DEPLOYMENT`. Caught by
reading the result back rather than trusting the `updated …: dependencies` success line, and
restored by passing the flag once per dependency. This is the same trap as
`--reference`/`--append-reference`, which was fixed by making the destructive form refuse;
`--depends-on` has no such guard.

## Next

The handoff's order continues at item 2: `REQ-LEGACY-REGISTRY-RECONCILE-2026-08-20` — re-verified
here as a clean deletion plus one test edit (`RequirementFormulaRegistry`, 0 production refs,
one reference at `test_formula_registries.gd:63`). Then item 3,
`PACK-SCHEMA-FRESHNESS-CHECK-2026-08-21`, which is the only one of the set that can be
*closed* while the round is out.

**Two things need an owner and block nothing:**

1. The `B4-IEQ-ITEMS-EQUIPMENT` → `PREP-V1-S02` edge above.
2. Whether `PREP-V1-S01` adopts `PrepActivityRegistry` or `B3-PHB-REGISTRY` shipped the
   wrong shape. Settle it **before** `S01` starts, or `S01` builds activity resolution twice.

`TEXT-V1-S01..S04` should be re-statused as built; that is a tracker edit other rows read,
so it is listed rather than done silently.
