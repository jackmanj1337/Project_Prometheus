# Input Mode Architecture — Design — 2026-06-20

Status: Target design
Last verified: 2026-06-20

Coupled work:
- `AGENT/Docs/display_scaling_resolution_design_2026-06-20.md` (crisp scaling, safe-area)
- `AGENT/Docs/debug_web_playtest_plan_2026-06-20.md` + `AGENT/Docs/handoff_2026-06-20_web_debug.md`
- `AGENT/Docs/mouse_only_cursor_mode_design_2026-06-19.md` (the existing `mouse_cursor` setting this absorbs)

This is a forward-looking architecture note. **No code changes yet** — it pins the
design before the mobile / Steam Deck input work begins so new UI is built to fit it.

> **Tracking home:** `AGENT/GDD/GDD_10_Roadmap.md` → *Forward Platform Workstreams*
> (indexed from the *Open Items Register* §A). The four unsettled choices below are mirrored
> there as the roadmap's "Open design decisions" so they resolve in one place.

## Goal

Ship a mobile build we are proud to put in front of strangers, while reusing one
codebase across desktop, a (lower-priority, eventual) Steam Deck build, and phones —
including phones with a Bluetooth game controller. A controller-equipped phone should
get the *same* control scheme a Steam Deck would.

## Core idea: model input modes, not platforms

The game must never branch on "what device am I" (`OS.has_feature("mobile")` etc.) for
interaction. It branches on **what is driving input right now**. The platform only
decides which modes are *available*; the rest of the game reacts to the active mode.

Four modes:

| Mode | Steam Deck | Phone + BT controller | Bare phone | Desktop |
|---|---|---|---|---|
| **Gamepad** | yes | yes | — | optional |
| **Touch** (Dedicated or Virtual gamepad) | — | optional | yes | — |
| **Keyboard & Mouse** | trackpad | — | — | yes |
| **Auto** (resolves to one of the above) | yes | yes | yes | yes |

**Why this matters for cost:** Gamepad mode is the shared backbone of Steam Deck,
phone-with-controller, *and* the Virtual-gamepad touch style (on-screen buttons just
synthesize gamepad actions) *and* the debug-web emulator shell. Building the gamepad
input layer once unlocks all of those. Touch-native ("Dedicated") menus are the only
genuinely separate, larger workstream. See Sequencing.

**Current state (verified 2026-06-20):** the input map has **zero gamepad bindings** —
actions are keyboard-only. The gamepad layer is the keystone dependency and does not
exist yet.

## Two concepts: the setting vs the active mode

These must be kept distinct:

- **Setting** (persisted, player-facing): `Auto | Gamepad | Touch | Keyboard & Mouse`.
- **Active mode** (runtime, derived): what is actually driving the UI this instant.
  Everything downstream — focus behaviour, on-screen button prompts, whether the
  virtual gamepad is shown — keys off the *active* mode, never the raw setting.

This mirrors how `mouse_cursor` already works, one level up.

## The settings tree (nested, multi-level)

Sub-settings nest under the mode they belong to:

```
Input Mode:  [ Auto ▾ ]                         default = Auto (last detected input)
  • Auto
  • Gamepad
       └─ (gamepad sub-settings, later: button layout, deadzone …)
  • Touch
       └─ Touch Controls: [ Dedicated ▾ ]   (Dedicated touch · Virtual gamepad)
  • Keyboard & Mouse
       └─ Mouse Cursor:   [ Follow ▾ ]       (Follow · Click · Off)   ← existing mouse_cursor moves here
       └─ (other mouse sub-settings, later)
```

- **Virtual gamepad** is a sub-option of **Touch**, not a top-level mode — it is a
  *presentation* of touch input (on-screen buttons firing gamepad actions), not a
  separate device.
- The existing `mouse_cursor` setting (`follow | click | disabled`) relocates under
  **Keyboard & Mouse**. This is mostly a UI/organisation move of an existing,
  already-migrated setting — the cfg key moves to the existing `[controls]` section
  (resolved 2026-06-20j; see Resolved decisions).

## Detect floor + conditional promotion

The boot/availability rule that makes lock-in essentially impossible. "Detect" is the
universal floor the game can never fall below, because it follows whatever the player
actually touches. The saved setting is treated as a **conditional promotion** on top.

