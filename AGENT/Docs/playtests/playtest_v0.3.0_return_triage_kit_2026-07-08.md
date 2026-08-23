---
Role: dated
Type: playtest
Status: Implemented - return intake executed 2026-07-08; results in `playtest_v0.3.0_results_triage_plan_2026-07-08.md`
Last verified: 2026-07-08
---

# v0.3.0 Playtest Return Triage Kit - 2026-07-08

## Scope

This is the intake and routing shell for the v0.3.0 playtest return. The build is
already cut; do not change the shipped `Project_Prometheus_v0.3.0_debug.exe`
unless returned evidence proves a new rerun build is needed.

Primary evidence:

- Build manifest: `playtest_build_v0.3.0.md`
- Live handbook: `playtest_checklist_v0.3.0.md`
- Validation gates:
  - `VAL-V030-GAMEPAD`: handbook Part I, plus Part VIII high-attention controller
    regressions.
  - `VAL-V023-DISPLAY`: handbook Part VII item 11 only.

## Returned Checklist Copy Pattern

When the tester returns the pass:

1. Save the edited checklist as
   `AGENT/Docs/playtests/playtest_checklist_v0.3.0_returned_YYYY-MM-DD.md`.
2. Preserve tester wording, checked boxes, timestamps, and inline comments. Add a
   short returned-evidence note near the top only if the tester supplied separate
   screenshots, logs, or environment details.
3. Add this front matter at the top of the returned checklist:

```markdown
---
Type: playtest
Status: Returned results - triaged in `playtest_v0.3.0_results_triage_plan_YYYY-MM-DD.md`
Last verified: YYYY-MM-DD
---
```

4. Move evidence into `AGENT/Docs/archive/evidence/` with stable names:
   - `godot_log_v0.3.0_returned_YYYY-MM-DD.log`
   - `v030_<short_issue_name>_YYYY-MM-DD.png`
   - `v030_<short_issue_name>_YYYY-MM-DD.txt` for pasted console/build-stamp text
5. Regenerate `AGENT/Docs/INDEX.md` after adding the returned checklist or any
   triage doc.

## Triage Plan Skeleton

Create or update:

`AGENT/Docs/playtests/playtest_v0.3.0_results_triage_plan_YYYY-MM-DD.md`

Use this section order:

1. **Scope** - returned checklist path, build manifest, source commit, tester
   environment, controller models, screenshots, and logs.
2. **Findings First** - gate state first, then highest-risk regressions.
3. **Workstreams** - one issue ID per distinct problem. Do not mix unrelated
   failures in one workstream.
4. **Gate Routing** - exact status updates for `VAL-V030-GAMEPAD`,
   `VAL-V023-DISPLAY`, and any follow-on release rows.
5. **Sequencing** - owner questions, fixes, tests, docs, rerun build if needed.

Use these issue-ID buckets unless a better local name is obvious:

| Bucket | Use for |
|---|---|
| `V030-GP-01` | Wrong controller mapping, missing button, confirm/cancel mismatch. |
| `V030-GP-02` | Stick deadzone, drift, diagonal jitter, repeat cadence. |
| `V030-GP-03` | Held LT/RT zoom feel, trigger sensitivity, zoom clamps. |
| `V030-GP-04` | R3/View/Start comfort, focus visibility, overlay/menu overlap. |
| `V030-INP-01` | Input Mode row, disabled Touch state, Auto/explicit persistence. |
| `V030-INP-02` | Prompt swapping, live refresh, non-Xbox printed labels. |
| `V030-REB-01` | Keybind rows, staging/apply, conflict blocking, reset/persistence. |
| `V030-SUS-01` | Suspend/Continue state, relaunch resume, clear-on-map-end. |
| `V030-MRD-01` | Threat overlay, watch markers, peek range, path arrows, terrain dim. |
| `V030-RNG-01` | Fresh-map RNG startup, repeated outcomes, combat hit-feel defects. |
| `V030-DSP-01` | Windowed custom-size readout / `client WxH` / `Custom (WxH)`. |
| `V030-DSP-02` | Windows maximize/un-maximize centering and saved-size behavior. |
| `V030-REG-01` | Other broad feature-sweep regression. |
| `V030-LOG-01` | Missing log, bad build stamp, wrong exe/hash, dirty evidence. |

