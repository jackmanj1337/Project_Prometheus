---
Type: plan
Status: Target design
Last verified: 2026-06-23
---

# Gamepad Input Layer — Implementation Plan — 2026-06-20

Status: Target design
Last verified: 2026-06-20

Coupled work:
- `AGENT/Docs/input_mode_architecture_design_2026-06-20.md` — this plan builds that
  design's **sequencing item #1** (the gamepad layer = keystone for Deck, phone+controller,
  virtual-gamepad, and the debug-web shell).
- `AGENT/Docs/shared_selector_extraction_design_2026-06-20.md` — V021-15: the single
  joypad-wiring point this plan attaches More-Info navigation to.

> **Tracking home:** `AGENT/GDD/GDD_10_Roadmap.md` → *Forward Platform Workstreams*
> (Input-mode / gamepad architecture) + *Open Items Register* §A. No code yet — this pins
> the build before bindings are added so all 19 actions are wired once, correctly.

## 1. Action map review (locked 2026-06-20j)

All 19 input-map actions, audited against every non-test `is_action_*` call site. Most
"verbs" are already menu-driven (`ActionMenu` = Attack/Staff/Item/Wait/Pair Up/…;
`MapMenu` = End Turn/Settings/Quit), so only a small set are true direct inputs.

| Action | Keys today | Gamepad home | Class |
|---|---|---|---|
| `cursor_up/down/left/right` | WASD + arrows | D-pad + left stick | Universal nav |
| `confirm` | Z/Enter/Space/LMB | A | Universal select |
| `cancel` | X/Esc/RMB | B | Universal back |
| `inspect_unit` | I | Y | Map primary |
| `more_info` | F | X | Map primary (contextual; V021-15 cycle) |
| `next_unit` | Tab | RB | Map primary (cycle) |
| `prev_unit` | Shift+Tab | LB | Map primary (cycle) |
| `open_menu` | M | Start | Opens pause menu (→ Settings/End Turn/Quit) |
| `zoom_in` | = / wheel-up | RT | Camera |
| `zoom_out` | − / wheel-down | LT | Camera |
| `zoom_reset` | 0 | L3 (left-stick click) | Camera (low-frequency) |
| `open_settings` | O | — (via Start → Settings) | Menu-only |
| `show_danger_zone` | Q / MMB | R3 (right-stick click) | Contextual (see §4) |
| `debug_toggle_force_levelup` | F2 | — | Excluded (release blocker) |
| `debug_toggle_growth_boost` | F3 | — | Excluded (release blocker) |
| `debug_toggle_hotseat_override` | F1 | — | Excluded (release blocker) |

Result: the full normal-play set fits a standard controller with **zero button-combos** —
the pause menu absorbs the long tail. Debug toggles stay keyboard-only (they are slated
for removal as release blockers; binding them to a pad would risk shipping them).

## 2. Focus / navigation wiring (resolved — was the open question)

**Finding (read 2026-06-20):** the UI is a *hybrid* focus model, not pure-focus or
pure-custom:
- Custom menus (`ActionMenu`, `ItemMenu`, `WeaponMenu`) handle `cursor_up/down` in
  `_input`, call `_move_focus` → `grab_focus()`, and **consume** the event
  (`set_input_as_handled()`).
- **Activation** relies on the focused `BaseButton`'s built-in `ui_accept` (Enter/Space,
  which overlaps `confirm` today by coincidence, not design).
- Native controls (`SettingsScreen` sliders + `OptionButton`s) depend on Godot's built-in
  `ui_up/down/left/right` + `ui_accept` to operate at all.

**Decision: bind the gamepad to BOTH the `ui_*` built-ins and the custom actions.** This
is necessary, not belt-and-suspenders:
- **`ui_accept` ← A** is *required* — focused buttons, OptionButton dropdowns, and slider
  commit all press through it; nothing else activates them.
- **`ui_up/down/left/right` ← d-pad/left-stick** is *required* for the Settings sliders /
  OptionButtons (no custom `cursor_*` handler there).
- **`cursor_*` ← d-pad/left-stick** keeps the map cursor, the custom menus, and the V021-15
  selector working.
- **`confirm`/`cancel` ← A/B** keep `MapCursorInput`, `LevelUpScreen`, `SettingsScreen`,
  and the custom menus working (they read the custom actions explicitly).

