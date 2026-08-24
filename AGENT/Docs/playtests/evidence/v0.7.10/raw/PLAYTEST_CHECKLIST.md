---
Role: dated
Type: playtest
Status: Ready
Last verified: 2026-08-24
---

# v0.7.10 Windows Tester Checklist

This focused replacement round verifies the newly authored free-roam campaign path and
closes the remaining narrow-layout findings. Return this checklist, screenshots, and the
complete Godot log directory. Record observed text and behaviour, not only checkmarks.

## Build identity

- [x] The log begins with BUILD STAMP version `0.7.10` and the commit in `BUILD_INFO.json`.
- [x] The executable matches `SHA256SUMS.txt`.
- [x] Windows version: 11
## 1. Fresh install and free-roam activation

Start with no installed packs and no saves. Import
`campaign-packs/proving-grounds-free-roam-0.1.0.zip` through Campaign Library.

- [x] Import succeeds without diagnostics.
- [x] New Game lists **The Proving Grounds**.
- [x] Starting it reaches Chapter 1's Prep screen directly; a new campaign does not
  visit the overworld before its first battle.
- [x] Begin Battle launches Chapter 1 without an activation or traversal error.
- [ ] Copy any activation or traversal error verbatim: Not strictly an error, but when the free roam menu was enabled, I clicked Chapter 1 again and it took me to the chapter 1 prep screen but would neither let me start the battle or return to any other menu. when the game was closed and rebooted I was placed in the chapter 2 prep area. Likely this will be fixed primarily when we upgrade the prep area, but we should remember to make sure that any menus that can't be backed out of or used to progress should be inacessable. Specificaly, If a player enters the prep hub for a node from a free roam menu/map they should be able to return to that screen. If the campaign is linear, that is not needed. 

## 2. Overworld progression

- [x] Complete Chapter 1 and confirm Continue routes to the overworld.
- [x] The overworld shows the authored nodes and clearly distinguishes the cleared
  Chapter 1, the next Chapter 2, and later unreached nodes. Screenshot the whole screen.
- [x] Selecting cleared Chapter 1 revisits its Prep screen without rewinding progression.
- [x] Chapter 2 becomes reachable while later prerequisites remain enforced.
- [x] An unreached node names its prerequisite in a sentence: ____________________
- [ ] Save, quit fully, relaunch, and Continue; the same node state is restored.
	- Campaign map should have access to settings and save and a save taken on the map or at the end of a mission should return to the map.
- [ ] No visible label contains `req.`, `#missing:`, `overworld.node.`, or `menu.`.

## 3. Narrow-layout disposition

- [ ] At the narrowest supported width, the application title is fully visible.
- [ ] `New Game (No Data Packs Installed)` is fully visible before pack installation.
- [x] Campaign Library text stays inside its decorative border. Screenshot.
- [ ] In Settings, record whether **Menu Density** is present: Not seen, please check with playwright before asking this again.
- [ ] Slider tracks, endcaps, thumbs, and focused state are visibly distinguishable.
  Screenshot the whole Settings screen. Not visable, check playwright before asking this again.

## 4. Regression smoke

- [x] Keyboard and controller can navigate the overworld and launch a reached node.
- [x] A battle map renders without missing terrain.
- [ ] No duplicate-signal, stuck-modal, input-leakage, focus-loss, activation, or save
  errors appear in the returned logs.

## Return contents

- [ ] Completed checklist.
- [ ] All requested screenshots.
- [ ] Complete Godot log directory, including the launch containing the BUILD STAMP.
