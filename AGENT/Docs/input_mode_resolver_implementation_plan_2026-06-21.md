---
Type: plan
Status: Target design
Last verified: 2026-06-23
---

# Input-Mode Resolver — Implementation Plan — 2026-06-21

Status: Target design
Last verified: 2026-06-21

Builds the **broader** Auto/Touch/K&M resolver that the gamepad layer plan deliberately
left out (it shipped only the gamepad arm + the signal). This is the rest of the
input-mode machine: device-class detection, the detect-floor + conditional-promotion
resolver, the gray-don't-hide + back-door availability logic, the persisted settings, and
the DoD#2 value-set guards.

Coupled work:
- `AGENT/Docs/input_mode_architecture_design_2026-06-20.md` — the architecture this
  implements; its *Resolved decisions* (4) are assumed settled and not re-opened here.
- `AGENT/Docs/gamepad_layer_implementation_plan_2026-06-20.md` — the gamepad arm + slice 3
  signal seam this generalises (see [ICD-2] for whether they land together).
- `AGENT/Docs/input_controls_open_decisions_2026-06-21.md` — every choice this plan could
  not make is deferred there by `[ICD-n]`.

> **Tracking home:** GDD_10 → *Forward Platform Workstreams* (Input-mode / gamepad) +
> *Open Items Register* §A. Docs-only until [ICD-1]/[ICD-2] resolve.

## 0. What is already settled (do not re-decide)

From the architecture design's *Resolved decisions*: cfg lives in **`[controls]`**; the
**setting vs active-mode** split; **detect-floor + conditional-promotion**; **cold-start
platform seed** (mobile→Touch, desktop→K&M, Deck→Gamepad); **gray-don't-hide + back-door
fallback**; touch default `dedicated` with a `virtual_gamepad` availability fallback until
the Dedicated layer exists; **prompt/glyph swapping deferred** but route everything through
the signal now. This plan only *implements* those.

## 1. State model (the owner)

**Owner = a new `InputModeManager` autoload ([ICD-1] resolved).** It loads **after**
`SettingsManager` and reads its three persisted values from it via `get_node_or_null` +
`.get()/.call()` (headless-autoload pattern), keeping `SettingsManager` persistence-focused
and the runtime resolver independently headless-testable. It holds:

**The persisted/runtime split follows the owner split:**

| Member | Owner | Kind | Values | Notes |
|---|---|---|---|---|
| `input_mode` | `SettingsManager` | persisted | `auto \| gamepad \| touch \| mouse_keyboard` | `[controls]` cfg; default `auto` |
| `touch_controls` | `SettingsManager` | persisted | `dedicated \| virtual_gamepad` | `[controls]`; default `dedicated` |
| `mouse_cursor` | `SettingsManager` | persisted | `follow \| click \| disabled` | **relocated** from `[gameplay]` to `[controls]` (migration §4) |
| `active_input_mode` | `InputModeManager` | runtime | one of the 4 modes | derived; never persisted |
| `_provisional_seed` | `InputModeManager` | runtime | a mode | platform seed for the zero-input frame |

The persisted values + their value-sets stay on `SettingsManager` (it owns `settings.cfg`
load/save + the normalise-on-load step); `InputModeManager` reads them. Two `const`
value-set arrays live on `SettingsManager` mirroring the existing `VALID_MOUSE_CURSOR_MODES`
pattern so the DoD#2 guard (§6) can parse them:

```gdscript
# on SettingsManager.gd, next to VALID_MOUSE_CURSOR_MODES
const VALID_INPUT_MODES: Array[String] = ["auto", "gamepad", "touch", "mouse_keyboard"]
const VALID_TOUCH_CONTROLS: Array[String] = ["dedicated", "virtual_gamepad"]
```

Each gets a `normalize_*` static (same shape as `normalize_mouse_cursor_mode`) returning
the default on any unrecognised value — this *is* the back-door guarantee at the
persistence layer (a corrupt/cloud-synced cfg can never seat an invalid mode).

## 2. Device-class detection

A single routine maps an incoming event to a device class:

```
InputEventKey, InputEventMouse*           → mouse_keyboard
InputEventJoypadButton, InputEventJoypadMotion (past deadzone) → gamepad
InputEventScreenTouch, InputEventScreenDrag → touch
```

