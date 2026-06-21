# Input / Controls — Open Decisions Register — 2026-06-21

Status: Decisions pending
Last verified: 2026-06-21

The single place to resolve every choice that the two remaining input/controls plans
could **not** draft without a call from you. Both implementation plans are drafted
decision-free and defer here by ID:

- `AGENT/Docs/input_mode_resolver_implementation_plan_2026-06-21.md`
- `AGENT/Docs/key_rebind_ui_implementation_plan_2026-06-21.md`

The already-settled input/controls choices live in
`input_mode_architecture_design_2026-06-20.md` → *Resolved decisions* (4 of them) and are
not repeated here. This file is **only** the still-open ones. Each carries: what's at
stake, the options, and a recommendation (standard best practice). Resolving one =
flip its status, write the choice into the owning plan's referenced section, and (per
DoD#1) mirror to GDD_10 if it changes a tracked status.

> **Decision IDs are stable.** The plans cite `[ICD-n]`; don't renumber.

---

## ICD-1 — Active-mode owner: extend `SettingsManager` vs new `InputModeManager` autoload

**Status:** OPEN — blocks both plans (foundational).

`SettingsManager` already owns the persisted settings (`mouse_cursor`, `keybindings`,
the `[controls]` section, `reset_section_to_defaults`). The new work adds **runtime**
state: `active_input_mode`, device-class detection from the live event stream, the
detect-floor + conditional-promotion resolver, and the `input_mode_changed(mode)` signal.
The gamepad plan (§10 Q1) and the architecture seam both float "extend `SettingsManager`
*or* a small dedicated autoload" without deciding.

| Option | Pros | Cons |
|---|---|---|
| **A. Extend `SettingsManager`** | One owner; persisted + runtime in one place; no new autoload wiring | Mixes pure persistence with stateful `_input` device detection; grows an already-390-line file; harder to unit-test the resolver in isolation |
| **B. New `InputModeManager` autoload** (Recommended) | Keeps `SettingsManager` persistence-focused; resolver is independently headless-testable; matches the design's "single owner exposes…" seam cleanly; reads its three persisted values from `SettingsManager` | One more autoload + load-order note (must load after `SettingsManager`) |

**Recommendation: B.** The runtime resolver is genuinely a different responsibility
(reacts to the event stream every frame; emits a signal) from saving a cfg. Per the
headless-autoload pattern memo, the new autoload references `SettingsManager` via
`get_node_or_null` + `.get()/.call()` so headless `--script` tests stay clean.

**Knock-on:** whichever is chosen, the gamepad plan's slice 3 ("input_mode_changed seam")
and this resolver plan land in the **same** owner. Resolve ICD-1 before either starts code.

---

## ICD-2 — Resolver landing point: fold into gamepad slice 3, or a separate follow-up slice

**Status:** OPEN — sequencing only (not architectural).

The gamepad plan's **slice 3** already builds "the gamepad arm of the resolver + the
`input_mode_changed` signal + focus-grab on switch." The broader resolver (Auto/Touch/K&M
detect-floor, conditional promotion, gray/back-door availability, the value-set guards)
is the *rest* of that same machine.

| Option | Trade-off |
|---|---|
| **A. Fold the full resolver into gamepad slice 3** (Recommended) | Builds the whole resolver once instead of stubbing a gamepad-only arm and immediately reopening it; the signal + detection are shared code. Slightly larger single slice. |
| **B. Ship gamepad slice 3 as the gamepad-only stub, do the full resolver after** | Smaller slices; but the stub's detection/signal get rewritten when the full resolver lands — throwaway, the exact anti-pattern the 2026-06-20j sequencing decision avoided for the web bridge. |

**Recommendation: A.** Same reasoning that reordered gamepad-before-web: don't build a
throwaway arm. If A is chosen, the gamepad plan §6/slice 3 becomes "implement
ICD-resolved owner per this plan" and this plan *is* slice 3's detail.

---

## ICD-3 — Touch detection vs `emulate_mouse_from_touch` (which event wins)

**Status:** OPEN — needs a chosen strategy + live verification.

With Godot's default `emulate_mouse_from_touch = true`, one finger tap emits **both** an
`InputEventScreenTouch` **and** a synthesized `InputEventMouseButton`. Naive
device-class detection would flip K&M ⇄ Touch on every tap. We must pick how detection
disambiguates.

| Option | Notes |
|---|---|
| **A. Touch-first precedence** (Recommended) | If a real `InputEventScreenTouch`/`Drag` was seen this frame (or within a short window), ignore the mouse event for detection purposes. Robust to emulation; small bit of state. |
| **B. Disable `emulate_mouse_from_touch` and synthesize cursor moves ourselves** | Clean detection, but **breaks** the V021-17 click-mode-by-tap path the web build relies on (that path *depends* on emulation). Rejected unless web input is rearchitected. |
| **C. Detect emulated mouse via event flags** | Godot 4 does not reliably tag emulated mouse events as such across platforms — fragile. |

