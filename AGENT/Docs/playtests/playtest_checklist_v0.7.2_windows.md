---
Type: playtest
Status: Superseded by v0.7.3
Last verified: 2026-08-09
---

# v0.7.2 Windows remediation checklist

Return this completed checklist and the debug log. Include screenshots for visual or
focus failures. Write `FAILED` or `UNRUN` beside every item that does not pass.

## 1. Identity

- [ ] `sha256sum -c SHA256SUMS.txt` passes before launch.
- [ ] Both startup logs report BUILD STAMP `version=0.7.2`; each commit matches
  `BUILD_INFO.json`.
- [ ] The release executable has no DEBUG MODE banner; the debug executable does.
- [ ] Main Menu displays `v0.7.2`.

Stop and return the bundle if any identity check fails.

## 2. Content-free launch and replacement pack

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

## 3. Game-owned filename modal

Use the debug executable and test each save-mode entry point included in the build.

- [ ] Export/Save opens a game-owned filename modal before the native directory picker.
- [ ] Escape in the filename modal closes only that modal and returns focus cleanly.
- [ ] Confirming a valid filename opens a directory-only picker; no filename field is
  embedded in the native picker.
- [ ] Keyboard and controller can reach the name field, Cancel, and Confirm without a
  trapped or invisible focus target.
- [ ] The chosen filename is preserved through the picker and the resulting file uses it.

## 4. Migration retry and smoke pass

- [ ] Existing saves/settings from the former `Fire Emblem RPG` user-data directory are
  available after launch and newer Project Prometheus data is not overwritten.
- [ ] Main Menu, Settings, New Game, Load Game, and Campaign Library render correctly at
  1280x720 and 1920x1080 with keyboard, mouse, and a named controller.
- [ ] Complete a representative map without a crash, stuck modal, or transition lockout.

## 5. Return format

For every failure include exact reproduction steps, display resolution/scaling, input
device, screenshot where applicable, and the debug-log timestamp. Do not upload or
redistribute this private candidate.
