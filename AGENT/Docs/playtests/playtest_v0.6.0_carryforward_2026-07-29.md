# v0.6.0 Playtest Carry-Forward Requirements

**Raised:** 2026-07-29, from the v0.5.8 owner return
**Source:** `playtest_v0.5.8_owner_return_2026-07-29.md`
**Status:** requirements only — the v0.6.0 checklist does not exist yet

v0.5.8 was accepted as the stable v0.5 release with three checklist areas
unresolved. When the v0.6.0 checklist is written, it **must** carry all three.
None of them has ever been verified on Windows: they have now slipped through
the v0.5.6, v0.5.7, and v0.5.8 cycles.

## 1. Controller hot-plug telemetry (carried, never collected)

Carry §4 of the v0.5.8 checklist forward verbatim. The critical part is that a
missing log record is a failure even when the on-screen prompts look right:

- Sequence: connect → use controller → disconnect → use keyboard → reconnect →
  use controller.
- Prompts switch keyboard → controller → keyboard → controller.
- The log records **every** connection transition: `connected=true`, then
  `connected=false`, then `connected=true`.
- Disconnect records retain controller name/GUID; no stale active-pad state
  survives a disconnect.

## 2. Logging and telemetry evidence (carried, never collected)

Carry §5's telemetry items:

- No `[V030 TRACE]` lines and no v0.3.0 resize trace file.
- BUILD STAMP, runtime environment, `PLAYTEST CONTEXT`, and controller
  telemetry all present in the returned log.

**The return must include the log bundle.** These items cannot be satisfied by a
verbal return; that is why they have gone uncollected three cycles running.

## 3. Cancel/Escape input ownership (carried, still failing)

§3 failed again on Windows in v0.5.8: the first physical Escape closes the whole
FileDialog instead of dropping filename focus to the file list. Per owner
decision this is **not** fixed on the release line — the fix belongs to the
text-input feature set (see below) — but v0.6.0 must verify it:

- X/Z and mapped Confirm/Cancel characters type normally in filename fields.
- First physical Escape removes filename focus, dialog stays open.
- Second physical Escape closes the dialog.

Add the related latent defect while a real pad is in hand:
`project.godot` `[input]` binds `confirm=joy(1,0)` and `cancel=joy(2,1)`, so
joypad button 1 is bound to both accept and back
(`BACKLOG-INPUTMAP-CONFIRM-CANCEL-DOUBLEBIND-2026-07-24`).

---

# FileDialog Escape defect brief — for the text-input implementation plan

The next feature set updates text input. The Escape fix must be designed into
that plan rather than bolted onto the release line. What follows is what was
verified on `agent/playtest-release-v0.5.8-fixes` at `bd6b5adb` on 2026-07-29,
separated from what is still hypothesis.

## Symptom

On Windows, with the FileDialog's filename field focused, the first physical
Escape closes the entire dialog window. Expected: first Escape releases filename
focus and moves focus to the file list, dialog stays open; second Escape closes.

## Verified

- **The guard is attached everywhere it should be.** All five FileDialog nodes
  carry `FileDialogInputGuard.gd`: `CampaignLibraryScreen.tscn`
  (ImportDialog, ExportDialog), `LoadGameScreen.tscn` (ImportDialog,
  ExportDialog), `NewGameScreen.tscn` (StatusImportDialog). An unguarded dialog
  is *not* the cause.
- **The focus-owner check resolves to the right viewport.** Measured on Godot
  4.6.3: once a `FileDialog` is inside the tree, `fd.get_viewport()` returns the
  FileDialog itself (`Window` is a `Viewport`), and `line_edit.get_viewport()`
  returns the same object. So `get_viewport().gui_get_focus_owner()` at
  `scripts/ui/FileDialogInputGuard.gd:66` does query the dialog's own viewport
  and does return the filename `LineEdit` when it holds focus. This was a
  plausible root cause and it is ruled out.
- **Subwindows are embedded.** `display/window/subwindows/embed_subwindows` is
  `true` (project default, not overridden), so the dialog is an embedded window
  inside the main viewport, not a native OS window. `project.godot` sets no
  native-file-dialog options, so the guard's script is in the input path.
- **The regression test cannot catch this class of failure.**
  `scripts/tests/test_settings_manager.gd:887` exercises the first-Escape case
  by calling the handler directly — `dialog.call("_on_window_input", escape)` —
  with a comment (line 886) explaining that a dispatched global Escape races
  other headless suites' windows. The test therefore proves the handler *body*
  is correct and proves nothing about whether a real Escape ever *reaches* it.
  A green suite alongside a failing Windows return is exactly the expected
  outcome of that gap.

## Not yet determined

The guard installs three interception points — `window_input` (line 10/13),
`_input` (line 18), `_shortcut_input` (line 53). Something on Windows closes the
window before any of them consumes the event, or the filename field does not
actually hold focus at the moment Escape arrives. Candidates to test on Windows,
cheapest first:

1. Whether the filename `LineEdit` genuinely has focus when the dialog opens —
   if focus starts on the file list, the guard correctly no-ops and the built-in
   close is the observed behaviour. This would make it a focus-initialisation
   bug, not an input-arbitration bug.
2. Whether `window_input` fires at all for an **embedded** subwindow, or only
   for native ones. The `_ready` comment assumes it fires first; that assumption
   is untested for the embedded case.
3. Whether `Window`'s built-in close-on-`ui_cancel` runs ahead of all three
   stages on Windows specifically.

## Requirement on the text-input implementation plan

1. Own Escape/cancel arbitration in the text-input layer rather than per-dialog.
   Three interception points on one dialog subclass is the symptom of not having
   a layer that owns it.
2. Replace the direct-call test with one that dispatches a real event through
   the input stack. The isolation problem the comment describes is real — solve
   it with test isolation, not by bypassing the path under test.
3. Determine the root cause on Windows **before** designing the fix; the
   verified section above removes the two cheapest wrong answers.
