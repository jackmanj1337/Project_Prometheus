---
Type: register
Status: OPEN — research prepared, owner walk not started
Last verified: 2026-08-12
Register: NMTE-1..20
Tracker: RESEARCH-NON-MODAL-TEXT-ENTRY-2026-08-12
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Non-Modal Text Entry — Owner Questions

Research: [Non-Modal Text Entry Comparative Research](../design/non_modal_text_entry_comparative_research_2026-08-12.md)

**Dependency:** this is a base packet. Hold the Reference Compendium search packet until
`NMTE-1..20` are resolved; it may then choose domain-specific categories, ranking and
result actions without inventing a second input contract.

## Architecture and ownership

### [NMTE-1] Does non-modal filtering extend the shared `TextEntryService`?

- **A — Extend the shared service with an inline presentation policy.** For: one owner for
  printable-input precedence, focus arbitration, validation, privacy and platform keyboard
  capability; reuses the tested request/session split. Against: the service must support
  both transactional modal naming and live view filters without becoming a monolith.
- **B — Build a separate `SearchInputService`.** For: narrow API and independent delivery.
  Against: duplicates the exact cancellation, keyboard, IME and input-mode problems that
  centralisation fixed; two services could both believe they own printable input.
- **C — Let every screen own a `LineEdit`.** For: least initial code. Against: guarantees
  divergent controller, Compact, privacy and cancellation behaviour.

**Recommendation: A.** Add policy/composition points; keep domain filtering outside the
service.

### [NMTE-2] How does a focused filter enter editing on controller/keyboard navigation?

- **A — Focus immediately edits and raises a keyboard.** For: one state. Against: merely
  navigating across the field changes context and captures gameplay-bound printable keys.
- **B — Focus highlights; Confirm/click/tap explicitly enters editing.** For: predictable,
  matches Godot's focus-versus-edit distinction and WCAG on-focus guidance. Against: one
  extra controller action.
- **C — Typing starts editing, Confirm is optional.** For: desktop convenience. Against:
  dangerous when WASD/Z/X are gameplay bindings and unclear on controller.

**Recommendation: B**, with direct printable typing as an optional desktop shortcut only
when the screen has explicitly declared global type-to-filter ownership.

### [NMTE-3] May more than one live filter session exist?

- **A — Exactly one editing owner; other fields retain dormant values.** For: unambiguous
  input and keyboard ownership. Against: switching fields must end the old generation.
- **B — One per viewport/window.** For: supports multi-window tools. Against: physical
  keyboard and platform IME still have one effective owner.
- **C — Multiple concurrent sessions.** For: maximal flexibility. Against: no intelligible
  routing rule for printable input or OS keyboard dismissal.

**Recommendation: A.** A later editor-specific design may add scoped windows, but game UI
must have one owner.

### [NMTE-4] What should happen when another field requests ownership?

- **A — Reject the new request.** For: preserves current work. Against: makes the UI feel
  broken when a user deliberately activates another field.
- **B — End the old request using its declared handoff policy, then start the new one.**
  For: deterministic, compatible with service generations. Against: callers must choose
  whether handoff commits or restores.
- **C — Commit every old request automatically.** For: simple. Against: wrong for private or
  invalid input and surprising for Cancel-oriented flows.

**Recommendation: B**, defaulting inline filters to keep their current value and modal
transactions to cancel/restore unless their request says otherwise.

## Live updates, submission and cancellation

### [NMTE-5] When does filtering consume text?

- **A — Every raw edit/composition update.** For: fastest apparent response. Against: runs
  queries on incomplete IME candidates and can thrash large libraries.
- **B — Debounced committed text, 100–150 ms.** For: responsive while coalescing bursts and
  respecting IME. Against: a small, measurable delay.
- **C — Only after explicit Search/Enter.** For: cheapest computation. Against: ceases to be
  a live filter and is cumbersome on touch/controller.

**Recommendation: B.** Empty committed text immediately restores the full collection.

### [NMTE-6] How is IME composition treated?

- **A — Store composition as ordinary text.** For: minimal custom state. Against: queries,
  validation and persistence see uncommitted candidates; cancellation corrupts the value.
- **B — Render composition separately and query only after commit.** For: correct CJK/dead-
  key behaviour and preserves candidate selection. Against: session/presenter APIs need a
  composition channel and real-platform tests.
- **C — Declare IME unsupported in v1.** For: smaller English-only scope. Against: conflicts
  with localization readiness and physical keyboard expectations.

