# Session Note - 2026-08-07

## Branch context

- Branch: `agent/from-integration/v070-windows-return-triage`
- Base branch: `agent/integration`
- Base SHA: `487dafaf5ddd6332413b3bb63ab020fff3cc7c5b`
- Coordination Work ID: `V070-WINDOWS-RETURN-TRIAGE-2026-08-07`

## What was done

The v0.7.0 Windows bundle came back. Triaged it the same day it arrived, against the code
rather than against the prose — the v0.6.0 logs came back complete and then sat uninspected
while the items they answered stayed recorded as outstanding, and that is the failure this
session was written to avoid repeating.

Three artifacts:

- `AGENT/Docs/playtests/evidence/v0.7.0/` — the preserved packet. Two logs, seven
  screenshots, the completed checklist and decision sheet, `SHA256SUMS.txt`, and a README
  recording what the logs do and do not contain. The `Incoming/` folder it arrived in is
  gitignored, so this move is what stops it being the only copy.
- `AGENT/Code Reviews/playtest_v0.7.0_root_cause_review_2026-08-07.md` — findings
  `V070-01..13`, each with a file/line or a log record, and each carrying a **Disposition**
  of Fix now / Fold in / No action judged against the responsive redesign. That column was
  the point of the exercise: do not repair a surface that eleven screen conversions are
  about to rewrite.
- `AGENT/Docs/playtests/playtest_v0.7.0_windows_return_2026-08-07.md` — section results,
  the findings table, and what the return unblocks.

**Verdict: reject `6cf2c89a` as a release candidate, accept the round.** Not in tension —
the round bought the answers a container cannot produce, and found six blockers doing it.

The two most expensive findings are not UI, which was not the expected shape.

`V070-02` — `uses_mag` is absent from all 16 weapon documents in **both** packs, so
`_apply_properties` leaves `WeaponData.uses_mag` at its `false` default and every tome
computes STR−DEF instead of MAG−RES. Three layers had to line up: the extractor never emits
it, the adapter copies only present keys, and `EntitySchemaRegistry` declares the property
but requires nothing of it while it *does* cross-check `wexp_track` against `combat_family`.
Sixth instance of the silent-default shape the bundle's own display-gated document warned
about. It explains the tester's "the mage was not doing as much damage as it used to …
consistent between public and private pack" — consistent because both were projected by the
same tool.

`V070-04` — `exp_gaining_factions` is declared, serialized both ways, asserted by two suites
and rendered to the player on the Prep screen, and **read by no gameplay code**. Red units
gain EXP and level mid-battle. The log shows it in one exchange: correlation `tr-000003`,
amount 14 to one unit and 6 to another.

`V070-01` is the blocker a first-time player hits first: the default content scale is
derived from the **screen** and applied to the project-default 1280×720 **window**, so on a
4K display the main menu renders into a 427×240 logical viewport and collapses. The
screenshot is unambiguous. The correct helper already exists —
`fit_content_scale_factor_for_size` — and is used only on the web-touch path.

`V070-06` is why the round's headline question came back unanswered even though the tester
ran the test. Zero `file_dialog_escape_owned` records in either log, so the guard never took
ownership all session; and the four-stage instrumentation built specifically to identify the
winning stage routes to `TextEntrySession.observe()`, which emits an in-memory signal and
writes nothing anywhere. The instrumentation has to become observable *before* §4 is asked
again, or the next round returns the same silence.

Five reports are recorded as **no action** with reasoning, so none of them returns as a new
finding: the size-class boundary inconsistency is the 24px hysteresis working as designed,
the surviving built-in Proving Grounds is already scheduled for deletion by
`IMPL-ZERO-CONTENT-EXPORT-GATE`, and the grey bar and keyboard lockout are unreproducible.

## Commits

One commit on this branch: the evidence packet, the two documents, and the regenerated
`INDEX.md`. Everything else this session did was tracker prose on the docs line
(`agent/staging-area`), written by `agent-update-task.sh`.

## Gates

- `bash run_tests.sh` (full, via `agent-push.sh`): **all suites green**. Receipt
  `audit/check-receipts/Project_Prometheus-full.json`, tree `feebf260`.
- `python3 AGENT/Docs/check_docs.py`: **PASS**, all 43 checks, after
  `gen_docs_index.py`.
- `python3 coordination/check_tasks.py`: **OK, 346 tasks valid, no conflicts.**
- `check_gdscript_style`: PASS, 306 files unchanged (no GDScript touched).

Tracker rows updated: four closed or resolved
(`BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND`, `PP-V060-CHECKLIST-CARRYFORWARD`,
`V070-BUNDLE-EXECUTION`, plus `IMPL-CROSSING-RESOLVER`'s `[PCM-7]` answer and
`IMPL-ZERO-CONTENT-BASE-PACK`'s exit condition); seven carry a folded-in finding; two new
rows (`V070-WINDOWS-RETURN-TRIAGE-2026-08-07`, `V070-RETURN-FIXES-2026-08-07`).

**Two claim collisions surfaced and are recorded rather than worked around.**
`V070-01` lives in `SettingsManager.gd`, claimed by `IMPL-FILEDIALOG-ESCAPE-TEXTINPUT`,
which did not close — the claim the round was meant to release. `V070-04` lives in
`CombatResolver.gd`, claimed by `IMPL-FORMULA-REGISTRY-EXTENSIONS`, which is `5-backlog`
with no branch, so a release blocker is currently held behind a backlog claim. Both need an
owner call, and both are written into the rows that hold the files.

## Next

Owner decision on the two claim collisions above — that gates whether `V070-01` and
`V070-04` can be started at all.

Then, in cost order and independent of each other: `V070-02` (validator first, then the
extractor, then re-emit both packs), `V070-03`/`V070-05`/`V070-09` as a single small pass,
and the Main Menu conversion, which `SIZE-CLASS-SEAM` returning clean has unblocked and
which carries three returned owner decisions (scrollable menu, droppable title card,
safe-area-aware menu chrome).
