---
Type: playtest
Status: Ready
Last verified: 2026-08-21
---

# v0.7.8 Windows Tester Checklist

This is the **batched native-host round**: seven rows have been waiting on a real
Windows display, a real keyboard and controller, or a screen reader, and none of them can
be answered in the container. It is deliberately **Windows-only** — the open iOS,
mobile-web and touch rows need a phone or a touch device and are not on this checklist.

**Please write down what you actually saw or heard, not just a tick.** Several items ask
for the exact text. That is not busywork: the strings involved have fallback forms that
*look* like real text (`req.has_item`, `#missing:req.has_item`), so "yes, something was
there" cannot tell a working table from a broken one. If a box is ticked with no text
recorded, the item has to be re-run next round.

Return this checklist and the complete Godot log directory.

## Do the sections in order — installing the pack early destroys section 1

The build ships **no campaign content**: `data/**` is excluded from the export, so a fresh
install has no campaign until you import one. The bundle supplies
`campaign-packs/proving-grounds-0.1.0.zip` for that.

**Sections 1 and 2 must be done first, before importing anything.** They depend on
Continue, Load Game and New Game all being *gated at once*, and New Game stops being gated
the moment a pack is installed — so importing early silently costs this round its
highest-value observation and it cannot be recovered without a clean reinstall.

1. Sections 1–2 with **no pack installed and no saves**.
2. Then import `proving-grounds-0.1.0.zip` through **Campaign Library** (import the ZIP
   itself; do not unzip it) and continue with sections 3–6.

If you have played an earlier round on this machine, clear its saves and installed packs
first — otherwise nothing on the Main Menu is gated and sections 1 and 2 are unanswerable.

## Build identity

- [ ] The log begins with BUILD STAMP version `0.7.8` and the commit recorded in
  `BUILD_INFO.json`.
- [ ] The executable matches the supplied checksum.
- [ ] Windows version: ______________________

## 1. Screen reader — the highest-value item this round

This answers `[ANN-5]`, which is the single thing blocking
`SHELL-UNMET-REASON-ANNOUNCEMENT-CHANNEL-2026-08-19`. The question is narrow: **does
Windows Narrator already read a gated entry's reason, or does it announce only the button
name and its dimmed state?** The project has never written an accessibility property, so
the answer decides whether that row is "verify and improve the wording" or real work.

Start Narrator with **Ctrl + Win + Enter**. Launch the game with **no campaign pack
installed and no saves**, so all three gated entries on the Main Menu are gated at once.

- [ ] Screen reader used: **Narrator** / other: ______________________
- [ ] Tab to **Continue** (gated). Write down **everything Narrator said**, verbatim:

  `_______________________________________________________________`

- [ ] Tab to **Load Game** (gated). Verbatim:

  `_______________________________________________________________`

- [ ] Tab to **New Game** (gated). Verbatim:

  `_______________________________________________________________`

