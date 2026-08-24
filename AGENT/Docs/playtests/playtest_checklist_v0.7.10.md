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

- [ ] The log begins with BUILD STAMP version `0.7.10` and the commit in `BUILD_INFO.json`.
- [ ] The executable matches `SHA256SUMS.txt`.
- [ ] Windows version: ______________________

## 1. Fresh install and free-roam activation

Start with no installed packs and no saves. Import
`campaign-packs/proving-grounds-free-roam-0.1.0.zip` through Campaign Library.

- [ ] Import succeeds without diagnostics.
- [ ] New Game lists **The Proving Grounds**.
- [ ] Starting it reaches Chapter 1's Prep screen directly; a new campaign does not
  visit the overworld before its first battle.
- [ ] Begin Battle launches Chapter 1 without an activation or traversal error.
- [ ] Copy any activation or traversal error verbatim: ___________________________

## 2. Overworld progression

- [ ] Complete Chapter 1 and confirm Continue routes to the overworld.
- [ ] The overworld shows the authored nodes and clearly distinguishes the cleared
  Chapter 1, the next Chapter 2, and later unreached nodes. Screenshot the whole screen.
- [ ] Selecting cleared Chapter 1 revisits its Prep screen without rewinding progression.
- [ ] Chapter 2 becomes reachable while later prerequisites remain enforced.
- [ ] An unreached node names its prerequisite in a sentence: ____________________
- [ ] Save, quit fully, relaunch, and Continue; the same node state is restored.
- [ ] No visible label contains `req.`, `#missing:`, `overworld.node.`, or `menu.`.

## 3. Narrow-layout disposition

- [ ] At the narrowest supported width, the application title is fully visible.
- [ ] `New Game (No Data Packs Installed)` is fully visible before pack installation.
- [ ] Campaign Library text stays inside its decorative border. Screenshot.
- [ ] In Settings, record whether **Menu Density** is present: ____________________
- [ ] Slider tracks, endcaps, thumbs, and focused state are visibly distinguishable.
  Screenshot the whole Settings screen.

## 4. Regression smoke

- [ ] Keyboard and controller can navigate the overworld and launch a reached node.
- [ ] A battle map renders without missing terrain.
- [ ] No duplicate-signal, stuck-modal, input-leakage, focus-loss, activation, or save
  errors appear in the returned logs.

## Return contents

- [ ] Completed checklist.
- [ ] All requested screenshots.
- [ ] Complete Godot log directory, including the launch containing the BUILD STAMP.
