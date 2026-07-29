---
Type: playtest
Status: Triaged - focused release-smoke rerun required
Last verified: 2026-07-16
---

# v0.4.0 Playtest Results and Root-Cause Triage

## Outcome and evidence

The returned checklist is preserved as
[`playtest_checklist_v0.4.0_returned_2026-07-15.md`](playtest_checklist_v0.4.0_returned_2026-07-15.md).
Its byte-for-byte original and both logs are preserved under
`AGENT/Docs/archive/evidence/`:

- `playtest_checklist_v0.4.0_d12eb33_returned_raw_2026-07-15.txt`
- `godot_v0.4.0_d12eb33_session_2026-07-15.log`
- `godot_v0.4.0_d12eb33_session_2026-07-15T15.38.54.log`

The duplicate returned build manifest exactly matches the tracked manifest
(SHA-256 `a1a9b287...40987`). All six BUILD STAMP records match version `0.4.0`,
commit `d12eb33`, build time `2026-07-14T07:01:49Z`, and the expected executable
name. The complete logs contain no crash, script error, assertion,
registry/resource failure, transaction failure, or repeated release-blocking
error. One rotated session contains the expected suppressed warning for the
deferred M9 `armsthrift` stub; it is not a v0.4.0 release blocker.

| Area | Returned result | Disposition |
|---|---|---|
| Build identity | Partial | BUILD STAMP and filename pass; size and SHA-256 were not checked |
| Boot/menu | Pass | Accepted for this artifact |
| Tactical map/input | Pass | Keyboard, mouse, and Xbox controller accepted |
| Attack Preview/combat | Pass | Accepted for this artifact |
| Victory gold | Not run / unsupported | Release blocker remains open; focused rerun required |
| Suspend/Continue | Pass | Accepted; non-blue-turn suspend request is deferred policy work |
| Settings/display | Pass | Character-sheet scrolling note goes to later UX validation |
| Log | Pass with known warning | No release-blocking log fault found |

The return is not a PASS. It left the final result blank, did not return the
requested artifact size/hash, screenshots, or exact reproduction steps, and left
all four victory assertions unchecked. Missing evidence is not converted into a
pass.

## `V040-UI-01` - party gold is not discoverable in the tested UI

The tester could not locate party gold, so they could not record the before,
award, or after values required to prove the ledger-backed victory award. This
is both a discoverability finding and a test-procedure blocker. Do not infer that
the award failed: the return contains no measured totals or reproduction showing
an incorrect transaction.

For the focused rerun, identify the exact existing party-gold surface in the
instructions, or add a temporary read-only diagnostic if no player-facing
surface exists. Record before/award/after values and prove that reopening menus
does not duplicate the award. Product work to expose party gold permanently
should be decided separately from the release-smoke evidence fix.

## `V040-UI-02` - victory overlay does not capture map-cursor input

The tester reports that keyboard and gamepad still move the map cursor while the
victory screen is visible. Treat this as a confirmed modal-input defect, but the
return lacks the requested map, exact action sequence, screenshot, and relaunch
reproduction. Diagnose the victory modal's input/cursor-lock ownership and add a
regression test before changing runtime behavior. Recheck this in the focused
rerun alongside victory gold.

## Routed observations

- Allowing suspend during non-blue turns is a future campaign/policy request,
  not a defect against this checklist's suspend contract.
- Character-sheet More Info scrolling received no failure report or requested
  evidence. Carry it into the next broad UI/scale playtest.
- No screenshots were present despite the checked screenshot assertion. This is
  an evidence-packaging miss.

## Next work

1. Diagnose and repair `V040-UI-02` with focused automated coverage.
2. Make the existing party-gold value testable and write exact rerun steps.
3. Run a narrow Windows rerun on the next exact artifact: filename, byte size,
   SHA-256, BUILD STAMP, victory transition, before/award/after gold, duplicate
   award guard, victory-modal cursor lock, and a clean original log.
4. Close the v0.4.0 smoke gate only when every rerun assertion has evidence.
5. Keep this `d12eb33` smoke separate from later campaign/save builds.
