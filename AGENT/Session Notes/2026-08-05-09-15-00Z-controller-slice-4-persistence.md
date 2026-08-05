# Session Note - 2026-08-05-09-15-00Z - controller slice 4 persistence

## Branch context

- Branch: `agent/from-integration/mobile-controller-web-wiring`
- Base branch: `agent/integration`
- Base SHA: `d61de61398f307b82a3c19aa9a9adcaef487b7ab`
- Coordination Work ID: `MOBILE-WEB-CONTROLLER-2026-08-04`

## What was done

Took the next bounded action the remaining-slices handoff names — **Slice 4,
starting with layout persistence** — and then its second step, the profile
selector, since the first unblocked it.

**Step 1, persistence.** `ControllerService` rebuilt
`ControllerLayout.default_collection()` on every launch, so a profile change or a
moved control lasted exactly one session. Every other control-related setting was
durable and this one was not, which is also what made Slice 5's theming
meaningless: a theme cannot be chosen if a layout cannot be saved.

`SettingsManager` now persists two `[controls]` keys — `controller_combinations`
(the whole collection, stored raw) and `controller_active_id` (the chosen slot).
Raw and type-guarded rather than clamped, because `ControllerLayout.normalize()` is
already the validation gate and runs on every entry when the service restores it;
clamping in the manager would be a second, separately-wrong copy of the same rules.
Both empty is the never-saved state **and** what a Controls reset produces, so a
first launch and a reset take one path back to the built-in collection.

`ControllerService` gained `restore_layout` / `layout_settings_payload` /
`save_layout` / `select_combination` / `commit_active_combination`. `save_layout()`
is the only method that touches disk, so an editor drag can re-apply a combination
every frame without a ConfigFile write per tick — callers commit deliberately, the
same shape `SettingsScreen` already uses for Game View.

**Step 2, the selector.** Two Settings rows, Control Style and Arrangement. The
model, the payload and the shell had supported all three styles and the whole
collection since Slice 2; only the UI was missing, so a player could not reach
anything the service could already do. Both rows are hidden off web for the same
reason the Game View rows are.

Three decisions worth keeping:

1. **A chosen slot applies only while the orientation can display it.** A
   landscape-pinned combination's viewport and element fractions were authored for
   the other shape, so honouring it in portrait hands the player a layout that does
   not fit. The choice is remembered rather than discarded — rotating back restores
   it.
2. **Registry defaults are no longer baked into the active combination.**
   `build_payload_for()` already resolves an empty element list against the
   registry, so keeping it empty preserves the meaning "follow the built-in
   placement" all the way into the saved cfg. A player who never moved a control
   therefore gets an updated build's defaults instead of a frozen copy of an older
   build's. Payload output is unchanged.
3. **`commit_active_combination()` does not pin what it replaces.** Editing the
   combination the orientation picked is not the same as choosing it. Without this,
   changing control style while Arrangement was on Automatic silently pinned the
   arrangement and rotation quietly stopped swapping layouts, with nothing on
   screen to explain why. Appending a *new* slot still selects it, because a fresh
   slot is reachable no other way.

**One trap, recorded because it is not visible in the code.** The service reloads
on `settings_changed` so an external edit (a Controls reset) is picked up, but a
reload emits `layout_changed`, and that makes the shell rebuild every button —
dropping whatever the player is holding. The echo of the service's own save is
therefore suppressed by comparing a **serialized** snapshot: `Array`/`Dictionary`
equality semantics differ between Godot versions, and a reference compare would
have fired the rebuild on every settings save from any screen.

## Commits

Ownership is recorded in `AGENT/Session Notes/CLAIMS.tsv`.

Two substantive commits — `22ffafb3` (persistence, plus `check_docs` guard `[45]`)
and `4ebab707` (the two Settings rows) — with a claim-ledger commit after each.

