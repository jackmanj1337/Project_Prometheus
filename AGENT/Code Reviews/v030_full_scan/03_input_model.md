# Pass 3 — Input model & settings persistence

> Part of the v0.3.0 full-scan (`AGENT/Code Reviews/v030_full_scan/`).
> Boundary: `ab81a21`..`b7bcfd2`. Document-only; no production edits.

## Files read (at head `b7bcfd2`, via working tree — no production code lands after `b7bcfd2`)

- `scripts/autoloads/InputModeManager.gd` (141 lines, new in delta) — event
  classification, platform detect-floor resolver, `input_mode_changed` de-dupe.
- `scripts/autoloads/SettingsManager.gd` (966 lines; +530/−50 in delta) — the
  new profile-ready keybinding system (per-device-slot token maps, `"Default"`
  profile nesting, old-form migration, `_apply_keybindings`/`apply_keybindings`/
  `rebind_action`, ui_* mirror), plus the `[controls]` input_mode/touch/
  mouse_cursor persistence.
- `scripts/core/MapCursorInput.gd` (134 lines; +61 in delta) — device-agnostic
  intent decode + held-direction auto-repeat, widened for gamepad (analog poll).

Cross-referenced (not in this pass's file set, read only to confirm seams):
`scripts/ui/SettingsScreen.gd` (input_mode row + `_apply_enum` write path — the
consumer side of the carried Medium; owned by Pass 4). Cross-referenced tests:
`test_input_mode_manager.gd`, `test_settings_manager.gd`, `test_map_cursor_input.gd`.

## Summary

The input model is in good shape. `InputModeManager` keeps its decision logic in
**pure static functions** (`resolve_input_mode`, `available_modes_for_platform`,
`_detect_floor`, `event_to_input_mode`) that are fully unit-tested headless, with
the Node layer only supplying the live settings/OS reads — the right seam. The
touch→mouse suppression guard (`TOUCH_MOUSE_SUPPRESSION_MSEC`) correctly swallows
the synthetic mouse events a touch emits. `_set_active_input_mode` de-dupes so
`input_mode_changed` only fires on a real change (tested). `SettingsManager`'s
keybinding rework is careful: tokens (not `Object(InputEvent…)`) are persisted so
the cfg round-trips cleanly; a baseline of the project InputMap is captured once
and restored before every re-apply so unbinding an action returns it to its
authored default; the ui_* mirror re-anchors on each rebind (2026-06-10 issue 2.9
stays fixed); slot events are keyed by device class so a keyboard rebind never
disturbs the pad binding. `MapCursorInput` is a clean state-agnostic decoder;
analog motion is deliberately polled through `Input.get_vector` (not treated as
discrete press events) and fed the same repeat timer as keyboard/d-pad edges.

**No correctness bugs.** One **Medium** (carried from the 6/10 delta review,
re-confirmed here) and **2 Low**. One cross-file seam is flagged for Pass 5.

## Findings

### M1 — [Medium, CARRIED, re-CONFIRMED] Changing Settings → Input Mode does not refresh the active mode/prompts until the next input event

- **Where:** `InputModeManager.gd:53` (`_refresh_active_input_mode`, private) +
  its only callers `:24` (`_ready`), `:39` (`note_detected_input_mode`, from
  `_input`), `:77` (`_on_joy_connection_changed`). Consumer side:
  `SettingsScreen.gd:104-113` — the `input_mode` schema row has **no `"apply"`
  hook**, so `_apply_enum` (`SettingsScreen.gd:365`) only does
  `sm.set("input_mode", value)`.
- **Problem:** Nothing re-resolves the active mode when the *setting* changes.
  `SettingsManager.input_mode` is updated, but `active_input_mode` (and the
  `input_mode_changed` signal every `ModalScreen` subscribes to at
  `ModalScreen.gd:43` to swap key/pad prompts) is only recomputed on `_ready`,
  on a device-classified `_input` event, or on joypad hot-plug. So after the
  player picks e.g. "Gamepad", the on-screen prompts keep showing the old mode
  until the *next* stray input event happens to fire `_input` and incidentally
  re-run the resolver.
- **Why it matters:** The setting looks inert — the visible prompts contradict
  the just-chosen mode until an unrelated keypress/mouse-move nudges them. On a
  Settings screen the player may not generate another classified event for a
  while (they're reading the labels), so the lag is user-visible, not a 1-frame
  blip.
- **Root cause:** `InputModeManager` exposes **no public "re-resolve from
  settings now" entry point**, and the Settings row has no hook to call one. The
  resolver is correctly written and correctly de-duped — it is simply never
  invoked on the settings-write path.
- **Recommended fix (two files):** (1) In `InputModeManager`, add a thin public
  wrapper, e.g. `func refresh_from_settings() -> void: _refresh_active_input_mode()`.
  (2) In `SettingsScreen`, give the `input_mode` row an `"apply"` hook (or a
  bespoke branch) that resolves `/root/InputModeManager` and calls it after
  `sm.set(...)`, mirroring how display rows call `_apply_display`. `reset_section_to_defaults("controls")`
  (`SettingsManager.gd:304`) resets `input_mode` but likewise never notifies
  `InputModeManager`, so route it through the same wrapper.
- **Tradeoffs:** None material. The de-dupe at `_set_active_input_mode` makes an
  extra call cheap and idempotent when the resolved mode is unchanged (e.g.
  switching between two modes the current platform can't honour). Fix site spans
  Pass 3 (the missing public API) + Pass 4 (the SettingsScreen wiring).
- **Test gap (coverage-shape, not a bug):** `test_input_mode_manager.gd` covers
  `resolve_input_mode` and the emit de-dupe, but there is no
  settings-change→refresh test — expected, since there is no public method to
  drive one. A regression test lands naturally with the wrapper above.

### L1 — [Low] Input-mode vocabulary + `normalize_input_mode` duplicated across two autoloads (two sources of truth)

- **Where:** `SettingsManager.gd:79` `const VALID_INPUT_MODES` +
  `SettingsManager.gd:934` `static func normalize_input_mode`; and the near-identical
  `InputModeManager.gd:9` `const VALID_INPUT_MODES` + `InputModeManager.gd:103`
  `static func normalize_input_mode`.
- **Problem:** The list of valid input modes and the "unknown → auto" normalize
  rule exist independently in both singletons. `SettingsManager.load_settings`
  (`:221`) normalizes with its own copy; `InputModeManager.resolve_input_mode`
  (`:94`) with the other.
- **Why it matters:** Adding/renaming a mode (the open-registry direction the
  project favours) means editing two constant lists + two normalizers kept
  byte-identical by hand; drift silently yields inconsistent validation between
  "what persists" and "what resolves". Low today (values are stable) but it is a
  latent divergence.
- **Root cause:** The mode vocabulary was introduced on both sides of the
  settings/resolver seam without a shared owner.
- **Recommended fix:** Let one autoload own the vocabulary + normalizer and have
  the other delegate (e.g. `SettingsManager.normalize_input_mode` calls
  `InputModeManager.normalize_input_mode`, since `InputModeManager` is the
  resolver of record). Extends the duplication theme logged in Pass 1 (L4) and
  Pass 2 (L2, `_string_array_from_variant` ×4).

### L2 — [Low] `_refresh_active_input_mode` rebuilds the platform-availability Dictionary + re-queries `OS.has_feature` on every input event

- **Where:** `InputModeManager.gd:53-58` calls `available_modes()`
  (`:117-119`) → `OS.has_feature("mobile")` + `OS.has_feature("web")` + a fresh
  Dictionary literal, and `_refresh_active_input_mode` runs on **every**
  device-classified `_input` event (via `note_detected_input_mode`).
- **Problem:** Platform availability is fixed for the session, yet it is
  recomputed (with two `OS.has_feature` calls and a Dictionary allocation) on
  each classified event.
- **Why it matters:** `_input` is per-event, not per-frame, so this is minor —
  but during a held stick or rapid key stream it is avoidable per-event garbage.
- **Recommended fix:** Cache `available_modes()` once in `_ready` (recompute only
  on `joy_connection_changed` if a future mode ever depends on device presence,
  which today it does not) and read the cached Dictionary in the resolver.
  Keep the pure `available_modes_for_platform(is_mobile, is_web)` static as-is
  for tests.
- **Tradeoffs:** None; availability doesn't change mid-session.

## Cross-file seam flagged for Pass 5 (verify, not a Pass-3 finding)

`MapCursorInput` now drives cursor stepping from **two** paths: `decode()` emits
a one-shot `Intent.MOVE` on a keyboard/d-pad edge, while `poll_direction(delta)`
independently returns a step when the polled `Input.get_vector` direction differs
from `_held_dir` (`MapCursorInput.gd:116-124`). Because `cursor_left/right/up/down`
are bound to **both** keyboard keys and stick axes, a held keyboard arrow satisfies
`_direction_from_current_actions()` too. This is safe **only if** `MapCursor` arms
the repeat timer (`arm_repeat`) on the same frame it consumes the `decode()` MOVE,
so `poll_direction` sees `dir == _held_dir` and falls through to `tick()` instead
of re-`arm_repeat`-ing and returning a second immediate step. If `MapCursor`'s
`_unhandled_input` steps on the decode path **without** arming, the first poll
frame double-steps. `MapCursor` is Pass 5 — confirm the arm-on-decode ordering
there; `MapCursorInput` itself is internally correct.

## Positives

- Decision logic isolated in pure, headless-tested static functions
  (`resolve_input_mode` / `available_modes_for_platform` / `_detect_floor`) — the
  Node only supplies live reads (the project's preferred testable seam).
- Keybindings persist as reversible **string tokens**, not `Object(InputEvent…)`
  blobs, so the cfg round-trips and the old-form migration is a clean one-shot
  (`load_settings:226-239`).
- Device-class slotting (`_slot_for_event` / `_erase_slot_events`) means a
  keyboard rebind never clobbers the pad binding for the same action, and a
  token that decodes to the wrong device class safely falls back to the authored
  default (`_apply_keybinding_slots:620-621`).
- `input_mode_changed` de-dupe at `_set_active_input_mode` prevents prompt-swap
  churn (tested at `test_input_mode_manager.gd:79-84`).

## Verdict

Pass 3: **0 High, 1 Medium (carried/re-confirmed), 2 Low.** No new correctness
bugs. The Medium's root cause (missing public re-resolve entry point) lives in
this pass's `InputModeManager`; the wiring half lands in Pass 4's `SettingsScreen`.
