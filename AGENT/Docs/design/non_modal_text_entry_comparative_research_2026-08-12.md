---
Type: design research
Status: Research prepared — owner decisions pending
Last verified: 2026-08-12
Track IDs: RESEARCH-NON-MODAL-TEXT-ENTRY-2026-08-12
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Non-Modal Text Entry — Comparative Research

## Scope and dependency ruling

This is the **base packet** for live search and filter fields that update another surface
while the player is still typing. It covers focus ownership, platform keyboards, IME,
responsive resizing, cancellation, privacy, accessibility and persistence. It does not
choose compendium categories, ranking or result presentation.

**Hold the Reference Compendium search packet until this packet is decided.** The
compendium depends on the answers to `NMTE-1..20`: authoring it first would quietly decide
whether search is modal, how the keyboard changes the result viewport, what Cancel means,
and how controller focus moves between field and results. Those are shared input-layer
contracts, not compendium policy.

This packet extends the accepted naming keyboard work rather than replacing it. Naming and
file-path entry are commit/cancel transactions; a filter is a reversible view parameter.
They should use one service and one editing engine, but not one full-screen presenter.

## Existing Project Prometheus evidence

The repository already contains the correct architectural nucleus:

- `TextEntryService` is the single session arbiter. It owns one active generation, routes
  printable input ahead of gameplay mappings, emits exactly one result, and prevents focus
  escaping its overlay.
- `TextEntryRequest` owns purpose, limits, normalisation, validation, privacy and dismissal
  policy. `TextEntrySession` owns the editable value, selection and validation state.
- Real dispatched-event tests prove that `Z`, `X`, WASD and other gameplay-bound printable
  keys become text, and that Escape is one semantic transition.
- The current `TextEntryOverlay` is deliberately modal: full-rect mouse interception,
  dimmer, focus trap and explicit Confirm/Cancel. That is correct for naming but wrong for
  a filter whose results must remain visible and operable.
- `ResponsiveLayout` publishes live Compact/Medium/Expanded changes after a 120 ms settled
  resize and requires state preservation. A keyboard-height change must feed the same
  layout principle without pretending the physical viewport changed size class.
- Compact mobile design suppresses the Web OS keyboard and lends the reserved control band
  to the in-game keyboard. Landscape splits that keyboard into the dead columns. This is a
  ratified product decision, so native-keyboard support below is capability-driven and
  cannot silently re-enable the exported Web experimental keyboard.
- `FileDialogInputGuard` now only remembers/restores caller focus; the platform owns native
  picker filename editing. Past Windows failures demonstrate why cancel arbitration must
  remain central rather than being reimplemented by each field or window.

The smallest compatible extension is therefore a **non-modal presenter policy** on the
existing service, not a second search-input singleton.

## Platform facts

### Godot text controls and IME

Godot's `LineEdit` distinguishes focus from edit mode. Controller/keyboard navigation may
focus a field without starting editing; `edit()`, `unedit()` and `editing_toggled` expose
the transition. `ui_text_submit` and `ui_cancel` leave edit mode, and
`keep_editing_on_text_submit` can retain it. This distinction is exactly what a
controller-friendly search field needs: focus can arrive without unexpectedly raising a
keyboard or filtering on stray gameplay keys.

`LineEdit` also supplies `language`, text direction/BiDi options, max length, selection,
shortcut keys, secret mode and native virtual-keyboard hints. A custom presenter must not
discard these semantics by treating text as an ASCII append-only string.

At the display layer, `FEATURE_VIRTUAL_KEYBOARD` exists only on Android, iOS and Web.
`virtual_keyboard_show()` accepts existing text, a screen rectangle, keyboard type, maximum
length, caret range and next/previous hints; `virtual_keyboard_get_height()` reports the
keyboard height. The height can be zero when hidden or unavailable, and a resize/layout
response must therefore tolerate late, changing and missing values rather than assume one
fixed keyboard ratio.

IME is a separate capability. Godot exposes `window_set_ime_active()` and
`window_set_ime_position()` plus `ime_get_text()` and `ime_get_selection()`. Composition is
not committed text: the underlined candidate span can change repeatedly before one commit.
Filtering, validation, history and persistence must consume only committed text, while the
field visibly renders composition. Destroying/reparenting the active editor during a size
class change risks cancelling composition and is therefore forbidden.

