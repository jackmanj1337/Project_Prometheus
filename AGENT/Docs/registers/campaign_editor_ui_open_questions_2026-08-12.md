---
Type: register
Status: OPEN - CEUI-1..40 await owner discussion; search UX held
Last verified: 2026-08-12
Register: CEUI-1..40
---

# Campaign Editor UI — Open Questions

**Started:** 2026-08-12  
**Research:**
[`campaign_editor_ui_comparative_research_2026-08-12.md`](../design/campaign_editor_ui_comparative_research_2026-08-12.md)

These questions do not reopen the integrated runtime-gated editor, engine chrome,
UUI semantic roles, JSON pack format, open registries, or one-active-self-contained-
pack decisions. Every recommendation is provisional until the owner answers.

> **HELD — search and text entry.** Search fields may be reserved spatially, but
> their behavior, syntax, ranking, keyboard/OSK lifecycle, and focus restoration
> belong to the non-modal text-entry packet. No CEUI answer decides them.

Legend: **[OPEN]** / **[HELD]** / **[RESOLVED]**.

## A. Shell, layout, and navigation

### [CEUI-1] What is the default desktop composition? **[OPEN]**
- **A — Tree / centre workspace / Inspector / collapsible bottom panel.** For: familiar, selection-driven, scales across content types. Against: dense and needs careful focus order.
- **B — Separate full-screen tools.** For: each tool can be simpler. Against: context switching and duplicated navigation.
- **C — Spreadsheet-first database with pop-out map.** For: excellent bulk records. Against: map, graph, and asset work become second-class.
- **Recommendation: A**, with workspace-specific centre tools.

### [CEUI-2] What content does the left tree expose? **[OPEN]**
- **A — Semantic content categories generated from schema/registry metadata.** For: author language and open-registry compliance. Against: requires good metadata.
- **B — Raw pack folders/files.** For: transparent disk mapping. Against: leaks storage details and encourages invalid manual organization.
- **C — Hand-coded fixed categories.** For: fastest first implementation. Against: violates the extension principle.
- **Recommendation: A**, plus an advanced Show file action.

### [CEUI-3] How many documents may be open? **[OPEN]**
- **A — One selected document with back/forward history.** For: simplest and low clutter. Against: slow cross-reference work.
- **B — Tabbed documents with pinned tabs and history.** For: good comparison and return points. Against: tab overload.
- **C — Arbitrary multi-window documents.** For: strong multi-monitor use. Against: platform/window-state complexity.
- **Recommendation: B**; defer floating windows.

### [CEUI-4] Are docks rearrangeable in v1? **[OPEN]**
- **A — Fixed layout with resizable/collapsible regions.** For: testable and recoverable. Against: less personal.
- **B — Reorder within approved slots and save layouts.** For: flexibility. Against: persistence and support burden.
- **C — Fully floating docks.** For: maximum flexibility. Against: weak portability and easy lost panels.
- **Recommendation: A** for v1; leave B as a later additive feature.

### [CEUI-5] What is the minimum supported editor viewport? **[OPEN]**
- **A — 1280×720 hard floor.** For: predictable density. Against: excludes 1024×768 and large-scale accessibility users.
- **B — 1024×768 floor, with only one side panel open; 1280×720 comfortable.** For: broad desktop support without phone compromises. Against: more responsive states.
- **C — Full Compact/phone support.** For: universal. Against: enormous design cost for a precision authoring tool.
- **Recommendation: B**; below it show an explanatory minimum-size state.

### [CEUI-6] How does the editor relate to the Campaign Library? **[OPEN]**
- **A — Library manages installed releases; a separate gated Editor entry manages drafts.** For: preserves settled library scope. Against: two entry points.
- **B — Edit button on every installed pack.** For: discoverable. Against: confuses immutable installed releases with drafts.
- **C — Editor replaces library management.** For: one surface. Against: reopens settled ownership.
- **Recommendation: A**, with an explicit Open source draft action only where one exists.