> On boot **and on every input-device connect/disconnect**: attempt to honour the
> saved explicit setting; if that mode is not currently available, stay in detect.

Boot is just the first instance of a device-availability change, so one rule covers:
cold start, a controller connecting mid-session, and a controller dying mid-battle.
The "fallback" is not a special case — it is simply "the promotion did not take."

### Auto vs explicit semantics (the only behavioural difference is post-promotion)

- **Setting = Auto:** active mode *always* follows the last-detected device, forever.
  Never pins.
- **Setting = explicit X:** boot in detect → promote to X when available → **stay
  pinned to X** while it is present → fall back to detect only if X disappears →
  re-promote when X returns.

So `Auto` keeps re-following; an explicit mode pins and only yields when forced.

### Cold-start provisional seed

Detect cannot be *purely* reactive: at boot, before any input event arrives and before
the saved-setting promotion runs, the first frame still has to render something
coherent (which prompts, whether the virtual gamepad is visible). So detect needs a
**platform-seeded provisional mode** for the zero-input state:

> detect = platform-seeded provisional (mobile→Touch, desktop→K&M, Deck→Gamepad)
> → refined by the first real input event → promoted to the saved setting if available

### Worked case — saved = Gamepad, no controller at boot

Resolves as: stay in detect (platform-seeded), promote to Gamepad the instant a
controller connects. Never grayed, never trapped. (Confirmed intended behaviour.)

## Availability: gray, don't hide — plus the back-door guarantee

Two complementary protections, both needed:

1. **Front door — gray, don't hide.** Unsupported modes are shown but disabled in the
   selector, never removed. A player is never locked in a menu they cannot interact
   with because the only listed option is one their device can't drive. This rule
   extends to sub-settings: a sub-setting whose parent mode isn't active is
   shown-but-grayed (one consistent rule top to bottom).
2. **Back door — fallback resolution.** Graying only prevents *selecting* a dead mode
   through the menu. It does **not** rescue a player who *arrives* at one via a corrupt
   cfg, a cloud-synced setting carried from another device, or a disconnect under an
   explicit pin. The detect-floor rule above is that guarantee: live input always
   resolves to a device-operable mode regardless of what the saved setting says, while
   the setting itself stays as authored so it re-activates when the device returns.

### "Unsupported" vs "not present right now"

- **Unsupported** (e.g. Touch on desktop): gray it.
- **Supportable but absent** (e.g. Gamepad on a phone with no controller connected):
  do **not** gray it — a controller could connect; Auto + the detect floor keep things
  operable until then.

## The dual-UI tax (this design's main standing constraint)

Reusing one set of scenes across all modes (the only sane choice under a 4-mode matrix)
means **every menu must support both focus-based and pointer-based interaction at once**:

- Gamepad / Keyboard need a Godot `Control` **focus graph** (focus neighbours, a
  sensible default grab-focus) and a visible focus highlight.
- Touch (Dedicated) is **pointer-based**: finger-sized hit areas (~44–48 logical px),
  ignores focus.

Console+PC games with mouse support do exactly this; it is proven but disciplined. It
is cheapest paid as scenes are built, not retrofitted. **Constraint on all new UI from
now:** reflow containers (no new absolute-offset layouts), a sane focus graph, and
touch-sized targets. Known debt: the two fixed-frame scroll panels (Settings,
UnitDetails) are the screens that will fight this hardest.

Auto-switching *amplifies* this tax, because mode changes happen unprompted mid-game:
- touch → gamepad (controller connects): grab focus on a sensible default, or the menu
  is dead until the player does.
- gamepad → touch: drop the focus highlight so it does not look stuck.

## Architecture seam

A single owner (extend `SettingsManager`, or a small dedicated autoload) exposes:

- persisted `input_mode` (`auto | gamepad | touch | mouse_keyboard`)
- persisted `touch_controls` (`dedicated | virtual_gamepad`) — applies when active mode is touch
- persisted `mouse_cursor` (existing `follow | click | disabled`) — applies under K&M
- runtime `active_input_mode`, derived by the detect-floor + promotion rule
- **signal `input_mode_changed(mode)`** — the backbone. Focus-grab, prompt swapping,
  and virtual-gamepad visibility all subscribe. Fits the existing `EventBus` +
  `SettingsManager` patterns.

