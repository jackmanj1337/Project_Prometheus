---
Role: dated
Type: code review
Status: Fix implemented - pending focused rerun
Last verified: 2026-07-16
---
# v0.4.1 Playtest Triage

## Result

The exact `66e1973` artifact identity passed. Sections 1-7 passed on Windows,
including controller operation, combat projection, reward deduplication and totals,
victory-modal cursor blocking, suspend/continue, display scaling, More Info scrolling,
and release-facing skill-choice filtering.

The release gate remains pending because ordinary combat produced six warnings for
release-unavailable skill stubs: `bastion`, `iron_wall`, `armsthrift`,
`indoor_fighter`, `dash`, and `rally_skill`. There were no crashes, script errors,
assertions, registry failures, missing resources, or leaks.

The promotion-validation map correctly has no victory reward. The checklist's
`Before: 800 / Award: 0 / After: 0` notation is internally inconsistent, but the
tester separately confirmed the rewarded Rout map awarded 500 gold and the results
screen screenshots prove `0 / 800` and `500 / 1300`. This is a test-recording issue,
not a resource-ledger defect.

The Rout screenshot also captures the victory panel's title, standings, and buttons
clipped at its top/left edges, unlike the validation-map screenshot. The checklist does
not identify this as a failure or provide the active Menu Scale/reproduction sequence,
so the evidence is insufficient for a safe layout change. Treat it as a focused visual
recheck, not a confirmed code defect.

## Diagnosis and fix

`release_available = false` filtered player-facing class-choice prose but legacy and
test-map unit loadouts remained intentionally loadable. `SkillHandler` still dispatched
those equipped records, reaching `_apply_unimplemented` and warning once per skill.

`SkillHandler._execute_skill` now returns before dispatch for release-unavailable
skills. This preserves map/save compatibility while keeping deferred effects inert and
quiet. `test_skill_release_availability` now proves no mutation and no warning record.

## Verification

- Focused skill-release test: 2 passed, 0 failed.
- Full project run: all 76 suites green.

## Remaining gate

Run a narrow Windows combat/preview pass on the promotion-validation map and confirm
that no `SkillHandler._apply_unimplemented` warning appears. Also reproduce the Rout
result at the tester's active Menu Scale and verify the panel is fully visible after it
settles; capture the scale and steps if clipping persists. No other v0.4.1 behavior
needs repair from this return.