Subtleties this plan handles:
- **Touch vs emulated mouse ([ICD-3] resolved → touch-first)** — if a real
  `InputEventScreenTouch`/`Drag` was seen this frame (or within a short window), the
  routine ignores the synthesized `InputEventMouseButton` for detection, so a tap does not
  flip K&M ⇄ Touch. Keeps `emulate_mouse_from_touch` on (the V021-17 web tap path needs
  it). **Gate:** smoke-test on real iOS Safari Godot-Web before trusting this.
- **Joypad motion noise** — only motion past the input-map deadzone counts as a real
  gamepad event, so a resting stick's drift never flips the mode.
- **Touch-style is not detectable** — `dedicated` vs `virtual_gamepad` both emit touch
  events, so detection only ever yields the *class* `touch`; the style comes from the
  `touch_controls` setting (architecture design, confirmed).

`InputModeManager` observes events via `_input` (an autoload Node receives `_input` while
in-tree). Detection updates `active_input_mode` through the resolver (§3), not directly.

## 3. The resolver (detect-floor + conditional promotion)

One pure function, headless-testable, called on (a) boot, (b) every device connect/
disconnect (`Input.joy_connection_changed` + the cold-start call), and (c) every detected
real input event:

```
resolve(setting, last_detected_class, available_modes, provisional_seed) -> active_mode
```

Rules (straight from the architecture design):
- `setting == auto` → active follows `last_detected_class` (or `provisional_seed` before
  any input). Never pins.
- `setting == explicit X`:
  - X available → active = X (promotion).
  - X unavailable → active = detect (= `last_detected_class` or seed). The "fallback" is
    just "the promotion did not take" — no special-case code.
- Emits `input_mode_changed(active_mode)` **only when `active_mode` actually changes**
  (de-dup; subscribers — focus-grab, prompt swap, virtual-gamepad visibility — must not
  fire on no-ops).

`available_modes` is computed by §5. `provisional_seed` is set once at boot from the
platform (mobile→touch, desktop→mouse_keyboard, Deck→gamepad).

> **[ICD-2] resolved → this full resolver IS the gamepad plan's slice 3** (not a
> gamepad-only stub + a later rewrite). The gamepad plan's §6/slice 3 reduces to "build
> `InputModeManager` per this plan"; the detection + signal + resolver are shared code,
> built once.

## 4. Persistence + the `mouse_cursor` relocation

- Add `input_mode` + `touch_controls` reads/writes under `[controls]` in `load_settings`
  / `save` (next to `keybindings`).
- **Relocate `mouse_cursor`** from `[gameplay]` to `[controls]` using the existing
  one-version read-old-write-new migration pattern (the same shape already used for
  `mouse_targeting`→`mouse_cursor` and `ui_scale_index`→`menu_scale_index`):
  read `[controls] mouse_cursor`, falling back to the legacy `[gameplay] mouse_cursor`,
  normalise, then `save()` writes it only under `[controls]`. Keep the legacy read for one
  release.
- `reset_section_to_defaults("controls")` extends to reset `input_mode=auto`,
  `touch_controls=dedicated`, and (now) `mouse_cursor=follow` — so "Reset Controls" clears
  cursor mode too (the reset-semantics improvement the architecture design called out).
  Remove `mouse_cursor` from the `"gameplay"` reset branch in the same edit.

## 5. Availability (gray-don't-hide + the unsupported/absent split)

`available_modes()` returns the set the selector may *enable*, per the architecture rules:

- **mouse_keyboard** — available on desktop/web; unsupported (gray) on bare mobile.
- **gamepad** — available whenever the platform *can* take a controller (desktop, mobile,
  Deck). Crucially **"supportable but absent" is NOT grayed** — a phone with no pad still
  shows Gamepad enabled (a pad could connect; Auto + detect-floor keep things operable).
- **touch** — available on touch-capable platforms; gray on desktop.
- **auto** — always available.

Two consumers of this set:
1. **Front door:** the Settings selector grays disabled modes (never removes them), and
   grays a sub-setting whose parent mode isn't active (one rule top-to-bottom).
2. **Back door:** the resolver (§3) treats an unavailable explicit setting as "promotion
   didn't take" — independent of the menu, so a corrupt/cloud cfg or a mid-battle
   disconnect always resolves to an operable mode.

