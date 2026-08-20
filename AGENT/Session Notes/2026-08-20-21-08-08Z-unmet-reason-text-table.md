# Session Note - 2026-08-20 (unmet-reason text table)

## Branch context

- Branch: `agent/from-integration/unmet-reason-text-table`
- Base branch: `agent/integration`
- Base SHA: `db114bbb73f4c36485d2e46f14aa4ea0b7a633a2`
- Coordination Work ID: `UNMET-REASON-TEXT-TABLE-2026-08-20`

## What was done

The owner took all five decisions the `PREP-V1-S01` unblock handoff asked for, and this
session executed the four that do not need a Windows host.

**The gate is closed.** `UNMET-REASON-TEXT-TABLE-2026-08-20` is built. A gated entry's
unmet reason now renders as a real player-facing sentence on a live surface, with tests
that assert the rendered text.

**Decision 1 — autoload, not injection.** `TextDB` is registered in `project.godot` and
loads `res://engine_data/text/en/core.json` at startup. The `class_name TextDB` was
dropped so the singleton owns that global name; nothing referenced the class name (both
consumers `preload` by path), and an autoload sharing a name with a global class is
rejected by the engine. The alternative — threading a table through every call site —
was rejected on the evidence in §4 of the handoff: "every new surface must remember X"
has already failed once in this codebase, one day after the thing to remember was ruled.

**Decision 2 — `req.*` wins.** The `B3-TEXT` fixture moved off `requirement.*`. `req.*`
is what the twelve `register_predicate` calls actually emit, so the fixture was the
cheaper side to change, and it now uses real registered keys (`req.class_level`,
`req.has_item`) with the real param name `n` — it demonstrates the live convention
instead of one nothing else uses.

**Decision 3 — the portfolio review is closed as superseded, not run.**
`REVIEW-ACCEPTED-PORTFOLIO-CODE-STATE-2026-07-27` → `completed`, with the successor
`PORTFOLIO-CODE-STATE-REVIEW-REBASELINED-2026-08-20` carrying deliverables 1–3
re-baselined and dropping the first-tranche readiness verdict. **All four direct
dependency edges were repointed** (`UIREC-V1-S01`, `PREP-V1-S01`, `TEXT-V1-S01`,
`DRC-V1-S00`), which is the half that makes the closure honest — closing the row alone
would have marked a dependency satisfied that was never performed.

**Decision 5 — the durable fix has a row.** `AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20`,
with the design question (shared availability-list builder vs. a check that a `disabled`
`BaseButton` carries a reason) left deliberately open.

**The second migration site was migrated, not left.** `CampaignManager._overworld_unmet_reason`
phrased its reasons as hardcoded English *because the shared table was empty* — a
documented stopgap. It now reads three `overworld.node.*` keys through the same table, so
one kind of string has one convention. This is also what gives the row a live consumer,
which matters: the re-scope document's §3.2 finding is that `RequirementSystem` itself
shipped a green suite and an API with **no production callers**, reproducing the exact
property it was built to cure. A text table with no consumer would have been the third
instance in the same area.

## Commits

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

