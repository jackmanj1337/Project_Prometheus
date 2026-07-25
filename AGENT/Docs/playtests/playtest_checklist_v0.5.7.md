# v0.5.7 Windows Verification Checklist

**Status:** Ready for Windows playtest after bundle metadata is filled  
**Date:** 2026-07-25  
**Return this completed checklist, all Godot logs, and screenshots together.**

## Bundle integrity

- [ ] `Project_Prometheus_v0.5.7_debug.exe` matches `SHA256SUMS.txt`.
- [ ] Main Menu shows `v0.5.7`; the startup BUILD STAMP matches `BUILD_INFO.txt`.
- [ ] `two-map-skirmish-1.0.zip` and `branching-skirmish-1.0.zip` are present.

## 1. Branching Results state and map identity

Import `branching-skirmish-1.0.zip`. Win Crossroads, then repeat this section
twice: once choosing River Pass and once choosing Ridge Pass.

- [ ] Results initially says **Choose the next chapter…**; Continue and Save are
      disabled until a real branch is selected.
- [ ] Reopening Results never retains the branch selected on the previous visit.
- [ ] River Pass is unmistakably the river crossing map.
- [ ] Ridge Pass is unmistakably a mountain-switchback map with four Ridge Guards;
      it is not a recolor or near-copy of River Pass.
- [ ] Saving after each selection and loading it launches the selected map only.

At 200% Menu Scale, populate Results with long reward/casualty/progression text.

- [ ] The summary scrolls independently; branch selector and all action buttons
      remain visible, readable, non-overlapping, and controller-reachable.
- [ ] OptionButton borders remain intact (no stretched or sliced corners).

## 2. Package save validation

Import `two-map-skirmish-1.0.zip`, play into the campaign, save between maps, return
to shipped content, and load the save both before and after restarting the exe.

- [ ] Both ordinary slot loads activate the saved package catalogue for validation,
      then restore the previously selected catalogue without a false missing-item error.

Close the game, temporarily move the imported package out of its installed folder,
restart, and try the same slot. Restore the package after this check.

- [ ] The load fails with a clear missing-package message, does not partially restore
      the campaign, and leaves shipped content selected and usable.

## 3. FileDialog input ownership

Open each campaign/save import or export FileDialog and focus its filename field.

- [ ] X/Z and mapped Confirm/Cancel characters type normally in the filename.
- [ ] First physical Escape removes filename focus and focuses the file list; the
      dialog remains open.
- [ ] Second physical Escape closes the dialog.

## 4. Controller hot-plug telemetry

Start once with the controller disconnected, then perform this exact sequence while
watching prompts: connect → use controller → disconnect → use keyboard → reconnect →
use controller.

- [ ] Prompts switch keyboard → controller → keyboard → controller.
- [ ] The returned log contains `PLAYTEST CONTROLLER` records for initial enumeration
      when applicable and for every connection transition, including
      `connected=true`, then `connected=false`, then `connected=true`.
- [ ] Disconnect records retain the controller name/GUID and no stale active-pad state
      remains after disconnect.

**A missing transition in the log is a failure even if prompts appeared correct.**

## 5. Logging and focused regression

- [ ] No `[V030 TRACE]` lines or v0.3.0 resize trace file are produced.
- [ ] BUILD STAMP, runtime environment, `PLAYTEST CONTEXT`, and controller telemetry
      remain present.
- [ ] Retry after Save preserves the advanced save while retrying the completed map.
- [ ] Results, Defeat, Rewind, Prep, FileDialogs, and dropdowns move exactly one item
      per controller press with no focus behind a modal.

## Return

Record PASS/FAIL beside every item, exact reproduction steps for failures, controller
model, Windows version, display resolution/scaling, and Menu Scale. Return the
completed checklist, current `godot.log`, rotated timestamped logs, and relevant
screenshots/save artifacts in one folder.
