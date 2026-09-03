---
Role: dated
Type: playtest
Status: Awaiting return
Last verified: 2026-08-10
---

# v0.7.3 Windows remediation checklist

Return this completed checklist and the debug log. Include screenshots for visual or
focus failures. Write `FAILED` or `UNRUN` beside every item that does not pass.

## 1. Identity

- [ ] `sha256sum -c SHA256SUMS.txt` passes before launch.
- [ ] Both startup logs report BUILD STAMP `version=0.7.3`; each commit matches
  `BUILD_INFO.json`.
- [ ] The release executable has no DEBUG MODE banner; the debug executable does.
- [ ] Main Menu displays `v0.7.3`.

Stop and return the bundle if any identity check fails.

## 2. First-run Campaign Library route

Run this section first, on a user-data directory that has never held this game.

- [x] Main Menu shows a **Campaign Library** entry of its own, and it is enabled.
- [x] Campaign Library holds initial focus on a fresh install; keyboard Enter and the
  controller confirm button open it without any prior mouse click.
- [x] The disabled New Game entry reads **New Game (No Data Packs Installed)** and its
  tooltip explains that a pack must be installed or selected.
- [x] Campaign Library opens directly from Main Menu — not only through New Game — and
  its Back returns focus to the Campaign Library entry.
- [ ] After importing a pack from inside the library, returning to Main Menu shows New
  Game enabled without quitting and relaunching.
- [x] Escape and the controller cancel button close the library the same way Back does.

## 3. Content-free launch and replacement pack

- [ ] On a clean user-data directory, New Game offers no built-in campaign and explains
  how to install content; no proving-grounds campaign is silently available.
- [ ] Import the supplied replacement-pack ZIP without extracting it.
- [ ] Campaign Library discovers and selects the installed pack without a `get`-on-String
  error or registry-envelope error.
- [ ] New Game lists the installed campaign, map, and roster only after selection.
- [ ] Launch a map and confirm player/enemy units, inventories, terrain, objective, and
  turn order are present.
- [ ] Save, quit, relaunch, and continue the package-backed campaign. A failed or cancelled
  load must not leave a different pack or partial campaign state active.
Pack failed to import with several vocabulary_value_unknown errors. Image included

## 4. Game-owned filename modal

Use the debug executable and test each save-mode entry point included in the build.

- [ ] Export/Save opens a game-owned filename modal before the native directory picker.
- [ ] Escape in the filename modal closes only that modal and returns focus cleanly.
- [ ] Confirming a valid filename opens a directory-only picker; no filename field is
  embedded in the native picker.
- [ ] Keyboard and controller can reach the name field, Cancel, and Confirm without a
  trapped or invisible focus target.
- [ ] The chosen filename is preserved through the picker and the resulting file uses it.

No changes noticed from last time. a single `escape` at any time moved me back to the main menu. and when using `wasd` to move the focus or using the joystick only `z` and `x` keys would be entered into to file name area until there was a mouse click on the entry box. Should we consider scrapping our entire filesystem interface and trying to make the game ask the OS to open its native file picker/download interface or should we do a more intensive research session and find where someone else has allready solved this problem and see what they did? possibly we should look at seperating the text input into its own screen like the echo strip that the on screen keyboard is supposed to be getting.

## 5. Migration retry and smoke pass

- [ ] Existing saves/settings from the former `Fire Emblem RPG` user-data directory are
  available after launch and newer Project Prometheus data is not overwritten.
- [ ] Main Menu, Settings, New Game, Load Game, and Campaign Library render correctly at
  1280x720 and 1920x1080 with keyboard, mouse, and a named controller.
- [ ] The added Campaign Library entry does not push Main Menu items out of the panel or
  behind a scroll at either resolution.
- [ ] Complete a representative map without a crash, stuck modal, or transition lockout.

## 6. Return format

For every failure include exact reproduction steps, display resolution/scaling, input
device, screenshot where applicable, and the debug-log timestamp. Do not upload or
redistribute this private candidate.