Detection reads the incoming event stream by device class: `InputEventKey` /
`InputEventMouse*` → K&M, `InputEventJoypad*` → gamepad, `InputEventScreenTouch` /
`InputEventScreenDrag` → touch. (Touch-native vs virtual gamepad is **not**
auto-detectable — both are touch events — which is exactly why touch style is its own
sub-setting.)

## What the existing codebase already gives us

- **`mouse_cursor="click"` (V021-17)** is already tap-to-relocate-then-tap-to-confirm —
  the seed of the touch map-interaction model, and already tested.
- **Map pinch-zoom** maps onto the existing `CameraController` zoom API.
- **Safe-area seam** (`SettingsManager.get_safe_area_insets()`, D5/E6) — notch /
  home-indicator handling is wired; mobile just feeds real values.
- **Reflow conversions** already underway (LevelUpScreen `Panel`→`PanelContainer`, etc.)
  are the down payment on the dual-UI constraint.
- **Type-based crisp scaling** (V021-18) lets mobile default to a larger crisp factor.
- **The debug-web emulator shell == the Virtual-gamepad touch style** — same mechanism;
  building one is most of the other.

## Sequencing (cheap-now, no-rework)

1. **Gamepad input layer** — add joypad events to existing actions + focus/cursor
   handling. The keystone: unlocks Gamepad mode, Steam Deck, phone-with-controller, the
   Virtual-gamepad touch style, and the debug-web shell.
2. **Steam Deck build** (eventual, lower priority than mobile) — cheapest validation of
   the gamepad scheme; reuses cursor + menu model wholesale. De-risks the shared layer.
3. **Virtual-gamepad touch style + debug-web shell** — nearly free once (1) exists.
4. **Touch-native ("Dedicated") layer** — the large, separate menu/interaction
   workstream for the proud-to-show phone release. The only remaining expensive piece.

## Resolved decisions (2026-06-20j)

All four open choices were settled this session (recommendations accepted). Mirrored in
GDD_10 *Forward Platform Workstreams*.

- **Default touch style → Dedicated (native), Virtual-gamepad interim.** The persisted
  `touch_controls` default is `dedicated` (best stranger-facing feel; matches the goal).
  Because Dedicated is sequencing item #4 (the last, most expensive layer), touch **resolves
  to Virtual gamepad until the Dedicated layer ships** (the debug-web shell is already that
  style). So the *authored default* is `dedicated`; the *availability gate* falls back to
  `virtual_gamepad` while Dedicated does not exist.
- **Cfg location → reuse the existing `[controls]` section** (not a new `[input]` section).
  `settings.cfg` already has `[controls]` holding `keybindings`, and
  `reset_section_to_defaults()` already handles `"controls"`. Put `input_mode`,
  `touch_controls`, and the relocated `mouse_cursor` all under `[controls]` so input settings
  are not fragmented across two sections. Migrate `mouse_cursor` out of `[gameplay]` with the
  same one-version read-old-write-new pattern already used for the legacy `mouse_targeting`
  key. (Reset semantics improve too: cursor mode then clears with "reset controls", not
  "reset gameplay".)
- **Prompt/glyph swapping → polish follow-up, but build the signal seam now.** The first
  mobile release is single-mode (bare phone = always touch), so dynamic A/B-vs-tap swapping
  has near-zero day-one payoff; its value is phone+controller and Steam Deck (both later).
  Render static touch-appropriate hints in the first release, but route **all** prompts
  through `input_mode_changed` from the start so the swap system is additive, not a retrofit.
- **Steam Deck resolution/aspect → accept the letterbox bars; defer any Deck-aware layout.**
  Deck (1280×800, 16:10) letterboxes slightly under `aspect=keep`. Deck is lower-priority and
  later than mobile, so a third aspect target is not worth maintaining now. Revisit only if
  Deck becomes a priority shipping target.

## Definition of done (when implemented)

- DoD#1: update the affected GDD chapter(s) (input/controls + Platform Targets in
  GDD_10) and flip the matching roadmap status in the same commit.
- DoD#2: add a `check_docs.py` guard for the new valid value-sets (`input_mode`,
  `touch_controls`) mirroring the existing `mouse_cursor` value-set check [14].
- Tests: the detect-floor + conditional-promotion resolver and the gray/fallback
  availability logic are headless-testable; add focused coverage. The focus-grab /
  prompt-swap visual behaviour is live-verify only.
