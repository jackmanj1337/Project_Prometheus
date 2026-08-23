---
Role: dated
---

# Pass 4 — Input display & rebind UI

Part of the resumable v0.3.0 full-scan (`_TRACKER.md`). Document-only; no code
edits. Boundary base `ab81a21` → head `b7bcfd2`.

## Files read (at head `b7bcfd2`)

- `scripts/ui/SettingsScreen.gd` (952 lines) — full read + `git diff ab81a21 b7bcfd2`
  (+379/−12): schema-driven enum rows, the staged keybind capture/conflict/apply
  flow, the input-mode gray-state selector, and the display confirm/write-back path.
- `scripts/shared/InputDisplay.gd` (266 lines) — full read + diff (+220): the
  B6-INPUT brand-aware prompt swapping (`detect_brand`, `joypad_button_label`,
  `action_prompt`, `more_info_hint_for`, `live_action_prompt`).

## Cross-referenced

- `scripts/tests/test_settings_screen.gd` (24 checks) — covers the rebind
  capture/conflict/apply/reset flow, the input-mode gray-state selector, and the
  focus-grab subscriber.
- `scripts/tests/test_input_display.gd` (7 checks) — covers brand detection,
  face-button label swap, and `action_prompt`/`more_info_hint_for` per mode.
- `scripts/autoloads/InputModeManager.gd` — to verify the InputDisplay↔manager
  and SettingsScreen↔manager contracts (see Positives + M2).
- `project.godot` `[input]` — to enumerate the shipped action vocabulary vs. the
  rebind list (see M1).

## Findings

### M1 — Medium (CARRIED, re-CONFIRMED): rebind list omits 5 shipped gameplay actions

**Where:** `SettingsScreen.gd:630-643` (`_KEYBIND_LABELS`), consumed by
`_populate_keybindings()` (`:661`) and `_recompute_keybind_conflicts()` (`:843`).

**Problem:** `_KEYBIND_LABELS` lists 12 actions
(`cursor_up/down/left/right`, `confirm`, `cancel`, `next_unit`, `prev_unit`,
`open_menu`, `open_settings`, `inspect_unit`, `show_danger_zone`). The
`project.godot` `[input]` map defines 5 more **non-debug, player-facing** actions
that are absent: `more_info`, `peek_range`, `zoom_in`, `zoom_out`, `zoom_reset`.
All 5 are live consumers (grep-confirmed in `MapCursor.gd`, `HUD.gd`,
`AttackPreview.gd`, `UnitDetailsScreen.gd`, `InputDisplay.gd`), so the player uses
them every map but can neither see nor rebind them in Settings.

**Why it matters (two consequences):**
1. Rebinding coverage gap — a shipped, actively-used control is unbindable.
2. **Silent conflict blind spot** — `_recompute_keybind_conflicts()` only scans
   `_KEYBIND_LABELS`. Because `more_info` defaults to `F` and the zoom actions bind
   keys too, a player can rebind a listed action (e.g. `confirm`) *onto* one of the
   omitted actions' keys and the conflict flow shows **no** red row / no Apply
   block — it only detects collisions among the 12 listed actions. So the omission
   also weakens the conflict-safety guarantee the staged-apply UI is supposed to give.

**Root cause:** the list is a hand-maintained closed dictionary that drifted behind
the InputMap when `more_info`/`peek_range`/zoom actions were added. This is the same
closed-vocabulary-vs-registry smell called out in `AGENTS.md` (author-facing
extension points should be data the engine reads, not a hardcoded list that needs a
manual edit per addition).

**Recommended fix:** add the 5 rows to `_KEYBIND_LABELS` with display labels
(e.g. "More Info", "Peek Threat Range", "Zoom In", "Zoom Out", "Reset Zoom"). Then
they flow through `_populate_keybindings` and the conflict scan for free. Stronger
fix (matches the `AGENTS.md` principle): derive the editable set from the InputMap
minus the debug/`ui_*` actions, with an override map only for display labels — so a
future action can't silently fall out of the rebind UI again. Zoom actions bind
BOTH keys and pad triggers/axes, so confirm the pad-slot capture (`_input`
`InputEventJoypadMotion` branch, `:272-285`) renders a sane label for a trigger axis
(`_joypad_axis_to_string` handles `JOY_AXIS_TRIGGER_LEFT/RIGHT`, so it should).

### M2 — Pass-4 half of the carried Pass-3 Medium (input-mode change doesn't refresh)

> This is **not a new Medium** — it is the SettingsScreen-side wiring of the single
> carried Medium already counted as Pass 3's M1 (`03_input_model.md`). Recorded here
> because the fix lands partly in this file.

