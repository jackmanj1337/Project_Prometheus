---
Role: dated
Type: playtest
Status: Ready
Last verified: 2026-08-22
---

# v0.7.9 Windows Tester Checklist

This replacement round verifies the repaired Proving Grounds pack and completes the
items blocked or left incomplete by v0.7.8. Return this checklist, screenshots, and the
complete Godot log directory. Record what you observe rather than only ticking boxes.

## Build identity

- [ ] The log begins with BUILD STAMP version `0.7.9` and the commit in `BUILD_INFO.json`.
- [ ] The executable matches `SHA256SUMS.txt`.
- [ ] Windows version: ______________________

## 1. Fresh install and pack activation

Start with no installed packs and no saves. Import
`campaign-packs/proving-grounds-0.1.0.zip` through Campaign Library; do not unzip it.

- [ ] Import succeeds without diagnostics.
- [ ] New Game lists **The Proving Grounds**.
- [ ] Starting it reaches the overworld rather than reporting a missing registry.
- [ ] Copy any activation error verbatim: ________________________________________

## 2. Controller completion

- [ ] Controller model: ______________________
- [ ] With no pack/saves, D-pad and stick reach gated Continue, Load Game, and New Game.
- [ ] Confirm on a gated entry does nothing.
- [ ] In-game unit and map menus remain navigable; note unreachable disabled entries:
  ______________________________________________________________________________

## 3. Gate reasons

- [ ] Continue reason, verbatim: _________________________________________________
- [ ] Load Game reason, verbatim: ________________________________________________
- [ ] On the overworld, an unreached node names its prerequisite in a sentence:
  ______________________________________________________________________________
- [ ] No visible label contains `req.`, `#missing:`, `overworld.node.`, or `menu.`.

## 4. Responsive UI follow-up

- [ ] At the narrowest window width, Campaign Library text does not touch or cross its
  border. Screenshot.
- [ ] In Settings, locate **Menu Density**, capture both settings, and confirm focus is
  retained. If it is absent, screenshot the whole Settings screen.
- [ ] Sliders and scrollbars have visible handles and focused state. Screenshot.

## 5. Terrain and smoke

- [ ] Screenshot a battle map; terrain variants look intentional and no tile is missing.
- [ ] Complete one battle, save, quit fully, relaunch, and Continue successfully.
- [ ] No duplicate-signal, stuck-modal, input-leakage, focus-loss, or activation errors
  appear in the returned logs.

## Return contents

- [ ] Completed checklist.
- [ ] All requested screenshots.
- [ ] Complete Godot log directory, including the launch containing the BUILD STAMP.