**Recommendation: B.** Never rebuild/reparent the active semantic editor mid-composition.

### [NMTE-7] What does Enter/Done do for an inline filter?

- **A — Clear the filter and close editing.** For: clean exit. Against: destroys the result
  context the player just created.
- **B — Keep the value, close the keyboard, focus selected/first result.** For: turns typing
  into navigation with one action. Against: requires an empty-result rule.
- **C — Keep editing indefinitely.** For: easy refinement. Against: controller cannot
  naturally reclaim result navigation.

**Recommendation: B.** If there is no result, remain on the field and announce “No results.”

### [NMTE-8] What does first Cancel do while editing?

- **A — Clear all text.** For: fast reset. Against: loses the pre-edit filter and makes
  Back/Escape destructive.
- **B — Restore the value captured on entry, leave edit mode, focus the field.** For:
  transactional and predictable; a second Cancel can leave the screen. Against: clearing
  needs its own visible action.
- **C — Keep current text and only hide the keyboard.** For: no lost edits. Against: Cancel
  becomes indistinguishable from Done.

**Recommendation: B** as the default request policy, with a dedicated Clear button/action.

### [NMTE-9] Does losing focus end the session?

- **A — Any focus loss cancels.** For: matches the current modal overlay. Against: makes it
  impossible to inspect or operate results while a filter remains active.
- **B — Focus may move within a declared field+results scope; leaving that scope ends per
  policy.** For: genuinely non-modal but bounded. Against: the owner must publish a stable
  focus scope across responsive reparenting.
- **C — Focus never affects lifetime.** For: robust against reparenting. Against: invisible
  sessions can keep consuming keys.

**Recommendation: B.** Scope membership, not ancestry of one overlay, becomes the shared
ownership test.

## Platform keyboard and responsive layout

### [NMTE-10] Which keyboard backend should inline filters use?

- **A — Always the in-game keyboard.** For: consistent, proven Web/Compact composition.
  Against: inferior to native IME and hardware entry where those work.
- **B — Capability and player preference: hardware when active, project keyboard for the
  ratified Web/Compact path, native only on explicitly supported future exports.** For:
  respects existing decisions while leaving a real platform seam. Against: several paths
  require verification.
- **C — Always native when Godot reports support.** For: best IME. Against: silently reopens
  the explicitly suppressed Web keyboard and can obscure the result surface.

**Recommendation: B.** Feature detection is necessary but not sufficient; export policy
and player override also govern selection.

### [NMTE-11] How should native keyboard height affect layout?

- **A — Feed reduced height into size-class selection.** For: reuses responsive layouts.
  Against: causes unrelated class changes and double jumps on keyboard show/hide.
- **B — Treat height as a transient bottom inset within the existing size class.** For:
  keeps navigation composition stable and directly models obscured space. Against: screens
  need an available-content-rect signal in addition to size class.
- **C — Overlay the keyboard and scroll only the field.** For: little layout work. Against:
  hides results/actions and violates focus-not-obscured expectations.

**Recommendation: B.** Height zero/late/change events must be tolerated and safe-area plus
IME insets composed, not substituted.

### [NMTE-12] What remains interactive while the in-game keyboard is visible?

- **A — Keyboard only, modal dimmer over results.** For: simple focus. Against: contradicts
  the purpose of live filtering.
- **B — Keyboard owns printable/navigation input; results remain visible and inspectable,
  with explicit Done moving controller focus to them.** For: preserves context without
  ambiguous pad ownership. Against: touch and controller have slightly different immediate
  reachability.
- **C — Keyboard and results both accept controller navigation simultaneously.** For:
  fastest expert use. Against: directional input has no obvious recipient.

**Recommendation: B.** Touch may inspect a result while editing; activation that leaves the
scope follows the request handoff policy.

### [NMTE-13] How should live resize or size-class change behave during editing?

- **A — Cancel editing and rebuild.** For: easy. Against: loses context and can abort IME.
- **B — Preserve request generation, text, composition, selection, selected result and
  scroll; reflow around the same semantic editor.** For: satisfies responsive programme
  state preservation. Against: requires stable nodes/adapters rather than scene replacement.
- **C — Defer all layout changes until editing ends.** For: protects IME. Against: leaves a
  broken layout during window drag/rotation.

**Recommendation: B**, with composition-sensitive changes deferred only when the platform
cannot move the candidate window safely.