The `touch_controls` Dedicated-vs-VG availability fallback (Dedicated not built yet →
resolve touch to `virtual_gamepad`) is expressed as a single `const DEDICATED_TOUCH_READY
:= false` flag the availability function reads, flipped to `true` when the Dedicated layer
ships (sequencing item #4). This keeps the *authored default* `dedicated` while the
*effective* style stays `virtual_gamepad` until then — no behavioural branch to rip out
later.

## 6. DoD#2 — `check_docs.py` guards

Add two value-set guards mirroring `[14] check_mouse_cursor_modes` exactly (parse the
`const` array via `_parse_gd_string_array`, assert it equals the expected list, assert the
GDD documents each `` `value` ``):

- **`check_input_modes`** — `VALID_INPUT_MODES == ["auto","gamepad","touch","mouse_keyboard"]`
  and GDD_07 (UI/UX, input/controls section) names each.
- **`check_touch_controls`** — `VALID_TOUCH_CONTROLS == ["dedicated","virtual_gamepad"]`
  and GDD_07 names each.

Register both in `main()`'s `steps` list (next numbers after `[17]`). This is the DoD#2
requirement: the rule (these are the only valid values) lands with its automated check in
the same change.

## 7. Headless test plan

New `test_input_mode_resolver.gd` (pure-logic, no scene):
- **resolver matrix** — for each `setting × available × last_detected × seed`, assert the
  right `active_mode` (auto-follows; explicit-pins; explicit-unavailable→detect;
  re-promote-on-return).
- **signal de-dup** — drive a sequence that lands on the same mode twice; assert exactly
  one `input_mode_changed` per *real* change.
- **detection mapping** — feed synthetic `InputEventKey` / `InputEventJoypadButton` /
  `InputEventScreenTouch`; assert the derived class. Include the [ICD-3] touch-vs-emulated
  case once that's decided.
- **normalisation/back-door** — `normalize_input_mode` / `normalize_touch_controls` return
  the default on garbage; a cfg with an invalid stored mode resolves to an operable mode.
- **availability** — assert the unsupported (gray) vs supportable-but-absent (not gray)
  split per platform stub.

Extend `test_settings_manager.gd`:
- `mouse_cursor` round-trips under `[controls]`; a legacy `[gameplay] mouse_cursor` cfg
  still loads (migration); after `save()` it is written only under `[controls]`.
- `reset_section_to_defaults("controls")` resets all three input settings;
  `"gameplay"` no longer touches `mouse_cursor`.

**Live-verify only:** focus-grab on switch-to-gamepad, focus-drop on switch-away, the
visual gray state, and real-device connect/disconnect feel.

## 8. Build slices

1. **Persisted state + migration + value-set guards** — §1, §4, §6. Headless-testable,
   ships nothing visible. Lowest-risk first; unblocks the cfg layout the rest assumes.
2. **Detection + resolver + signal** — §2, §3, in the new `InputModeManager` autoload.
   **This is the gamepad plan's slice 3** ([ICD-2]). Headless-test the matrix; live-verify
   the switch feel with the gamepad layer present.
3. **Availability + selector grays** — §5 + the Settings UI gray/nest rendering. Live UI,
   so it follows the dual-UI-tax constraints (reflow, focus graph, touch targets).

Slice 1 is fully independent (pure persistence on `SettingsManager` — the consts +
`normalize_*` + the `mouse_cursor` relocation), so it can land first. Slices 2–3 add the
`InputModeManager` autoload and tie to the gamepad layer.

## 9. Definition of done

- DoD#1: update GDD_07 (input/controls + the new value-sets) **and** GDD_10 Platform
  Targets / Forward Platform Workstreams status in the same commit.
- DoD#2: the two `check_docs.py` guards (§6) land in the same change as the consts.
- Tests: §7 headless coverage green; full suite + `check_docs` green per commit.

## 10. Decisions — all resolved (2026-06-21)

Per `input_controls_open_decisions_2026-06-21.md`: **[ICD-1]** → new `InputModeManager`
autoload; **[ICD-2]** → the resolver IS gamepad slice 3 (built once, no stub); **[ICD-3]**
→ touch-first detection, gated on an iOS Safari smoke test. **This plan is build-ready.**
Slice 1 (persistence + value-set guards + `mouse_cursor` relocation) has no remaining
dependency and is the recommended first commit.