- [ ] Did any of the three include the *reason* (e.g. "There are no saved games to load
  yet"), or only the button name and something like "dimmed"/"unavailable"? ____________

- [ ] Press Enter on a gated entry. Nothing should happen — no screen change, no sound
  beyond Narrator. Anything else: ______________________

## 2. Keyboard and controller on gated entries

This is the sole remaining item on `SHELL-FOCUSABLE-DISABLED-ENTRIES-2026-08-17`. The
ruling is that a gated entry **stays in the focus order but cannot be activated**, so its
reason is reachable without a mouse. The container verified this headlessly; it cannot
verify that a real keyboard and a real controller agree.

With the same no-pack, no-save state, **using only the keyboard**:

- [ ] Tab and Shift+Tab step **onto** the gated Continue, Load Game and New Game entries
  rather than skipping over them.
- [ ] Arrow keys / WASD do the same.
- [ ] Enter and Space on a gated entry do nothing.
- [ ] On first opening the menu, focus lands on a **usable** entry (Campaign Library),
  not on a gated one — and focus is visible without hovering the mouse.

Now with a controller plugged in:

- [ ] Controller model: ______________________
- [ ] D-pad and stick reach the gated entries the same way.
- [ ] The confirm button on a gated entry does nothing.
- [ ] Please also walk the **in-game** menus with the controller (unit action menu, map
  menu) and note any entry that is greyed out but unreachable: ______________________

## 3. Gate reasons read as sentences

New this build: unmet reasons come from a shared text table instead of rendering as their
own internal ids. **If any of these reads like `req.has_item` or `#missing:req.has_item`,
that is the bug** — write down exactly what appeared.

- [ ] Hover (or focus) gated **Continue** — the reason reads as an English sentence:

  `_______________________________________________________________`

- [ ] Hover gated **Load Game**:

  `_______________________________________________________________`

- [ ] Start **The Proving Grounds** (the supplied pack) and open the **overworld**. Hover a
  node you have not reached. The reason should name the node to clear first, e.g. "Clear
  Chapter 1 - First Blood first." Verbatim:

  `_______________________________________________________________`

- [ ] Anywhere in the game, did you see a label containing `req.`, `#missing:`,
  `overworld.node.` or `menu.`? Where: ______________________

## 4. Main Menu and UI at different window sizes

Covers `V080-RESPONSIVE-MAIN-MENU-2026-08-08` and `UI-PHASE0-UNBLOCKED-ITEMS-2026-08-16`.
Both are visual-pass rows: the container can assert numbers but cannot tell us whether it
looks right.

Resize the window by dragging, and at each size:

- [ ] **Maximised / full screen** — the menu panel is centred and does not stretch to a
  silly width. Screenshot.
- [ ] **About half width** — the panel narrows sensibly rather than clipping. Screenshot.
- [ ] **As narrow as Windows lets you drag it** — buttons stay readable and reachable;
  the list scrolls if it must. Screenshot.
- [ ] While dragging the window slowly across those sizes, **the focused button stays
  focused** and the list does not jump back to the top.
- [ ] Text is never clipped, overlapped, or cut off at any size. Where it is: __________
- [ ] Open **Settings** and change **Menu Density**. The rows change size and focus is not
  lost. Screenshot both densities.
- [ ] Sliders and scrollbars in Settings look like part of the same UI — correct colours,
  visible handles, obvious which one is focused. Screenshot.

## 5. Terrain

Covers `IMPL-TERRAIN-VARIANTS-AND-PACK-TERRAIN-2026-08-01`.

- [ ] Start a battle and screenshot the map. Terrain variants should read as intentional
  variety, not as mismatched or obviously-tiled art.
- [ ] Any tile that looks wrong, missing, or like a placeholder: ______________________

## 6. General regression smoke

- [ ] Play at least one battle start to finish; nothing new is obviously broken.
- [ ] Save, quit fully, relaunch, and Continue — it restores on the first attempt.
- [ ] No duplicate-signal, stuck-modal, input-leakage, focus-loss, or package-activation
  errors in the returned log.

## Not on this checklist, and why

These rows also want a host, but a Windows desktop **cannot** answer them — they need a
phone, a mobile browser, or a touch screen, and they are waiting on their own device
session: `IOS-DEVICE-PWA-VERIFICATION-2026-08-03`, `MOBILE-WEB-UX-GAPS-2026-08-03`,
`DEDICATED-TOUCH-CONTROLS-2026-08-03`.

`IMPL-FOG-RENDER-2026-08-02` is not here either: fog currently **computes but draws
nothing**, so there is nothing to look at until that slice is built.

## Carried over — two questions from the v0.7.6 return

Not build items; they need you rather than the executable
(`V076-RETURN-RESIDUE-2026-08-16`).

- [ ] The v0.7.6 checklist has a note that stops mid-word: *"browser cancel is fine, but I
  think that when a download was canceled then the "*. What was the rest of that thought?

  `_______________________________________________________________`

- [ ] Two migration checks came back marked *"not sure how to test this"*. That is a gap
  in the checklist, not in you — would a build that ships deliberately-broken save files
  for you to try loading make those testable? ______________________

## Tester notes

- Findings/screenshots:
- Anything that felt wrong but is not covered above:
