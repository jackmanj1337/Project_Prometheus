# Key-Rebind UI — Implementation Plan — 2026-06-21

Status: Target design
Last verified: 2026-06-21

Plans the capture UI that turns the existing **read-only** keybinding list into an
editable one. The persistence primitive (`SettingsManager.rebind_action`) already exists;
what's missing is the capture flow, conflict handling, reset, and how it composes with the
gamepad bindings and the input-mode setting.

Coupled work:
- `AGENT/Docs/gamepad_layer_implementation_plan_2026-06-20.md` — adds joypad events to the
  same actions; the binding model must not wipe them ([ICD-4]).
- `AGENT/Docs/input_mode_resolver_implementation_plan_2026-06-21.md` — `[controls]` cfg +
  the input-mode setting this composes with.
- `AGENT/Docs/input_controls_open_decisions_2026-06-21.md` — open choices by `[ICD-n]`.

> **Tracking home:** GDD_10 → *Open Items Register* §A (Input/controls). Docs-only until
> the [ICD-4]/[ICD-5]/[ICD-6] decisions land.

## 1. What exists today (verified 2026-06-21)

- **`SettingsScreen.gd`** renders a **read-only** list: `_populate_keybindings()` →
  `_add_keybind_row(action, label)` builds `[name label | key label]` rows from
  `_KEYBIND_LABELS` (12 game actions) + `_DEBUG_KEYBIND_LABELS` (debug-build only). Key
  text comes from `InputDisplay.keys_for_action(action)`. Comment: *"Rebinding is deferred
  to Phase 2."* This plan is Phase 2.
- **`SettingsManager.rebind_action(action, event)`** sets `keybindings[action] = [event]`,
  re-applies the InputMap, **re-mirrors** game keys onto `ui_*` (so a rebind of `confirm`
  re-anchors `ui_accept`), and saves. It is idempotent-safe and already tested.
- **`reset_section_to_defaults("controls")`** clears `keybindings = {}` and re-applies —
  the natural "Reset Controls to Defaults" backing.
- **The mirror baseline** (`_ui_baseline_events`, `_mirror_game_keys_to_ui`) already
  handles the "don't leave the old key stuck on `ui_accept`" edge — the rebind UI inherits
  this for free; it must **not** re-implement mirror logic.

> **Contract change pending [ICD-4]:** `rebind_action`'s `keybindings[action] = [event]`
> replaces the *entire* list, which would wipe a joypad binding once the gamepad layer
> ships. The recommended per-device-slot model ([ICD-4] option A) changes this signature.
> The UI below is drafted to that model but the precise `rebind_action` change is gated.

## 2. UI flow (the capture interaction)

Convert each read-only row to an editable row:

```
[ Action name ]   [ current key glyph ]   [ Rebind ]   ( [ Pad ] if 5b=A )
```

- **Rebind** button → row enters **capture mode**: button text → "Press a key…",
  the row highlights, all other input to the screen is suppressed.
- The next eligible `InputEvent` (filtered by device class for the slot being rebound —
  see [ICD-4]) is captured:
  - **Esc / cancel** aborts capture, restores the prior binding (Esc is reserved for
    cancel, never bindable to a game action through this flow).
  - A **conflict** (event already bound to another game action) is handled per **[ICD-6]**
    (recommended: block + warn inline; keep old binding).
  - Otherwise call `SettingsManager.rebind_action(action, event)` (per-device-slot variant
    per [ICD-4]); the row re-renders from `InputDisplay`.
- **Reset Controls** button (screen-level) → `reset_section_to_defaults("controls")` then
  `_populate_keybindings()` to repaint. This is the always-available self-trap escape
  hatch that lets [ICD-5a] keep the universal nav/confirm/cancel actions rebindable.

Capture is implemented with a focused modal state on `SettingsScreen` (a `_capturing`
member + the target action/slot), consuming input in `_input` during capture so the
captured event never also triggers a game action. **No new scene** — extend the existing
list rows.

## 3. Composition with the gamepad layer ([ICD-4])

The binding model is **[ICD-4]** (per-device slots recommended). Under per-device slots:
- A row shows up to two glyphs: the K&M binding and (if [ICD-5b]=A) the pad binding.
- `rebind_action` gains a device-class filter so a keyboard rebind replaces only the K&M
  event in `keybindings[action]`, leaving any `InputEventJoypad*` event in place. The
  reverse for a pad rebind.
- The mirror (`_mirror_game_keys_to_ui`) re-runs after either, so `ui_*` tracks both.

