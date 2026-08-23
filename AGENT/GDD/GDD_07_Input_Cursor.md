---
Role: topic
Topic ID: GDD-07-INPUT-CURSOR
---

# GDD_07 — Input And Cursor

**Status:** Active input/cursor contract — implemented and planned slices are labelled
per section.
**Last verified:** 2026-08-11
**Governance:** section template + status vocabulary in
`AGENT/Docs/governance/documentation_governance_2026-06-13.md`.

This companion owns action bindings, device-mode resolution, repeat behavior,
MapCursor interaction states, and threat/range interaction. Cross-cutting UI policy
remains in [GDD_07 — UI & UX](GDD_07_UI_UX.md); surface-specific behavior lives in
[GDD_07 — Screens And Panels](GDD_07_Screens_Panels.md).

---

## Input System

Status: **Implemented** (keyboard + mouse parity; gamepad binding/menu-control,
headless map-cursor decoder, profile-ready keybind persistence, and key-rebind capture
for keyboard/mouse + gamepad); live controller feel **Target design** / pending
validation.
Last verified: 2026-07-14

All input is handled through Godot's **Input Map** (defined in Project Settings).
`MapCursor.gd` is the primary input handler during gameplay.
`MapCursorInput.decode(event)` translates keyboard and d-pad/button events into
state-agnostic intents; `_process()` polls the cursor vector for left-stick
movement and the zoom action strengths for held LT/RT zoom.

### Text entry is bounded to naming and file/path entry (TEXT-06)

Status: **Pending validation** (request/session/entry-mode registry, persisted mode
setting, hardware and grid presenters, printable-US-ASCII layout, same-viewport modal,
and game-owned export naming implemented; Windows validation remains)
Last verified: 2026-08-11

**V1 may require free-text entry only for naming and file/path entry.** Everything
else uses selection, filters, or generated identifiers unless separately approved.

Why the rule exists rather than just an on-screen keyboard: Godot's virtual keyboard
is Android/iOS/Web only, so on Windows and the Steam Deck `LineEdit.virtual_keyboard_enabled`
— which defaults to `true` — does nothing at all. Controller text entry also measures
at roughly 6–7 words per minute regardless of layout, so a feature that *needs* typing
is expensive for every player on a pad, not just those without a keyboard.

The text-entry foundation classifies each request by purpose and applies one
allowed-character and length/byte validator to hardware and on-screen input. Its
open entry-mode registry has `grid` and `hardware` presenters and reserves a
backend-free `system` seam. The persisted preference offers Auto, On-screen Grid,
Hardware Keyboard, and System Keyboard; Auto routes gamepad/touch to the grid and
physical keyboard input to hardware. The grid layout is data-driven and exposes fixed `ABC`,
`123`, and `Symbols` layers covering printable US-ASCII; disallowed keys remain in
place and become disabled.

Both presenters run inside one caller-viewport modal surface with a value echo,
prompt, validation feedback, and explicit Cancel/Confirm actions. While it is open,
`TextEntryService` is the top input owner: modal repeat and underlying focus navigation
stand down, printable Z/X/WASD remain text instead of gameplay actions, and Escape,
mapped cancel, Enter, arrows, Tab, Backspace, and ordinary characters produce at most
one service-owned transition. Focus enters the surface without a pointer click and is
restored to the caller when the session closes.

The keyboard's existence **does not reopen** the three
features cut for input-cost reasons — drag/drop item movement, free-text stock search,
and the forge item alias. Those were cut on their own merits: the search cut was an
interaction-cost decision, not only an input one.

When adding another v1 feature that wants free text, pick a bounded alternative:
authored selection lists, filter chips, or an engine-generated id with a display label.

Export naming is game-owned: save-mode FileDialogs first open a constrained filename
modal using the shared text-entry service. Confirmation opens FileDialog only for
directory selection, with its filename field read-only. FileDialog therefore keeps one
conventional Escape/Cancel meaning instead of the failed two-stage contract. Imports
remain navigation-first and retain picker-owned path entry. A Windows-host input and
visual pass is still required before this behavior is release-accepted.

### Action Definitions

