# v0.5.8 Windows Verification Checklist

**Status:** Ready after bundle metadata is filled
**Date:** 2026-07-28
**Return this completed checklist, all Godot logs, and screenshots together.**

v0.5.8 replaces rejected v0.5.7. Its focused code change accepts valid explicit
directory entries in campaign ZIPs while retaining the single-package-root boundary.

## Bundle integrity and import blocker

- [ ] `Project_Prometheus_v0.5.8.exe` matches `SHA256SUMS.txt`.
- [ ] Main Menu shows `v0.5.8`; startup BUILD STAMP matches `BUILD_INFO.json`.
- [ ] Import the bundled `two-map-skirmish-1.0.zip` successfully.
- [ ] Import the bundled `branching-skirmish-1.0.zip` successfully.
- [ ] Neither import reports a package-root or directory-entry error.

If either bundled pack fails to import, stop and return the log plus the exact ZIP;
the replacement build is rejected.

## 1. Branching Results state and map identity

Win Crossroads in `branching-skirmish-1.0`, then repeat once choosing River Pass
and once choosing Ridge Pass.

- [ ] Results requires a real branch selection before Continue or Save.
- [ ] Reopening Results does not retain the previous branch selection.
- [ ] River Pass is the river crossing and Ridge Pass is the mountain switchback.
- [ ] Saving after each choice loads only the selected map.
- [ ] At 200% Menu Scale, the summary scrolls while branch controls remain visible.
- [ ] OptionButton borders remain intact.

## 2. Package save validation

In `two-map-skirmish-1.0`, save between maps and load before and after restarting.

- [ ] Ordinary loads activate the saved package for validation and restore the
      previously selected catalogue without false missing-item errors.
- [ ] Temporarily removing the installed package produces a clear failure without
      partial campaign restoration; restoring it makes the package usable again.

## 3. FileDialog input ownership

- [ ] X/Z and mapped Confirm/Cancel characters type normally in filename fields.
- [ ] First physical Escape removes filename focus but keeps the dialog open.
- [ ] Second physical Escape closes the dialog.

## 4. Controller hot-plug telemetry

Perform connect -> use -> disconnect -> keyboard -> reconnect -> use.

- [ ] Prompts switch keyboard -> controller -> keyboard -> controller.
- [ ] The log records each connection transition, including true/false/true.
- [ ] Disconnect records retain controller identity and clear stale active-pad state.

## 5. Logging and focused regression

- [ ] No `[V030 TRACE]` lines or v0.3.0 resize trace are produced.
- [ ] BUILD STAMP, runtime environment, `PLAYTEST CONTEXT`, and controller telemetry remain.
- [ ] Retry after Save preserves the advanced save while retrying the completed map.
- [ ] Results, Defeat, Rewind, Prep, FileDialogs, and dropdowns move once per press.

## Return

Record PASS/FAIL beside every item, reproduction steps for failures, controller
model, Windows version, display resolution/scaling, and Menu Scale. Return the
completed checklist, current and rotated Godot logs, and relevant screenshots/save
artifacts together.
