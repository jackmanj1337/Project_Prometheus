---
Role: dated
Type: playtest
Status: Awaiting return - shipped in the v0.7.0 Windows-round bundle
Last verified: 2026-08-06
---

# Decisions to make while the game is running

Five questions. Each one is answerable **live in the application on your own display** —
this round ships no screenshot album, because a browser-rendered album is not what a
Windows session is for. Each offers concrete options; "does this look right?" is not a
question anyone can answer twice the same way, so none are phrased that way.

Write your answer under each one. **Anything decided here becomes a tracker row in the
same session** — a decision that lives only in a returned document is how the last two
rounds lost their outcomes.

Four further decisions (mobile default scale, portrait behaviour, PWA icons, safe-area
padding on a real device) are **deferred to the mobile pass** and are not asked here.
They are preserved in [`v0.7.0_decision_sheet.md`](../../v0.7.0_decision_sheet.md).

---

## 1. Window sizing for Load Game and the Campaign Library

**How to see it:** open Load Game, then Campaign Library, at 1920×1080 and again at
2560×1440 or larger if you have it.

Both currently present as large, near-fullscreen panels rather than modest centred
dialogs.

- [x] **Accept as intended** — they are content-heavy screens and deserve the space.
- [ ] **Constrain them.** Name the target: a maximum proportion of the window
      (e.g. 60% width × 70% height), or a fixed maximum size in logical pixels.

Answer: They can have everything on windows and everything in the game viewport for the web version, just make sure to consider rounded corners and notches/punchouts.

---

## 2. Main-menu proportion at wide aspect ratios

**How to see it:** the Main Menu at your widest available resolution, and again with the
window dragged deliberately wide and short.

At very wide ratios the menu panel occupies a narrow central column with large empty
margins either side.

- [x] **Accept** — a centred column is the intent, and empty margin is fine.
- [ ] **Grow the panel.** Say how: scale with height, hold a fixed aspect, or widen to
      a proportion of the window.

Answer: Centered collumn is fine, possibly even make sure it can scroll so that with especially large fonts or small screens all the options are still accessable. Also be willing to skip the title card at the top if the space is valuable.

---

## 3. Viewport Scale — default and range

**How to see it:** Settings → Viewport Scale. Note what it defaults to on your display,
then walk it to both ends and look at the map HUD at each.

The desktop default is the identity diagonal (screen height ÷ 720, snapped to 0.5).

- [x] **Identity default is right**, and the slider's range is useful at both ends.
- [ ] **Change the default** to: ______
- [ ] **Change the range.** Which end is useless, and what should it be?

**This one now feeds the responsive redesign, not the closed anchoring row.** The size
class a device lands in is derived from `window_size / content_scale_factor`, so the
default you set here decides which class a given machine gets.

Answer: You can currently still slide the viewport scale up high enough that at small resolutions the menu gets cut off. I would also consider looking into increasing the max menu scale, but that might be stepping onto the toes of the mobile ui redesign.

the default also appeared to be viewport 3x when I opened it on the 4k monitor but the app still opened at 1280x720 so the main menu was unusable. At 1x viewport, the main menu looked fine at 720p and 3x looked good when the menu was actually at 4k.

---

## 4. Terrain variants

**How to see it:** load a map from the installed pack and look at forest and mountain
tiles.

Variants of one terrain must *behave* identically — the stat block is shared by
construction. The question is whether they still *read* as the same terrain.

- [ ] **Yes** — visually distinct but unmistakably the same terrain.
- [ ] **No** — name which variant reads as a different terrain, and whether the fix is
      art or a reduction in how far variants may differ.

Answer: What was supposed to bee seen here? The forests are dark green squares and the mountains are brown. there is no variation noticed in either stat or visuals.

---

## 5. `[PCM-7]` — a rules decision, not a visual one

When a crossing trigger fires but produces **no effect**, does the move become
permanent?

- [x] **Yes** — firing is what commits the move, effect or not.
- [ ] **No** — only an effect commits it; an effect-less trigger leaves the move
      provisional.

Answer:
