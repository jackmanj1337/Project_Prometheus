> **Historical** — archived 2026-06-23 in the docs reorg (by-type layout). Kept for provenance; not an active doc. See `AGENT/Docs/INDEX.md`.

# Playtester Handbook and Checklist - v0.2.1 (RETURNED 2026-06-19)

> Verbatim tester return for the v0.2.1 pass. Tester: Jacob Jackman, 2026.06.19,
> Windows 11, 1920x1080. Archived as evidence for the v0.2.1 triage
> (`playtest_v0.2.1_triage_plan_2026-06-19.md` + GDD_10 "v0.2.1 findings" action list).
> Checkbox states and tester comments are reproduced as returned.

v0.2.1 is a **fix-and-clarity** build on top of v0.2.0. Priority was **Part I**
(verifying the v0.2.0 bug reports are fixed) and **Part II** (the new
character-sheet / More Info surfaces and the menu-scale split). **Part III** rechecked
the touched display controls; **Part IV** was the regression pointer.

---

## Part I — Bug-fix re-verification (priority)

### 1.1 High-zoom camera is stable (V020-01) — [x] PASS

### 1.2 Map Zoom slider applies live (V020-02) — [x] PASS

### 1.3 Combat forecast never covers the defender (V020-03) — [x] PASS

### 1.4 F9 toggling does not revive spent units (V020-04) — [ ] FAIL

**Tester comments:** units that I move I am unable to move again, but the computer can
move them all if I hand control back. If I take control mid phase I can move units that
I haven't moved, but the computer will use all units regardless of expenditure. Visually,
units that the ai moved are not going dim like units that are moved manually until the
phase ends. On further inspection it seems like swapping control in the middle of an enemy
unit's movement causes the unit to end up at its destination without having expended its
movement. I recommend rolling the game state back to the start of that unit's activation
when switching on hotseat mode.

### 1.5 Seize objective uses one-based coordinates (V020-05) — [x] PASS

### 1.6 HUD Reset keeps Terrain More Info aligned (V020-06) — [ ] FAIL

**Tester comments:** this still behaves strangely when you mess with it enough. You can
also exit out of the settings menu and use the directional keys to move the cursor up and
down and access other menus while the edit hud menu is still open. if you change the size
of the terrain corner while in the hud layout menu it stops going tightly into the corner
all together. I recommend locking the size of the moveable block to the max size so that
the menu doesn't unexpectedly overlap or go off screen. Also, make the sample text stay
inside the bounds of the info block and preferably follow the same location and format
that actual text would show. Also on the topic of the terrain panel, it is very hard to
scroll the more info page without moving the cursor of that tile, try putting the text
description and the movement costs on separate pages where you can use the more info key
to flip between the pages with one page being completely invisible to increase viewable
map area and more pages can be added if more info is needed. Plan this out thoroughly and
think about how to better integrate this with existing systems.

---

## Part II — New character-sheet, More Info & scale surfaces

### 2.1 Internal Lv label (V020-07) — [x] PASS

### 2.2 CON and LoS on the sheet (V020-15) — [x] PASS

### 2.3 Class summary section (V020-11) — [ ] FAIL

**Tester comments:** Lets move most of that information to the class more info section.
Also note that light-footed should probably be changed to be a movement type instead of a
trait. We should also list movement type under a class's more info section. Bonus project:
make the class skills listed in the more info page spawn new info boxes displaying the
skill's description when clicked or selected using the same selector as for stats.

### 2.4 Weapon stats in More Info (V020-10) — [x] PASS

### 2.5 Directional More Info selector (V020-10) — [ ] FAIL

**Tester comments:** pressing up moves the cursor left and pressing down moves the cursor
right with it only moving up and down when it cant go further left or right instead of
actually moving the cursor up and down directly.

### 2.6 Pair Up duration wording (V020-08, Map 950) — [x] PASS (with request)

**Tester comments:** change `this combat` to `until separated` for pair up effects.

### 2.7 Support partner named on the HUD (V020-09, Map 950) — [ ] FAIL

**Tester comments:** we can remove the stat bonuses from the map hud, and the default
block position needs to be moved up so that the support name isn't cut off the edge of the
screen. look back at the plan for the terrain panel for possible fixes.

### 2.8 Menu Scale is independent of the HUD (V020-16) — [x] PASS (with request)

**Tester comments:** Menu and hud elements do not look crisp at different scales, look
into redoing method to use changing font and element sizes instead of just zooming in or
out. Menus stay centered horizontally, but the top and bottom get cut off at large scale
on long menus.

### 2.9 HUD layout editor affordances (V020-12) — [x] PASS

### 2.10 Debuff Tonic shows red effective stats (V020-14, Map 950) — [x] PASS

---

## Part III — Display controls recheck

### 3.1 Borderless vs Fullscreen (V020-13) — [x] PASS (with request)

**Tester comments:** lets try to natively support 1440p and 4k resolutions in the next
patch. lets also make a note to make sure we get support for steam deck and various mobile
resolutions and keep rounded corners and notches/holepunches in mind when designing the
polished ui.

### 3.2 Resolution + oversized-window clamp — [x] PASS

---

## Part IV — Regression pointer — [x] Regression pass run

---

## Error-log check — [ ] NOT MARKED

No tester comment recorded; treat as NOT RUN pending a rerun note.

---

## Known deferred issues — tester reopen notes

- Clicking the Map Menu backdrop does not dismiss the menu. → tester: "We should try to
  implement this soon."
- Weapon names in the combat preview are not shown. → tester: "lets reopen this issue as
  well."
- Directional More Info selector exists only on the character sheet (forecast + terrain
  still F-cycle). → tester: "reopen this issue."

## Playtester requests (new)

- Click the cancel button (keyboard or mouse) while hovering an unselected unit to open
  its character sheet.
- Consider a mouse-only mode (also touchscreen): the map cursor does not follow mouse
  hover but jumps to it on a click, with a second click (that does not move the cursor)
  selecting the tile/unit. In this mode, add a next-page button to the terrain panel for
  switching, or have the entire panel switch when any part of it is clicked.
