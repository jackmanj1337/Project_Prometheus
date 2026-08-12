---
Type: playtest
Status: Ready - pending live Windows validation
Last verified: 2026-08-02
---

# v0.6.0 Return-Fix Native Windows Checklist

Use only the executable identified in
[`playtest_build_v0.6.0_return_fixes.md`](playtest_build_v0.6.0_return_fixes.md).
Return this file, `godot.log` plus rotated logs, controller model, Windows version,
and reproduction screenshots/video for any failure.

## 1. Artifact and preserved display behavior

- [ ] Executable SHA-256 is
  `08bb4278372fbce700e4aa026b9cb6cf9fc115d06e462d6ebf9c4610dec5e75a`.
- [ ] Startup log contains BUILD STAMP and RUNTIME ENVIRONMENT blocks.
- [ ] Free-drag the window through 16:9, 16:10, and a wide shape: no snap-back to
  16:9, no black bars, and the wider axis reveals more game area.
- [ ] Maximize and restore: the accepted expand/free-resize behavior remains intact.

This is regression evidence only. It does not accept the still-unimplemented bounded
temporary-window or HUD attachment-pair slices.

## 2. FileDialog filename ownership and crash boundary

Repeat the entire sequence at least five times in an Import or Export FileDialog:

1. Focus the filename field and enter text with the grid and physical keyboard.
2. Confirm X, Z, W, A, S, and D type normally when allowed.
3. Confirm a real caret is visible and edits land in the filename field.
4. Press physical Escape once: editing ends, the dialog stays open, and focus lands
   on the file `ItemList`.
5. Press physical Escape again: the FileDialog closes normally.

- [ ] Five consecutive repetitions complete without crash or stuck overlay.
- [ ] Submit, click/Tab away, Cancel, dialog close, and reopen each release the old
  text-entry session.
- [ ] Returned log contains a structured `file_dialog_escape_owned` transition for
  every first Escape. Record its `fields.stage` value here: ____________.
- [ ] The second Escape has no `file_dialog_escape_owned` record for that edit session.

Do not infer native success from browser or headless results; FileDialog owns a separate
native Window/Viewport on Windows.

## 3. Controller transition and watchdog evidence

With one real controller, repeat each boundary several times and move the stick plus
press a trigger immediately afterward:

- [ ] Attack that does not level up, then resume cursor movement.
- [ ] Attack that awards a level, dismiss the level-up screen, then resume movement.
- [ ] Open and close Unit Details after leaving it visible for more than five seconds.
- [ ] Open end-turn confirmation; test Cancel, then reopen and Confirm.
- [ ] Connect, use, disconnect, use keyboard, reconnect, and use the controller again.

For every sequence:

- [ ] Input resumes; no cursor/controller lockout occurs.
- [ ] `TRANSITION` records carry the same correlation ID from attack confirmation
  through combat completion and include EXP/level-up boundaries when applicable.
- [ ] Unit Details produces no false watchdog record while visibly open.
- [ ] Modal acquire/release and end-turn decision records are balanced.
- [ ] Hot-plug `PLAYTEST CONTROLLER` lines retain device name/GUID on disconnect.

If input locks, stop interacting long enough for the five-second watchdog, then return
the untouched log. Do not relaunch before copying it. The single watchdog record must
include suppression owners, modal stack, focus, input mode/device, combat, turn,
level-up, scene-transition state, and elapsed time.

## 4. Return verdict

- FileDialog native ownership/crash: PASS / FAIL
- Controller transition lockout: PASS / FAIL
- Expand/free-resize regression: PASS / FAIL
- Tester notes: ________________________________________________

These results can accept only the native portions represented by this candidate. The
full v0.6.0 return-fix goal remains open until its separate browser, display-policy,
HUD, save-schema, review, tracker, and handoff gates are satisfied.