`291a981c` is the whole build: the engine table, the autoload registration, the
idempotent `_ready()`, the lazy `/root/TextDB` resolution inside `render_reason`, the
`all_text_keys()` accessor, the overworld migration, the fixture prefix change, and the
two GDD updates (DoD#1).

## Gates

- `bash run_tests.sh` — **PASS: all suites green** (run twice: once by hand, once by
  `agent-commit.sh`'s fast command).
- `test_text_db` — 4 passed → **7 passed, 0 failed**.
- `test_overworld_screen` — 10 passed → **11 passed, 0 failed**.
- `bash scripts/ci/check_gdscript_style.sh` — PASS, 335 files.
- `python3 AGENT/Docs/check_docs.py` — PASS, all 46 checks.

### The test hazard, and how the assertions were shaped around it

The handoff's §1.4 warning is real and both fallbacks were exercised during the build.
`render_reason` with no table returns the bare key (`req.flag`); `TextDB.tr_key` returns
`#missing:req.flag`. **Both are non-empty and both look like strings a UI would produce**,
so every "is it non-empty?" assertion passes whether or not the table was consulted.

Three assertions were written against the rendered text instead:

1. `test_text_db` walks `RequirementSystem.all_text_keys()` and fails a key whose
   rendering equals the key itself or begins with `#missing:`. This is what stops the
   vocabulary drifting: adding a predicate adds two keys, and nothing else notices.
2. `test_text_db` asserts a reason renders as `"Requires the seal."` with **no table
   threaded through**, which is the only assertion that proves the autoload seam works.
3. `test_overworld_screen` gained a rendered-sentence assertion beside its existing
   `tooltip_text != ""` check — which is itself an instance of the vacuous shape, and was
   left in place with a comment explaining why it is insufficient on its own. The
   assertion pins the interpolated label (`"Clear Chapter 2 - Take the Throne first."`)
   so a table hit that dropped its params would still fail.

Assertion 3 was **negative-checked by accident and it earned its keep**: the first draft
asserted the wrong sentence and failed with the real one, which is how the `{node}`
substitution was confirmed to work end to end rather than assumed.

### A harness fact worth recording

Inside a `SceneTree` script's `_init()`, **the root `Window` is not yet inside the tree**:
`root.is_inside_tree()` is `false`, `root.get_path()` is empty, absolute lookups like
`get_node_or_null("/root/TextDB")` return `null`, and queued `_ready()` calls have not
run. `await process_frame` is therefore load-bearing for any test of autoload wiring, not
ceremony — a test written without it measures the harness rather than the wiring, and the
first draft of assertion 2 did exactly that and reported a bare key.

Related: a GDScript runtime error inside `_init()` aborts before `quit(1)` and the suite
**exits 0**. The first run of `test_text_db` printed `SCRIPT ERROR ... Invalid access of
index '0'` and was reported as a pass by exit code. Read the output, not the status.

## Next

The batched native-host trip is now worth taking, and the ordering argument in the
handoff's §2 has been discharged: `[ANN-5]` ("does a Windows screen reader already
announce `tooltip_text`?") would previously have tested the announcement path against
`req.has_item`, a string no player will ever hear. It now tests real sentences.

Two things to re-check before booking it:

- The tracker shows roughly **eleven** open rows wanting a native host, a screen reader,
  or a visual pass — not the four the control plane names. Re-read that list first.
- `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17`'s native keyboard/controller pass is that
  row's sole remaining item and belongs in the same trip.

`PREP-V1-S01` is startable once the host trip closes `SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19`,
and it builds a gated surface — until `AVAILABILITY-SURFACE-GATE-GUARD-2026-08-20` lands,
check by hand that its gated entries stay focusable and take their reason from the
availability authority rather than phrasing it in the screen (`[EPUX-04]`).

### Claim collision to disclose

`scripts/autoloads/CampaignManager.gd` and `scripts/tests/test_overworld_screen.gd` are
claimed by `DESIGN-OVERWORLD-CADENCE-2026-07-25`, which is `in_review` and already merged
(`0da644f9`). Both files were edited here anyway: that row's open residues are the
`hours_played` producer and the requirement-context widening, neither of which touches
`_overworld_unmet_reason` or the overworld screen's reason assertions. Flagged rather
than assumed away.

### Known limitation in the shipped table

The threshold predicates (`class_level`, `proficiency`, `stat`) carry an `op` param with
six possible values, and the fallback sentences are phrased for the default (`gte`) —
`"Requires level {n} or higher."` reads wrong for an `lt` requirement. Authors have
`presentation.override_text_key` for precision today. Making the fallback op-aware means
either injecting a rendered comparator into the reason params or splitting each key by
op; neither was in this row's scope. `req.compare` deliberately carries **no**
placeholders at all, because its params are nested formula objects and `tr_key`
substitutes with `str()` — a `{left}` placeholder would print a GDScript literal on
screen, which is the same defect as the prep rules summary (V070-10).
