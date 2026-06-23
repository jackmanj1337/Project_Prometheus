---
Type: plan
Status: Target design
Last verified: 2026-06-23
---

# Key-Rebind UI — Implementation Plan — 2026-06-21

Status: Target design
Last verified: 2026-06-21

Plans the capture UI that turns the existing **read-only** keybinding list into an
editable one. The persistence primitive (`SettingsManager.rebind_action`) already exists;
what's missing is the capture flow, conflict handling, reset, and how it composes with the
gamepad bindings and the input-mode setting.

Coupled work:
- `AGENT/Docs/plans/gamepad_layer_implementation_plan_2026-06-20.md` — adds joypad events to the
  same actions; the binding model must not wipe them ([ICD-4]).
- `AGENT/Docs/plans/input_mode_resolver_implementation_plan_2026-06-21.md` — `[controls]` cfg +
  the input-mode setting this composes with.
- `AGENT/Docs/registers/input_controls_open_decisions_2026-06-21.md` — open choices by `[ICD-n]`.

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

> **Contract change ([ICD-4] resolved → per-device slots):** `rebind_action`'s
> `keybindings[action] = [event]` replaces the *entire* list, which would wipe a joypad
> binding once the gamepad layer ships. `rebind_action` is changed to a **per-device-slot**
> model: each action stores up to one K&M binding **and** one joypad binding, and a rebind
> replaces only the slot matching the captured event's device class. The mirror still
> re-runs after either.

### 1a. Human-readable persistence ([ICD-5a-i])

The "edit the cfg by hand" escape hatch (ICD-5) only works if bindings are human-editable.
Today `keybindings` serialises `InputEvent` **objects** → opaque `Object(InputEventKey,…)`
blobs in `settings.cfg`. Change the persisted format to a **per-device-slot, human-readable
shape** and rehydrate to `InputEvent`s on load:

```
keybindings[action] = { "kbd": "<keycode/mouse token>", "pad": "<joy button/axis token>" }
```

- Tokens are plain strings/ints (e.g. `"Z"`, `"Mouse1"`, `"JoyA"`, `"JoyAxis5+"`), not
  serialized objects — so a tinkerer can edit `settings.cfg` directly to recover.
- `load_settings` parses each token into the matching `InputEvent` (a small token↔event
  map); an unparseable token falls back to that action's default slot (back-door safety,
  same spirit as the resolver's `normalize_*`).
