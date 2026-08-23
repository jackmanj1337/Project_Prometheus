---
Role: dated
Type: playtest
Status: Planned - ready for returned v0.3.1 evidence
Last verified: 2026-07-12
---

# v0.3.1 Focused-Rerun Return Triage Kit - 2026-07-12

## Scope

Use this kit when the completed v0.3.1 handbook, logs, and screenshots return.
This is an intake/routing pass first; do not edit production code until the
evidence is preserved and each failure has a distinct issue row.

Expected vehicle:

- Handbook: `playtest_checklist_v0.3.1.md`
- Build manifest: `playtest_build_v0.3.1.md`
- Expected source stamp: `c7ce311`
- Expected SHA-256:
  `ac4b079a5fdde815823f0c6c6fe883a1e23f59792fe66d4b761995bdb1205332`
- Gates: `VAL-V030-GAMEPAD`, `VAL-V023-DISPLAY`
- Presentation decision: `[MRD-7]`
- Regression check: `B1-SUSPEND`

## Intake Procedure

1. Copy the tester-edited handbook to
   `AGENT/Docs/playtests/playtest_checklist_v0.3.1_returned_YYYY-MM-DD.md`.
2. Preserve tester wording and checkboxes. Add front matter:

```markdown
---
Type: playtest
Status: Returned results - triaged in `playtest_v0.3.1_results_triage_plan_YYYY-MM-DD.md`
Last verified: YYYY-MM-DD
---
```

3. Move returned artifacts into `AGENT/Docs/archive/evidence/` using stable names:
   - `godot_log_v0.3.1_<launch>_returned_YYYY-MM-DD.log`
   - `v031_<short_issue_name>_YYYY-MM-DD.png`
   - `v031_build_stamp_YYYY-MM-DD.txt` when the stamp arrives separately.
4. Verify every available BUILD STAMP says version `0.3.1` and commit
   `c7ce311`. Verify the executable hash if the tester recorded it. Treat a
   wrong stamp/hash as `V031-LOG-01` before interpreting behavior.
5. Create
   `AGENT/Docs/playtests/playtest_v0.3.1_results_triage_plan_YYYY-MM-DD.md`.
6. Run `python3 AGENT/Docs/gen_docs_index.py` after adding the returned checklist,
   evidence references, or triage plan.

## Results-Triage Document Order

1. **Scope and evidence** - returned paths, environment, controller, monitor,
   Menu Scale, stamp/hash, missing artifacts.
2. **Findings first** - state both gates, MRD-7 choice, and Suspend regression
   result before proposing fixes.
3. **Issue workstreams** - one id per distinct failure, with exact repro,
   expected/actual, evidence paths, likely owner, and whether a headless repro
   is credible.
4. **Gate routing** - exact control-plane and `GDD_10` status changes.
5. **Sequencing** - fixes/tests/docs, diagnostic cleanup, and whether another
   focused build is actually required.

## Issue Buckets

| ID | Use for |
|---|---|
| `V031-GP-01` | Settings/modal repeat, focus scrolling, or capture-mode leakage. |
| `V031-GP-02` | New Game focus containment or `V030-NG-FOCUS` evidence. |
| `V031-GP-03` | Left-stick attack/Pair Up target cycling or repeat cadence. |
| `V031-GP-04` | LT/RT sensitivity, threshold, or zoom repeat feel. |
| `V031-INP-01` | Wrong last-active-pad prompt brand or physical mapping. |
| `V031-DSP-01` | One-axis edge drag/readout failure; preserve `V030-DSP-TRACE`. |
| `V031-DSP-02` | Maximize/un-maximize label or saved-size behavior. |
| `V031-MRD-01` | `stacked_perimeter` readability, retained overlays, or no acceptable candidate. |
| `V031-SUS-01` | Suspend/Continue regression in DONE, Pair Up, turn, or relaunch state. |
| `V031-REG-01` | Unrelated regression not already tracked in handbook section 7. |
| `V031-LOG-01` | Missing/wrong build stamp, hash, logs, or evidence provenance. |

Do not reopen cursor-traced pathing (`[MRD-8]`), Main Menu 2.0x overlap
(`UI-INSPECTION`), or controller sensitivity sliders (`B6-INPUT`) unless the
return shows behavior worse than the already-recorded request.

## Gate Routing

### `VAL-V030-GAMEPAD`

Close only when handbook sections 1-3 pass on real hardware: modal repeat and
capture containment, New Game focus containment, and d-pad/left-stick targeting.
Trigger feel may close as an accepted default or remain a clearly-scoped
`B6-INPUT` tuning note; a softlock, missing target input, or escaping modal focus
keeps the gate open.

On pass: mark the validation row `Implemented`, record hardware/controller and
v0.3.1 evidence, and remove `V030-NG-FOCUS` diagnostics in the release-cleanup
commit. On failure: keep `Pending validation`, create one `V031-GP-*` row per
defect, and preserve the failing launch log.

### `VAL-V023-DISPLAY`

Close only when handbook section 4 proves two-axis and both one-axis edge drags,
`Maximized (WxH)`, restore behavior, and relaunch persistence on Windows.

On pass: mark the row `Implemented` and remove `V030-DSP-TRACE` diagnostics in
the release-cleanup commit. On failure: keep `Pending validation`, split
one-axis detection (`V031-DSP-01`) from maximize/persistence
(`V031-DSP-02`), and inspect the trace before changing code.

### `[MRD-7]`

Record the tester's selected mode and evidence. If `stacked_perimeter` is
accepted, make it the default and remove the temporary F8 cycle in the same
release-cleanup stream. If another existing mode wins, record that choice and
remove unused prototype paths only after confirming no other overlay consumer
depends on them. If none wins, keep `[MRD-7]` pending and do not guess from
headless rendering.

### `B1-SUSPEND`

Keep its implemented/live-validated status if section 6 passes. A regression
gets `V031-SUS-01`, blocks release cleanup, and routes back to `B1-SUSPEND` with
the returned save/log evidence.

## Next-Session Checklist

- [ ] Returned handbook copied without rewriting tester comments.
- [ ] Logs/screenshots archived and referenced.
- [ ] Version, commit stamp, and hash checked before behavioral triage.
- [ ] Findings-first summary states both gates, MRD-7, and Suspend.
- [ ] Distinct failures have distinct `V031-*` ids.
- [ ] Control-plane and `GDD_10` rows updated only from live evidence.
- [ ] Passing diagnostics/F8 aids routed to one release-cleanup commit.
- [ ] Any behavior-changing fix updates the owning GDD section and roadmap row.
- [ ] Generated docs index refreshed and documentation checks green.

## Stop Conditions / Owner Decisions

Ask before cutting another build if the return is incomplete enough that the
gate result depends on missing hardware evidence, or if multiple acceptable
MRD modes are returned without a clear preference. Otherwise preserve evidence,
diagnose each failure headlessly where credible, and propose the smallest
focused rerun.
