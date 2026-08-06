# Session Note - 2026-08-06

## Branch context

- Branch: `agent/from-integration/mobile-controller-web-wiring`
- Base branch: `agent/integration`
- Base SHA: `cd7797fe0985999bac16fd4c6b46e1e299c580fe`
- Coordination Work ID: `MOBILE-WEB-CONTROLLER-2026-08-04`

## What was done

**Slice 3 — the Game View editor.** A player can now drag the game canvas itself:
move the whole rectangle, or resize it from four edge and four corner handles,
with snapping, guides, a minimum-size guard, Undo and a Reset that tells the
truth. The plan sequenced this after Slice 4's control editor precisely so it
could inherit that editor's contract, and it does — the gesture is local, the
result is reported once on release, and the engine owns validation.

### The decision that shaped everything else: one rectangle, one owner

Before this, the Game View was two numbers (`game_view_size` + `game_view_offset`)
resolved per orientation, deliberately chosen because that pair "cannot express an
off-screen or inside-out canvas". A free editor needs a free rectangle, so the
question was where it lives.

It lives in **the active combination's own `viewport`** — the same place the
control placements live — and not in a rectangle of its own. A saved arrangement
is *where the canvas sits and where the controls sit*; a free editor layered over
the preset rows would give one rectangle two owners, and the anti-off-screen
property came back for free because `ControllerLayout.effective_viewport()`
already clamps and already carries the 640x360 minimum.

The consequence is the interesting part. **Opening the editor folds any live
preset into the combination and returns the preset row to `auto`.** That is the
control editor's materialization rule wearing a second hat: while a preset is
active, the rectangle on screen comes from the settings override rather than from
the combination, so a drag would be *measured against one rectangle and stored in
another* — the canvas jumps on first touch and every later drag is silently
overruled by the preset. Adoption is itself an undoable step and each undo entry
carries the preset it was pushed under, so undoing back past the adoption returns
the player to the preset they were on rather than stranding them on Automatic
looking at a rectangle Custom produced.

Reset **writes** the built-in rectangle rather than clearing an override, which is
the opposite of `reset_elements()`. The reason is structural, not a preference: an
empty element list has a meaning ("follow the registry placement"), and a viewport
is one rectangle whose keys are always present, so there is no empty state that
could mean the same thing.

### What the engine does and what the browser does

`ControllerService` gained an edit **mode** (`none`/`controls`/`viewport`) in place
of the editing bool. Two booleans would have permitted a state the screen cannot
express: both editors need the shell overlay to swallow every pointer, so a screen
offering both would give one touch two meanings. `is_editing()` survives as the
derived "are pointers mine?" answer that every touch path already asks.

The shell draws a **ghost frame** and eight handles. The canvas is not touched
until release, and the reason is sharper than it is for a control: under
`html/canvas_resize_policy=0` the backing store is ours, so applying a rect
reallocates a GPU buffer at the new device-pixel size — a per-move apply would do
that on every frame of the drag and re-render the whole game into each one.

The eight handles are one code path: a handle names which of the four edges it may
move. Each moved edge snaps independently to the window, the safe area, the
screen's middle, and the box the controls occupy. **Order is load-bearing** — snap,
then the minimum, then the window bounds. Snapping last could produce a canvas the
engine would reject; clamping first could leave a snapped edge off-screen. The
clamps are applied per edge rather than to the finished rectangle, so dragging the
left handle past the right one stops instead of turning the canvas inside out.

Controls are still drawn in this editor and are **inert**. They are there so the
player can see what the canvas has to avoid; one that took a pointer would steal
it from the frame behind it. Overlap is **reported, not refused** — the frame
switches to a dashed border when the canvas covers the controls, because a
full-window canvas over the controls is the intended landscape arrangement and the
wrong portrait one, and only the player knows which they meant.

`publish_canvas` now reaches the renderer as well as the layout global. That is the
fourth thing split out of the layout publish, for the fourth identical reason: a
rebuild drops held controls. It is also how the frame learns what the drag actually
produced, since the engine clamps and may aspect-lock the reported rectangle — but
never mid-gesture, where the finger is the newer truth.

### Two smaller things worth knowing

`_game_view_override()` resolved `/root/SettingsManager` directly while every other
settings read in the file goes through `_settings_node()`. That made the entire
override branch unreachable under test — which is exactly where the adoption rule
lives. Now routed through the seam, and the stub carries real `game_view_*` fields.

A resize mid-edit redraws the guides. A mobile URL bar collapsing is a resize, it
happens unbidden, and it moves the controls; a guide still drawn around where they
used to be is worse than no guide at all.

## Commits

Four commits on the feature branch. The first adds the engine seam — edit modes,
the free-rect writes, the undo stack that carries the preset, the `viewport` shell
message, guard `[48]` extended and GDD_07 documenting it. The second is the browser
half: the frame, the handles, the snapping, the guides, and the renderer's new
`canvas` entry point. The third wires it to Settings — Edit Game View, Undo Game
View Change, the preset rows going inert while the editor holds their rectangle,
and Reset resetting the rectangle as well as the preset. The fourth is this note.

Ownership is in `AGENT/Session Notes/CLAIMS.tsv`.

## Gates

- `bash run_tests.sh` — green (run four times across the session).
  `test_controller_service` 152 -> 174, `test_settings_screen` 36 -> 37.
- `bash scripts/ci/check_gdscript_style.sh` — PASS, 301 files.
- `python3 AGENT/Docs/check_docs.py` — PASS, 49 checks.
- `node tools/web/controller_shell.test.mjs` — 45 -> 78 assertions, green.

**Browser-verified against a real export, 17/17.** Chromium on the served v0.7.0
web export at `?test_bridge=1`, driven entirely through the on-screen controls:
they open Settings, stepping reaches the Edit Game View row, the editor engages and
draws its frame around the canvas the engine actually has, eight handles are
grabbable, **the frame survives the whole gesture** (nothing republished the layout
under the finger), the canvas does not resize until release, the south handle
resizes only the height, the whole rectangle then moves, and **all of it is still
there after a page RELOAD** — shell to bridge to service to `SettingsManager` to
`user://` and back. No page errors.

That probe is deliberately not checked in, for the same reason the last one was
not: it needs an export plus a served build, and folding it into
`scripts/playwright-drive.sh` belongs with Slice 6's matrix work. Two notes for
whoever writes the next one. The test bridge reports the Settings modal as
`settings`, not `SettingsScreen` — a probe that expects the class name reads a
working screen as a missing one. And a handle centred on the window's own edge is
half outside the viewport, where no pointer event can be delivered: grab a few
pixels inside the frame.

## Next

**Slice 3's remaining acceptance step: verify every major screen at the minimum
candidate viewport (640x360).** The editor now makes that reachable, which it was
not before. Note the standing conflict recorded in the handoff — that step cannot
pass in portrait while the in-game UI has no portrait layout
(`SMALL-SCREEN-UI-REDESIGN-2026-08-05`), which is why this session's browser pass
ran in landscape.

Still open from the plan's §6 list: global opacity and scale (the model carries
`global_opacity` and nothing edits it), combination save/rename/delete, Slice 5's
themes and haptics, and Slice 6's album and matrix.

Branch is unmerged; no PR opened.