Sources: [Godot `LineEdit`](https://docs.godotengine.org/en/stable/classes/class_lineedit.html),
[Godot `DisplayServer`](https://docs.godotengine.org/en/stable/classes/class_displayserver.html).

### Web and mobile geometry

The existing project measured Godot Web's experimental keyboard proxy and deliberately
exports `experimentalVK:false`; its own grid replaces the reserved controller band. That
decision avoids a platform keyboard covering both the field and most Compact content.

On a future native Android/iOS export, keyboard geometry must be treated as an inset, not a
new resolution. Android's edge-to-edge guidance describes IME insets as dynamic and notes
that apps must keep interactive content unobscured. The robust response is to reduce the
available content rectangle, anchor the field above the inset, preserve the selected
result, and scroll only as much as necessary. Reclassifying the whole screen from Medium
to Compact when a keyboard appears would rebuild unrelated navigation and make the layout
jump twice on show/hide.

Source: [Android edge-to-edge and inset guidance](https://developer.android.com/develop/ui/views/layout/edge-to-edge).

### Accessibility requirements

Non-modal filtering is valuable because it need not steal context, but it creates live
changes that must be described:

- WCAG 2.4.3 requires sequential focus order to preserve meaning and operability. Field,
  results and actions need one deterministic order even when responsive composition moves
  them visually.
- WCAG 3.2.1 says focus alone must not trigger a change of context. Merely landing on the
  field must not enter edit mode, raise a keyboard or clear results for controller users.
- WCAG 4.1.3 specifically uses search result counts and “no results” as examples of status
  that should be announced without moving focus. Announcing every keystroke or every result
  row would be excessively chatty; announce settled count/empty/error changes.
- Custom controls must expose name, role, value, focused/editing state and validation.
  Prefer a real `LineEdit` as the semantic editor, even when an echo strip presents it in
  Compact.

Sources: [WCAG focus order](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html),
[WCAG on focus](https://www.w3.org/WAI/WCAG22/Understanding/on-focus),
[WCAG status messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html),
[WCAG name, role, value](https://www.w3.org/WAI/WCAG22/Understanding/name-role-value).

## Comparable interaction patterns

The strongest comparable pattern is not a particular skin; it is a two-mode surface:

1. Search/filter is visibly present but dormant while normal list navigation owns input.
2. An explicit action enters editing; committed text updates the visible result set.
3. Submit/Done exits editing without leaving the screen; controller focus moves to the
   first valid result or remains on the field when empty.
4. Cancel first exits editing according to a stated rollback policy; a second Cancel backs
   out of the screen.

Console system keyboards, including Steam's official floating gamepad text input, support
the same separation: the game supplies the field rectangle and receives dismissal while
the underlying screen remains the task context. Fire Emblem's modern entries largely
avoid free-text search altogether and use bounded authored lists; where text is required,
they use the console keyboard. The lesson retained here is to keep filtering optional and
never make it the only way to reach a result.

Source: [Steamworks `ISteamUtils` gamepad text input](https://partner.steamgames.com/doc/api/ISteamUtils).

## Recommended base contract

### Service and request

Keep one `TextEntryService` and add a request presentation/commit policy rather than a
second service. A non-modal request needs at least:

- stable owner and field id;
- presentation `inline_filter`;
- update policy `committed_text_debounced`;
- cancel policy `restore_initial` or `clear_current` (chosen per field, default restore);
- submit policy `leave_value_and_focus_results`;
- keyboard preference/capabilities;
- privacy classification and persistence scope;
- result-owner callbacks/signals, never direct knowledge of a compendium.

Only one editing session may own printable input. Other filters can retain values, but are
dormant. Beginning a new session deterministically ends the old one and emits its outcome.

### Focus state machine

Use four explicit states:

`dormant field -> editing -> results navigation -> dormant field`

- Pointer/touch activation enters editing directly.
- Controller focus only highlights the field; Confirm enters editing.
- Done/Enter commits the current filter, closes the keyboard, and focuses the selected or
  first result. Empty results keep focus on the field and announce the state.
- Cancel while editing restores the request's initial value and returns focus to the field;
  Cancel outside editing belongs to the screen.
- Switching input families does not end the session or rewrite text. It changes prompts and
  the available presenter only at a safe boundary; active IME composition is never moved.

### Layout response

- Desktop hardware keyboard: results remain in place; no modal dimmer or focus trap.
- Compact Web/mobile under the ratified in-game-keyboard model: keyboard occupies the
  control region, field echo strip is pinned above it, and results use the remaining game
  view. Results can still be inspected by touch but gameplay controls are unavailable.
- Medium landscape: use the split keyboard in control columns and keep the result surface
  in the game-view rectangle.
- Native keyboard, if a future export enables it: treat reported height as a transient
  bottom inset, not a size-class input; ensure the field and selected result are visible.
- Expanded/FHD/4K: cap field width to a readable measure and let results consume space; do
  not stretch the input across the whole workspace.

### Filtering and performance

Text editing is immediate; expensive result recomputation is debounced after committed
text (recommended 100–150 ms, cancelled/restarted per commit). Arrow/result navigation is
never debounced. Composition updates render in the field but do not query until committed.
Each query carries a monotonically increasing generation; late asynchronous results are
discarded. Empty text restores the unfiltered collection rather than running a special
empty-string search.

### Privacy and persistence

Filter text is local UI state. Do not write it to telemetry, logs, crash breadcrumbs or a
campaign pack. Default persistence is while the screen instance lives, optionally within
the current application session for low-sensitivity compendium filters. Never persist a
private request, composition text, clipboard content, or typed value into gameplay saves.
History/suggestions are a separate opt-in feature and should not be implied by retaining a
field value.

## Required verification matrix

- Compact 360×640 and 393×852, Medium 852×393 and 768×1024, Expanded 1024×768,
  1280×720, 1920×1080 and 3840×2160.
- Physical keyboard/mouse, controller-only, touch, and live switching between them.
- Web with experimental native keyboard disabled; future native Android/iOS with keyboard
  height show/change/hide; desktop with no virtual-keyboard feature.
- Latin committed text, paste, selection, dead keys, CJK IME composition/commit/cancel,
  RTL text, emoji/non-BMP input, max characters and max UTF-8 bytes.
- Zero, one, many and slowly produced results; stale async completion; focus owner removed;
  viewport resize and size-class change while editing.
- Screen-reader field name/value/editing state, validation, settled result count and empty
  state; reduced motion; 200% menu-scale stress; field never obscured.
- Privacy audit proving typed/filter/composition values are absent from logs and saves.

## Decision queue

Walk [`NMTE-1..20`](../registers/non_modal_text_entry_open_questions_2026-08-12.md)
before authoring compendium search. `NMTE-1` (one service), `NMTE-2` (explicit edit mode),
`NMTE-6` (IME) and `NMTE-8` (keyboard geometry) are the foundational answers; the
remaining questions refine the contract.