### [CEUI-7] What appears persistently in the header? **[OPEN]**
- **A — Draft identity/dirty state, Undo/Redo, Validate, Test, Export, Help.** For: critical state/actions always visible. Against: consumes width.
- **B — Only file and workspace menus.** For: quiet. Against: hides safety actions.
- **C — Fully contextual header.** For: maximum canvas space. Against: key actions move unpredictably.
- **Recommendation: A**, collapsing labels to icons with accessible names at the floor.

### [CEUI-8] How is authoring context switched? **[OPEN]**
- **A — Tree selection alone.** For: minimal chrome. Against: weak overview.
- **B — Top-level workspaces (Content, Maps, Graph, Assets, Test, Release) plus tree.** For: clear mental modes. Against: two navigation axes.
- **C — Command palette only.** For: expert speed. Against: poor discoverability and search dependency.
- **Recommendation: B**; command shortcuts may supplement it later.

## B. Records, Inspector, references, and change transactions

### [CEUI-9] What is the primary record-editing surface? **[OPEN]**
- **A — Schema-generated Inspector/forms.** For: consistent validation and open content kinds. Against: may be slow for bulk edits.
- **B — Spreadsheet for everything.** For: rapid bulk comparison. Against: poor nested/reference editing and accessibility.
- **C — Bespoke screen per content kind.** For: tailored. Against: expensive and closed.
- **Recommendation: A**, with schema-generated table views for bulk-safe fields.

### [CEUI-10] How are defaults/inherited values represented? **[OPEN]**
- **A — Visually distinct inherited/default values with per-field reset and origin link.** For: transparent and safe. Against: more states to teach.
- **B — Materialize all values.** For: simple files. Against: hides inheritance and creates noise.
- **C — Hide inherited values.** For: clean. Against: authors cannot explain behavior.
- **Recommendation: A**.

### [CEUI-11] How are references authored? **[OPEN]**
- **A — Typed picker showing valid ids, with jump-to-target and usages.** For: prevents dangling/mistyped refs. Against: needs reference index.
- **B — Free string fields.** For: easy implementation. Against: errors arrive late.
- **C — Drag-only from tree.** For: direct. Against: inaccessible and slow at scale.
- **Recommendation: A**, with drag/drop and literal advanced entry as optional supplements.

### [CEUI-12] How does multi-selection editing work? **[OPEN]**
- **A — Common fields only, with mixed-value state and one atomic edit.** For: safe bulk work. Against: limited for heterogeneous selections.
- **B — Apply entire source record to all.** For: fast. Against: destructive.
- **C — No multi-edit.** For: safest implementation. Against: tedious map/roster work.
- **Recommendation: A**.

### [CEUI-13] What is an Undo unit? **[OPEN]**
- **A — User-intent transactions: coalesced typing, one paint stroke/drag/import/batch operation.** For: predictable. Against: requires explicit transaction discipline.
- **B — Every field event.** For: simple logging. Against: unusable history.
- **C — Whole-document snapshots only.** For: robust. Against: coarse and memory-heavy.
- **Recommendation: A**, backed by snapshots for recovery rather than ordinary Undo.

### [CEUI-14] Is Undo global or document-local? **[OPEN]**
- **A — One chronological project history.** For: actions undo in visible order across references. Against: can affect another tab.
- **B — Per-document histories.** For: local mental model. Against: cross-document transactions become incoherent.
- **C — Both selectable.** For: power. Against: ambiguous and complex.
- **Recommendation: A**, always naming the affected content in the action label.

### [CEUI-15] How are destructive/batch operations committed? **[OPEN]**
- **A — Preview affected records/files, then atomic commit and Undo where safe.** For: informed and recoverable. Against: extra step.
- **B — Confirmation count only.** For: quick. Against: authors cannot inspect consequences.
- **C — Immediate application.** For: fastest. Against: high risk.
- **Recommendation: A**; consume the shared transaction vocabulary rather than inventing editor-only semantics.