**Recommendation: A**, and **smoke-test on real iOS Safari Godot-Web** (same load-bearing
risk already flagged for the web build) before trusting it. This is a decision because it
constrains the resolver's detection routine and interacts with the web input model.

---

## ICD-4 — Per-action binding model: replace-all vs per-device slots

**Status:** OPEN — blocks the key-rebind UI; also affects the gamepad bindings' durability.

`SettingsManager.rebind_action(action, event)` today does `keybindings[action] = [event]`
— it **overwrites the entire event list with one event**. Once gamepad bindings exist on
the same actions (gamepad plan §3 adds joypad events to `confirm`, `cursor_*`, etc.),
a keyboard rebind through this path would **wipe the joypad binding** (and vice-versa).

| Option | Behaviour |
|---|---|
| **A. Per-device slots** (Recommended) | Model each action as up to one keyboard/mouse event **and** one joypad event. Rebinding the keyboard replaces only the K&M slot, leaving the pad slot intact. `rebind_action` gains a device-class filter. |
| **B. Replace-all (today's behaviour), rebind keyboard only** | Simplest, but rebinding any key silently drops that action's gamepad binding — a real bug the moment §3 ships. Requires re-applying gamepad bindings after every rebind. |
| **C. Append (multi-bind, never replace)** | Players accumulate stale bindings; needs a separate "clear" affordance. Messier UX. |

**Recommendation: A.** It is the only model that coexists cleanly with the gamepad layer.
It changes `rebind_action`'s contract, so the rebind UI plan is drafted **around A** but
gated on confirmation.

---

## ICD-5 — Rebind UI scope: which actions are rebindable, and gamepad rebinding now or later

**Status:** OPEN — shapes the rebind UI surface.

Two sub-questions:

**5a — Rebindable set.** The read-only list today shows 12 game actions
(`_KEYBIND_LABELS`) + 2 debug rows (debug-build only).

- **Option A (Recommended):** all 12 game actions rebindable; debug rows stay read-only;
  universal nav/confirm/cancel rebindable too but with conflict protection (ICD-6).
- **Option B:** lock the universal set (`cursor_*`, `confirm`, `cancel`) to avoid players
  trapping themselves; only rebind the "verb" actions.

Recommend **A** — conflict protection (ICD-6) plus "reset to defaults" (already in
`reset_section_to_defaults("controls")`) make a self-trap recoverable, so there's no need
to restrict the set.

**5b — Device coverage at first ship.**

- **Option A (Recommended):** capture-any-`InputEvent` UI (keyboard *and* joypad
  capturable), but list/glyph polish for pad comes with the deferred prompt/glyph work.
- **Option B:** keyboard rebinding only for v1; add pad rebind with the glyph system.

Recommend **A** for capture (the capture flow is device-agnostic for free), **B-style**
for display polish (gamepad glyph rendering is already the deferred polish item in the
architecture design). I.e. *capture* any device now; *pretty pad glyphs* later.

---

## ICD-6 — Rebind conflict policy

**Status:** OPEN — blocks the rebind UI's capture flow.

When a captured event already belongs to another action:

| Option | UX |
|---|---|
| **A. Block + warn** (Recommended) | Reject the capture, show "Already bound to <Action>", keep the old binding. Simplest, predictable, no surprise side-effects. |
| **B. Swap** | Move the conflicting action to the just-vacated key. Slick but surprising; needs careful messaging. |
| **C. Allow duplicates** | A key can fire two actions — almost never wanted; causes silent double-input bugs. |

**Recommendation: A.** Pairs with the always-available "Reset Controls" escape hatch.
Note the existing `_mirror_game_keys_to_ui` baseline machinery means conflicts can also
exist against `ui_*` mirrors — the conflict check must run against the **game** actions
(the mirror is derived), which the plan accounts for.

---

## ICD-7 (carried from gamepad plan §10) — tune-live items, listed for completeness

These are **not** blocking user decisions — they're "tune during live verify" — but
recorded here so the cluster's open list is in one place:

- **Trigger deadzone + zoom-strength→speed curve** (gamepad §10 Q2) — tune live.
- **Left-stick discrete-step vs continuous-glide feel** (gamepad §10 Q3) — the rebuild
  ships discrete (keyboard parity); confirm or switch live.
- **Per-enemy threat range** (gamepad §10 Q4) — needs its own UI/UX design before the
  contextual R3 arm; the gamepad resolver ships the faction path regardless.

No action needed from you on ICD-7 now; they resolve at implementation/verify time.

---

## Resolution log

| ID | Decision | Date | Where recorded |
|---|---|---|---|
| ICD-1 | _pending_ | | |
| ICD-2 | _pending_ | | |
| ICD-3 | _pending_ | | |
| ICD-4 | _pending_ | | |
| ICD-5 | _pending_ | | |
| ICD-6 | _pending_ | | |