**Where:** the `input_mode` row `_ENUM_SETTINGS[..]` (`SettingsScreen.gd:104-113`)
has an `"availability"` marker but **no `"apply"` hook**; `_on_enum_setting_changed`
(`:350`) therefore only does `sm.set("input_mode", …)` + `sm.call("save")` and never
tells `InputModeManager` to re-resolve. Same gap on reset: `_reset_keybindings_to_defaults`
(`:806`) calls `reset_section_to_defaults("controls")` (which rewrites `input_mode`)
but does not refresh the manager either.

**Why it matters:** confirmed in Pass 3 — the active mode / on-screen prompts stay
stale until an unrelated input event nudges `_refresh_active_input_mode`. The Settings
control looks inert.

**Fix-shape wrinkle (for whoever lands it):** the existing `"apply"` hook mechanism
calls `sm.call(schema_row["apply"])` — i.e. a method **on SettingsManager**, not on
InputModeManager. So the Pass-3 recommendation (add a public
`InputModeManager.refresh_from_settings()`) can't be invoked directly through the
current hook shape. Either (a) add a thin `SettingsManager` proxy method that forwards
to `InputModeManager.refresh_from_settings()` and set `"apply"` to it, or (b) have
`InputModeManager` subscribe to a SettingsManager "settings changed" signal so any
persist re-resolves the mode (cleaner, and also covers the reset path + programmatic
saves for free). Pick (b) if a settings-changed signal is cheap to add; it closes the
reset path without a second wiring site. `refresh_from_settings` does not exist yet
(grep-confirmed) — correct, since Pass 3 was document-only.

### L1 — Low: `pad_rebind` stored via node-path re-fetch instead of the in-scope local

**Where:** `SettingsScreen.gd:701-718` (`_add_keybind_row`).

`rebind_button` and `clear_button` are declared `= null` above the `if editable`
block and assigned inside it, then stored directly into `_keybind_rows`. But
`pad_button` is declared **only inside** the block, so the dict stores it via
`row.get_node_or_null("BtnPadRebind_%s" % action)` (`:718`) — a string-path
round-trip to recover a reference it just had in hand. It works, but it's
asymmetric and fragile: the stored `pad_rebind` now silently depends on the
`"BtnPadRebind_%s"` name string matching the one set at `:702`. Hoist
`var pad_button: Button = null` next to the others and store the local, like
`rebind`/`clear`.

### L2 — Low: `more_info_hint_for` hardcodes an "F" fallback when `more_info` is unbound

**Where:** `InputDisplay.gd:199` — `var k := token if token != "" else "F"`.

In keyboard/other modes, when `more_info` has no key bound (possible once M1's fix
makes it clearable/rebindable), the hint still prints "…press F…", advertising a key
that isn't bound. Minor today (default is F), but the fallback becomes a lie exactly
when a player has cleared the binding. Prefer a neutral fallback ("the More Info key")
paralleling the gamepad branch's "the More Info button" (`:194`), or suppress the
"press …" clause when the token is empty.

## Positive observations

- **InputDisplay↔InputModeManager contract is exact.** `active_mode` reads
  `imm.get("active_input_mode")` (`InputDisplay.gd:168`) and the mode strings compared
  in `action_prompt`/`more_info_hint_for` (`"gamepad"`, `"touch"`, `"mouse_keyboard"`)
  match `InputModeManager`'s `MODE_*` constants exactly, which in turn match the
  `_ENUM_SETTINGS` input_mode row values — one consistent vocabulary across all three
  sites. `_apply_mode_availability` calls the real static `available_modes()`.
- **Prompt purity is well-factored.** `action_prompt` / `more_info_hint_for` are pure
  (no tree/autoload access), with thin live wrappers (`live_action_prompt`,
  `more_info_hint`) layering in `active_mode`/`active_pad_brand`. That's why they're
  cleanly unit-testable in `test_input_display` with no scene tree. Good seam.
- **Brand handling degrades safely.** SDL normalizes button POSITION, so bindings are
  brand-correct with zero per-brand code; only the printed label is heuristic, and the
  code + comment (`:71-79`) are explicit that a wrong brand guess is cosmetic, never a
  mis-input. Non-face buttons defer to the positional name, so an unlisted button can't
  crash the label path.
- **Staged keybind apply is genuinely safe.** `_apply_pending_keybindings` early-returns
  while `_keybind_conflicts` is non-empty (`:788`), conflicts turn both rows red + gate
  Apply, and nothing touches the live InputMap until Apply — matching the ICD-6 staged
  batch decision. Esc always aborts capture (checked before the slot match, `:267`).

## No correctness bugs found in these two files

The findings are one carried coverage/registry-debt Medium (M1), the SettingsScreen
half of the already-counted Pass-3 Medium (M2, not double-counted), and two Lows. The
capture/conflict/apply/reset state machine and the brand/prompt resolution are correct
as written.
