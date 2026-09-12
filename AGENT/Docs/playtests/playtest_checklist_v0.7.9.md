---
Role: dated
Type: playtest
Status: Ready - focused disposition bundle
Last verified: 2026-08-24
---

# v0.7.9 Windows Tester Checklist

This focused follow-up preserves the exact accepted v0.7.9 executable and asks only for
the unresolved narrow-layout disposition. Pack activation, controller navigation, battle
completion, save/restore, and node advancement already passed on Windows and are not
repeated. Return this checklist and the requested screenshots.

## Build identity

- [ ] The log begins with BUILD STAMP version `0.7.9` and the commit in `BUILD_INFO.json`.
- [ ] The executable matches `SHA256SUMS.txt`.
- [ ] Windows version: ______________________

## 1. Narrow-layout disposition

- [ ] At the narrowest supported window width, capture Campaign Library with the minimum-
  width title and the New Game unavailable reason visible.
- [ ] Disposition: the observed horizontal clipping is acceptable / must be repaired
  (circle one), with reason: _____________________________________________________
- [ ] Capture the complete Settings screen. Confirm whether **Menu Density** is absent:
  ______________________________________________________________________________
- [ ] Capture one focused slider and one scrollbar. Confirm whether their tracks/endcaps
  are visible behind the thumbs: _________________________________________________

## 2. Overworld item — recorded blocker, do not improvise

The supplied Proving Grounds campaign is linear. The v0.7.9 exported schema rejects an
authored `traversal_mode: "free_roam"` campaign as an unknown field, so this executable
cannot perform the requested authored-pack overworld check. Do not edit or rezip the pack.
That check remains release-line work and is not evidence this focused bundle can collect.

## Return contents

- [ ] Completed checklist.
- [ ] All requested screenshots.
- [ ] Godot log only if a new error appears; include the launch containing the BUILD STAMP.