| Action | Primary Keys | Mouse | Gamepad |
|---|---|---|---|
| `cursor_up` | W, Up Arrow | — | D-pad Up / Left Stick Up |
| `cursor_down` | S, Down Arrow | — | D-pad Down / Left Stick Down |
| `cursor_left` | A, Left Arrow | — | D-pad Left / Left Stick Left |
| `cursor_right` | D, Right Arrow | — | D-pad Right / Left Stick Right |
| `confirm` | Z, Enter, Space | Left Click | Pad A |
| `cancel` | X, Escape | Right Click | Pad B |
| `next_unit` | Tab | — | RB |
| `prev_unit` | Shift + Tab | — | LB |
| `show_danger_zone` | Q (threat resolver) | Middle Click (threat resolver) | R3 |
| `peek_range` | E (hold to peek) | — | View (hold) |
| `inspect_unit` | I | — | Pad Y |
| `more_info` | F | — | Pad X |
| `open_menu` | M; also confirm/cancel on an empty tile | Left/Right Click on an empty tile | Start |
| `open_settings` | O | — | via Start -> Settings |
| `zoom_in` | = | Wheel Up | RT |
| `zoom_out` | - | Wheel Down | LT |
| `zoom_reset` | 0 | — | L3 |
| `debug_toggle_hotseat_override` | F9 | — | — |

`show_danger_zone` is the **threat resolver** (free cursor state only, see
*Threat Overlay* below): over a hostile attack-capable enemy it toggles that
enemy's membership in a persistent **watch set**; over empty/terrain it cycles
the **danger mode**. `open_settings`
opens the Settings screen during a map (see Map Menu / Settings Screen below).
`debug_toggle_hotseat_override` is debug-build-only; it temporarily routes every
faction through hotseat control for live testing and is listed in the debug HUD
banner as `hotseat-all` while active.

> **Menus and the game's keys.** Menus (Main Menu, Map Menu, Settings, the
> Action / Item menus) navigate via Godot's built-in `ui_*` actions.
> `SettingsManager._mirror_game_keys_to_ui()` copies the `cursor_*` / `confirm` /
> `cancel` bindings onto `ui_*` at startup, so WASD / Z / X and their pad
> equivalents drive menus exactly as they drive the map cursor. Saved bindings use
> per-device slots (`kbd`, `pad`), so rebinding one device class preserves the other.

> **On-screen prompts follow the active scheme (B6-INPUT prompt swapping).** Player-facing
> control hints — the level-up "Press _X_ to continue" line and the More Info hints on the
> combat forecast, character sheet, and compact terrain panel — render the binding for the
> **active input mode** (`InputModeManager.active_input_mode`) and re-render live when the
> scheme changes. In keyboard/touch modes they show the key (or a tap verb); in gamepad mode
> they show the **brand-correct pad label**. Because SDL normalizes button _position_
> (`JOY_BUTTON_A` = physical bottom on every pad), the bindings are brand-correct with no
> per-brand code; only the printed label differs — Nintendo swaps the A/B and X/Y positions
> vs Xbox, and PlayStation prints words such as `Cross` / `Square` until the `UI-INSPECTION`
> glyph pass proves font coverage. Brand is classified heuristically from the last active
> joypad device's `Input.get_joy_name()` (Godot has no native controller-type API), so a
> wrong guess is cosmetic, never a mis-input. `InputDisplay` owns the mode/brand-aware
> prompt helpers; `InputModeManager` owns last-active-pad tracking.
>
> `InputModeManager` is also the persistent owner of joypad hot-plug telemetry. It
> enumerates already-connected pads at startup and logs every connect/disconnect with
> device id, cached name, and GUID before clearing active-pad state. Therefore a missing
> transition in a returned playtest log is a failed observation, not evidence of success.

### Mouse Behavior
- **Left Click on tile:** Same as moving cursor to that tile and pressing `confirm`
- **Right Click:** Same as pressing `cancel`
- **Hovering** over a tile with the mouse moves the cursor to that tile instantly
  (no movement delay — cursor teleports to hovered tile)
- Mouse and keyboard cursor control can be mixed freely at any time

### Threat Overlay

Status: **Implemented** (watch set + mode cycle; source-4 darker-red watch tile
authored as a placeholder colour; "D" markers; suspend restore of
watch-set/mode state; MRD-7 selection/targeting compose plumbing and
shared-cell visual prototypes including the v0.3.1-requested dual outline)
Last verified: 2026-07-12

The `show_danger_zone` action (MMB / Q / R3) drives two orthogonal pieces of state through one resolver, in
the free cursor state only:

- **Watch set** — a persistent set of hostile, attack-capable enemies the player
  hand-picks. The resolver over such an enemy toggles its membership (stored as
  stable unit ids, so a defeated enemy is pruned and a suspend save can
  round-trip them). Each controlling faction owns an independent watch set and
  mode; only the active faction's markers/view render. Members that die or cease
  to be hostile to that owning faction are pruned. Each watched enemy shows a
  small **"D"** marker on its tile.
- **Danger mode** — the overlay display mode, one of exactly **`none`**,
  **`full`**, **`selected`**, **`combined`**. The resolver over empty terrain
  cycles `full → selected → combined → none` (starting from `none → full`).
  - `full` paints every hostile enemy's threat (dark red).
  - `selected` paints the watch set's threat (a distinct darker red).
  - `combined` paints both, with the watch set winning shared cells.
  - `none` paints no threat.

