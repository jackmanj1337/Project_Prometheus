# Session Note - 2026-08-06-17-16-13Z-responsive-ui-design-pass

## Branch context

- Branch: `agent/from-integration/small-screen-ui-redesign`
- Base branch: `agent/integration`
- Base SHA: `a0826599aced8a9a285c2bbd049ed19b13d09a62`
- Coordination Work ID: `SMALL-SCREEN-UI-REDESIGN-2026-08-05`

## What was done

Design-only session. No engine code changed. The row's own scope note says it "deliberately
claims only a design doc", and that is what this is:
`AGENT/Docs/design/responsive_ui_redesign_2026-08-06.md`.

**The scope widened, on owner instruction, from a portrait fix to a full responsive UI
redesign.** The trigger was measurement rather than opinion. A fresh v0.7.0 web export driven
with Playwright at 1179×2556 DPR 3 shows portrait snapping to the 0.5 content-scale floor —
logical viewport 2358×1326, body type at **2.7 CSS px** — and landscape clearing the old floor
only in the sense that nothing clips: 1704×786, type near 8 CSS px, d-pad drawn on top of the
menu. There is no orientation where the current UI is right, because there is no responsive
model at all; screens are authored at ~1280×720 and centred in whatever they get.

**The model.** `logical viewport = backing ÷ content_scale_factor`, and a **size class**
derived from logical width: Compact < 600, Medium 600–1023, Expanded ≥ 1024. One dial covers
phone, small Linux handheld, desktop and a phone cast to a display with a keyboard. Design
floor drops to **360 × 640**. Two density token sets keyed off a new Menu Mode (touch: row
48+8, font 16, target 44; controller: row 28+2, font 14, detail row 18) because Awakening's
bottom sheet runs a 17.6px pitch — a third of any touch minimum — purely because nothing on it
is ever tapped. Density follows the input device, not taste.

**The size class is live.** The player can resize the window to arbitrary sizes (already
committed by `UI-VIEWPORT-ASPECT-2026-07-31` decision 2) and can change content scale from the
Settings screen while looking at it, so a screen can change class *while open*. Recompute is
debounced with hysteresis at the boundaries, and class changes must preserve selection, scroll
position and any open More Info target. Settings is both the worst case and the best test.

**Two measurements corrected earlier assumptions.** The portrait canvas band is **26%** of
screen height, not the 55% `portrait_top` defines — `game_view_preset` defaults to `auto`, so
the active controller combination's viewport wins and reserves ~three quarters of the screen
for controls, against 54–55% in all three references. And
`UnitDetailsScreen._update_responsive_layout()` already stacks its panes below a hard-coded
`900.0`: an ad-hoc size class exists in the codebase today, and the seam generalises it rather
than inventing something new.

**A gap in my own earlier wireframes, found by the owner.** The first two passes drew
`UnitDetailsScreen` as a flat stat sheet. It is a two-pane host — content pane (title, class,
stats, inventory, **skills, weapon ranks**, Pair Up, Back) beside an `InfoVBox` — where every
entry is a BBCode `[url]` link and selecting one fills the pane from `MoreInfoContent` plus a
`StatBreakdown` with green/red flags for active buffs and debuffs. More Info is a *mode* with a
priority cycle (combat forecast → character sheet → terrain HUD), and terrain already
implements paging. Skills and weapon ranks were missing entirely. The design doc now carries
the real structure and a four-point accessibility contract for the Compact popup form.

**New reference material.** Five Fire Emblem Awakening (3DS) portrait shots filed at
`Incoming/reference/portrait-3ds-awakening/` with a README of measurements. Local only,
gitignored, never committed — same rule as `mobile-controller-target/`. They close the one gap
the first pass could not measure and confirm the scale model: both 3DS surfaces render at
~1 logical px = 1 CSS px (top 0.94, bottom 0.97).

**Owner decisions taken** (full table in the design doc): floor 360×640; full redesign;
responsive rather than duplicated scenes; images always present but never informative (the
campaign editor will auto-insert an author-coloured rectangle and a pack can be rejected
without one); nothing covers the controls by default; defaults are large buttons with the
controller on screen, with distributors explaining the available settings; the resulting ~4
visible Compact rows accepted; More Info as a small anchored popup that must stay reachable;
**information density ships in v1** and v1 is held for it; `IMPL-VIEWPORT-ANCHORING` folded in;
v0.7.0 may slip.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`.

One documentation commit on this branch: the design doc, this note, the index row and the
regenerated docs index. No engine code, no scenes, no tests touched — the implementation seam
is deliberately step 2 of the sequencing plan and is not started.

Tracker edits went to the docs line through `scripts/agent-update-task.sh`:
`SMALL-SCREEN-UI-REDESIGN-2026-08-05` gained the full decision record and the measurements,
and `IMPL-VIEWPORT-ANCHORING-2026-07-31` was annotated as reopened and partly superseded.

## Gates

- `python3 AGENT/Docs/gen_docs_index.py` — regenerated, committed in the same change.
- `python3 AGENT/Docs/check_docs.py` — see command output in this session.
- `python3 scripts/ci/check_session_commit_claims.py --fix` — claims appended.
- No `run_tests.sh` run: no engine code changed. The Playwright measurements above were taken
  against a fresh export of `mobile-controller-web-wiring` @ `06a22b92`, not against this
  branch, and are recorded as evidence rather than as a gate.
- Wireframe album (17 wireframes, 6 groups, 3 measured captures):
  <https://claude.ai/code/artifact/d84bbb29-6e89-4fc7-890e-f1cc0286b9b5>

## Next

**Close `IMPL-VIEWPORT-ANCHORING-2026-07-31` as superseded** — that is step 1 and the only
true blocker. Its 1280×720 floor is gone and it claims `scenes/ui/`, so nothing else can start
while it is open. Keep its `content_scale_factor`-as-a-persisted-setting work (the foundation
of the whole model) and pick over its unmerged branch
`agent/from-integration/viewport-anchoring` @ `f4a7f8f6` for the `MenuScale` reconciliation and
the div-by-zero / corrupt-cfg guards rather than merging it wholesale. Do not run its Windows
visual pass against the old floor.

Then step 2, the size-class seam: one autoload, three classes, a `size_class_changed` signal,
both density token sets and the information-density token, with headless tests for the
boundary, the hysteresis and state preservation across a live class change.