## Gate Routing Rules

### `VAL-V030-GAMEPAD`

Close this validation row only if all of these are true:

- Part I items 1-5 pass on real controller hardware.
- Any non-Xbox label note is cosmetic only: the printed label may be wrong, but
  the physical button still performs the intended action.
- No controller-only softlock, repeated double input, or focus trap is reported
  in Part VIII.

If it passes, update `project_control_plane_2026-06-29.md`:

- `VAL-V030-GAMEPAD` status: `Implemented`
- next action: live controller validation passed on v0.3.0; remaining input
  expansion, if any, stays under `B6-INPUT`.

If it fails, keep `VAL-V030-GAMEPAD` as `Pending validation`, write one
`V030-GP-*` or `V030-INP-*` workstream per failure, and cut a focused rerun only
after the fixes and automated coverage land.

### `VAL-V023-DISPLAY`

Close this validation row only if handbook Part VII item 11 passes on real
Windows hardware:

- drag-resize writes a sensible `client WxH` / `Custom (WxH)` value,
- no bogus second applied size is shown for a custom client size,
- maximize keeps Settings centered at normal and high Menu Scale,
- un-maximize restores the chosen windowed size instead of saving the maximized
  client size.

If it passes, update `project_control_plane_2026-06-29.md`:

- `VAL-V023-DISPLAY` status: `Implemented`
- next action: display gate closed on v0.3.0; proceed to `REL-V023-MERGE` and
  schedule `B6-WEB-DEBUG` as appropriate.

If it fails, keep `VAL-V023-DISPLAY` as `Pending validation`, diagnose under
`V030-DSP-01` and/or `V030-DSP-02`, and cut a section-1.6-only rerun build after
the fix.

### Non-Gate Failures

Do not block either validation gate for unrelated feature-sweep notes unless the
failure also invalidates that gate's checklist item. Route non-gate failures to
the owning rows:

| Failure area | Control-plane home |
|---|---|
| Keybind/prompt/input mode issue outside the real-controller gate | `B6-INPUT` |
| Suspend/Continue state issue | `B1-SUSPEND` / `B1-CST` |
| Threat/readability issue | `B6-MRD` |
| Combat hit/RNG issue | `B1-PKGA` or `B3-COMBAT-ROLL-RESOLVER` |
| Aspect ratio / black bars / Steam Deck viewport policy | `UI-VIEWPORT-ASPECT` |
| Broad UI clipping/polish | `UI-INSPECTION` |

## Return Triage Checklist

- [x] Returned checklist copied with front matter.
- [x] Screenshots/logs moved into `AGENT/Docs/archive/evidence/`.
- [x] Build hash/source stamp verified against `playtest_build_v0.3.0.md`
  (all BUILD STAMPs read commit `7b23412`).
- [x] `godot.log` BUILD STAMP pasted or logged as missing (archived logs carry
  the stamps; the returned checklist's 12.3 paste slot was left empty by the
  tester, covered by the attached logs).
- [x] Findings First section written before fix recommendations.
- [x] Gate routing recorded for both validation rows.
- [ ] Any behavior-changing fix updates the owning GDD section and control-plane
  row in the same commit. (No fixes landed at intake time; applies to the
  upcoming `V030-*` fix passes.)
- [x] `python3 AGENT/Docs/gen_docs_index.py` run after doc additions/renames.
- [x] `python3 AGENT/Docs/check_docs.py` passes before commit.

## Immediate Next Step

Intake executed 2026-07-08. Continue in
`playtest_v0.3.0_results_triage_plan_2026-07-08.md` (fix sequencing) and
`AGENT/Code Reviews/playtest_v0.3.0_triage_review_2026-07-08.md` (owner Q1-Q5).