Adding a member auto-promotes the mode on the empty→non-empty transition
(`none→selected`, `full→combined`); removing the last member auto-demotes it
(`selected→none`, `combined→full`). The overlays share one layer, ordered by the
[MRD-1] overlay precedence registry (range < faction threat < watch threat <
opaque top layers). The set + mode survive phase changes, menus, and unit
selection (teardown clears only the paint; a return to the free state recomputes
it from live positions); a fresh map load clears them, while a suspend resume
restores every faction view from the versioned
`suspend.threat_views_by_faction` field.

Selection and targeting overlays are built as registry layer specs and composed
with retained threat specs, so selecting a unit or entering attack/staff/pair-up
targeting does not clear watched-threat paint or "D" markers ([MRD-7]).
Threatened tiles inside movement/target range support five renderer modes:
`single_layer`, `border_through`, `stacked`, `stacked_perimeter`, and
`dual_outline`. `border_through` bakes threat colour into the tile center with
a strong range-colour border on the shared overlay layer; `stacked` paints
retained threat on the base overlay and range on a second `TileMapLayer`;
`stacked_perimeter` keeps that stacked fill and swaps threat tiles to generated
edge-mask sources based on the union of threatened tiles, creating one outline
around each contiguous threat area. `dual_outline` (V031-MRD-01, the
v0.3.1-requested candidate, 2026-07-12) keeps the stacked fill and strokes two
strong world-space outlines on a `ThreatPerimeterOverlay` draw surface rendered
**above unit sprites**: a bright-red line around the union of ALL threatened
tiles and a dark-red line around the WATCHED subset, dark drawn over bright on
shared edges. The v0.3.2 live return accepted `dual_outline`, so it is now the
fixed default and the temporary F8 comparison control has been removed. Action
Menu retains the acting unit's movement range composed with threat/watch layers;
Map Menu retains only threat/watch. Both suppress path arrows and hover peek.
Enemy-phase locking and map/suspend restoration still clear paint so positions
are recomputed before display.

Full-screen gameplay modals use the shared EventBus gameplay-modal lock. MapCursor
checks it before event/pointer input and held-direction polling; ownership counting
prevents one nested modal from releasing another.

**Hover-to-peek** (`peek_range`, hold **E**, free cursor state) previews the
unit under the cursor's reach — blue move range + red attack reach — as an
exclusive opaque top layer over any threat overlay. The reach is computed once
per hovered unit and cached: moving the cursor to a *different* unit recomputes,
staying on the same unit reuses the cache (no per-tick recompute). Releasing the
key clears the peek and restores the threat overlay.

**Movement path arrows.** While a unit is selected, a directional chain traces
its cheapest path (`get_movement_path`) from the unit to the cursor tile, drawn
above the blue move-range overlay. Only the path to the *current* cursor tile is
recomputed as the cursor moves (no range recompute); it clears on move-commit or
deselect. (Placeholder polyline render — UI polish may swap for arrow-tile art.)

### Cursor Direction Repeat
When a directional key, d-pad direction, or left-stick direction is held:
- First move: immediate
- Delay before repeat begins: 0.25 seconds
- Repeat rate: every 0.10 seconds

Custom modal menus that own selection (`ActionMenu`, `UnitDetailsScreen`) use
a slower menu-specific 0.30s / 0.15s policy through `MenuRepeatPolicy` instead
of per-event stick-axis stepping, so a held stick/key has one immediate step
followed by stable repeat. Menus stepped at the map-cursor cadence until the
v0.3.1 return called that "a little fast" for discrete rows (V031-GP-03,
2026-07-12); `MENU_KEY_REPEAT_DELAY/RATE` now own the menu timing while the
map cursor keeps 0.25s / 0.10s.

Engine-focus modals (`SettingsScreen`, `NewGameScreen`, Promotion/Reclass) use
the shared `ModalScreen` vertical repeat path. Horizontal input stays with the
focused control, so sliders and option buttons keep their own left/right
behavior. While a capture-mode UI is active — an open `OptionButton` dropdown
or any other embedded popup Window — the polled repeat and focus containment
stand down entirely, and the popup-close frame re-latches the repeat to
neutral, so picking from a dropdown never moves the panel focus behind it
(V031-GP-02, fixed 2026-07-12; the polled `Input` singleton cannot see event
capture, so the standdown is checked explicitly).