`22ffafb3` also repairs a sentence `GDD_07_Input_Cursor.md` lost in `00ca02f5`,
when the Game View paragraph was inserted mid-sentence and left the mouse-cursor
and touch-presentation vocabularies as a dangling fragment.

## Gates

- `bash run_tests.sh` — all suites green, twice (once per substantive commit).
  `test_controller_service` 60 → 80; `test_settings_manager` +1 case;
  `test_settings_screen` 33 → 34.
- `bash scripts/ci/check_gdscript_style.sh` — PASS, 301 files.
- `python3 AGENT/Docs/check_docs.py` — PASS, 45 checks. New guard `[45]` verified
  to FAIL on a source-side rename **and** on a doc-side rename, not merely to pass
  today.
- `node --test tools/web/controller_shell.test.mjs` — pass, 0 fail.
- Browser evidence, ad-hoc Playwright probe against a fresh export (emulated
  Pixel 7 portrait, 412×839): shell installs, **9 labeled controls render**, no
  page errors. Every control box measured — all nine sit at y 564–812, the canvas
  ends at y 371.8, so **nothing overlaps the canvas**. The browser's canvas rect
  `(0, 140.02) 412×231.75` matches the headless model's rect for the same window
  **exactly**, so the export is faithfully rendering the model.
  `scripts/playwright-drive.sh` still has no mobile-emulation flag, so this had to
  be hand-written again.
- **Not browser-verified:** the two new Settings rows. Reaching Settings on a phone
  is currently impossible — see below.

The persistence tests deliberately run against a stub settings node rather than the
autoload, so `test_controller_service` does not race `test_settings_manager` on
`user://settings.cfg` in a parallel run. The cfg round-trip of the two new keys is
covered in `test_settings_manager` instead, which already owns that file.

## Found, not fixed

**The default control profile has no directional controls, so a phone player cannot
navigate any menu.** Measured, not inferred:

- `labeled_actions` → `confirm, cancel, open_menu, inspect_unit, more_info,
  prev_unit, next_unit, zoom_in, zoom_out`
- `virtual_gamepad` → `cursor_up, cursor_down, cursor_left, cursor_right, confirm,
  cancel, inspect_unit, more_info, prev_unit, next_unit, show_danger_zone,
  open_menu`

`ControllerLayout.default_combination()` selects `labeled_actions`, and menu
navigation needs `ui_up`/`ui_down`, which only the d-pad supplies. The main-menu
screenshot shows the highlight sitting on New Game with no way to move it. The new
Control Style row is exactly the fix — and it lives inside Settings, which cannot
be reached, so it does not resolve itself.

Left as an owner call rather than silently changed, because there are three
defensible answers and they are not equivalent: default touch web to
`virtual_gamepad`; add directional controls to `labeled_actions`; or keep the
default and make the style reachable from somewhere that needs no navigation.
Tracked as `PP-CONTROLLER-TOUCH-MENU-NAV-2026-08-05`.

**Portrait's canvas is 16:9-locked by default**, so a 412×839 phone gets a
412×231.75 game area rather than the 412×461 band the layout authors — the
`portrait` default viewport carries `aspect_locked: true` and `_lock_aspect()`
shrinks to fit. Backing store is 1082×608, below the ratified 1280×720 design
floor. This is the §5 "portrait runs but is not laid out for portrait" gap, not a
new defect, but the numbers were not previously recorded.

## Next

**Slice 4 step 3, element editing** (drag, scale, opacity) on the existing
`set_editing` seam, which already pauses gameplay and captures pointers. Step 1 and
step 2 are done; steps 3 and 4 (optional-control toggles, auto-hide) remain, and
Slice 3's drag editor should still follow Slice 4's per the ordering argument in
`AGENT/Docs/plans/mobile_web_controller_remaining_slices_handoff_2026-08-05.md`.

Before that, the owner call above is worth answering: it decides whether the
default a tester meets on a phone is usable at all, and the v0.7.0 bundle is out
for exactly that kind of decision.

Branch is unmerged; no PR opened.
