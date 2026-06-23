---
Type: register
Status: RESOLVED 2026-06-21
Last verified: 2026-06-23
Register: ICD-1..7
Resolved-in: 2026-06-21 (ICD-7 non-blocking)
---

# Input / Controls — Open Decisions Register — 2026-06-21

Status: Decisions resolved (ICD-1..6 settled 2026-06-21; ICD-7 non-blocking)
Last verified: 2026-06-21

The single place to resolve every choice that the two remaining input/controls plans
could **not** draft without a call from you. Both implementation plans are drafted
decision-free and defer here by ID:

- `AGENT/Docs/plans/input_mode_resolver_implementation_plan_2026-06-21.md`
- `AGENT/Docs/plans/key_rebind_ui_implementation_plan_2026-06-21.md`

The already-settled input/controls choices live in
`input_mode_architecture_design_2026-06-20.md` → *Resolved decisions* (4 of them) and are
not repeated here. This file is **only** the still-open ones. Each carries: what's at
stake, the options, and a recommendation (standard best practice). Resolving one =
flip its status, write the choice into the owning plan's referenced section, and (per
DoD#1) mirror to GDD_10 if it changes a tracked status.

> **Decision IDs are stable.** The plans cite `[ICD-n]`; don't renumber.

---

## ICD-1 — Active-mode owner: extend `SettingsManager` vs new `InputModeManager` autoload

**Status:** ✅ RESOLVED 2026-06-21 → **B, new `InputModeManager` autoload.**

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

**Status:** ✅ RESOLVED 2026-06-21 → **A, fold the full resolver into gamepad slice 3.**

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

**Status:** ✅ RESOLVED 2026-06-21 → **A, touch-first precedence.** Gated on an iOS Safari
Godot-Web smoke test before it is trusted (load-bearing risk).

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

**Status:** ✅ RESOLVED 2026-06-21 → **A, per-device slots** (one K&M slot + one joypad slot
per action; `rebind_action` gains a device-class filter).

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

**Status:** ✅ RESOLVED 2026-06-21.

**5a — Rebindable set → ALL actions rebindable.** Every game action is rebindable (the
universal nav/confirm/cancel set included). Two escape hatches make a self-trap fully
recoverable, both required by this decision:

1. **A prominent "Reset Controls to Defaults" button that stays accessible at all times**
   (backed by the existing `reset_section_to_defaults("controls")`).
2. **The cfg as a last-resort hand-edit path** for a tinkerer who truly wedges themselves
   — which forces the new consideration below.

> Debug rows (`_DEBUG_KEYBIND_LABELS`, debug-build only, slated for removal as release
> blockers): "all actions" is read as **all player-facing game actions**. Debug rows may
> be rebindable in debug builds for consistency since they never ship, but persisting a
> binding for an action that won't exist in release is pointless — implementer's call,
> default to leaving the debug rows read-only.

**5a-i — NEW consideration (raised with this decision): human-readable cfg serialization.**
The hand-edit escape hatch only works if the saved bindings are *editable by hand*. Today
`keybindings` stores serialized `InputEvent` **objects**, which `ConfigFile` writes as
opaque `Object(InputEventKey, ...)` blobs — present but miserable to edit. To honour the
hand-edit requirement, store bindings in a **human-readable form** (e.g. per-device-slot
keycode names / mouse-button + joy-button indices as plain strings/ints) and rehydrate
them into `InputEvent`s on load. This is a real change to the persistence format (pairs
with the ICD-4 per-device-slot dict) — captured here, detailed in the rebind plan §1/§5.

**5b — Device coverage → capture any device now, glyphs later.** The capture flow is
device-agnostic for free, so accept both keyboard and joypad captures from v1; pad
bindings render a **textual label** (e.g. "Pad A") until the deferred prompt/glyph system
lands (architecture design's deferred polish item).

---

## ICD-6 — Rebind conflict policy

**Status:** ✅ RESOLVED 2026-06-21 → **B, Swap** (chosen over the recommendation).

When a captured event already belongs to another action, perform a **two-way swap within
the same device slot** — never a silent single change:

> Capturing input **E** for action **A**, where **E** is currently bound to action **B**
> in the same device slot: **A receives E; B inherits A's previous binding for that slot.**
> If A had no prior binding in that slot, B's slot is left empty (and shows as unbound).

Required behaviour for this to be safe (detailed in the rebind plan §2/§5):
- **Clear messaging** — the confirmation/inline notice must state *both* changes ("Bound E
  to A; moved B to <A's old input>"), since two bindings changed at once.
- **Conflict scope is the matching device slot** — a keyboard capture only swaps against
  the other action's keyboard slot; a pad capture only against pad slots (consistent with
  ICD-4 per-device slots).
- **Check against game actions only** — `_mirror_game_keys_to_ui` derives the `ui_*`
  entries from the game actions, so the conflict scan runs over the game-action set, not
  the `ui_*` mirror (checking the mirror would produce phantom conflicts).
- **Esc is never swappable** — it stays the reserved capture-abort (rebind plan §5).

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

| ID | Decision | Date | Where applied |
|---|---|---|---|
| ICD-1 | New `InputModeManager` autoload (B) | 2026-06-21 | resolver plan §1, §2 |
| ICD-2 | Fold full resolver into gamepad slice 3 (A) | 2026-06-21 | resolver plan §3, §8; gamepad plan slice 3 |
| ICD-3 | Touch-first precedence + iOS smoke gate (A) | 2026-06-21 | resolver plan §2 |
| ICD-4 | Per-device slots (A) | 2026-06-21 | rebind plan §1, §3 |
| ICD-5 | All actions rebindable + always-on Reset + human-readable cfg; capture any device now, glyphs later | 2026-06-21 | rebind plan §1, §2, §5 |
| ICD-6 | Swap (two-way, same device slot) (B) | 2026-06-21 | rebind plan §2, §5 |
| ICD-7 | Tune-live; no decision | — | gamepad plan §10 |
