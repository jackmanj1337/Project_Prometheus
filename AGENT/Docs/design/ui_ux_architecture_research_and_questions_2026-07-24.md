---
Role: dated
Type: design
Status: Accepted - architecture defaults recorded; web-export experiment tracked separately
Last verified: 2026-07-24
Tracker: PLAN-UIUX-REUSE-PASS-2026-07-24
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# UI/UX Architecture Research and Owner Questions

This is the live research record for the
[UI/UX interaction vocabulary](ui_ux_interaction_vocabulary_2026-07-24.md).
It is implementation-neutral research, not authority to build UI or ratify open
campaign/data schemas.
Sequencing and ownership remain in the
[Project Control Plane](../plans/project_control_plane_2026-06-29.md).

## Scope and method

The pass begins with the live Project Prometheus tree, then compares one to four
version-pinned readable-source projects with produced-UI evidence. Facts,
interpretations, recommendations, and owner decisions are kept separate. External
research and the prototyping matrix are still in progress.

## Current-project audit (live notes)

### Existing reusable foundations

- `scripts/ui/ModalScreen.gd` centralizes hide/open lifecycle, cancel-to-close,
  controller/keyboard focus seeding, touch focus release, modal focus containment,
  held vertical repeat, popup capture, focus lookahead, and menu-scale adoption.
- `scripts/ui/SelectionCursor.gd` provides reusable logical one- and two-dimensional
  indexed selection with optional wrapping and inactive state. It is already used by
  HUD, attack-preview, and unit-detail surfaces.
- `scripts/ui/MenuScale.gd` scales typography and layout metrics without scaling the
  world/HUD. Its tests exercise repeated application, authored themes, fit behavior,
  and 200% stress constraints.
- `scripts/shared/InputDisplay.gd` plus `scripts/autoloads/InputModeManager.gd`
  provide live input-mode and controller-brand prompt resolution.
- Existing tests cover these primitives independently and exercise focus behavior in
  Settings and Unit Details. `scripts/tools/ui_inspection_preview.gd` is a current
  Godot-native rendering/inspection baseline.

### Composition debt and inconsistency

- Load, New Game, Campaign Library, Settings, Promotion, Reclass, and Unit Details
  share `ModalScreen`, but each still owns its record construction, selection/detail
  coupling, actions, state copy, and responsive behavior.
- `CampaignLibraryScreen.gd` is currently a management/import list embedded under
  New Game, while the accepted campaign-library direction makes it the shared
  Campaign → Run → Save browsing surface. Current structure is evidence of working
  primitives, not a target information architecture.
- `LoadGameScreen.gd` creates save rows and row actions locally. New Game uses
  `OptionButton` controls and includes temporary v0.3.0 focus tracing. These patterns
  do not yet form a reusable record-list/master-detail/action contract.
- Native Control focus and `SelectionCursor` coexist appropriately in different
  surfaces, but there is no documented decision rule for which owns selection in a
  reusable record screen.
- Modal containment supports embedded popups, but a reusable action-menu contract
  still needs explicit origin-focus restoration and nested-modal policy.
- Menu scale is strong at the primitive level; no shared composition currently
  guarantees the accepted wide master-detail → narrow sequential collapse.

### Initial interpretation

The strongest reuse boundary sits above the existing input/scale/modal primitives:
a record collection model with stable-id selection, a responsive master-detail host,
and a context-derived action list. Replacing the proven primitives would add risk and
duplicate behavior; composing them would address the repeated screen-level work.

## Comparator study: Playnite Fullscreen 10.56

### Why this comparator

