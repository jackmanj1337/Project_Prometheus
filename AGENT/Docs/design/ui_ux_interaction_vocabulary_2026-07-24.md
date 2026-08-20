---
Type: design
Status: Active - research in progress; the Theme roles section is Ratified per [UUI-13]
Last verified: 2026-08-18
Tracker: PLAN-UIUX-REUSE-PASS-2026-07-24, UI-PHASE0-UNBLOCKED-ITEMS-2026-08-16
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# UI/UX Interaction Vocabulary

This live vocabulary accompanies the
[UI/UX architecture research and owner questions](ui_ux_architecture_research_and_questions_2026-07-24.md).
It names player-facing interaction patterns without ratifying campaign schemas,
content ownership, or a particular widget implementation.
Sequencing and ownership remain in the
[Project Control Plane](../plans/project_control_plane_2026-06-29.md).

## Status key

- **Observed:** describes behavior or vocabulary already present in the project.
- **Recommended:** research direction; implementation still requires the normal lifecycle.
- **Pending:** consequential owner choice remains open.
- **Ratified:** settled by a register, and cited. Not a research direction — a name that
  other work is entitled to depend on. Added 2026-08-18 when `[UUI-13]` assigned this
  document a list that is neither observed nor merely recommended.

## Core terms

### Record list — Recommended

A vertically or spatially ordered collection of selectable summaries for objects
such as campaigns, runs, saves, items, or units. A record list exposes identity and
comparison fields; it does not imply storage format or ownership.

- Player meaning: the set of things available to browse or act upon.
- Widget meaning: a collection view with stable selection, focus, ordering, empty
  state, and optional sorting/filtering.
- Avoid: using **menu** when the rows represent persistent objects rather than
  immediate commands; using **table** unless columns and grid navigation are real.
- Example: campaign summaries grouped by pack. Non-example: Continue/Settings/Quit.
- Input/accessibility: selection must survive redraws by stable identity, remain
  visible during held navigation, and have an explicit initial focus.

### Action list — Recommended

A collection of commands available in the current context, such as Continue,
Inspect, Export, or Delete.

- Player meaning: what can be done now.
- Widget meaning: command controls whose enabled state and explanation derive from
  the current selection and operation state.
- Avoid: **record list** for commands; **context menu** as a blanket synonym because
  actions may live persistently in a detail pane.
- Example: campaign-detail actions. Non-example: the campaigns being acted upon.
- Input/accessibility: unavailable actions remain understandable; destructive
  actions are separated and confirmation returns focus predictably.

### Master-detail — Recommended

A composition where selection in a record list controls a richer adjacent detail
region. At narrow widths the same relationship may become sequential screens.

- Player meaning: browse summaries, then inspect one without losing place.
- Widget meaning: coordinated list and detail regions sharing one selected record id.
- Avoid: **split view** when referring to the information relationship; split view
  describes only one responsive presentation.
- Example: campaign list plus campaign details/actions. Non-example: two unrelated
  panels displayed side by side.
- Input/accessibility: list and details need an explicit region-transition command,
  a reliable return path, and preserved selection/focus.

### Selection — Observed / Recommended

The current record or value used by the interface. Selection is application state;
keyboard/controller focus is the input destination and may be a different concept.

- Avoid: treating **selected**, **focused**, and **hovered** as interchangeable.
- Example: a campaign remains selected while focus moves into its action list.
- Input/accessibility: expose both selected and focused states without relying on
  colour alone. Pointer hover must not silently commit selection-dependent work.

### Focus — Observed

The control that receives keyboard/controller UI input. Project Prometheus already
seeds and contains focus in `ModalScreen` and drops stale focus for touch input.

- Avoid: **cursor** for GUI focus; the project also has map and custom selection
  cursors with different movement contracts.
- Non-example: the record displayed in the detail pane after focus moved elsewhere.
- Input/accessibility: focus order, focus visibility, modal containment, initial
  focus, and restoration are part of the screen contract.

### Selection cursor — Observed

A project-owned logical index navigator for custom one- or two-dimensional
selection (`SelectionCursor.gd`). It is suitable when native Control focus is not
the authoritative selection mechanism.

- Avoid: adopting it automatically for ordinary buttons or lists that already have
  useful native focus semantics.
- Input/accessibility: custom cursor visuals still need readable labels, current
  position/state, and an equivalent pointer/touch path.

### Filter — Recommended

A reversible constraint on which records are shown, based on known categories or
states. Filtering never mutates the records.

- Avoid: **search** when the UI only offers fixed facets; **sort** when records are
  being hidden.
- Input/accessibility: announce the active constraint and result count; provide a
  one-step clear/reset action and a distinct no-results state.

### Sort — Recommended

A reversible ordering of the same visible record set.

- Avoid: conflating sort with filter or grouping.
- Input/accessibility: communicate the active key and direction in text, not only an
  arrow; selection should remain on the same stable record after reordering.

### Empty state — Recommended

The intentional presentation when a valid collection has no records. It explains
why the surface is empty and offers the next useful action.

- Avoid: using the same presentation for loading, permission failure, invalid data,
  or a filter with zero matches.
- Example: no campaigns installed, with Import as the primary action.

### No-results state — Recommended

The presentation when records exist but the active filters produce no visible
matches. It preserves the user's query and offers Clear Filters.

- Non-example: a genuinely empty library.

### Loading / progress state — Recommended