No double-movement: the custom menus consume `cursor_*` in `_input` (which runs before the
viewport's default focus navigation), so the duplicate `ui_*` binding is swallowed there;
on pure-focus screens only `ui_*` is handled. This relies on per-menu consume **discipline**,
not structure — the durable fix (an input-context owner so exactly one context is live) is
**Rebuild C, deferred to V021-15** (§5). For this plan, an adoption-pass audit + a test that
asserts every cursor-handling menu consumes (§8) is the guard.

**Single source of truth for accept/cancel:** keep `confirm`/`cancel` and
`ui_accept`/`ui_cancel` carrying the **same event list** (so `Z` and gamepad `A` both
activate a focused control, not just `ui_accept`'s defaults). This closes the pre-existing
`confirm`-vs-`ui_accept` overlap (today they coincide only on Enter/Space) rather than
leaving it coincidental.

## 3. The binding scheme (`project.godot` additions)

Add joypad events to the existing actions (Godot `JoyButton` / `JoyAxis`; SDL/Xbox layout):

| Action(s) | Joypad event |
|---|---|
| `cursor_up` + `ui_up` | `JOY_BUTTON_DPAD_UP` (11); left-stick `JOY_AXIS_LEFT_Y` − |
| `cursor_down` + `ui_down` | `JOY_BUTTON_DPAD_DOWN` (12); left-stick `JOY_AXIS_LEFT_Y` + |
| `cursor_left` + `ui_left` | `JOY_BUTTON_DPAD_LEFT` (13); left-stick `JOY_AXIS_LEFT_X` − |
| `cursor_right` + `ui_right` | `JOY_BUTTON_DPAD_RIGHT` (14); left-stick `JOY_AXIS_LEFT_X` + |
| `confirm` + `ui_accept` | `JOY_BUTTON_A` (0) |
| `cancel` + `ui_cancel` | `JOY_BUTTON_B` (1) |
| `inspect_unit` | `JOY_BUTTON_Y` (3) |
| `more_info` | `JOY_BUTTON_X` (2) |
| `next_unit` | `JOY_BUTTON_RIGHT_SHOULDER` (10) |
| `prev_unit` | `JOY_BUTTON_LEFT_SHOULDER` (9) |
| `open_menu` | `JOY_BUTTON_START` (6) |
| `zoom_in` | `JOY_AXIS_TRIGGER_RIGHT` (5) past threshold |
| `zoom_out` | `JOY_AXIS_TRIGGER_LEFT` (4) past threshold |
| `zoom_reset` | `JOY_BUTTON_LEFT_STICK` (7, L3) |
| `show_danger_zone` | `JOY_BUTTON_RIGHT_STICK` (8, R3) |

Per-action deadzone stays the input-map default (0.5) except the camera triggers, which
want a smaller deadzone so a light pull starts zooming. Edit via the Godot editor or by
hand-appending events to each action block (keep the existing keyboard/mouse events).

## 4. Contextual danger zone — depends on an unbuilt feature

`show_danger_zone` today (`MapCursor`) is **faction-wide only**. The intended R3 behaviour
is contextual:
- **R3, cursor not over an enemy** → faction-wide threat range (exists today).
- **R3, cursor over a specific enemy** → that enemy's individual threat range
  (**does not exist** — this is the UI/UX backlog item "individual unit threat range").

**Prerequisite dependency edge:** the per-enemy contextual mode requires implementing
per-unit threat-range computation + render first. **Now designed:**
`AGENT/Docs/individual_threat_range_design_2026-06-21.md` — it extracts the per-unit
primitive (`get_unit_threat_tiles`) and defines a shared **resolver** routing the
`show_danger_zone` action by cursor context: **over a hostile enemy → toggle it in a
persistent watch set; over empty terrain → cycle the display mode** (`full | selected |
combined | none`). The same resolver serves the mouse MMB and the gamepad R3, so R3-over-
enemy edits the set and R3-over-empty cycles the mode. That design's slices 1–2 are the
prerequisite; this plan's slice 4 = its slice 3 (bind R3 through the resolver). Until those
land, R3 binds to the faction-wide path only. (Binding note: the action is **MMB**, not RMB
— see that design §3.)

## 5. Map-cursor input rebuild — NOT a data edit (Rebuilds A + B)

**Finding (read 2026-06-20):** the §3 "add joypad events" approach is enough for menus and
native controls, but **not for the map cursor**. `MapCursorInput` is keyboard-typed:
`decode_key(event: InputEventKey)` is only called by MapCursor *after* it filters to key
events, so a d-pad `InputEventJoypadButton` never reaches it; and the auto-repeat model
(`arm_repeat` / `note_key_released` / `tick`) assumes discrete press/release edges, which an
analog stick does not produce. So the map cursor needs a **rebuild**, not just bindings. The
bones are already right: the `MapCursorInput.Intent` enum is a clean device-agnostic
translation abstraction, and `is_action_pressed` (used inside the decoder) is already
device-agnostic — only the *type signature* and MapCursor's key-only gating are bound to the
keyboard.

**Rebuild A — `MapCursorInput` → device-agnostic decoder (required for d-pad + stick):**
- Widen `decode_key(event: InputEventKey)` → `decode(event: InputEvent)` and drop MapCursor's
  key-event-only gate so `InputEventJoypadButton` (d-pad) flows through the same `Intent`
  decode for free.
- Add **polled analog** for the left stick: in `_process`, read
  `Input.get_vector("cursor_left","cursor_right","cursor_up","cursor_down")` (built-in
  deadzone) and feed the *existing* repeat timer (`arm_repeat`/`tick`) so a held stick steps
  the cursor discretely. The stick has no release edge, so `note_key_released` is replaced for
  the stick path by "vector returned to deadzone → clear repeat" (keys/d-pad keep the edge
  path). Repeat timings stay `GameConstants.CURSOR_KEY_REPEAT_DELAY/RATE`.
- Net: one decoder serves keyboard, d-pad, and stick; the `Intent` layer downstream is
  unchanged. This is the real input-translation layer the game needs.

**Rebuild B — zoom → polled analog strength (cheap win, fixes trigger-held):**
- Zoom is edge-triggered today (`event.is_action_pressed("zoom_in")` in
  `MapCursor._unhandled_input`). Keyboard held-repeat works only by OS key-echo, which analog
  triggers do not emit — so a held trigger would zoom once. Rebuild to poll
  `Input.get_action_strength("zoom_in")` / `"zoom_out"` in `_process`: free held-repeat AND
  **proportional analog zoom speed** from the triggers. The keyboard/wheel keep their existing
  feel (strength 0/1). Camera-trigger deadzone is smaller than the nav default so a light pull
  starts zooming.

The **right stick** is reserved (camera pan, a later consumer; not this slice). Right-stick
*click* = R3 (danger zone); left-stick *click* = L3 (zoom reset).

**Deferred to V021-15 (Rebuild C):** the structural fix for the §2 dual-vocabulary fragility
— an input-context owner that guarantees exactly one of {map cursor, modal menu, selector} is
live (replacing the `_input_suppressed` bool + per-menu consume discipline), letting menus
move to native Godot focus. It subsumes the V021-15 selector arbiter, so it lands with that
work, not here. See `AGENT/Docs/shared_selector_extraction_design_2026-06-20.md`.

## 6. Active-mode integration (ties to the input-mode design)

This layer is the first concrete piece of the input-mode architecture, so it lands the
seam that design specified:
- The single owner (extend `SettingsManager` or a small `InputModeManager` autoload — match
  the design's "architecture seam") detects device class from the event stream
  (`InputEventJoypad*` → gamepad) and emits **`input_mode_changed(mode)`**.
- On a switch **to** gamepad mid-game, **grab focus on a sensible default** so the active
  menu is operable (the dual-UI tax); on a switch **away** from gamepad, drop the focus
  highlight so it does not look stuck.
- Detect-floor + conditional promotion and the gray/back-door availability logic are the
  input-mode workstream's broader scope; this plan implements the **gamepad arm** of it and
  the signal, leaving the full Auto/Touch/K&M resolver to the input-mode impl plan.

## 7. Build slices (cheap-now, testable per step)

1. **Bindings + accept/cancel unification + focus parity.** Add the joypad events (§3),
   make `confirm`/`cancel` share `ui_accept`/`ui_cancel`'s event lists (§2); verify every
   menu/native-control screen is navigable + activatable by pad (manual + the consume audit
   from §2). Unlocks Gamepad mode for menus/native controls.
2. **Map-cursor decoder rebuild (A) + polled zoom (B).** §5 — widen `MapCursorInput.decode`
   to all device events (d-pad), add left-stick `get_vector` polling into the existing repeat
   timer, rebuild zoom to polled `get_action_strength` (analog triggers). Unit-cycle bumpers,
   R3/L3 clicks. After this the map is fully pad-driven.
3. **`input_mode_changed` seam + focus-grab on mode switch.** §6 — detection, signal,
   focus-grab/drop. Headless-test the detection + signal; live-verify the focus feel.
4. **Contextual danger-zone resolver** (faction-wide arm now; per-enemy arm gated on the
   threat-range feature — ship the resolver + faction path, leave the per-enemy branch
   behind the feature flag/TODO with its dependency edge).

Slices 1–2 deliver a fully pad-playable build (the Steam Deck / phone-with-controller
target); slice 3 makes mode-switching graceful; slice 4 is the contextual polish. **Rebuild C
(input-context owner + native menu focus) is out of scope here — it lands with V021-15.**

## 8. Headless test plan

- `test_input_bindings.gd` (new) — assert every gameplay action carries ≥1 joypad event and
  the debug actions carry **none** (mirrors the DoD#2 spirit; guards against a future
  binding regression). Cross-check the `ui_*` ↔ `cursor_*`/`confirm`/`cancel` pairing.
- `MapCursorInput` decoder rebuild — extend the existing `test_map_cursor_input` suite:
  `decode(InputEvent)` returns the right `Intent` for a d-pad `InputEventJoypadButton` (not
  just keys); the stick-vector → repeat-timer path arms on entering and clears on returning to
  deadzone (parity with the keyboard `arm_repeat`/`note_key_released` tests).
- Polled zoom — unit-test that `get_action_strength` polling yields held-repeat and that a
  full vs partial trigger pull scales zoom speed (logic-level; the camera apply stays live).
- `input_mode_changed` detection — feed synthetic `InputEventJoypadButton` /
  `InputEventKey` and assert the derived mode + one signal per real change (reuse the
  input-mode resolver tests when that lands).
- Contextual resolver — unit-test cursor-over-enemy → per-unit vs faction selection (the
  per-unit render stays live-verify / gated).
- Regression: re-run the menu suites (`test_action_menu`-equivalent via `test_hud`,
  `test_unit_details_screen`, `test_attack_preview_selector`) after the focus-consumption
  audit to prove keyboard/mouse nav is unchanged.
- Focus-grab visuals, stick feel, and real-device pad behaviour are **live-verify**.

## 9. Definition of done

- DoD#1: update the GDD input/controls chapter + Platform Targets (gamepad gap closes) and
  flip the roadmap Input-mode/gamepad status in the same commit.
- DoD#2: add a `check_docs.py` guard asserting gameplay actions are pad-bound and debug
  actions are not (the §8 `test_input_bindings` invariant has a doc-sync mirror if the
  binding table is documented in the GDD).
- Sequencing: lands the gamepad arm; the full Auto/Touch/K&M resolver + value-set guards
  (`input_mode`/`touch_controls`) belong to the input-mode impl plan that follows.

## 10. Open questions (resolve at implementation)

1. **Owner type** — extend `SettingsManager` vs a new `InputModeManager` autoload. Lean:
   small dedicated autoload (the design floats both); keeps `SettingsManager` persistence-
   focused and the runtime active-mode logic separate.
2. **Trigger thresholds** — exact `JOY_AXIS_TRIGGER_*` deadzone + the zoom-strength→speed
   curve (tune live).
3. **Stick repeat vs analog feel** — the decoder reuses the discrete step+repeat timer for
   the left stick (parity with keys). Confirm live that discrete stepping feels right, or
   whether the stick wants a continuous glide instead (would diverge from the keyboard model).
4. **Per-enemy threat range** — ✅ now designed in
   `AGENT/Docs/individual_threat_range_design_2026-06-21.md` (its slices 1–2 are the
   prerequisite; this plan's slice 4 binds R3 through that design's shared resolver). This
   plan still ships the resolver + faction path regardless.