Playnite is a library manager rather than a tactical RPG, which makes it a useful
comparison for the Campaign Library's information architecture without inviting the
project to copy another RPG's visual style. Its Fullscreen mode is explicitly designed
for couch/controller use. The inspected release is **10.56**, signed commit
[`02fc197`](https://github.com/JosefNemec/Playnite/commit/02fc197), released 2026-05-26;
the repository is MIT-licensed. Produced-UI evidence comes from Playnite's official
[Fullscreen Mode manual](https://api.playnite.link/docs/manual/gettingStarted/playniteFullscreenMode.html)
and [filter/preset manual](https://api.playnite.link/docs/manual/features/filtersAndFiltersPresets.html).

### Source and produced-UI facts

- The official Fullscreen manual identifies three regions: top/preset controls,
  filters, and the library. A selected game opens a separate game view via the default
  confirm button. Shoulder buttons switch quick filter presets. This is produced-UI
  evidence, not an inference from source.
- The pinned
  [`Main.xaml`](https://github.com/JosefNemec/Playnite/blob/02fc197/source/Playnite.FullscreenApp/Themes/Fullscreen/Default/Views/Main.xaml)
  composes those regions as separately named controls. Its library is a `ListBoxEx`;
  filters are separate non-focusable hosts; the bottom action bar contains install,
  play, details, options, search, and filter commands. A dedicated zero-results label
  is driven by the list item count, and progress has its own named region.
- The pinned
  [`FullscreenAppViewModel.cs`](https://github.com/JosefNemec/Playnite/blob/02fc197/source/Playnite.FullscreenApp/ViewModels/FullscreenAppViewModel.cs)
  stores selected game, last valid selected index, list visibility/focus, detail
  visibility/focus, and a derived details view model as explicit state. Its own TODO
  says selection and details should be more fully decoupled; this is a useful warning,
  not a pattern to reproduce blindly.
- The shared pinned
  [`MainViewModelBase.cs`](https://github.com/JosefNemec/Playnite/blob/02fc197/source/Playnite/ViewModels/MainViewModelBase.cs)
  owns the collection view, database filters, sorted filter presets, progress state,
  and commands. Desktop and Fullscreen presentations inherit that shared model.

### Interpretation for Project Prometheus

- **Adopt the separation, not the framework:** collection/filter/selection/operation
  state can be shared while different layouts own focus and presentation.
- **Do not copy a permanent command strip wholesale:** Project Prometheus has fewer
  high-frequency commands and more consequence-heavy actions. Primary actions fit in
  details; secondary actions fit a contextual action list.
- **Keep filter state outside row widgets:** Playnite's shared collection view supports
  multiple presentations and quick presets. Project Prometheus can achieve the same
  separation with an opaque presentation-state object rather than WPF/MVVM.
- **Make no-results and progress first-class states:** both are separate from the
  collection in Playnite's produced UI and source. This aligns with already accepted
  campaign-library empty/scanning/error distinctions.
- **Preserve last valid selection by stable id, not index:** Playnite explicitly keeps
  an index, but Project Prometheus records can regroup and reorder. The comparator
  proves restoration matters; the local domain requires a stronger key.

### Limitations

Playnite 10.56 targets Windows/WPF, uses a 1920×1080 fullscreen design baseline, and
does not demonstrate Project Prometheus's narrow-window or 200% menu-scale collapse.
The source/build was read remotely and not downloaded or executed. The official manual
provides screenshots and controller mappings, but this session did not perform an
owner-only live controller inspection. No code or assets were copied.

## Prototyping workflow matrix

Godot 4.6 remains the fidelity baseline. The official UI documentation describes
`Control`/`Container` composition, and the 4.6 `Control` reference exposes explicit
focus neighbors plus new accessibility relationships and live regions:
[Godot UI](https://docs.godotengine.org/en/4.6/tutorials/ui/) and
[Control reference](https://docs.godotengine.org/en/4.6/classes/class_control.html).
The non-Godot candidates below were researched only; nothing was installed or adopted.

| Criterion | Godot scene fixture + inspection preview | Static semantic HTML/CSS + Playwright | Storybook + browser tests |
|---|---|---|---|
| Headless render/capture | Already present; highest engine fidelity | Strong: browser creation, input, fixed viewport, screenshot | Strong after framework setup; story-per-state model |
| Structural assertions | Strong for scene/control properties; accessibility assertions need project helpers | Strong DOM and ARIA snapshots; targeted assertions | Strong DOM/component assertions; story states are explicit |
| Keyboard/focus/modal | Exact Godot behavior and action map | Strong keyboard/pointer simulation; gamepad semantics require an adapter and remain approximate | Strong component interactions, same gamepad limitation |
| Touch/responsive/200% | Exact when fixtures set viewport/menu scale | Strong viewport/touch emulation and CSS reflow; menu scale must be represented intentionally | Strong through story parameters, with same translation caveat |
| Accessibility inspection | Godot 4.6 exposes accessibility metadata, but current project has not built an audit harness | Best machine-readable semantics; ARIA snapshots and optional axe checks | Good: official a11y addon plus interaction tests |
| Visual regression | Existing capture path can be made deterministic in one container; comparison helper still needed | Built-in screenshot comparison; official docs warn baselines vary by OS/browser/environment | Visual workflow exists, but official native path uses hosted Chromatic; local alternative adds configuration |
| Iteration/owner review | Slower authoring, but artifact is production-faithful | Fast, portable static artifact; easy screenshots and browser review | Excellent component catalogue, but heavy for two disposable screens |
| Offline/reproducible | Best: Godot already pinned in workspace | Good after approved pinned browser/runtime installation; not currently present/approved | Weaker: framework, addons, browser/runtime, and often hosted visual service |
| Supply-chain/maintenance | No new stack | Node + Playwright + browser binaries; meaningful but bounded new dependency | Largest surface: framework adapter, Storybook, test addon, browser tooling, optional service |
| Translation risk | None | Medium/high: CSS/DOM layout and semantics must be manually translated to Godot | High: component abstractions can become a second UI implementation |
| Source-of-truth risk | Low if fixtures instantiate production scenes | Controlled only if disposable and contract/data fixtures are generated from neutral examples | High unless stories wrap the production UI, which is not possible across engines |

Primary evidence for the browser option:

- Playwright supports fixed viewport/touch emulation and keyboard/pointer interaction:
  [emulation](https://playwright.dev/docs/emulation) and
  [input](https://playwright.dev/docs/input).
- It supports accessibility-tree snapshots with roles, names, selected/disabled state,
  and order: [ARIA snapshots](https://playwright.dev/docs/aria-snapshots).
- It supports deterministic-environment screenshot baselines but warns that rendering
  varies across host environments:
  [visual comparisons](https://playwright.dev/docs/test-snapshots).
- Storybook supports state fixtures plus browser interaction and accessibility tests,
  but its official setup installs framework/test addons; the official visual path uses
  Chromatic:
  [interaction tests](https://storybook.js.org/docs/9/writing-tests/interaction-testing),
  [accessibility tests](https://storybook.js.org/docs/9/writing-tests/accessibility-testing),
  and [visual tests](https://storybook.js.org/docs/8/writing-tests/visual-testing).

### Recommendation

**Default: stay Godot-native.** Add reusable, data-seeded scene fixtures to the existing
inspection preview; drive real `InputEventAction`s; assert focus, selection, modal
containment, scale/collapse thresholds, and control rectangles; capture screenshots in
the pinned container. This tests the engine, theme, input map, and translation at once.

**Fallback for early layout exploration: a disposable static HTML/CSS artifact with
Playwright, only after explicit approval to install its pinned runtime/browser.** Use it
when rapid reflow, semantic structure, focus-order inspection, or owner-review captures
materially outweigh translation risk. Inputs are neutral fixture JSON, not copied game
managers. Outputs are annotated screenshots plus interaction/ARIA contracts; no HTML or
CSS ships and the prototype is deleted or archived as research evidence after the Godot
scene reproduces the accepted contract.

**Do not adopt Storybook for this proof of concept.** Its catalogue is valuable for a
web component system, but Project Prometheus has no web-component production layer. It
adds more maintenance and a stronger second-source-of-truth risk than static HTML plus
Playwright.

### Smallest useful proof of concept (approval-gated only if using the fallback)

Model one neutral record set and four states: populated, empty, filtered-no-results,
and long-title/error stress. Exercise wide master-detail and narrow sequential layouts
at 100/150/200% equivalents; keyboard through list → details → actions → confirmation →
cancel; verify focus restoration, visible selection, readable disabled reasons, ARIA
order, and screenshot baselines. Do not connect campaign managers, persist state, or
define domain schemas. The Godot-native version of this proof needs no new-tool approval.

## Evidence matrix (live)

| Finding / question | Project evidence | External evidence | State |
|---|---|---|---|
| Preserve input, scale, and modal primitives; standardize composition above them | `ModalScreen.gd`, `SelectionCursor.gd`, `MenuScale.gd`, `InputDisplay.gd`, tests | Godot 4.6 Control/focus model; Playnite separates collection state from layouts | Recommendation |
| Stable selection must be distinct from focus | Custom cursor plus native focus paths; actions need focus without losing record context | Playnite has separate selected game and list/detail focus state | Recommendation |
| Restore selection by stable id after filter/sort/refresh | Campaign rows regroup/reorder and accepted state persists | Playnite explicitly preserves last valid selection, though by index | Recommendation strengthened for local domain |
| Treat empty, no-results, progress, and errors as distinct states | Accepted CL-FIRST-04 and local async-progress decision | Playnite source gives zero results and progress separate regions | Finding |
| Master-detail needs a sequential narrow presentation | Accepted CL-NAV-01; no shared implementation exists | Playnite details are a distinct controller view, but lacks narrow/200% evidence | Owner decision accepted; exact threshold pending |
| Stay Godot-native by default | Existing inspection preview and headless real-engine tests | Godot exactness vs browser translation; Playwright strongest fallback capabilities | Recommendation |
| Prototype must not become a second UI authority | Production scenes and handoff boundary | Storybook/HTML necessarily create parallel composition | Constraint |

## Owner decisions

On 2026-07-24 the owner accepted the recommended defaults for `UI-ARCH-01` through
`UI-ARCH-06`. These are now the structural direction for later planning and
implementation, subject to measured layout thresholds and live controller/visual
validation. `UI-TOOL-01` was superseded by the owner-requested actual-web-export
Playwright experiment, tracked as `EXP-UI-WEB-PLAYWRIGHT-2026-07-24`.

### Foundation

#### UI-ARCH-01 — Reusable record-screen state boundary — Accepted-default

- Why it matters: stable selection, filtering, refresh, and responsive collapse need
  one coherent contract, but campaign/data objects remain unsettled.
- Current evidence: current screens locally construct rows and bind directly to
  managers; accepted Campaign Library decisions require the same interaction shape
  across Campaign → Run → Save and later inventory-like surfaces.
- Decision: the reusable layer owns presentation state keyed by an
  opaque stable record id; domain managers continue to own records and mutations.
  Use callbacks/signals for queries and actions rather than embedding campaign schema.
- Default if deferred: build no shared domain model; document the presentation contract
  only.
- Dependencies/defer: do not decide catalogue, persistence, or save identity schemas.

#### UI-ARCH-02 — One controller with wide/narrow compositions — Accepted-default

> **SUPERSEDED 2026-08-12 by the size-class model (`[UUI-1]`, `[UUI-2]`).** Both halves of the
> decision below moved. There are **three** size classes, not two compositions — Compact (`< 600`),
> Medium, and Expanded (`≥ 1024`) — against a ratified **360×640** design floor. And the "measured
> content-width rule … not a hard-coded device name" qualifier no longer holds: the classes are
> named, with fixed width breakpoints. The single-controller principle itself survives and is what
> the size-class seam implements. Live spec:
> [`responsive_ui_redesign_2026-08-06.md`](responsive_ui_redesign_2026-08-06.md) and
> [`unified_ui_decisions_2026-08-12.md`](../registers/unified_ui_decisions_2026-08-12.md).
> Recorded by `R1`, [`r1_plan_corpus_precedence_diff_2026-08-17.md`](r1_plan_corpus_precedence_diff_2026-08-17.md) §5.3.

- Why it matters: duplicated scenes can drift in action availability, focus, and state;
  one deeply adaptive scene can become difficult to test.
- Current evidence: CL-NAV-01 already requires wide master-detail and narrow sequential
  presentation; Menu Scale can force narrow behavior even at a nominally wide viewport.
- Decision: one presentation controller/state model with two small
  layout compositions selected by available content width; preserve selected record and
  focused region across transition.
- Default if deferred: treat sequential navigation as authoritative and enhance to two
  panes only when measured space permits.
- Dependencies/defer: the threshold is a measured content-width rule after typography
  and art constraints settle, not a hard-coded device name or campaign schema.

### Input and actions

#### UI-ARCH-03 — Native focus versus SelectionCursor — Accepted-default

- Decision: native Control focus owns ordinary GUI controls and
  action lists; use `SelectionCursor` only for custom-rendered/spatial collections where
  Control focus cannot express selection. In both cases selection remains stable-id state.
- Default if deferred: native focus for the reusable record-list layer.

#### UI-ARCH-04 — Primary and secondary action placement — Accepted-default

- Why it matters: a permanent command strip is fast but crowds small/high-scale layouts;
  a popup hides discoverability and creates another modal layer.
- Evidence: Campaign Library already places Continue/New Run in details; Playnite 10.56
  uses a permanent bottom command strip for frequent couch actions.
- Options: all persistent in details; permanent primary plus contextual secondary;
  action-menu-only.
- Decision: one or two persistent primary actions in details, followed by a
  labelled More Actions list for secondary/destructive commands. Keep selection in the
  list while focus moves through actions. Confirm only consequence-heavy mutations.
- Default if deferred: persistent primary + contextual secondary.
- Dependencies/defer: exact commands remain domain-owned; no campaign action enum.

#### UI-ARCH-05 — Explicit controller region transitions — Accepted-default

- Why it matters: implicit geometric focus can become unpredictable when panes collapse,
  filters appear, or buttons enable/disable.
- Evidence: Godot supports explicit focus neighbors; Playnite dedicates controller
  commands/regions and shoulder shortcuts; `ModalScreen` currently provides linear
  vertical traversal rather than a reusable region graph.
- Options: geometry-only; explicit directional neighbors; explicit region command plus
  local directional navigation.
- Decision: explicit focus neighbors within stable layouts plus a consistent
  region transition (confirm/right into details, cancel/left back to list). Shoulder
  shortcuts are reserved for stable high-frequency sibling views, not arbitrary actions.
- Default if deferred: sequential screen behavior is authoritative; wide mode mirrors it.

#### UI-ARCH-06 — Direct-mode HUD-layout-editor controller scheme — Accepted-default

- Why it matters: the current editor is mouse-drag driven and swallows every non-mouse
  event except cancel. Headless tests cover open/reset/save/cancel but not controller
  choose/move/scale behavior.
- Evidence: `HudLayoutEditor.gd` already has selected panel id, offset/scale primitives,
  reset, Done, and Cancel snapshot restoration. The missing work is an input/state model,
  not new persistence.
- Options: virtual pointer; direct panel-cycle/edit mode; grid/snap palette.
- Decision: direct mode. Enter editor → focus toolbar; Choose Panel opens a
  controller-selectable panel list/cycle; confirm enters Move; d-pad moves by a small
  step and held input repeats; shoulder buttons scale; a modifier or alternate prompt
  offers coarse movement; confirm exits Move; Reset is confirm-gated; Done persists;
  Cancel restores the opening snapshot. Keep the map fully suppressed throughout.
- Default if deferred: retain mouse editor and label controller editing unavailable;
  never pretend swallowed controller input is support.
- Dependencies/defer: snap size/coarse step and final prompts need owner preference and
  live controller validation; persistence and panel ids remain unchanged.

### Research tooling

#### UI-TOOL-01 — Disposable prototype choice — Superseded

- Original options: remain Godot-native; approve static HTML/CSS + pinned Playwright proof;
  adopt a component-preview system.
- Recommendation: remain Godot-native for the first proof. Approve the static-browser
  fallback only if the Godot fixture proves materially slower for reflow/focus evidence.
  Do not adopt Storybook for this project.
- Default if deferred: stay Godot-native using scene fixtures, headless interaction
  tests, and deterministic screenshots from the existing inspection path.
- Ongoing-cost dependency: any Playwright proof requires owner approval before its
  runtime/browser download and a pinned dependency policy.

**Superseding owner decision, 2026-07-24:** add a bounded Playwright experiment against the
actual Godot web export to the pass. This authorizes investigation and experiment
planning; installing Playwright/browser binaries remains a separate explicit approval
gate. The tracked child is `EXP-UI-WEB-PLAYWRIGHT-2026-07-24`.

The experiment must compare two modes:

1. **Uninstrumented export:** focus the Godot canvas, drive real keyboard/mouse/touch
   input, observe boot/console/runtime failures, test target viewports and Menu Scale,
   and capture deterministic screenshots.
2. **Test export with a minimal state bridge:** use Godot's web-only
   `JavaScriptBridge` to publish read-only state such as current screen, selected stable
   record id, focused region, modal/operation state, and Menu Scale. Playwright still
   drives the public input path; it must not call domain mutations or become an
   alternate control API.

Required findings: how reliably the canvas receives focus/input; coordinate-click
brittleness; deterministic waiting without sleeps; screenshot stability in the pinned
container/browser; browser console and export-load diagnostics; touch emulation;
whether Godot accessibility metadata becomes useful browser semantics; and the exact
coverage gap left for physical controllers and human visual judgement. ~~The bridge must
compile only into a dedicated test export, expose no protected/player data, and stay
absent from production exports.~~ **Superseded 2026-08-10, corrected here 2026-08-23:** the
owner decided the bridge ships in public web builds, gated and read-only. It is an ordinary
autoload (`project.godot:41`) present in every export; `WebTestBridge.gd:66-72` makes the
boundary *structural* instead — it calls `set_process(false)` before anything else, returns
immediately unless `OS.has_feature("web")`, and then requires an explicit `test_bridge=1`
query parameter. "Expose no protected/player data" still binds. This sentence lives outside
the `UI-TOOL-01` entry that `R1` bannered on 2026-08-17, which is why the correction debt
read as paid while the claim still stood. Success means a smallest repeatable flow covering boot
→ record navigation → details/actions → confirmation/cancel at wide/narrow and 200%
stress, with a clear adopt/decline recommendation and ongoing dependency cost.

## Recorded walkthrough order

The owner accepted the architecture defaults in the proposed order. The only remaining
tooling gate is execution of `EXP-UI-WEB-PLAYWRIGHT-2026-07-24`, including explicit
approval before installing its pinned tooling/browser dependency.

## Explicit deferrals

- No campaign/data ownership, persistence, identity, catalogue, or save schema.
- No production widgets, scenes, assets, or implementation plan.
- No visual-theme or asset-registry ratification.
- No third-party code/assets and no unapproved research-tool adoption.

## Research gaps / owner-only inspection

No CAPTCHA, robots.txt, purchase, private access, or owner-only evidence block was
encountered. Playnite was not downloaded or built; official screenshots/manual and
pinned source were sufficient for the bounded comparator. No tool was installed.
