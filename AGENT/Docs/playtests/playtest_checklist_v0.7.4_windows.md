---
Type: playtest
Status: Superseded by v0.7.5
Last verified: 2026-08-11
---

# v0.7.4 Windows remediation checklist

Return this completed checklist and the debug log. Include screenshots for visual or
focus failures. Write `FAILED` or `UNRUN` beside every item that does not pass.

## 1. Identity

- [ ] `sha256sum -c SHA256SUMS.txt` passes before launch.
- [ ] Both startup logs report BUILD STAMP `version=0.7.4`; each commit matches
  `BUILD_INFO.json`.
- [ ] The release executable has no DEBUG MODE banner; the debug executable does.
- [ ] Main Menu displays `v0.7.4`.

Stop and return the bundle if any identity check fails.

## 2. Clean first-run pack import

Run this section first, on a user-data directory that has never held this game.

- [ ] Campaign Library is enabled and initially focused; keyboard and controller confirm
  open it without a prior mouse click.
- [ ] Import the supplied `replacement-pack.zip` without extracting it.
- [ ] Import completes without a registry-envelope error, `get`-on-String error, crash,
  or partial package entry.
- [ ] The installed pack can be selected and New Game becomes enabled without quitting.
- [ ] New Game lists the supplied campaign, map, and roster; launching it produces units,
  inventories, terrain, objective, and turn order.
- [ ] Save, quit, relaunch, and continue the package-backed campaign.

## 3. Filename modal and input ownership

Use the debug executable. Exercise the campaign export and each available save/export
entry point.

- [ ] Export/Save opens the game-owned filename modal before the native directory picker.
- [ ] The existing suggested filename is selected and ordinary typing replaces it.
- [ ] Left/Right, Home/End, Backspace, and Delete edit at the visible caret correctly.
- [ ] Escape closes only the filename modal and restores focus to the invoking control.
- [ ] Controller cancel has the same ownership behavior and does not also close the
  underlying screen.
- [ ] Keyboard and controller can reach the field, Cancel, and Confirm with one visible
  focus owner and no trapped target.
- [ ] Confirming a valid name opens a directory-only picker; the chosen name is preserved
  and the resulting file uses it.
- [ ] Cancelling the native picker returns cleanly without creating or overwriting a file.

## 4. Import/export round trip and smoke pass

- [ ] Export the installed replacement pack, then import that exported ZIP into a clean
  user-data directory; it is accepted and launches normally.
- [ ] Main Menu, Settings, New Game, Load Game, and Campaign Library render correctly at
  1280x720 and 1920x1080 with keyboard, mouse, and a named controller.
- [ ] Complete a representative map without a crash, stuck modal, or transition lockout.

## 5. Return format

For every failure include exact reproduction steps, display resolution/scaling, input
device, screenshot where applicable, and the debug-log timestamp. Do not upload or
redistribute this private candidate.
