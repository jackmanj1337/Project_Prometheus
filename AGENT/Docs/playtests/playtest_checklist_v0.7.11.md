---
Role: dated
Type: playtest
Status: Ready
Last verified: 2026-08-25
---

# v0.7.11 Windows Tester Checklist

This focused replacement round verifies the v0.7.10 remediation. Return this
completed checklist, every requested screenshot, and the complete Godot log directory.
Record observed text and behaviour rather than only checking boxes.

## Build identity

- [ ] The log begins with BUILD STAMP version `0.7.11` and the commit in `BUILD_INFO.json`.
- [ ] The executable matches `SHA256SUMS.txt`.
- [ ] Windows version: ______________________

## 1. Reach the campaign map

Start clean and import the supplied free-roam Proving Grounds pack.

- [ ] Import succeeds without diagnostics and New Game lists **The Proving Grounds**.
- [ ] New Game launches Chapter 1 Prep; completing Chapter 1 reaches the campaign map.
- [ ] Chapter 2 is reachable and a later gated node states its prerequisite in a sentence.
- [ ] No visible label contains `req.`, `#missing:`, `overworld.node.`, or `menu.`.

## 2. Cleared-node return and map persistence

- [ ] Revisit cleared Chapter 1 and confirm its non-repeatable battle remains disabled.
- [ ] Activate **Return to Campaign Map** with keyboard; progression and reached nodes
  remain unchanged.
- [ ] Repeat the revisit/return with controller, including the normal Cancel action.
- [ ] On the campaign map, choose **Save** and record the success text: ______________
- [ ] Quit fully, relaunch, choose Continue, and confirm the same campaign-map node
  availability returns.
- [ ] Open **Settings** from the map, change one harmless setting, close it, and confirm
  focus returns to the map's Settings button.

## 3. Main Menu and Menu Density

- [ ] At the narrowest supported width, **Project Prometheus** is fully visible.
- [ ] Before pack installation, `New Game (No Data Packs Installed)` is fully visible.
- [ ] In Settings, **Menu Density** offers Full / Standard / Minimal.
- [ ] Change Menu Density, close Settings, reopen it, and confirm the selection persisted.
- [ ] Screenshot the narrow Main Menu and the Menu Density row.

## 4. Slider visual approval

At native resolution, use the Settings sliders and capture evidence showing:

- [ ] Normal, mouse-hover, keyboard focus, and controller focus are distinguishable.
- [ ] Trough, filled portion, both endcaps, and thumb remain visible at minimum value.
- [ ] The same four parts remain visible at midpoint and maximum value.
- [ ] A disabled slider state, if reachable in the current Settings surface, remains
  distinguishable; otherwise record `not reachable` here: __________________________
- [ ] Screenshot the whole Settings screen plus focused close-ups at minimum, midpoint,
  and maximum.

## 5. Regression smoke and return contents

- [ ] Launch the next reached battle; terrain renders and input remains responsive.
- [ ] No duplicate-signal, stuck-modal, focus-loss, activation, save, or restore error
  appears in the returned logs.
- [ ] Completed checklist, requested screenshots, and complete Godot log directory are
  included.