This plan does **not** add pad bindings itself (the gamepad plan §3 does); it only
guarantees the rebind flow is *non-destructive* to them. If [ICD-4] resolves to option B
(replace-all), §3 instead requires re-stamping the action's default pad event after each
keyboard rebind — noted but not recommended.

## 4. Composition with the input-mode setting

- The rebind list is a **K&M / gamepad** concern; it stays under **Controls**, alongside
  (not gated by) the `input_mode` selector from the resolver plan. Rebinding is allowed
  regardless of the active mode (you may configure a controller while on K&M).
- Captured **pad** rebinds ([ICD-5b]=A) require no active-mode change — capture filters by
  the slot, not the active mode.
- Glyph rendering for pad bindings reuses `InputDisplay`; pretty controller glyphs are the
  **deferred** prompt/glyph polish (architecture design) — first ship shows a textual pad
  label (e.g. "Pad A"), upgraded with the glyph system later. This keeps the rebind UI
  decoupled from the deferred polish.

## 5. Edge cases the plan must cover

- **Esc reserved** — capture always treats Esc/`ui_cancel` as abort, so a player can't
  bind away their only escape. (Cancel/back as a *game* action is still rebindable to a
  different key; Esc-the-abort is a capture-flow reservation, not an InputMap change.)
- **Conflict against `ui_*` mirrors** — conflict detection runs against the **game**
  actions only (the `ui_*` entries are derived by the mirror; checking them would produce
  phantom conflicts). The plan checks `_KEYBIND_LABELS` keys, not `ui_*`.
- **Debug rows stay read-only** ([ICD-5a]) — they render but have no Rebind button.
- **Empty binding** — capturing must always set ≥1 event; there is no "unbind to nothing"
  affordance (avoids creating a dead action). Reset is the way back to defaults.
- **Persistence** — `rebind_action` already saves; no extra write path.

## 6. Headless test plan

Extend `test_settings_screen.gd`:
- A Rebind button enters capture state; a synthetic `InputEventKey` calls
  `rebind_action` with that event and the row re-renders the new glyph.
- A captured event that conflicts with another action is rejected per [ICD-6] and the old
  binding is unchanged.
- Esc during capture aborts and restores the prior binding.
- "Reset Controls" repopulates rows to defaults.
- Debug rows expose no Rebind button.

Extend `test_settings_manager.gd` (for the [ICD-4] per-device-slot variant):
- A keyboard rebind on an action that also has a joypad event keeps the joypad event.
- A pad rebind keeps the keyboard event.
- After either, `_mirror_game_keys_to_ui` leaves `ui_accept`/`ui_cancel` consistent
  (no stale event) — extends the existing 2.9 mirror tests.

**Live-verify only:** the capture-highlight feel, focus behaviour during capture, and
real-device pad capture.

## 7. Build slices

1. **Editable K&M rebinding** — convert rows to editable, capture flow, conflict policy
   ([ICD-6]), Reset button. Uses today's `rebind_action` for K&M. Fully shippable on its
   own (keyboard-only), independent of the gamepad layer.
2. **Per-device-slot model** ([ICD-4]) — the `rebind_action` signature change + two-glyph
   rows. Lands with / after the gamepad bindings so rebinding can't wipe pad events.
3. **Pad capture + textual pad glyphs** ([ICD-5b]=A) — capture joypad events; glyph polish
   deferred to the prompt/glyph system.

Slice 1 is the near-term, fully-unblocked deliverable (modulo [ICD-5a]/[ICD-6], both with
clear recommendations). Slices 2–3 sequence with the gamepad layer.

## 8. Definition of done

- DoD#1: update GDD_07 (the keybinding/rebind UI section moves from "read-only" to
  "editable") + flip the matching GDD_10 status in the same commit.
- DoD#2: no new value-set vocabulary here, so no new `check_docs` guard is required (the
  binding *content* is player data, not a fixed vocabulary). If the rebindable-action set
  is documented in GDD_07 as canonical, add a guard that `_KEYBIND_LABELS` keys match the
  documented list (same mirror-the-const pattern) — confirm at implementation.
- Tests: §6 headless coverage green; full suite + `check_docs` green per commit.

## 9. Decisions this plan is waiting on

In `input_controls_open_decisions_2026-06-21.md`: **[ICD-4]** binding model (blocks
slices 2–3; recommended option A is assumed by the draft), **[ICD-5]** rebindable set +
device coverage, **[ICD-6]** conflict policy (blocks slice 1's capture flow). With the
recommended answers, **slice 1 is ready to build**.