### [CEUI-16] How are external disk edits handled? **[OPEN]**
- **A — Detect per-file changes; offer Reload, Keep mine, or structured diff/merge when safe.** For: no silent loss. Against: merge UI cost.
- **B — Editor always wins.** For: simple. Against: destroys external work.
- **C — Disk always wins.** For: disk authority. Against: destroys unsaved editor work.
- **Recommendation: A**, with no generic auto-merge for unknown schemas.

## C. Validation, issues, and developer surfaces

### [CEUI-17] When does validation run? **[OPEN]**
- **A — Incremental after edits plus explicit full Validate/Test/Export passes.** For: fast feedback and authoritative gates. Against: validator scheduling complexity.
- **B — Save only.** For: simple. Against: late feedback.
- **C — Export only.** For: least interruption. Against: costly late failures.
- **Recommendation: A**.

### [CEUI-18] How are issues presented? **[OPEN]**
- **A — Persistent bottom panel grouped by severity/content, each issue navigable to object/field.** For: actionable and scalable. Against: consumes panel space.
- **B — Modal error lists.** For: impossible to miss. Against: interrupts work.
- **C — Inline fields only.** For: local. Against: no project overview.
- **Recommendation: A** plus inline markers.

### [CEUI-19] What blocks test and export? **[OPEN]**
- **A — Test blocks runtime-invalid errors; export blocks all release errors; warnings require review but not blanket acknowledgement.** For: iterative yet safe. Against: severity taxonomy must be trustworthy.
- **B — Any issue blocks both.** For: strict. Against: warnings halt experimentation.
- **C — Nothing blocks.** For: freedom. Against: produces broken packages.
- **Recommendation: A**.

### [CEUI-20] Are quick fixes allowed? **[OPEN]**
- **A — Only deterministic, previewable, undoable fixes registered beside validator rules.** For: safe and extensible. Against: more implementation per rule.
- **B — Broad automatic repair.** For: convenient. Against: obscures intent.
- **C — No fixes.** For: validator purity. Against: repetitive repair work.
- **Recommendation: A**.

### [CEUI-21] Which developer details are visible by default? **[OPEN]**
- **A — Author language by default; ids, paths, schema versions, and raw JSON in an Advanced disclosure.** For: approachable without hiding evidence. Against: two presentation layers.
- **B — Everything always visible.** For: transparent. Against: intimidating/noisy.
- **C — Never expose internals.** For: simple. Against: blocks diagnosis.
- **Recommendation: A**.

### [CEUI-22] Is raw JSON editing built in? **[OPEN]**
- **A — Read-only structured view plus Open externally; revalidate external changes.** For: avoids building a code editor and protects transactions. Against: power users switch apps.
- **B — Full embedded JSON editor.** For: power. Against: text-entry, merge, schema, and accessibility burden.
- **C — No raw view.** For: clean. Against: opaque diagnostics.
- **Recommendation: A** for v1.

## D. Map, encounter, fixtures, and balance testing

### [CEUI-23] How are map concerns separated? **[OPEN]**
- **A — Explicit layers/groups: terrain, regions, deployment, units, objectives, triggers, annotations.** For: selectable visibility/locking and clear semantics. Against: layer management overhead.
- **B — One flat canvas.** For: simple. Against: clutter and accidental edits.
- **C — Separate map files per concern.** For: isolation. Against: synchronization burden.
- **Recommendation: A**.

### [CEUI-24] How are map tools exposed? **[OPEN]**
- **A — Contextual canvas toolbar plus Inspector.** For: tools stay near work; properties remain consistent. Against: mode indicators must be strong.
- **B — Permanent giant palette.** For: all visible. Against: crowds canvas.
- **C — keyboard-only commands.** For: expert speed. Against: inaccessible/discoverability failure.
- **Recommendation: A**, with shortcuts shown in tooltips.