- This is a one-version migration from the old object form (read-old-write-new, same
  pattern as `mouse_targeting`/`ui_scale_index`). Detailed token table at implementation.

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
  - A **conflict** (event already bound to another game action **in the same device slot**)
    triggers a **two-way swap** ([ICD-6]): capturing input E for action A where E belongs
    to B → A gets E, **B inherits A's previous binding for that slot** (B's slot is left
    empty if A had none). The inline notice must state *both* changes ("Bound E to A; moved
    B to <A's old input>") since two bindings changed at once.
  - Otherwise call `SettingsManager.rebind_action(action, event)` (per-device-slot variant
    per [ICD-4]); the row re-renders from `InputDisplay`.
- **Reset Controls** button (screen-level, **always visible/accessible** per [ICD-5a]) →
  `reset_section_to_defaults("controls")` then `_populate_keybindings()` to repaint. This is
  the always-available self-trap escape hatch that lets every action — including the
  universal nav/confirm/cancel — stay rebindable. Backed up by the hand-editable cfg (§1a)
  as the ultimate recovery path.

Capture is implemented with a focused modal state on `SettingsScreen` (a `_capturing`
member + the target action/slot), consuming input in `_input` during capture so the
captured event never also triggers a game action. **No new scene** — extend the existing
list rows.

## 3. Composition with the gamepad layer ([ICD-4])

The binding model is **per-device slots** ([ICD-4] resolved):
- A row shows up to two bindings: the K&M binding and the pad binding (pad capture ships
  in v1 per [ICD-5b]; pad renders a textual label until glyphs land — §4).
- `rebind_action` gains a device-class filter so a keyboard rebind replaces only the K&M
  slot in `keybindings[action]`, leaving any joypad binding in place. The reverse for a pad
  rebind. (Swap conflicts, §2, also resolve within the matching slot only.)
- The mirror (`_mirror_game_keys_to_ui`) re-runs after either, so `ui_*` tracks both.

This plan does **not** add pad bindings itself (the gamepad plan §3 does); it only
guarantees the rebind flow is *non-destructive* to them.

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
- **All actions rebindable** ([ICD-5a]) — including the universal nav/confirm/cancel set;
  the always-visible Reset (§2) + hand-editable cfg (§1a) make any self-trap recoverable.
  Debug rows default to read-only (they ship in debug builds only and are slated for
  removal — persisting bindings for them is pointless; implementer's call).
- **Swap can vacate a slot** — under the [ICD-6] swap, if A had no prior binding in the
  device slot, the swapped action B is left **unbound for that device** (shows "unbound").
  This is acceptable and recoverable (rebind it, or Reset). There is no separate
  "unbind to nothing" *button* — vacancy only ever arises as a swap side-effect.
- **Persistence** — `rebind_action` saves; the human-readable format (§1a) is what gets
  written, so the cfg stays hand-editable.

## 6. Headless test plan

Extend `test_settings_screen.gd`:
- A Rebind button enters capture state; a synthetic `InputEventKey` calls
  `rebind_action` with that event and the row re-renders the new glyph.
- A captured event that conflicts with another action **swaps** ([ICD-6]): A gets the new
  input, B inherits A's old binding for that slot; assert both rows update.
- A swap where A had no prior slot binding leaves B unbound for that device.
- Esc during capture aborts and restores the prior binding.
- "Reset Controls" repopulates rows to defaults.
- Debug rows expose no Rebind button.

Extend `test_settings_manager.gd` (per-device-slot model, [ICD-4]):
- A keyboard rebind on an action that also has a joypad binding keeps the joypad binding.
- A pad rebind keeps the keyboard binding.
- **Human-readable round-trip ([ICD-5a-i])** — a rebind writes a plain-token cfg (not an
  `Object(...)` blob); `load_settings` rehydrates it to the right `InputEvent`; an
  unparseable token falls back to that slot's default.
- After either, `_mirror_game_keys_to_ui` leaves `ui_accept`/`ui_cancel` consistent
  (no stale event) — extends the existing 2.9 mirror tests.

**Live-verify only:** the capture-highlight feel, focus behaviour during capture, and
real-device pad capture.

## 7. Build slices

The decisions re-ordered this: the persistence foundation lands first so we never ship the
old object-blob cfg and re-migrate.

1. **Binding-model + persistence foundation** ([ICD-4] + [ICD-5a-i]) — `keybindings` becomes
   the per-device-slot dict with **human-readable token** serialization + the one-version
   migration from the old object form; `rebind_action` gains the device-class slot filter.
   Headless-testable, no UI change yet; independent of the gamepad layer (the K&M slot
   stands alone). Lowest-risk first.
2. **Editable K&M rebind UI** — convert rows to editable, capture flow, **swap** conflict
   ([ICD-6]), always-visible Reset ([ICD-5a]). Shippable keyboard-only.
3. **Pad capture + textual pad labels** ([ICD-5b]) — capture joypad events into the pad
   slot; sequence with the gamepad bindings; pretty glyphs deferred to the prompt/glyph
   system.

Slices 1–2 are the near-term, fully-unblocked deliverable. Slice 3 sequences with the
gamepad layer (which supplies the default pad bindings the rebind UI then edits).

## 8. Definition of done

- DoD#1: update GDD_07 (the keybinding/rebind UI section moves from "read-only" to
  "editable") + flip the matching GDD_10 status in the same commit.
- DoD#2: no new value-set vocabulary here, so no new `check_docs` guard is required (the
  binding *content* is player data, not a fixed vocabulary). If the rebindable-action set
  is documented in GDD_07 as canonical, add a guard that `_KEYBIND_LABELS` keys match the
  documented list (same mirror-the-const pattern) — confirm at implementation.
- Tests: §6 headless coverage green; full suite + `check_docs` green per commit.

## 9. Decisions — all resolved (2026-06-21)

Per `input_controls_open_decisions_2026-06-21.md`: **[ICD-4]** per-device slots;
**[ICD-5a]** all actions rebindable + always-on Reset; **[ICD-5a-i]** human-readable cfg
serialization; **[ICD-5b]** capture any device now, glyphs later; **[ICD-6]** swap on
conflict. **This plan is build-ready** — slices 1–2 have no remaining dependency.