Held map zoom ignores LT/RT values below a 0.85 activation threshold. Any pull
past the threshold steps the zoom once, then repeats on one constant slow
cadence (0.65s initial delay and per-step rate) — pull depth does not change
the speed. Analog trigger motion is consumed only by this threshold-aware
poller; discrete keyboard and mouse zoom presses remain immediate. The earlier
strength-scaled timer (0.45s to 0.18s by pull depth)
kept reading as "too sensitive" on live returns and was removed by owner
decision on the v0.3.2 return (2026-07-13, V032-D1); per-player sensitivity
sliders remain a `B6-INPUT` backlog item. The new feel still requires a focused
live controller rerun.

---

## Transition telemetry and suppression watchdog

Status: **Implemented; pending native Windows/controller validation (2026-08-02)**
Last verified: 2026-08-02

`TransitionTelemetry` keeps a bounded structured record of attack confirmation,
combat, EXP, level-up presentation, end-turn confirmation, modal ownership, focus,
input mode/device, suppression ownership, and turn phase. One correlation ID follows
an attack through combat completion. The existing `PLAYTEST CONTROLLER` hot-plug
lines remain unchanged.

If cursor input stays suppressed beyond five seconds without a visible modal,
combat, level-up presentation, scene transition, or an explicitly registered visible
owner such as Unit Details, the watchdog emits one snapshot
for that suppression interval. The snapshot includes every suppression owner, modal
refcounts, focus owner, input mode/device, and combat/turn/level-up state. It is
strictly diagnostic: it never releases a lock, changes cursor state, or clears an
owner. Native Windows verification must repeat controller attacks, level-ups, and
end-turn confirmation and retain the log if the lockout recurs.

The record is bounded in memory (256 entries) and its tracing is bounded too. A debug
build traces every record as it happens; a release build keeps them in memory and
writes nothing until the watchdog fires, at which point it flushes the retained history
alongside the snapshot. Tracing unconditionally would have written a JSON line to a
player's log on every focus change for an entire session, which is a shipped log-growth
cost for a diagnostic nobody is reading unless something went wrong. Testers reproducing
a lockout should prefer the debug executable in the bundle, which traces throughout.

---

## Cursor System

Status: **Implemented** (static cursor art; animated art is a later presentation pass)
Last verified: 2026-06-13

The `MapCursor` is a `Node2D` with a `Sprite2D` child.
It sits on top of all tiles and indicates the currently focused tile.

At map start `GameMap` places the cursor on the first player unit (via
`MapCursor.center_on_tile()`), not the map's (0,0) corner, so play begins
focused on the player's force.

**Visual:** current cursor art is a static 64x64 sprite. Animated cursor art is
a future presentation pass.

**States:**
- `free` — cursor moves freely; hovering shows unit/terrain info
- `unit_selected` — a controllable unit is selected; movement range shown in blue
- `unit_moved` — selected unit has moved; action menu is open
- `targeting` — the active controller is selecting a target; attack range shown in red
- `locked` — cursor cannot move (during animations or controller handoff)

**State Transitions:**
```
free
  → [confirm on controllable unit] → unit_selected
  → [confirm or cancel on an empty tile, or the open_menu key (M)]
        → map menu opens (cursor locked until it closes)
  → [cancel over an unselected unit] → that unit's character sheet opens (V021-16)

unit_selected
  → [confirm on move tile] → unit_moved (unit moves)
  → [cancel] → free (deselect)
  → [next_unit] → unit_selected (select next unacted unit)

unit_moved
  → [Attack] → targeting
  → [Staff] → targeting (green overlay for allies)
  → [Item / Wait] → free (action resolved)
  → [cancel] → unit_selected (undo move)

targeting
  → [confirm on valid target] → show AttackPreview
    → [confirm] → resolve combat → free
    → [cancel] → targeting
  → [cancel] → unit_moved (back to action menu)

locked
  → [automatic] → previous state (unlocked by TurnManager after animation)
```

---

## Input Settings Vocabulary

The persisted input-prompt preference is exactly `auto`, `gamepad`, `touch`, or
`mouse_keyboard`. `InputModeManager` resolves that preference to the available live
device mode without disabling physical input from other devices. **Availability now
recognises a mobile browser.** Godot tags `mobile` only for a native Android/iOS
export, so a PWA on a phone reported no touch capability at all and `touch` was
unselectable on the one platform it is for; the tags `web_ios` and `web_android` are
what identify it, and they also seed the platform default to touch. A mobile browser
keeps `mouse_keyboard` selectable, because an attached keyboard remains reachable
there. Mouse cursor behavior
is exactly `follow`, `click`, or `disabled`. Touch presentation preference is
exactly `dedicated` or `virtual_gamepad`; until dedicated touch controls ship, the
runtime may fall back to the virtual-gamepad presentation while preserving the saved
preference.

These fixed vocabularies and the action table above are guarded by `DOC-011`.
Settings-screen layout and persistence details are owned by
[GDD_07 — Screens And Panels](GDD_07_Screens_Panels.md).

---