### [CEUI-25] How are authored triggers/objectives represented? **[OPEN]**
- **A — Ordered readable cards/graph backed by registered predicates/actions, with map links.** For: no-code extensibility and spatial navigation. Against: needs cycle/order visualization.
- **B — Free-form script.** For: powerful. Against: violates no-code author model.
- **C — Fixed event dropdowns.** For: easy initially. Against: closed enum.
- **Recommendation: A**.

### [CEUI-26] What test-launch entry points ship first? **[OPEN]**
- **A — Campaign start, selected node/map with fixture, and validation-only.** For: covers end-to-end and fast iteration. Against: fixture model required early.
- **B — Campaign start only.** For: authentic. Against: slow iteration.
- **C — Launch arbitrary runtime scene/state.** For: maximum power. Against: unstable developer surface.
- **Recommendation: A**.

### [CEUI-27] What is an editor fixture? **[OPEN]**
- **A — Named, versioned, editor-only launch context referencing real pack content.** For: reproducible and shareable. Against: must track invalid refs.
- **B — A copied save file.** For: realistic. Against: brittle, mutable, and may leak user state.
- **C — Ad-hoc dialog values discarded after launch.** For: quick. Against: not reproducible.
- **Recommendation: A**, with temporary unsaved overrides allowed before Save as Fixture.

### [CEUI-28] Which fixture fields are required? **[OPEN]**
- **A — Entry node/map, seed, roster/loadouts, campaign flags/resources, difficulty/profile, and optional turn/state setup.** For: deterministic coverage. Against: detailed schema.
- **B — Map and roster only.** For: simple. Against: misses campaign-dependent behavior.
- **C — Full serialized runtime state.** For: exact. Against: tightly coupled and migration-heavy.
- **Recommendation: A**, using declarative inputs rather than serialized transient runtime objects.

### [CEUI-29] How does test return report results? **[OPEN]**
- **A — Structured receipt: fixture/version, seed, outcome, turns, errors, changed campaign state preview, and navigable content refs.** For: reproducible evidence. Against: runtime instrumentation.
- **B — Console text only.** For: cheap. Against: hard to act on.
- **C — No return; author observes play.** For: minimal. Against: loses evidence.
- **Recommendation: A**.

### [CEUI-30] What balance tooling is appropriate? **[OPEN]**
- **A — Deterministic batch runner showing distributions, outliers, failure causes, and exact replayable seeds.** For: evidence without false certainty. Against: simulator/runtime parity cost.
- **B — One numeric balance score.** For: simple. Against: misleading and opaque.
- **C — Manual test only.** For: no simulator bias. Against: weak regression coverage.
- **Recommendation: A**, only where runtime mechanics can be reused exactly; never auto-tune content.

### [CEUI-31] Are reusable encounter templates inherited live? **[OPEN]**
- **A — Explicit template instances with visible overrides; propagation produces a reviewable transaction.** For: reuse plus control. Against: template dependency inside the pack.
- **B — Copy-on-create.** For: simple and independent. Against: fixes do not propagate.
- **C — Silent live inheritance.** For: effortless consistency. Against: surprising mass changes.
- **Recommendation: A**, strictly within the single pack.

## E. Assets, provenance, and themes

### [CEUI-32] Where does the asset manager live? **[OPEN]**
- **A — First-class Editor workspace sharing the tree, Inspector, issues, Undo, and references.** For: one coherent tool and satisfies CSA-11/17. Against: larger editor.
- **B — Separate executable.** For: focused. Against: duplicated pack/session/validation state.
- **C — Modal importer only.** For: smaller. Against: cannot manage usage, provenance, animation, or palettes over time.
- **Recommendation: A**.

### [CEUI-33] What is the import transaction? **[OPEN]**
- **A — Stage files, preview classification/duplicates, enter required catalogue/provenance data, then atomic commit.** For: prevents orphan files and licence omissions. Against: slower than blind drop.
- **B — Copy immediately, annotate later.** For: quick. Against: creates invalid untracked assets.
- **C — Filesystem-only import.** For: power-user simplicity. Against: bypasses catalogue and safety.
- **Recommendation: A**.