An operation state in which results are not yet ready. Use determinate progress when
meaningful work units are known and indeterminate progress for short bounded work.
Cancellation is offered only before the operation's commit point.

- Avoid: **empty** or **frozen** presentation during active work.
- Input/accessibility: state changes need readable status text; focus cannot escape
  into controls whose backing data is being replaced.

### Badge — Recommended

A short, redundant status label attached to a record summary, such as Modified,
Missing Content, or Invalid.

- Avoid: colour-only dots and unexplained icons.
- Input/accessibility: the same status appears in the accessible/readable record
  label and is explained in details.

### Modal — Observed / Recommended

A temporary interaction layer that blocks interaction with its owning surface until
completed or cancelled. The term describes input ownership, not visual centering.

- Avoid: calling every overlay a modal; non-blocking details and notifications are
  not modal merely because they float.
- Input/accessibility: contain focus, provide one consistent cancel path, suppress
  background commands, and restore a valid originating focus target.

### Confirmation — Recommended

A modal decision requested immediately before a consequential or hard-to-recover
action. Confirmation states the object and consequence.

- Avoid: confirmation for reversible browsing or inspection; vague “Are you sure?”
  copy.
- Input/accessibility: safe action receives initial focus unless project policy
  explicitly chooses otherwise; accept/cancel bindings stay consistent.

### Responsive collapse — Recommended

The change from simultaneous master-detail regions to sequential list and detail
screens when available width or menu scale cannot preserve readable content.

- Avoid: shrinking type or hit targets to retain a two-pane shape.
- Input/accessibility: the information hierarchy and back path remain the same;
  only presentation changes.

### Menu scale — Observed

The project preference that scales menu typography and layout metrics while leaving
the map/HUD scale independent. It is not global display scaling.

- Input/accessibility: every reusable composition must be structurally tested at all
  supported factors, including 200% stress, rather than relying on visual scaling.

### Input prompt — Observed

Readable text and/or a glyph that identifies an available action for the active input
mode and controller brand. `InputDisplay.gd` and `InputModeManager.gd` are the current
project seams.

- Avoid: hard-coded keyboard keys or one controller brand in screen copy.
- Input/accessibility: prompts supplement labels and focus; they are not the sole way
  to discover an action.

### Prototype — Recommended / Pending workflow

A deliberately non-authoritative artifact used to test layout, navigation, or
interaction hypotheses before production implementation.

- Avoid: allowing prototype state/schema or styling to become a second source of
  truth. The Godot production scenes and ratified design remain authoritative.
- Input/accessibility: a useful interaction prototype must exercise focus order,
  containment, reflow, and input-state transitions, not only render a screenshot.

## Theme roles — Ratified

The eleven **role names** a themed Control may declare. Ratified by `[UUI-13]`
(`unified_ui_decisions_2026-08-12.md`), which assigned them to this document because it is
the project's naming authority and had explicitly deferred exactly this. Answers `[UITH-3]`.

`frame` · `header` · `footer` · `list_row` · `detail_pane` · `action` · `danger` ·
`tooltip` · `hud` · `dialog` · `slider`

**The mechanism is `theme_type_variation`**, Godot's supported way to paint the same Control
class differently by role. It has **zero uses in the repo**, so adoption is greenfield: there
is no existing convention to migrate and no interim dialect to support.

**Roles are named semantically, never visually.** The name is `danger`, not "the red one" —
a pack repaints the palette, so any name describing the paint is wrong the first time a pack
is themed. This is the naming rule the list exists to fix, not a stylistic preference.

**The published list is a versioned API.** Authors cannot invent roles, because they cannot
edit `scenes/ui/`; and themes are distributed separately on their own cadence, so a rename
breaks packs the build has never seen and therefore cannot migrate. The list rides
`format_version` / `builder_content_version` with a real compatibility story. Treat adding a
role as an API addition and renaming one as a breaking change.

**What a role does and does not carry.** A role selects *paint* — `[UUI-10]` limits a pack to
paint and font face. Metrics are computed from the density tokens (`[UUI-9]`: `content_margin`
derives from tokens, `texture_margin` stays with the art). That split is load-bearing rather
than theoretical, because the campaign editor renders chrome-themed and pack-themed surfaces
in the same window at the same time (`[CEUI-S3]`), and `EW-8` makes *a pack theme cannot reach
editor chrome tokens* an explicit **test obligation** rather than an assumption.

- Player meaning: none. A role is invisible to players; it is how a surface asks to be
  painted consistently with every other surface of its kind.
- Avoid: role names that describe an appearance, a screen, or a widget class
  (`red_button`, `settings_panel`, `HSlider`) rather than a semantic part.
- Input/accessibility: a role carries no focus or input behavior. Focus order, minimum target
  size and reachability come from the density tokens and the component, never from the theme.

## Terms intentionally deferred

Campaign, Pack, Run, Save, Backup, Rule Profile, and their ownership relationships
are recorded in the campaign-library decisions. This vocabulary may use those as
examples but does not broaden or ratify their data contracts. Asset registries and
final art language remain deferred to the art/import work.

**Visual-theme tokens are no longer wholly deferred.** The *role names* above were ratified
by `[UUI-13]` and published here on 2026-08-18; the density token values themselves live in
`ResponsiveLayout.DENSITY_TOKENS` and are ratified per column (`[UUI-11]` `dense`,
`[CEUI-S1]`/`[CEUI-S50]` `editor`). What remains deferred is the paint: palettes, art
language, and the built-in theme sets.
