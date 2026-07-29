# v0.6.0 Playtest Carry-Forward Requirements

**Raised:** 2026-07-29, from the v0.5.8 owner return
**Source:** `playtest_v0.5.8_owner_return_2026-07-29.md`
**Status:** requirements only — the v0.6.0 checklist does not exist yet

v0.5.8 was accepted as the stable v0.5 release with three checklist areas
unresolved and two more never reported either way. When the v0.6.0 checklist is
written, it **must** carry all five. Nothing here has been verified on Windows;
the first three have now slipped through the v0.5.6, v0.5.7, and v0.5.8 cycles.

| # | Area | v0.5.8 state | Needs the log bundle? |
|---|---|---|---|
| 1 | Controller hot-plug telemetry (§4) | not collected | **yes** |
| 2 | Logging/telemetry presence (§5 items 1–2) | not collected | **yes** |
| 3 | Cancel/Escape input ownership (§3) | failing | no |
| 4 | Package save validation (§2) | not reported; half of it has never been runnable | no |
| 5 | Retry-after-Save and one-per-press nav (§5 items 3–4) | not reported; passed in v0.5.6 | no |

Rows 1 and 2 are the only ones a verbal return can never satisfy. Rows 3–5 are
observable on screen and can be reported by eye.

**Rows 4 and 5 are not blank slates.** The returned v0.5.6 checklist already
covers both, and reading it changes what v0.6.0 needs to do: one half of row 4
has never been runnable because the instruction omits a filesystem path, and
row 5's Retry-after-Save passed outright. Details in each section.

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

§5 mixes two kinds of item and only these two are log-dependent. They are
inspected in the returned `godot.log` (plus rotated logs) and in the user data
directory — there is nothing to see on screen, which is precisely why they keep
going uncollected:

- No `[V030 TRACE]` lines anywhere in the log, and no v0.3.0 resize trace file
  written to disk.
- BUILD STAMP, runtime environment, `PLAYTEST CONTEXT`, and controller
  telemetry all present in the log.

**The return must include the log bundle** — current `godot.log`, the rotated
timestamped logs, and a check that the resize trace file is absent. These two
items cannot be satisfied by a verbal return; that is why they have gone
uncollected three cycles running. Item 1 of this document has the same
constraint: prompts switching correctly on screen is *not* evidence, the
transition records in the log are.

§5's other two items are behavioural, need no log, and are carried in section 5
below.

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

## 4. Package save validation (half verified, half never runnable)

§2 was not reported either way in v0.5.8. Checking the returned v0.5.6 evidence
shows the two halves have very different histories, and only one of them is
actually unverified:

| §2 half | v0.5.6 result |
|---|---|
| Ordinary load activates the saved catalogue, no false missing-item error | **[x] passed** |
| Missing package fails clearly without partial mutation | **[ ] not run** — tester wrote *"don't know how to test this"* |

That note is the whole reason this keeps slipping. The instruction says
"temporarily move the imported package out of its installed folder" without
saying where that folder is, so the tester has been unable to run it since
v0.5.6. **v0.6.0 must give the concrete path**, which is:

```
%APPDATA%\Godot\app_userdata\Fire Emblem RPG\campaign_packs\installed\<package_id>\
```

(`user://campaign_packs/installed/` per `CampaignPackRegistry.gd:7`; the project
sets no custom user dir, so the Windows default above applies. Confirm the exact
folder on the test machine before writing it into the checklist.)

Steps for the half that has never run:

1. Import `two-map-skirmish-1.0.zip` and make a save inside its campaign.
2. **Fully close the game.**
3. Move (do not delete) the package folder above to the desktop.
4. Restart the exe and load that same save slot.
   - The load fails with a clear missing-package message.
   - The campaign is **not** partially restored.
   - Shipped content stays selected and usable.
5. Move the folder back, restart, and confirm the save loads normally again.

Re-run the first half too — it passed in v0.5.6 but has not been confirmed on
any build since.

## 5. Retry-after-Save and controller navigation (re-confirmation)

The two behavioural items from §5. No log needed; both are watched on screen.

### Retry after Save — already passed once, needs re-confirmation

**This is not unverified work.** The returned v0.5.6 checklist exercised it in
full and passed all five sub-checks:

- [x] Retry remains available and shows a warning that the advanced save remains.
- [x] Cancel leaves Results unchanged.
- [x] Confirm returns through Prep to the just-completed map at round zero.
- [x] Loading the earlier saved timeline still resumes the advanced successor.
- [x] Winning the retried map advances exactly once (no skipped/double node).

That is the acceptance evidence `B4-RESULT-ACTIONS-2026-07-22` has been waiting
for, and it exists. The one caveat is that `19e2c0e4` ("Fix v0.5.6 playtest
blockers and prepare v0.5.7") landed afterwards and restructured
`MapResultsScreen` — the action buttons moved into an `Actions` container and
Save gained branch-choice-dependent disabling. The retry/save *semantics* were
not touched, but the screen driving them was, so the evidence is strong rather
than airtight.

Re-run the five checks above on v0.6.0. If the owner accepts the v0.5.6
evidence as sufficient given the untouched semantics, B4 can close now and
`PP-INTEGRATION-RELEASE-RECONCILE` is unblocked immediately — that is a decision,
not a test result.

### Controller navigation

- **Results, Defeat, Rewind, Prep, FileDialogs, and dropdowns move exactly one
  item per controller press,** with no focus left behind a modal.

Note the v0.5.6 return marked the related long-list scrolling items as passing
except **successor dropdown navigation staying inside the dropdown until it
closes**, which failed. Include that case explicitly.

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