## Input families and results

### [NMTE-14] How do controller users move from results back to refining the query?

- **A — Back always returns to the field.** For: easy to learn. Against: conflicts with
  screen Back and can add steps.
- **B — A labelled Refine Search action plus focus-neighbour path to the field.** For:
  discoverable and works in every composition. Against: consumes one action hint.
- **C — Typing automatically reopens from results.** For: desktop speed. Against: controller
  buttons and gameplay mappings are not text.

**Recommendation: B**, with desktop type-to-filter allowed only where explicitly enabled.

### [NMTE-15] What happens when filtering removes the focused/selected result?

- **A — Leave focus on a hidden/removed node.** For: no selection algorithm. Against:
  invalid focus and invisible context.
- **B — Select the nearest surviving result by stable source order, otherwise return to the
  field.** For: deterministic and preserves locality. Against: selection can visibly move.
- **C — Always jump to the first result.** For: simple. Against: disorienting in long lists.

**Recommendation: B.** Announce the settled count, not every selection shuffle.

### [NMTE-16] Can free-text filtering be the only discovery path?

- **A — Yes.** For: minimal UI. Against: excludes controller users who avoid text, creates
  localization/spelling barriers, and conflicts with Fire Emblem's bounded-list precedent.
- **B — No; categories, sorting and ordinary list traversal remain sufficient.** For:
  accessible fallback and resilient to unavailable keyboards. Against: more navigation UI.
- **C — Screen-specific.** For: flexibility. Against: silently makes some content keyboard-
  dependent.

**Recommendation: B.** Search is acceleration, never reachability.

## Validation, accessibility, privacy and persistence

### [NMTE-17] How are invalid input and result-count changes communicated?

- **A — Colour/icon only.** For: compact. Against: inaccessible and ambiguous.
- **B — Inline text tied to the field plus non-focus-stealing accessibility announcements
  for settled count/empty/error changes.** For: meets the non-modal status-message model.
  Against: needs announcement throttling to avoid chatter.
- **C — Modal dialog on every error/no-result state.** For: impossible to miss. Against:
  interrupts typing and turns a filter modal.

**Recommendation: B.** Do not announce each keystroke or every result title.

### [NMTE-18] What Unicode/length contract should filters use?

- **A — Printable ASCII like current naming requests.** For: existing keyboard content.
  Against: cannot find localized pack content.
- **B — Full committed Unicode, normalized for matching without rewriting the displayed
  query; explicit character and UTF-8 byte safety caps.** For: localization/IME ready and
  keeps user intent visible. Against: matching needs documented normalization/case rules.
- **C — Locale-specific allowlists.** For: controlled input. Against: brittle, excludes
  mixed-language names and grows as a closed vocabulary.

**Recommendation: B.** The in-game keyboard may ship limited layers, but paste/hardware/IME
must not be reduced to ASCII when the active content contains Unicode.

### [NMTE-19] May filter text be logged, telemetered or retained as history?

- **A — Log and retain by default.** For: diagnostics and convenience. Against: typed text
  can contain personal or sensitive strings and leaks into support bundles.
- **B — Never log values; history is a separately consented, local feature.** For: privacy
  by default while preserving a future explicit convenience option. Against: harder to
  diagnose content-specific matching complaints.
- **C — Hash values in logs.** For: comparison without plaintext. Against: low-entropy
  queries are guessable and hashes do not explain matching failures.

**Recommendation: B.** Diagnostics may record length, backend, generation and result count,
never text, composition or clipboard contents.

### [NMTE-20] How long does an inline filter persist?

- **A — Clear whenever focus leaves the field.** For: no stale state. Against: destroys
  non-modal results navigation.
- **B — Retain for the screen instance; optionally retain low-sensitivity filters for the
  application session, never gameplay saves or packs.** For: useful back-navigation without
  permanent residue. Against: callers must declare persistence scope.
- **C — Save all filters across launches.** For: maximum continuity. Against: stale context,
  privacy risk and save-schema burden.

**Recommendation: B.** Private requests and IME composition are always memory-only and
cleared when their session ends.

## Exit condition and dependent queue

When the owner resolves `NMTE-1..20`, record the resulting request fields, focus-state
machine, inset signal and verification matrix in the implementation plan. Only then open
the Reference Compendium search packet; it should consume this contract and decide only
compendium-specific taxonomy, matching/ranking and result actions.