### [CEUI-34] How is licence/provenance authored in batches? **[OPEN]**
- **A — Per asset by default; explicitly selected batch may share fields with a review list.** For: efficient without accidental licence stamping. Against: extra review.
- **B — One licence per folder/import.** For: fast. Against: often legally false.
- **C — Infer from filename/source URL.** For: automated. Against: unreliable and unsafe.
- **Recommendation: A**; the editor records claims but never grants permission.

### [CEUI-35] How integrated are sprite/palette tools? **[OPEN]**
- **A — One asset detail workspace with cell/pivot/animation, rotate/mirror, palette frequency/swaps/tint fallback, preview and bake actions.** For: matches settled CSA workflow. Against: dense.
- **B — Separate wizard per operation.** For: guided. Against: fragmented iteration.
- **C — external tools only.** For: smaller scope. Against: fails owner direction.
- **Recommendation: A**, with progressive disclosure and guided first-use tasks.

### [CEUI-36] What happens when an asset is deleted? **[OPEN]**
- **A — Show usages; allow cancel, replace references, or intentional break with issues; never cascade silently.** For: explicit and recoverable. Against: more choices.
- **B — Cascade-delete dependents.** For: leaves no dangling refs. Against: catastrophic content loss.
- **C — Delete and warn afterward.** For: simple. Against: repair burden.
- **Recommendation: A**.

## F. Save/recovery, release, onboarding, and accessibility

### [CEUI-37] What autosave/recovery model is used? **[OPEN]**
- **A — Periodic versioned recovery snapshots separate from explicit saves; crash start offers Restore, Inspect, Discard.** For: protects work without redefining Save. Against: storage/pruning logic.
- **B — Autosave directly over draft.** For: simple. Against: propagates accidental/broken edits.
- **C — Manual save only.** For: clear. Against: poor crash resilience.
- **Recommendation: A**, retaining the last known-good explicit snapshot.

### [CEUI-38] How does export/version bump work? **[OPEN]**
- **A — Release workspace runs full validation, shows diff, recommends semantic bump, requires author confirmation, exports atomically, records size/SHA-256/snapshot.** For: deliberate and auditable. Against: more ceremony.
- **B — Export button silently increments patch.** For: fast. Against: wrong compatibility claims.
- **C — Free-form version and direct zip.** For: flexible. Against: weak safety/evidence.
- **Recommendation: A**; export does not install or activate implicitly.

### [CEUI-39] What onboarding starts a new author? **[OPEN]**
- **A — Open/fork an eligible public pack and guide through identity, map, node, roster, validate, fixture, provenance, export.** For: matches CSA-30/31 and teaches a real vertical slice. Against: needs a suitable public example.
- **B — Blank-pack wizard with generated content hints.** For: clean slate. Against: contradicts the settled no-hints/fork direction.
- **C — Documentation only.** For: cheap. Against: high abandonment.
- **Recommendation: A**; never offer the internal FE pack as a distributable fork.

### [CEUI-40] What accessibility baseline is mandatory? **[OPEN]**
- **A — Full keyboard/controller focus, visible focus and selection, non-color issue/dirty states, scalable chrome, reduced-motion previews, patterned/icon map overlays, keyboard-operable splitters, semantic labels.** For: usable and aligned with UUI. Against: design/test cost.
- **B — Mouse/keyboard desktop minimum, accessibility later.** For: faster. Against: architecture hardens around inaccessible controls.
- **C — Match the game UI exactly including touch/virtual controls.** For: consistency. Against: precision authoring has different needs and mobile scope explodes.
- **Recommendation: A**, while keeping touch-only/phone authoring out of v1.

## Queue and dependency result

This packet can be discussed now. Resolve `CEUI-1..40` as one campaign-editor
session or in the section order above. Do **not** answer search-specific details
during that walk: first resolve the non-modal text-entry packet, then add a small
editor-search supplement if its shared decisions leave editor-only questions.

