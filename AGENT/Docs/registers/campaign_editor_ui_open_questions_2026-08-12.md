---
Type: register
Status: OPEN - S10 walk in progress; CEUI-5/S1-S20 ruled 2026-08-14; 22 questions open; Section A closed; search UX released
Last verified: 2026-08-14
Register: CEUI-1..40
Tracker: DISCUSS-CAMPAIGN-EDITOR-UI-2026-07-31
---

# Campaign Editor UI — Open Questions

**Started:** 2026-08-12  
**Research:**
[`campaign_editor_ui_comparative_research_2026-08-12.md`](../design/campaign_editor_ui_comparative_research_2026-08-12.md)

These questions do not reopen the integrated runtime-gated editor, engine chrome,
UUI semantic roles, JSON pack format, open registries, or one-active-self-contained-
pack decisions. Every recommendation is provisional until the owner answers.

> **~~HELD~~ — search and text entry. RELEASED TO THIS REGISTER 2026-08-14.** The hold
> pointed at the non-modal text-entry packet; the owner has since ruled that **non-modal
> text entry is editor-only** and that `NMTE-1..20`'s residue is answered *inside* this
> walk rather than before it. So `CEUI` now **does** decide search behaviour, syntax,
> ranking, focus restoration and the keyboard lifecycle — for the editor, and only for the
> editor. Six `NMTE` questions are closed outright and three are narrowed by the ruling;
> read
> [`NMTE`'s owner rulings](non_modal_text_entry_open_questions_2026-08-12.md#owner-rulings--2026-08-14)
> before answering any search question here. There is no OSK lifecycle to design: the
> editor assumes a physical keyboard.

> **Editor hardware assumption, ruled 2026-08-14 (`[NMTE-S2]`).** The editor may state that
> a **mouse, a physical keyboard and a large screen are strongly recommended**. With
> `[CEUI-5]`'s `1920×880` floor this makes the editor Expanded-only, single-state, and
> **controller is not a design driver** — narrowing every question written around pad
> ownership. Keyboard *reachability* of all essential actions is unaffected; that is an
> accessibility obligation, not an input-device assumption, and `[CEUI-40]` still owns it.
> **`[CEUI-40]` needs an explicit answer because of this:** its option A mandates "full
> keyboard/**controller** focus", and the ruling says controller is not a driver here. Decide
> in the walk whether the editor's accessibility baseline keeps the controller clause or drops
> it to keyboard-only; do not let it pass unexamined.

> **READ THE PRECEDENCE DIFF FIRST — `S9`, written 2026-08-14.**
> [`ceui_precedence_diff_2026-08-14.md`](../design/ceui_precedence_diff_2026-08-14.md) checks all
> forty questions plus the twelve `NMTE` residues against the corpus ratified since this packet was
> authored. **This register cites two ratified ids in forty questions.** Four questions are closed
> by precedence and must not be walked as written — `CEUI-2` (option set), `CEUI-6`, `CEUI-32`,
> `CEUI-39`'s choice; twenty-one are narrowed; six are live conflicts; six questions the packet
> never asks are promoted. **Two of those promoted questions come first:** whether **Menu Scale
> applies to the editor** (if it does, `[CEUI-5]`'s floor does not protect `CEUI-1`'s layout, because
> Menu Scale multiplies density tokens without changing the size class), and **which of three
> incompatible minimum-viewport mechanisms governs** (§3.1). The diff's §7 gives the walk order.

Legend: **[OPEN]** / **[HELD]** / **[RESOLVED]**.

## A. Shell, layout, and navigation

### [CEUI-1] What is the default desktop composition? **[RESOLVED 2026-08-14 — option A; `[CEUI-S1]` removed the `EPUX-03` objection, but the editor's exemption from the pane budget must be stated explicitly]**
- **A — Tree / centre workspace / Inspector / collapsible bottom panel.** For: familiar, selection-driven, scales across content types. Against: dense and needs careful focus order.
- **B — Separate full-screen tools.** For: each tool can be simpler. Against: context switching and duplicated navigation.
- **C — Spreadsheet-first database with pop-out map.** For: excellent bulk records. Against: map, graph, and asset work become second-class.
- **Recommendation: A**, with workspace-specific centre tools.

### [CEUI-2] What content does the left tree expose? **[RESOLVED 2026-08-14 — see `[CEUI-S21]`; option A, one generated descriptor for every category]**
- **A — Semantic content categories generated from schema/registry metadata.** For: author language and open-registry compliance. Against: requires good metadata.
- **B — Raw pack folders/files.** For: transparent disk mapping. Against: leaks storage details and encourages invalid manual organization.
- **C — Hand-coded fixed categories.** For: fastest first implementation. Against: violates the extension principle.
- **Recommendation: A**, plus an advanced Show file action.

### [CEUI-3] How many documents may be open? **[RESOLVED 2026-08-14 — option B (tabs); each tab is an independent `[CEUI-S6]` transaction with its own dirty state]**
- **A — One selected document with back/forward history.** For: simplest and low clutter. Against: slow cross-reference work.
- **B — Tabbed documents with pinned tabs and history.** For: good comparison and return points. Against: tab overload.
- **C — Arbitrary multi-window documents.** For: strong multi-monitor use. Against: platform/window-state complexity.
- **Recommendation: B**; defer floating windows.

### [CEUI-4] Are docks rearrangeable in v1? **[RESOLVED 2026-08-14 — option A for v1; whether the layout persists, and at what scope, defers to `S12`]**
- **A — Fixed layout with resizable/collapsible regions.** For: testable and recoverable. Against: less personal.
- **B — Reorder within approved slots and save layouts.** For: flexibility. Against: persistence and support burden.
- **C — Fully floating docks.** For: maximum flexibility. Against: weak portability and easy lost panels.
- **Recommendation: A** for v1; leave B as a later additive feature.

### [CEUI-5] What is the minimum supported editor viewport? **[RESOLVED]**
- **A — 1280×720 hard floor.** For: predictable density. Against: excludes 1024×768 and large-scale accessibility users.
- **B — 1024×768 floor, with only one side panel open; 1280×720 comfortable.** For: broad desktop support without phone compromises. Against: more responsive states.
- **C — Full Compact/phone support.** For: universal. Against: enormous design cost for a precision authoring tool.
- **Recommendation: B**; below it show an explanatory minimum-size state.

**RESOLVED 2026-08-14 — owner ruling: D, a maximized-browser-window floor of
`1920×880`.** None of A/B/C. The editor assumes a maximized window on the most common
desktop display: `1920` wide, and *just under* `1080` tall once browser chrome and the OS
taskbar are subtracted — a ~200px allowance covering tab strip, omnibox, bookmarks bar and
taskbar, which is the pessimistic case rather than the typical one. Below the floor the
editor shows the explanatory minimum-size state (kept from the `B` recommendation); it does
not degrade into a compromised layout.

**What this ruling removes.** The editor now lives entirely in **Expanded** and has exactly
one responsive state. `B`'s "one side panel at a time" compact-desktop mode does not exist,
so `CEUI-1`'s tree/workspace/Inspector/bottom-panel composition never has to collapse, and
the editor has no Medium and no Compact behaviour to design. Touch-only and phone authoring
remain out of v1 (unchanged). Consequently **the editor is not a consumer of any
size-class-conditional decision** — including the `NMTE` modality ruling, which is a Compact
constraint.

**Cost accepted:** authors on 1366×768 laptops, on 1024×768, or running a non-maximized
window are shown the minimum-size state rather than a working editor. The owner accepted
this deliberately for a precision authoring tool; it is not an oversight to be re-derived.

> **AMENDED 2026-08-14 by `[CEUI-S2]`** (below). The floor stands at `1920×880`, but it is now
> measured in **effective** pixels — `window ÷ editor scale` — not raw ones, because
> `[CEUI-S1]` gave the editor its own scale knob. The cost paragraph above is therefore
> **narrowed**: a 1366×768 author is no longer shut out, they scale down to clear the floor.
> The minimum-size state survives for what remains below it, and names the knob as the remedy.
>
> **One sentence above also needs reading narrowly after `[CEUI-S3]`.** *"The editor is not a
> consumer of any size-class-conditional decision"* is true of the **editor chrome** and false of
> the **embedded playable session**, which renders real game UI at a size class derived from its
> own sub-viewport — including Compact, deliberately, because that is how an author checks a phone
> layout (`[DLUX-15]`, `[L10N-16]`). The `NMTE` modality ruling still does not reach the editor;
> it reaches the *simulated game* running inside it, exactly as it does when the game runs alone.

### [CEUI-6] How does the editor relate to the Campaign Library? **[RESOLVED 2026-08-14 — see `[CEUI-S22]`; option A plus an *Edit a copy* action, which amends `[CEUI-S13]`]**
- **A — Library manages installed releases; a separate gated Editor entry manages drafts.** For: preserves settled library scope. Against: two entry points.
- **B — Edit button on every installed pack.** For: discoverable. Against: confuses immutable installed releases with drafts.
- **C — Editor replaces library management.** For: one surface. Against: reopens settled ownership.
- **Recommendation: A**, with an explicit Open source draft action only where one exists.

### [CEUI-7] What appears persistently in the header? **[RESOLVED 2026-08-14 — see `[CEUI-S11]`; option A, labels always, scroll on overflow]**
- **A — Draft identity/dirty state, Undo/Redo, Validate, Test, Export, Help.** For: critical state/actions always visible. Against: consumes width.
- **B — Only file and workspace menus.** For: quiet. Against: hides safety actions.
- **C — Fully contextual header.** For: maximum canvas space. Against: key actions move unpredictably.
- **Recommendation: A**, collapsing labels to icons with accessible names at the floor.

### [CEUI-8] How is authoring context switched? **[RESOLVED 2026-08-14 — see `[CEUI-S12]`; option B with Localization as a seventh workspace]**
- **A — Tree selection alone.** For: minimal chrome. Against: weak overview.
- **B — Top-level workspaces (Content, Maps, Graph, Assets, Test, Release) plus tree.** For: clear mental modes. Against: two navigation axes.
- **C — Command palette only.** For: expert speed. Against: poor discoverability and search dependency.
- **Recommendation: B**; command shortcuts may supplement it later.

## B. Records, Inspector, references, and change transactions

### [CEUI-9] What is the primary record-editing surface? **[RESOLVED 2026-08-14 — see `[CEUI-S14]`; option A, and the bulk table edits scalars and enums only]**
- **A — Schema-generated Inspector/forms.** For: consistent validation and open content kinds. Against: may be slow for bulk edits.
- **B — Spreadsheet for everything.** For: rapid bulk comparison. Against: poor nested/reference editing and accessibility.
- **C — Bespoke screen per content kind.** For: tailored. Against: expensive and closed.
- **Recommendation: A**, with schema-generated table views for bulk-safe fields.

### [CEUI-10] How are defaults/inherited values represented? **[RESOLVED 2026-08-14 — see `[CEUI-S16]`; option A, origins limited to schema defaults and templates]**
- **A — Visually distinct inherited/default values with per-field reset and origin link.** For: transparent and safe. Against: more states to teach.
- **B — Materialize all values.** For: simple files. Against: hides inheritance and creates noise.
- **C — Hide inherited values.** For: clean. Against: authors cannot explain behavior.
- **Recommendation: A**.

### [CEUI-11] How are references authored? **[RESOLVED 2026-08-14 — see `[CEUI-S15]`; option A, and the picker IS the `[TSV-10]`/`[EPUX-04]` shared selector]**
- **A — Typed picker showing valid ids, with jump-to-target and usages.** For: prevents dangling/mistyped refs. Against: needs reference index.
- **B — Free string fields.** For: easy implementation. Against: errors arrive late.
- **C — Drag-only from tree.** For: direct. Against: inaccessible and slow at scale.
- **Recommendation: A**, with drag/drop and literal advanced entry as optional supplements.

### [CEUI-12] How does multi-selection editing work? **[RESOLVED 2026-08-14 — see `[CEUI-S23]`; option A, and the bulk table is the only surface that does it]**
- **A — Common fields only, with mixed-value state and one atomic edit.** For: safe bulk work. Against: limited for heterogeneous selections.
- **B — Apply entire source record to all.** For: fast. Against: destructive.
- **C — No multi-edit.** For: safest implementation. Against: tedious map/roster work.
- **Recommendation: A**.

### [CEUI-13] What is an Undo unit? **[RESOLVED 2026-08-14 — see `[CEUI-S6]`; the open document's staged overlay, file operations excluded]**
- **A — User-intent transactions: coalesced typing, one paint stroke/drag/import/batch operation.** For: predictable. Against: requires explicit transaction discipline.
- **B — Every field event.** For: simple logging. Against: unusable history.
- **C — Whole-document snapshots only.** For: robust. Against: coarse and memory-heavy.
- **Recommendation: A**, backed by snapshots for recovery rather than ordinary Undo.

### [CEUI-14] Is Undo global or document-local? **[RESOLVED 2026-08-14 — see `[CEUI-S6]`; option B, session-scoped; id-rename residue closed by `[CEUI-S8]`]**
- **A — One chronological project history.** For: actions undo in visible order across references. Against: can affect another tab.
- **B — Per-document histories.** For: local mental model. Against: cross-document transactions become incoherent.
- **C — Both selectable.** For: power. Against: ambiguous and complex.
- **Recommendation: A**, always naming the affected content in the action label.

### [CEUI-15] How are destructive/batch operations committed? **[RESOLVED 2026-08-14 — see `[CEUI-S6]`; option A, consuming the two-primitive staged transaction, not `TSV`]**
- **A — Preview affected records/files, then atomic commit and Undo where safe.** For: informed and recoverable. Against: extra step.
- **B — Confirmation count only.** For: quick. Against: authors cannot inspect consequences.
- **C — Immediate application.** For: fastest. Against: high risk.
- **Recommendation: A**; consume the shared transaction vocabulary rather than inventing editor-only semantics.

### [CEUI-16] How are external disk edits handled? **[RESOLVED 2026-08-14 — see `[CEUI-S24]`; option A narrowed to Reload / Keep mine, no merge UI]**
- **A — Detect per-file changes; offer Reload, Keep mine, or structured diff/merge when safe.** For: no silent loss. Against: merge UI cost.
- **B — Editor always wins.** For: simple. Against: destroys external work.
- **C — Disk always wins.** For: disk authority. Against: destroys unsaved editor work.
- **Recommendation: A**, with no generic auto-merge for unknown schemas.

## C. Validation, issues, and developer surfaces

### [CEUI-17] When does validation run? **[RESOLVED 2026-08-14 — see `[CEUI-S25]`; option A, incremental scoped to the committing document]**
- **A — Incremental after edits plus explicit full Validate/Test/Export passes.** For: fast feedback and authoritative gates. Against: validator scheduling complexity.
- **B — Save only.** For: simple. Against: late feedback.
- **C — Export only.** For: least interruption. Against: costly late failures.
- **Recommendation: A**.

### [CEUI-18] How are issues presented? **[RESOLVED 2026-08-14 — see `[CEUI-S26]`; option A, pack-wide from the last full pass plus live open documents]**
- **A — Persistent bottom panel grouped by severity/content, each issue navigable to object/field.** For: actionable and scalable. Against: consumes panel space.
- **B — Modal error lists.** For: impossible to miss. Against: interrupts work.
- **C — Inline fields only.** For: local. Against: no project overview.
- **Recommendation: A** plus inline markers.

### [CEUI-19] What blocks test and export? **[RESOLVED 2026-08-14 — see `[CEUI-S27]`; two severities, three gates, reconciled onto the ratified model]**
- **A — Test blocks runtime-invalid errors; export blocks all release errors; warnings require review but not blanket acknowledgement.** For: iterative yet safe. Against: severity taxonomy must be trustworthy.
- **B — Any issue blocks both.** For: strict. Against: warnings halt experimentation.
- **C — Nothing blocks.** For: freedom. Against: produces broken packages.
- **Recommendation: A**.

### [CEUI-20] Are quick fixes allowed? **[RESOLVED 2026-08-14 — see `[CEUI-S28]`; the registration seam ships, the fixes do not]**
- **A — Only deterministic, previewable, undoable fixes registered beside validator rules.** For: safe and extensible. Against: more implementation per rule.
- **B — Broad automatic repair.** For: convenient. Against: obscures intent.
- **C — No fixes.** For: validator purity. Against: repetitive repair work.
- **Recommendation: A**.

### [CEUI-21] Which developer details are visible by default? **[RESOLVED 2026-08-14 — see `[CEUI-S29]`; option A, one global Advanced mode]**
- **A — Author language by default; ids, paths, schema versions, and raw JSON in an Advanced disclosure.** For: approachable without hiding evidence. Against: two presentation layers.
- **B — Everything always visible.** For: transparent. Against: intimidating/noisy.
- **C — Never expose internals.** For: simple. Against: blocks diagnosis.
- **Recommendation: A**.

### [CEUI-22] Is raw JSON editing built in? **[RESOLVED 2026-08-14 — see `[CEUI-S5]`; option B, narrowed]**
- **A — Read-only structured view plus Open externally; revalidate external changes.** For: avoids building a code editor and protects transactions. Against: power users switch apps.
- **B — Full embedded JSON editor.** For: power. Against: text-entry, merge, schema, and accessibility burden.
- **C — No raw view.** For: clean. Against: opaque diagnostics.
- **Recommendation: A** for v1.

## D. Map, encounter, fixtures, and balance testing

### [CEUI-23] How are map concerns separated? **[RESOLVED 2026-08-14 — see `[CEUI-S30]`; option A, with the layer set derived from the map schema]**
- **A — Explicit layers/groups: terrain, regions, deployment, units, objectives, triggers, annotations.** For: selectable visibility/locking and clear semantics. Against: layer management overhead.
- **B — One flat canvas.** For: simple. Against: clutter and accidental edits.
- **C — Separate map files per concern.** For: isolation. Against: synchronization burden.
- **Recommendation: A**.

### [CEUI-24] How are map tools exposed? **[RESOLVED 2026-08-14 — see `[CEUI-S31]`; option A, tool set derived from the active layer]**
- **A — Contextual canvas toolbar plus Inspector.** For: tools stay near work; properties remain consistent. Against: mode indicators must be strong.
- **B — Permanent giant palette.** For: all visible. Against: crowds canvas.
- **C — keyboard-only commands.** For: expert speed. Against: inaccessible/discoverability failure.
- **Recommendation: A**, with shortcuts shown in tooltips.

### [CEUI-25] How are authored triggers/objectives represented? **[RESOLVED 2026-08-14 — see `[CEUI-S32]`; option A, the outline is canonical and any graph is a projection]**
- **A — Ordered readable cards/graph backed by registered predicates/actions, with map links.** For: no-code extensibility and spatial navigation. Against: needs cycle/order visualization.
- **B — Free-form script.** For: powerful. Against: violates no-code author model.
- **C — Fixed event dropdowns.** For: easy initially. Against: closed enum.
- **Recommendation: A**.

### [CEUI-26] What test-launch entry points ship first? **[RESOLVED 2026-08-14 — see `[CEUI-S3]` for the surface and `[CEUI-S18]` for the entry-point list; option A]**
- **A — Campaign start, selected node/map with fixture, and validation-only.** For: covers end-to-end and fast iteration. Against: fixture model required early.
- **B — Campaign start only.** For: authentic. Against: slow iteration.
- **C — Launch arbitrary runtime scene/state.** For: maximum power. Against: unstable developer surface.
- **Recommendation: A**.

### [CEUI-27] What is an editor fixture? **[RESOLVED 2026-08-14 — see `[CEUI-S19]`; the snapshot's starting state, saved in the pack, shipped in the one export]**
- **A — Named, versioned, editor-only launch context referencing real pack content.** For: reproducible and shareable. Against: must track invalid refs.
- **B — A copied save file.** For: realistic. Against: brittle, mutable, and may leak user state.
- **C — Ad-hoc dialog values discarded after launch.** For: quick. Against: not reproducible.
- **Recommendation: A**, with temporary unsaved overrides allowed before Save as Fixture.

### [CEUI-28] Which fixture fields are required? **[RESOLVED 2026-08-14 — see `[CEUI-S20]`; option A, declarative inputs]**
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

### [CEUI-32] Where does the asset manager live? **[RESOLVED 2026-07-30 by `[CSA-11]` — option A; recorded here 2026-08-14, the label was stale]**
- **A — First-class Editor workspace sharing the tree, Inspector, issues, Undo, and references.** For: one coherent tool and satisfies CSA-11/17. Against: larger editor.
- **B — Separate executable.** For: focused. Against: duplicated pack/session/validation state.
- **C — Modal importer only.** For: smaller. Against: cannot manage usage, provenance, animation, or palettes over time.
- **Recommendation: A**.


**Recorded, not newly decided.** `[CSA-11]` resolved this on 2026-07-30, owner, option A:
*the tool lives inside our campaign editor, not the general Godot editor*, with the pure
`RefCounted` core underneath kept headless-testable, and `IMP-EDITOR-PLUGIN-2026-07-20`
**superseded and retired** (that tracker row is `completed`). `CEUI-32`'s option A restates
it; option B is the already-rejected `EditorPlugin` shape in different clothes.

The `S9` precedence diff flagged this in §1.1 and said *do not ask* — but the status label was
never flipped, so the register kept advertising a closed question as open. **That is the third
instance of this shape**, after `[CEUI-S7]`'s content palette (ruled 2026-08-10, recorded in no
document) and `TSV-1..9`. The genuinely open part is not *where* the asset manager lives but
*how much room it gets*, which is `CEUI-35`.

### [CEUI-33] What is the import transaction? **[OPEN — platform-neutral per `[CEUI-S4]`; option C is retired with it]**
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

### [CEUI-37] What autosave/recovery model is used? **[OPEN — web-durability half answered by `[CEUI-S4]`; the primitive question walks with diff §3.3]**
- **A — Periodic versioned recovery snapshots separate from explicit saves; crash start offers Restore, Inspect, Discard.** For: protects work without redefining Save. Against: storage/pruning logic.
- **B — Autosave directly over draft.** For: simple. Against: propagates accidental/broken edits.
- **C — Manual save only.** For: clear. Against: poor crash resilience.
- **Recommendation: A**, retaining the last known-good explicit snapshot.

### [CEUI-38] How does export/version bump work? **[OPEN — two destinations per `[CEUI-S9]`; id/author ruled by `[CEUI-S10]`]**
- **A — Release workspace runs full validation, shows diff, recommends semantic bump, requires author confirmation, exports atomically, records size/SHA-256/snapshot.** For: deliberate and auditable. Against: more ceremony.
- **B — Export button silently increments patch.** For: fast. Against: wrong compatibility claims.
- **C — Free-form version and direct zip.** For: flexible. Against: weak safety/evidence.
- **Recommendation: A**; export does not install or activate implicitly.

### [CEUI-39] What onboarding starts a new author? **[OPEN — choice closed by precedence; the authoring floor is `[CEUI-S7]`'s generated art; residue = guided task list vs "no hints"]**
- **A — Open/fork an eligible public pack and guide through identity, map, node, roster, validate, fixture, provenance, export.** For: matches CSA-30/31 and teaches a real vertical slice. Against: needs a suitable public example.
- **B — Blank-pack wizard with generated content hints.** For: clean slate. Against: contradicts the settled no-hints/fork direction.
- **C — Documentation only.** For: cheap. Against: high abandonment.
- **Recommendation: A**; never offer the internal FE pack as a distributable fork.

### [CEUI-40] What accessibility baseline is mandatory? **[RESOLVED 2026-08-14 — see `[CEUI-S17]`; option A minus the controller clause; reduced motion editor-local]**
- **A — Full keyboard/controller focus, visible focus and selection, non-color issue/dirty states, scalable chrome, reduced-motion previews, patterned/icon map overlays, keyboard-operable splitters, semantic labels.** For: usable and aligned with UUI. Against: design/test cost.
- **B — Mouse/keyboard desktop minimum, accessibility later.** For: faster. Against: architecture hardens around inaccessible controls.
- **C — Match the game UI exactly including touch/virtual controls.** For: consistency. Against: precision authoring has different needs and mobile scope explodes.
- **Recommendation: A**, while keeping touch-only/phone authoring out of v1.

## Owner rulings — 2026-08-14 (`S10`, walk in progress)

Walked against
[`ceui_precedence_diff_2026-08-14.md`](../design/ceui_precedence_diff_2026-08-14.md). The walk
took the diff's §7 order and opened on the two promoted questions that gate the rest.

### `[CEUI-S1]` The editor owns its own scale, font size and density settings — **RULED**

**The player's Menu Scale does not reach the editor.** The editor carries its own scale, font
size and related display settings, because it is a different kind of surface: heavy text entry,
dense dropdowns, and — per `[CEUI-S3]` — a game session running inside it.

**This answers the diff's §4.1 and unblocks `CEUI-1`.** `[UUI-8]`'s slider multiplies the density
tokens without changing the size class, so had it reached the editor, `2.0×` on a `1920×880`
window would have produced an effective `960×440`, `[CEUI-5]`'s floor would never have fired, and
`CEUI-1`'s four regions would have sat in exactly the case `[EPUX-03]` cited when it ruled *"never
three panes: a third collapses at 200% Menu Scale"*. That case no longer exists.

**Build it as a token column, not a second scaling system.** `[UUI-11]` set the precedent when
the keyboard grid did not fit the touch tokens: *"rather than a local override or a named
exception, add a third column"*. The editor is a fourth column plus its own multiplier through
the same assembler. `ResponsiveLayout.DENSITY_TOKENS` currently holds only `touch` and
`controller` — `dense` is ruled and unbuilt — so the editor column lands with `dense` rather than
being retrofitted around it.

**It inherits `[UUI-18]` with no new decision.** An editor scale slider can make the editor hard
to get back from, which is exactly what `reachability_risk` means, so it gets the confirm-or-
revert dialog — and the dialog stays exempt from the setting it is confirming, as `[UUI-18]`
already requires.

**Consequence for `S12`:** editor display settings are a new settings group, and their scope
(device? seat? global?) is unruled. `SETTINGS-PERSISTENCE-SCOPE-REVIEW` inherits it. Do not
answer it here.

### `[CEUI-S2]` The floor is measured in effective pixels; the scale knob is the remedy — **RULED**

`[CEUI-5]`'s `1920×880` floor is evaluated against **`window ÷ editor scale`**, not raw window
pixels. An author on 1366×768 who scales the editor down clears the floor and gets a working, if
small, editor; below that the explanatory minimum-size state still appears and **names the scale
knob as the fix**.

**This is the ratified formula, not a new one.** `ResponsiveLayout` already derives the logical
viewport as `backing size ÷ content_scale_factor`; the editor scale is that factor's editor-side
analogue, so the floor test has the same shape as the game's size-class test.

**What it does to Branch K** (`campaign_library_ux_decisions_2026-07-24.md`, ratified
2026-07-25), resolving diff §3.1:

| Branch K mechanism | Disposition |
|---|---|
| Dismissible warning below **1920×1080** | **Superseded** by `[CEUI-5]`+`[CEUI-S2]`. Warn-and-continue is replaced by clear-the-effective-floor-or-see-the-minimum-size-state. |
| The **OR gate's input-mode axis** (warn when input is not keyboard+mouse) | **Survives.** It is the only mechanism that tells an author their input is wrong, and `[NMTE-S2]` made kbm a stated assumption rather than an enforced one. Keep it, keyed off kbm presence — never off "touch absent", per Branch K's own iPad caveat. |
| Settings **declutter row** (hide / auto-hide the editor entry) | **Untouched.** It is about clutter for players who never author, not about capability. |

### `[CEUI-S3]` The simulator is an embedded playable session — **RULED**, and it resolves `CEUI-26` in part

The editor hosts the **full runtime playing the pack being edited**, inside the editor window —
not a preview surface, and not a launch-out. This is the strongest authoring loop and it is what
the owner asked for; it also subsumes `[DLUX-15]`'s per-size-class preview obligation and
`[L10N-16]`'s pseudolocale captures, which a launch-out model would have needed a second
mechanism to satisfy.

**Prior art exists:** `scripts/tools/ui_inspection_preview.gd` already renders production screens
into an offscreen `SubViewport` with theme-resolution and overlap checks, headlessly.

**Five things this forces. None of them are optional, and two are defect risks.**

1. **`ResponsiveLayout` must become context-scoped.** It is an autoload holding one global
   `size_class`, `menu_mode` and `logical_size` derived from the whole window. An embedded
   session needs the editor chrome at editor density while the game view derives its own class
   from its sub-viewport. Today there is exactly **one** production consumer
   (`UnitDetailsScreen.gd`), so this costs almost nothing now and becomes a migration once the
   responsive rollout lands. The same applies to `InputModeManager` — previewing a touch layout
   means the simulated session wants touch density while the editor chrome stays keyboard+mouse.
2. **The session is a `snapshot`, in the ratified vocabulary.** `[DLUX-15]` forbids preview from
   committing campaign state, spending resources, firing authoritative triggers or creating
   `MapLedger`/Rewind history — all of which a *playable* session does by definition. The
   resolution is not an exemption: the embedded session **captures a snapshot at launch and
   discards it at exit**, which is the second of the two primitives ruled 2026-08-13. No third
   mechanism, and `CEUI-27`'s "fixture" is then simply the snapshot's starting state — the two
   concepts unify instead of competing.
3. **Autosave must be sandboxed — defect risk.** `AutosaveTriggerRegistry` and `SavePolicy` are
   live engine paths. An embedded test session that autosaves into the player's slots is a data-
   loss bug, not a UX wrinkle. Route the session's saves into the disposable snapshot scope or
   suppress them, and test that explicitly.
4. **Keyboard arbitration returns, in a new place.** A playable session capturing arrow keys while
   the editor has focused text fields is the same "who owns printable input" problem `NMTE`
   dissolved for the game UI. It reappears as an editor question: click-to-focus the game view,
   an explicit release key, and a visible indication of which context has the keyboard.
   `CEUI-24`'s "mode indicators must be strong" applies to the simulator, not just to map tools.
5. **Two themes on screen at once.** The editor is chrome-themed (`[UUI-14]`) and the game view is
   pack-themed (`[UUI-16]`). `UUI-16` already accepted one boundary-crossing surface — Settings,
   dual-themed by entry point — so this is a second instance of a known shape, but it makes
   `[UUI-9]`/`[UUI-13]`'s "metrics are computed, paint is authored" split load-bearing rather than
   theoretical: the same window renders both theme sets simultaneously.

**`CEUI-26` is therefore resolved in part** — the embedded session is the primary test surface.
Its remaining half (which *entry points* ship: campaign start, selected node/map, validation-only)
is unaffected and still open, as is diff §4.4: **what the session activates**. `CL-ADV-01` already
rules that loose-folder dev packs load only under developer mode and never activate in a normal
player session, which fits — an editor session *is* a developer session. The residue is whether
the working copy activates as a dev source and what becomes of `active_package_identity`
(`[CSA-28(f)/(g)]`) on exit.

### `[CEUI-S4]` Web is a deliberately lesser environment on durability, and the mitigation ships — **RULED**

**Resolves diff §3.2.** The diff framed a binary — capability-gated affordances, or a declared
lesser environment. The ruling is the second, **scoped to one axis and mitigated in the build**:

- **Every web build ships a standing recommendation to export important data frequently to durable
  storage.** Not a one-time modal. `[CSA-36]` already ruled that on web `user://` is browser
  storage a cache clear, private session or storage-pressure eviction can wipe without warning, and
  that the durability warnings get built; this makes the *export* habit the mitigation, and it must
  be reachable at any time rather than dismissed once on entry.
- **Import is streamlined for the same reason.** Frequent export is only a real mitigation if
  getting the data back is cheap.
- **The residual risk is accepted.** It is why desktop exists, and why dedicated mobile builds are
  planned. Web is the accessible tier, not the durable one, and the program says so rather than
  pretending otherwise.

**Two of the six "desktop assumption" questions are not platform questions at all.**
`TransferFileService` (`scripts/resources/TransferFileService.gd`) is a built platform seam whose
own header states the problem exactly: on web `FileDialog` browses the Emscripten virtual
filesystem, so a user "can neither reach a file on their machine nor retrieve anything an export
wrote into browser storage". It stages web saves through `user://` into
`JavaScriptBridge.download_buffer` and web imports through a short-lived `<input type=file>`, and
it does so **without changing any consumer's path-taking API** — `CampaignPackExporter.export_zip`
still just writes to a path. `CampaignLibraryScreen`, `NewGameScreen`, `LoadGameScreen` and
`UserDataMigration` already consume it.

So `CEUI-33`'s import transaction and `CEUI-38`'s export are **identical on both platforms at the
design level**; the editor is a fifth consumer of an existing seam, not a new mechanism, and
neither question needs a platform carve-out. Do not design a second web file path.

**What *is* capability-gated and absent on web: live disk coupling.** A browser has no watchable
path and no second application to hand a file to, so `CEUI-16`'s per-file external-edit detection
and the "Show file" / "Open externally" actions in `CEUI-2` and `CEUI-22` do not exist there. The
editor **states this** rather than hiding the affordance — same family of accepted cost as
durability, same answer.

**Still open, deliberately:** `CEUI-37`'s *other* half — whether a recovery snapshot is a third
persistence primitive — is untouched by this and walks with diff §3.3. Only its web-durability
half is answered here.

### `[CEUI-S5]` Raw JSON is a plain embedded text view, on every platform — **RULED**, answering `CEUI-22`

`CEUI-22`'s recommended option A (read-only structured view plus **Open externally**) would have
preserved `[DLUX-11]`'s ratified *"supported hand-edited JSON remains a first-class input to the
same validator"* on desktop and **silently retired it for every web author** — `[DRC-4]` depends on
that path. Unlike durability, no recommendation mitigates it: the path simply would not be there.

**The ruling is option B, narrowed to its cheapest form.** A plain text view of one record's raw
JSON — Notepad-level. No syntax highlighting, no autocomplete, no schema awareness, no merge UI,
no code editor. `CEUI-22`'s option B was rejected for the text-entry, merge, schema and
accessibility burden of a *full* embedded editor; none of that burden is incurred here.

**It commits through the same validator.** Editing raw JSON is not a bypass — `[DLUX-11]`'s point
is that hand-edited JSON is first-class input *to the same validator*, so the text view revalidates
on commit exactly as the structured form does. A malformed record can be **opened** in it and
fixed; it cannot be **saved** malformed.

**Second rationale, and it constrains the design:** the text view is also the fallback when the
structured editor GUI itself fails on a record — most valuable while the editor is under
development, but not scoped to that period. **Therefore it must be a peer view of the record, not a
tab inside the structured form.** An escape hatch reachable only from the surface that is broken is
not an escape hatch. It has to open for a record the form cannot render.

### `[CEUI-S6]` Editor Undo is not a third primitive — it is a document-scoped staged transaction — **RULED**

**Resolves diff §3.3, and §3.4 with it.** `CEUI-13`/`CEUI-14` proposed an ordered, chronological,
individually reversible project history — a genuinely different mechanism from the two primitives
ruled 2026-08-13. It is **not adopted**. The editor's model is the ordinary document one:

> **Open a document, make changes, save. An interruption reverts.**

That is a **staged transaction** in the ratified vocabulary — overlay + commit/discard — scoped to
the open document. Save commits the overlay; close-without-saving, cancel, or a crash discards it.
No third primitive is introduced, and `RPD-17`/`DRC-33`'s rejected shape is not readmitted through
the editor.

**Why the third primitive was tempting, and why it is unnecessary.** The honest case for one is
that the ratified two govern **runtime campaign state**, where a player must never retroactively
rewrite history, whereas authoring is the one domain where that is the point. But the standing rule
*"prefer staging; snapshot only to undo something already committed"* already covers the whole
surface: the overlay handles the in-progress edit, and `CEUI-37`'s recovery snapshots handle
getting back something already saved. Undo needed no mechanism of its own.

**Three scoping calls, all ruled minimal for v1:**

1. **File-touching operations are excluded from Undo.** Asset import, palette/slice bakes and asset
   deletion write or remove files, not just records. They are **not** undoable actions in v1;
   recovery from a mis-aimed batch import is manual. This is the single biggest simplification —
   it removes filesystem side-effects from the transaction model entirely, and it is why almost
   nothing an author does spans documents.
2. **Undo history is session-scoped.** It does not survive closing and reopening the editor.
   `CEUI-37`'s crash recovery is the durable path; Undo is not, and the two must not be conflated.
3. **`CEUI-14` is therefore document-local (option B), not the packet's recommended A.** The
   recommendation for one chronological project-wide history existed to keep cross-document
   transactions coherent; with file operations excluded, the cross-document case nearly vanishes.
   *Open point:* id renames that rewrite references are the one surviving case — see the note
   below.

**`CEUI-15` names its target: the two-primitive staged transaction, not `TSV`.** `CEUI-15` said to
"consume the shared transaction vocabulary" without saying which, and **two ratified vocabularies
answer to that name**. `TSV-1..24` is the **economy** model, whose ruled consequence #1 reads *"no
cart, no staging, no holds, no per-receipt undo, no partial commits, no expiry windows"* — taken
literally it forbids most of what `CEUI-15` describes. The target is the **staged transaction
primitive** ruled 2026-08-13. A build slice reading `CEUI-15` must not pick whichever it greps
first; this resolves diff §3.4.

**Not undoable, stated so the boundary is deliberate:** a Test session that ran (per `[CEUI-S3]` it
is a snapshot discarded at exit — nothing survives to undo); an export (the zip is written, or on
web the browser download has fired); view state (panel sizes, scroll, selection, layer
visibility/lock, active workspace — `CEUI-4`/`S12` own whether it persists at all); and editor
settings, which have `[UUI-18]`'s confirm-or-revert and are a different mechanism.

**Open, carried into the rest of the walk:** whether an id rename auto-rewrites referencing
records. Under a document-scoped model it is the one author action that must touch documents the
author does not have open. The candidate answers are a multi-document staged transaction, no
auto-rewrite (dangling references surface as validation issues, consistent with `CEUI-36`'s ruled
"show usages, never cascade silently" for the analogous asset-deletion case), or an immediate
unstaged cross-document write — which the model exists to prevent.

### `[CEUI-S7]` The authoring floor is **generated**, not a shipped palette — **RECORDED** (owner ruling 2026-08-10)

**This is not a new decision. It is a decision that existed in no document.** The owner ruled this
on 2026-08-10 on tracker row `DECIDE-EDITOR-CONTENT-PALETTE-2026-07-31`; the row was then closed
`completed` while `grep -ri "content palette" AGENT/Docs/` returned nothing, so the ruling was
invisible to every reader not standing in the tracker. The `S9` precedence diff reopened it as the
`TSV-1..9` provenance shape — a document citing a ruling that exists on no branch — and **the
diff's own guess that "option A is the likely answer" was wrong**. Recorded here 2026-08-14 so it
is findable; the substance is unchanged from 2026-08-10.

**The ruling: none of A–D. Option (E), generate it.** The campaign editor **procedurally generates
flat-colour RGBA panels** — whatever basic shapes and sizes a pack needs — so a newly created pack
has working art from the moment it exists. Curated look-and-feel ships as **pre-selected UI element
combinations distributed separately**: the fork-a-public-pack model applies to the curated
combinations only, never to the bare authoring floor.

**Consequences, as ruled:**

1. **The build ships no palette content.** `CSA-35`'s licensing burden, `CSA-6` `rights_status`
   validation and the `FE-EXPORT-GUARD` question therefore do not arise for the palette at all —
   generated solid-colour rects are first-party by construction.
2. **`IMPL-ZERO-CONTENT-EXPORT-GATE` needs no second carve-out beside web**, because nothing is
   bundled to carve out. The gate must not mistake generated art written into `user://` for
   shipped content.
3. **Option A's "authors start empty" failure mode is answered without shipping anything.** The
   author faces a working pack with placeholder art, not an empty project.

**The two assumptions the row flagged as stated-not-ratified were confirmed by the owner
2026-08-14, and are now ratified:**

- **The panels are written as real image files into the pack at creation time**, not synthesised at
  runtime. This is what "technically has art" buys: a pack that validates and loads by the normal
  uniform-loader path with no special-case empty-art branch. Runtime synthesis would make the
  loader behave differently for new packs than for imported ones.
- **No first-party palette *pack* is produced.** The separately distributed curated combinations
  supersede it.

**Propagation debt this discharges — do not defer it.**
`FIX-ICO5-SEED-CLAUSE-SUPERSESSION-2026-07-31` is unblocked. Its two target lines —
`campaign_content_overlay_open_questions_2026-06-23.md:54` (`[ICO-1]`'s resolution text, not
`[ICO-5]`'s) and `campaign_save_expectations_and_foundations_2026-06-23.md:96` — must be
**rewritten to describe generation**, not deleted. Deleting them silently picks option A and
retires a feature the owner did not drop. A successor row is also owed for the separately
distributed curated combinations, which does not yet exist.

### `[CEUI-S8]` An id rename rewrites references only on explicit per-rename confirmation — **RULED**

Closes the residue `[CEUI-S6]` left open. Under a document-scoped staged transaction, renaming an
id is the one ordinary author action that must touch documents the author does not have open.

**The ruling: it is an opt-in, confirmed, cross-document write.** A small dialog appears **each
time**, and the author confirms or declines; declining leaves the references pointing at the old
id, to surface as ordinary validation issues. The dialog **warns that the rewrite cannot be
automatically undone**, which is true and must be stated rather than hidden — the rewrite commits
outside the open document's overlay, and `[CEUI-S6]` scoped Undo to that overlay.

**This is `CEUI-36`'s pattern, not a second one.** `CEUI-36` already ruled asset deletion as *"show
usages; allow cancel, replace references, or intentional break with issues; never cascade
silently."* Id rename is the same shape and gets the same interaction, so the editor has **one**
"this touches records you do not have open" pattern rather than two bespoke dialogs. Accordingly
the dialog **names how many records and which ones** will be rewritten — `CEUI-36`'s show-usages
bar applies; a bare "are you sure" is a dialog authors learn to click through.

**Recommended and written in here, flagged so it can be vetoed:** the confirmed rewrite is a
**trigger for a `CEUI-37` recovery snapshot**, captured automatically immediately before it
commits. It costs nothing — the snapshot primitive is ruled and already required for crash
recovery, so this adds only a trigger — and it turns "cannot be automatically undone" into a
warning with a real escape hatch behind it.

### `[CEUI-S9]` The editor and the playable library are strictly separated — **RULED**, resolving diff §4.4

**The boundary, and it is stronger than `CL-ADV-01` alone.** The editor **imports a copy** of a
pack from the library. Editing never touches the library original. To play the result outside the
editor, the author **explicitly exports it back to the library as its own version**. There is no
implicit write-back and no in-place editing of an installed pack.

This makes `CL-ADV-01`'s *"installed packs are immutable"* **structurally** true rather than a
policy the editor must remember to honour: the editor has no path that writes into the installed
root. The only route from editor to library is an explicit, validated, author-confirmed export.

**Four calls, ruled:**

1. **Test activates the working copy, as a dev source with its own distinct identity.** Never the
   installed pack. `active_package_identity` must visibly *be* the working copy and must never
   masquerade as the installed `<id>/<version>` — otherwise a save produced in the editor claims
   provenance it does not have, and `CL-ADV-01`'s "never activates in a normal player session"
   becomes unenforceable because nothing can tell the two apart.
2. **Entering the editor deactivates an in-progress campaign — editor entry is quit-to-shell.**
   > **AMENDED 2026-08-14 by `[CEUI-S13]`.** The requirement stands; the *transition* does not. The
   > editor is offered only on the main menu, where no pack is active, so it never performs this
   > deactivation and shows no confirmation for it. Read this call as a **precondition** on the entry
   > point rather than as editor behaviour — and note that the precondition is ratified
   > (`[CSA-28]` clause (f)) but **unbuilt**, so it must be asserted rather than assumed.

   `CSA-28(g)` already deactivates on quit-to-shell and `ICO` permits one active pack, so any
   alternative is a second activation model. The cost is real and the UI states it: entering the
   editor ends the current session, so an in-progress run is saved first. Suspend-and-restore was
   considered and **rejected** — a second activation model is too much machinery for one
   convenience.
3. **An existing save that depends on the pack being edited is unaffected, and this already holds
   in code.** Saves store package *identity*, not paths, and
   `DataManager.select_saved_campaign_source` resolves through the service-owned root — *"Paths
   never come from save data"*. Editing produces a copy elsewhere and the installed pack is
   immutable, so no player save can be reached by any amount of editing. **The hazard runs the
   other way**: the editor session writing into player slots. `[CEUI-S3]` already ruled autosave
   must be sandboxed; this restates it as a **test obligation**, not a design question.
4. **The editor is not a sixth `EPUX-02` availability surface — it inherits the shell's
   vocabulary.** `RPD-10` was rejected 2026-08-13 for proposing a sixth availability vocabulary and
   this would repeat the error. One sentence still has to be written rather than assumed:
   `[EPUX-04]` puts gating in the **game** shell while the editor is application chrome, so the
   inheritance path needs stating explicitly.

**Two consequences that fall out of the boundary and must not be left implicit:**

- **There are two export destinations, and `CEUI-38` was written for only one.**
  **Export-to-library** (playable; lands in `user://campaign_packs/<id>/<version>/` through
  `CampaignPackInstaller`) and **export-to-file** (a zip, or a browser download via
  `TransferFileService` per `[CEUI-S4]`, for distribution). They share the validation gate and
  differ in destination. Build both or say which is deferred; do not build one and assume it covers
  the other.
- **The embedded session is not the developer-mode loose-folder path.** `CL-ADV-01` gates
  loose-folder dev packs behind developer mode, but that rule governs loading loose folders in the
  **normal shell**. Playing the working copy inside the editor is the sanctioned path and does
  **not** require developer mode — Branch K ships the editor visible by default, and putting its
  primary loop behind a flag would contradict that. Do not wire the dev-mode gate to the embedded
  session.

**The export-back id and authorship residue is closed by `[CEUI-S10]`.**

### `[CEUI-S10]` Export-back forks the id, and the pack carries an author the author controls — **RULED**

Closes the residue `[CEUI-S9]` left open. `CampaignPackInstaller` rejects a re-install of the same
id *and* version, so an export back to the library must resolve the identity question; and
`PackManifest` today carries `version`, `builder_content_version`, `authoring_status` and
`format_version` but **nothing identifying who made the pack**, so the editor cannot detect whether
a pack is the author's own.

**Two parts:**

1. **Export-back takes a new id — it forks.** Not the original id with a bumped version. Defaulting
   the other way would let an edited copy of someone else's public pack present in the library as
   *their* newer version, which is a provenance misrepresentation sitting next to `CSA-13`'s
   attribution rules. It costs nothing technically: `ICO` already ruled cross-pack id collisions
   are fine because packs are never loaded together. It also matches the ratified
   **fork-a-public-pack** onboarding model, so forking is the expected flow rather than an edge
   case.
2. **The manifest gains a pack-level author, defaulted from an editor-settings profile and
   overridable at export time.** Exports are marked as the author's by default, and an author who
   wants to publish without their name attached overrides it at the export step. Anonymous export
   is a supported outcome, not a workaround.

**Guardrail one — the author field is authored metadata, never a trust signal.** There is no
account system and no verification; anyone can type any name. It is for display and attribution
only. Nothing may use it to decide ownership, authorization, or "is this pack mine" — that
inference is forgeable by construction, and the editor already has no way to detect ownership,
which is why part 1 defaults to forking rather than to detection.

**Guardrail two — anonymity covers *your* authorship, not third-party attribution.** Overriding
the author field withholds the pack author's own name. It does **not** strip per-asset attribution:
`CSA-34`'s provenance and `CSA-13`'s required attribution are licensing obligations attached to the
assets, not author preferences, and `CSA-6`'s `rights_status` validation still applies. Pack-level
authorship and per-asset attribution are two different things and must not be conflated in the
export UI.

**Implementation constraint, stated so it is not rediscovered:** the field must be **optional** on
`PackManifest`. `format_version` is `1` and the parser rejects unsupported versions, so an optional
field (absent = unattributed) keeps every existing pack valid; making it required would force a
format bump and a migration for no benefit.

**Consequence for `S12`:** the author profile is a new **editor settings** entry per `[CEUI-S1]`,
and it is personal data rather than a display preference — its persistence scope (device? seat?
global?) matters more than the scale slider's. `SETTINGS-PERSISTENCE-SCOPE-REVIEW` inherits it
alongside the editor display settings. Do not answer it here.

**Related gap, flagged not solved:** `authoring_status` (`draft`/`complete`) already exists and is
validated. An export-back landing as `draft` unless the author explicitly marks it complete is a
free way to keep work-in-progress distinguishable in the library; it is not ruled here, and belongs
with `CEUI-38`'s export flow.

### `[CEUI-S11]` The header keeps labels always and scrolls on overflow — **RULED**, answering `CEUI-7`

`CEUI-7` resolves to **A** — draft identity/dirty state, Undo/Redo, Validate, Test, Export, Help
persistently in the header — with its trailing clause replaced.

**The "collapsing labels to icons at the floor" clause is retired**, because `[CEUI-5]` removed the
compact-desktop mode: there is no floor behaviour left to collapse into. It is **replaced, not
deleted**, because the width pressure it addressed is real and now arrives from a different
direction. `[L10N-7]` requires **1.4× text extent proven against a pseudolocale at every durable
viewport**, so seven labelled actions still overflow in a translated build — at the *only* viewport
the editor has.

**The ruling: labels are always shown, and the header scrolls when they overflow.** Never collapse
to icons, never truncate, never clip.

**This is the project's second instance of the same overflow answer, and that is deliberate.**
`UBS-4` ruled that a dialogue line which fits in English and overflows in German **scrolls within
its line object rather than clipping** — explicitly as the answer to `[L10N-7]`'s 1.4× extent. The
editor header now answers the same pressure the same way. Two instances is not yet a ratified
shell-wide rule, but a third surface should adopt it rather than inventing a third behaviour.

**Narrowing from `[CEUI-S6]`:** Undo/Redo are **document-scoped** now, so whether they belong in
the global header or on the document surface is a composition question for the wireframes, not a
settled part of this list.

### `[CEUI-S12]` Localization is a seventh workspace — **RULED**, answering `CEUI-8`

`CEUI-8` resolves to **B** — top-level workspaces plus the tree — and **the proposed workspace list
is extended**. The packet's list (Content, Maps, Graph, Assets, Test, Release) had no slot for
localization, and `CEUI-1..40` mentions localization **zero times**, while four ratified
obligations are authored work with nowhere to live:

- `[L10N-3]` each pack ships its own locale catalogues (forced by `ICO`)
- `[L10N-14]` a pack declares a **completeness level per locale**; missing keys are reported
- `[L10N-15]` explicit **locale-to-asset mapping** in the pack catalogue, using `CSA` semantic
  asset groups
- `[L10N-17]` versioned **context, character limits and screenshots stored beside the message
  IDs**, with spreadsheets as an export and never the authority

**The workspace list is therefore: Content, Maps, Graph, Assets, Localization, Test, Release.**

This resolves diff §4.2 and prevents the failure it named: the first localization surface being
designed by whoever implements `L10N`, rather than by the editor design.

**One boundary still to state:** `[L10N-16]`'s mandatory **pseudolocale captures at all durable
viewports** could belong to Localization or to `CEUI-26`'s test entry points. It is a *test* action
over *localization* data, so the two workspaces need one sentence deciding which owns the entry
point. Not ruled here.

### `[CEUI-S13]` The editor is reachable only from the main menu, so there is no entry transition — **RULED**

**Narrows `[CEUI-S9]` call 2.** That call ruled *"entering the editor deactivates an in-progress
campaign — editor entry is quit-to-shell"*, and the wireframes drew the confirmation dialog it
implies. The owner ruled the dialog away by moving the entry point: **the editor is offered only on
the main menu, where no pack is active.** The editor therefore never ends a run, never deactivates
anything, and shows no confirmation for doing so.

**Call 2's substance survives and is stronger.** The editor still requires that no campaign be
active — but as a **precondition of where the entry point lives**, not as a transition the editor
performs. A player mid-campaign quits to the menu through the shell's own existing confirmation;
the editor adds no second one. This removes an editor-specific interaction rather than duplicating
a shell one, which is the same reasoning `[CEUI-S8]` used to keep the id-rename and asset-delete
confirmations as one pattern.

**It narrows `CEUI-6`.** The question stays open — the *Open source draft* action and the library's
own affordances are untouched — but the editor's entry point is now fixed: **main menu only**. Not
on the Campaign Library screen, not in an in-progress pause menu. Branch K's declutter row (hide or
auto-hide the editor entry) still applies to that main-menu entry and is unaffected.

**The precondition is ratified and unbuilt — a build gate, not a design question.** `[CSA-28]` clause (f)
ruled that quit-to-shell deactivates, but it is not implemented:
`DataManager.deactivate_campaign_package()` has **no production caller**, and `MainMenu.gd` reads
only the installed-pack registry (`playable_campaign_count()`) to enable New Game — it never touches
the active package. **Today the main menu is reached with content still loaded.** Nothing depends on
that yet, which is why it has gone unnoticed; the editor would be the first thing that does, and
activating a working copy over a still-active player pack is the provenance failure `[CEUI-S9]`
call 1 exists to prevent. Give `deactivate_campaign_package()` its caller on the path back to the
shell, and **assert** at editor entry that no package is active rather than assuming it.

### `[CEUI-S14]` Schema-generated forms generalize; the bulk table edits scalars and enums only — **RULED**, answering `CEUI-9`

`CEUI-9` resolves to **A**, and it is a confirmation rather than a new decision: `[DLUX-12]` already
ruled schema-generated forms from the owning registry's schema for the dialogue editor, `DRC-6`
confirmed it, and `EXT` forces it to generalize — a bespoke screen per content kind (option C) would
require an engine edit per new content kind, which is the closed-enum smell the architecture
principle names outright.

**The live residue, ruled: the bulk table view may edit scalar and enum fields, and nothing else.**
No references, no nested structures. Reference edits go only through `[CEUI-S15]`'s typed picker, so
there is exactly **one** authoring path for the one field type that can dangle. The table is a safe
bulk tool over flat values, not a second editor competing with the form.

### `[CEUI-S15]` The editor's reference picker **is** the shared selector — **RULED**, answering `CEUI-11`

`CEUI-11` resolves to **A**, with the mechanism named rather than left open. `[TSV-10]` ruled a
shared selector contract with stable instance ids and `[TSV-24]` ruled focus restoration across
recomposition; `[EPUX-04]` made list/detail/focus/selection shared shell primitives keyed by an
opaque stable record id. **None of it exists in code** — `TSV`'s ruled set names it as unbuilt.

The editor picker **is that selector**, not a second one. A private editor picker would be the sixth
instance of the duplicate-mechanism shape this project has caught five times already.

**Sequencing fact, recorded because it is a scheduling input and not a design detail:** the editor is
what finally forces the shared selector to be built. Whoever schedules editor work is scheduling
`TSV-10`/`TSV-24`/`EPUX-04` implementation with it, and that cost belongs on the editor's estimate
rather than arriving as a surprise dependency.

### `[CEUI-S16]` "Inherited" means schema defaults and templates — never another pack — **RULED**, answering `CEUI-10`

`CEUI-10` resolves to **A**, with the vocabulary pinned. `[ICO-1..6]` reversed the base+overlay
model: one pack is active, completely self-contained, no runtime inheritance and no merge engine.
So an unset value in the editor can have exactly **two** origins:

1. a **schema default**, and
2. a **template instance** (`CEUI-31`).

Values the author has not set are shown distinctly, with per-field reset. **The "origin link" points
at the schema default or the template it came from, and never at another pack or another document.**
This is written explicitly because the phrase *inherited values* is how the overlay model would come
back — an origin link implemented as a cross-pack pointer would revive exactly what `ICO` removed,
and it would look like a feature while doing it.

### `[CEUI-S17]` The accessibility baseline is option A minus controller; reduced motion is editor-local — **RULED**, answering `CEUI-40` and the diff's §4.6

**`CEUI-40` resolves to A with the controller clause struck.** Mandatory: keyboard reachability of
every essential action, visible focus and selection, non-colour issue and dirty states, scalable
chrome, keyboard-operable splitters, and semantic labels. **Controller is dropped** — `[NMTE-S2]`
ruled it is not a design driver for the editor, and paying design and test cost for an input device
the editor tells authors not to use is cost without a beneficiary. Keyboard *reachability* is
untouched by that: it is an accessibility obligation, not an input-device assumption.

**Focus behaviour is inherited, not redeclared.** `[RPD-15]` ruled disabled entries **focusable but
not activatable** shell-wide. The editor takes it. It does **not** declare itself a sixth surface —
`RPD-10` was rejected for proposing a sixth availability vocabulary and this would repeat the error.

**Non-colour channels have a precedent to follow.** `[UUI-13]`'s semantic role vocabulary is the
naming authority, and `[CSA-27]` already ruled the non-colour channel for faction identity
(author-owned palettes plus an engine **glyph**). Issue and dirty states follow that shape rather
than inventing a second one.

**Reduced motion — the diff promoted this, and it is ruled EDITOR-LOCAL.** `grep -ri "reduced
motion" AGENT/Docs/` finds no ratified decision, no settings row and no register, while the game
already has `combat_animations`, `movement_speed` and the whole `CFB-1..18` motion vocabulary. The
answer is the same one the 2026-08-14 walk gave `NMTE-17`'s screen-reader contract: **solve it where
it bites and decline to invent a shell-wide contract early.** Editor chrome does not animate. The
**embedded session still plays the real game**, animations included — it is the game, and muting its
motion would make the preview lie about what a player sees. If a shell-wide reduced-motion contract
is ever wanted it belongs to the game's motion surfaces and `CFB` first, not to an editor register.

### `[CEUI-S18]` All three test entry points ship — **RULED**, closing `CEUI-26`

`CEUI-26` resolves to **A**, closing the half `[CEUI-S3]` left open: **campaign start, selected
node/map with a fixture, and validation-only.** The objection to A was that it needs the fixture
model early; `[CEUI-S19]` and `[CEUI-S20]` settle that in the same walk, so the dependency is paid
rather than deferred.

Option B (campaign start only) makes every check of a late-campaign map cost a full playthrough,
which is most of the iteration cost the editor exists to remove. Launching an arbitrary runtime
scene is **not** adopted: it is an unstable developer surface that would be depended on and would
then constrain refactors.

### `[CEUI-S19]` A fixture is the snapshot's starting state, and it ships in the one export — **RULED**, answering `CEUI-27`

**There is no second fixture concept.** `[CEUI-S3]` already unified it: the embedded session captures
a snapshot at launch and discards it at exit, and a fixture is simply that snapshot's **starting
state**, named and saved. `[DLUX-15]`'s *disposable fixture state* is the same thing. `[DRC-17]`
ruled authored fixtures **supported, not mandatory** — making them mandatory would gate the
fork-a-public-pack onboarding behind writing tests.

**Fixtures live in the pack, and there is ONE export.** The owner rejected the recommended
"excluded from the playable build" and was right to: `[CEUI-S9]` ruled two export *destinations*,
and nothing in the corpus makes the two artifacts differ in *content*. A stripped playable variant
would be a third thing to build, verify and get wrong — the duplicate-mechanism shape again, this
time proposed by the recommendation itself.

**The harms were checked and are not there.** Fixtures are declarative inputs per `[CEUI-S20]`, so
size is negligible. Nothing in the runtime enumerates fixtures, so a player never sees one. There is
no licensing dimension — a fixture references pack content by id and carries no third-party asset,
so `CSA-13` and `CSA-34` are untouched. There is no spoiler surface either: anyone who can unzip a
pack can already read all of its content.

**What is gained is concrete.** One artifact serves *send this so you can play it* and *fork this to
make your own*, which removes a whole class of "did I publish the right export?" error. And because
fork-a-public-pack is the ratified onboarding, a fork now arrives with working test setups — it
teaches how a pack is **exercised**, not only what it contains.

**Two guardrails, neither obvious:**

1. **The fixtures section must be OPTIONAL, and unknown to an older parser is not an error.** Same
   reasoning `[CEUI-S10]` used for the author field: `format_version` is `1` and the parser rejects
   unsupported versions, so a required new section would force a format bump and a migration for no
   benefit.
2. **A dangling fixture reference is a WARNING, never an error.** A fixture can reference content the
   author later renames or deletes. If that were an error it could block `CampaignPackInstaller` and
   stop a **player** installing a pack that is perfectly playable — a broken test setup must never
   be able to do that. `[CEUI-S8]`'s rename confirmation already covers the authoring-time case.

### `[CEUI-S20]` Fixture fields are declarative inputs — **RULED**, answering `CEUI-28`

`CEUI-28` resolves to **A**: entry node/map, seed, roster and loadouts, campaign flags and resources,
difficulty/profile, and optional turn/state setup.

**Declarative authored values, never captured runtime objects.** Option C (full serialized runtime
state) couples fixtures to runtime internals and buys a migration obligation every time those change
— and `[CEUI-S19]` now ships fixtures inside packs, which would make that obligation other people's
problem too. Option B (map and roster only) misses everything campaign-dependent, which is where
most authored branching actually lives.

**The seed is not a new determinism model.** It rides the ratified one — `EXT-4` per-output-path
determinism over the Package A RNG. Do not introduce a fixture-local seed concept.

### `[CEUI-S21]` One generated descriptor produces every tree category — **RULED**, answering `CEUI-2`

`CEUI-2` resolves to **A**, and the residue the diff left is ruled the wide way: **asset kinds and
non-asset content families come from the same declared metadata.** Adding a content family adds a
tree category with **no editor code edit**; display order, grouping and author-facing labels are
authored *in that metadata*, not in GDScript.

**This is the `AGENTS.md` open-registry principle turned on the editor itself.** `[CSA-17(a)]`
ruled one registry rather than "three lists that drift" for the asset side; a hand-ordered
top-level list for content would reintroduce exactly the closed-enum smell one level up — the
registries stay open while the *tree that exposes them* becomes the thing needing an engine edit
per content kind.

**Today there are two sources and neither is a tree descriptor** — `RegistryCatalog` carries
`family`/`id` entries with `REQUIRED_FAMILIES` (`action_primitives`, `resource_types`,
`occupancy_policies`, `objective_conditions`, `item_effects`), and `EntitySchemaRegistry` covers
schema-bearing records. The ruling does **not** require merging them into one registry; it requires
that whatever the editor reads to build the tree is **declared data both of them contribute to**,
so the editor never enumerates families itself. That descriptor is net-new build work and belongs
on the editor's estimate, alongside `[CEUI-S15]`'s shared selector.

**`[CEUI-S4]` already answered the other residue:** *Show file* is live-disk coupling, present on
desktop and absent on web, and the editor states so.

### `[CEUI-S22]` The library gets an *Edit a copy* action — **RULED**, answering `CEUI-6` and **amending `[CEUI-S13]`**

`CEUI-6` resolves to **A** — the library manages installed releases, the editor manages drafts —
**plus an explicit *Edit a copy* action on an installed pack**, which imports a working copy per
`[CEUI-S9]` and opens the editor on it. The recommendation here was "nothing editor-related in the
library"; the owner ruled discoverability worth a second entry point, and the collision that
creates must be written down rather than left for a build slice.

**`[CEUI-S13]` said main-menu-only. That is now amended to two entry points, and the ruling's
substance survives intact.** What `[CEUI-S13]` actually protects is the **precondition** — the
editor is only reachable where no campaign is active, so it never deactivates a run and shows no
confirmation. That still holds, and it holds *in code*: `CampaignLibraryScreen` is instantiated
only as a child of `MainMenu` and of `NewGameScreen` (`scripts/ui/MainMenu.gd:17`,
`scripts/ui/NewGameScreen.gd:50`). Both are pre-campaign shell contexts. **No pause-menu or
in-run entry exists, and none may be added** — that is the part of `[CEUI-S13]` that is not
negotiable, and the `[CSA-28(f)]` deactivate-on-quit-to-shell build gate it named is unchanged and
still owed.

**Recommended and written in here so it can be vetoed:** the action appears only in the
**main-menu** instance of the library, not in the one embedded in `NewGameScreen`. Opening the
editor from inside *choose a campaign to start* is a mode switch away from the task in hand, and
`EPUX-02`'s absent-hides rule covers it without new vocabulary. Branch K's declutter setting hides
the editor entry; when it does, it hides **both** entry points, or the setting does not do what it
says.

**What the action must not become.** It imports a copy — it never opens the installed pack for
editing. `[CEUI-S9]`'s strict separation is unchanged, and the button label says *copy* for that
reason.

### `[CEUI-S23]` The bulk table is the only multi-edit surface — **RULED**, answering `CEUI-12`

`CEUI-12` resolves to **A** — common fields only, mixed-value state, one atomic edit — with the
surface pinned: **the Inspector always edits exactly one record.** Any multi-selection, *including
a selection made on the map canvas*, opens `[CEUI-S14]`'s bulk table over that selection.

**One bulk path, for the same reason `[CEUI-S14]` gave.** That ruling already restricted the table
to scalars and enums so that references have exactly one authoring path; adding mixed-value editing
to the Inspector as well would build the mixed-value state machine twice and give one edit two
routes with different capabilities. The table inherits `[CEUI-S14]`'s restriction unchanged —
scalars and enums, no references, no nested structures — so a multi-selection cannot reach a field
type that can dangle.

**The atomic edit is a staged transaction** (`[CEUI-S6]`), not a new mechanism, and it is
document-scoped like every other one: a bulk edit spanning several records is one commit over the
open documents it touches.

### `[CEUI-S24]` External edits are detected and offer Reload or Keep mine — no merge UI — **RULED**, answering `CEUI-16`

`CEUI-16` resolves to **A**, narrowed: per-file change detection, and a choice of **Reload**
(discard the open overlay and take disk) or **Keep mine** (the next save overwrites disk). **No
structured diff and no merge UI in v1** — that was the largest unbudgeted piece of work in
Section B, and the two-button choice loses nothing that cannot be recovered by hand.

**Detection is not optional, because the workflow it protects is ratified.** `[DLUX-11]` made
hand-edited JSON a first-class input to the same validator and `[DRC-4]` depends on it, so an
author editing a file externally is a supported path, not a misuse. "Editor always wins" would
silently destroy that work; "disk always wins" would silently destroy the overlay.

**Desktop only, per `[CEUI-S4]`.** A browser has no watchable path, so on web this affordance does
not exist and the editor says so. Nothing here is a second web file path — `TransferFileService`
already owns import/export on both platforms.

**It stays outside Undo.** `[CEUI-S6]` excluded file-touching operations from the transaction
model; Reload discards the overlay by the ordinary discard path, and Keep mine changes nothing
until the ordinary save commits.

### `[CEUI-S25]` Validation is incremental per committing document, plus explicit and gate passes — **RULED**, answering `CEUI-17`

`CEUI-17` resolves to **A**, with the incremental half scoped: a document is validated **when its
staged edit commits** (`[CEUI-S6]`), not continuously while the author types. On top of that sit an
**explicit full-pack Validate** the author can run at any time, and an automatic full pass at
**Test** and at **Export**.

**The scoping matters more than the option letter.** Validating an *uncommitted overlay* would make
the validator a consumer of in-progress state and create a second input path beside the committed
document — the validator would have to be correct against data the author has not asserted yet.
Commit-time validation keeps one input shape and still puts the error in front of the author within
one action of causing it.

**Placement was already ruled and is restated, not re-decided:** `CL-ADV-02` puts the deep author
validator in the editor and leaves the player runtime with the plain summary plus exportable
report; `[DLUX-15]` requires preview to **reuse production validators** rather than maintain a
second interpretation. The editor therefore schedules the existing validators; it does not own a
private dialect of them.

### `[CEUI-S26]` The issues panel is pack-wide from the last full pass, with open documents live — **RULED**, answering `CEUI-18`

`CEUI-18` resolves to **A**. A persistent bottom panel groups issues by severity and by content,
each navigable to the object **and field**, with inline markers in the forms. Its contents are the
**last full Validate's results for the whole pack**, with entries for open documents refreshed live
as they commit per `[CEUI-S25]`.

**Staleness is shown, not avoided.** Pack-wide entries carry the pass they came from, so the panel
never claims a clean pack it has not re-checked. The alternative — scoping the panel to open
documents — is never stale and never useful: an author would have no standing view of the pack's
health, which is the whole reason the panel is persistent rather than a dialog.

**It inherits the shell's vocabulary rather than inventing an issue-state one.** `EPUX-02`'s
absent-hides / gated-shows-disabled-with-reason and `[RPD-15]`'s **focusable but not activatable**
govern entries whose target cannot currently be opened. `[CEUI-S17]` already bound the editor to
non-colour channels for issue and dirty states, so severity is never colour alone.

### `[CEUI-S27]` Two severities, three gates — the editor reconciles the ratified model instead of adding a fourth dialect — **RULED**, answering `CEUI-19`

`CEUI-19` is **not** answered with its own taxonomy. Three ratified rulings already govern this and
the editor adopts them:

| Gate | What blocks it |
|---|---|
| **Activation** — and in the editor **a Test launch *is* an activation** of the working copy (`[CEUI-S9]` call 1) | `[DRC-17]`'s four checks, plus any error that makes the pack runtime-invalid |
| **Export-to-library** (`[CEUI-S9]`) | all release errors; `[CRD-9]`'s missing-notice failure; `[L10N-14]`'s declared completeness |
| **Export-to-file** (`[CEUI-S9]`) | the same gate — the two destinations share the validation gate and differ only in destination |

**Severity is two levels: error and warning.** The draft / release-complete axis is `[CRD-9]`'s and
`[L10N-14]`'s, and it is what keeps iteration fast: a working copy is a **draft**, so a missing
attribution notice or an incomplete locale **warns** during authoring and **fails** at
release-complete export. Warnings never block anything; they are reviewable in `[CEUI-S26]`'s panel.

**The activation gate is the one the packet was missing.** `CEUI-19` asked about *test* and *export*
while the ratified vocabulary is *activation* and *export*; naming Test as an activation makes the
editor's gates the same gates the runtime already has, rather than a parallel pair that has to be
kept in step.

**Build note, because this is net-new.** There is **no severity model in the engine today** —
validators return flat error-string arrays (`RegistryCatalog.validate_entry`, `SkillData`,
`CampaignTier2Validators`), and the only warning channels are ad-hoc
(`SpriteSheetFramesBuilder`, `ContentSession.content_warnings`). Two severities and three gates is
a change to the validators themselves, not editor-side presentation, and it belongs on the
estimate as such.

### `[CEUI-S28]` The quick-fix seam ships in v1; the fixes do not — **RULED**, answering `CEUI-20`

`CEUI-20` resolves to **A in contract, deferred in content**. The rule contract carries an
**optional registered fix** from day one — so a fix is added later by registering it beside its
rule, with no engine edit and no reshaping of the issues panel (`EXT`, and DoD#2 applies to the
contract). **v1 validators report only.**

**The seam is the part that is expensive to add late** and cheap to add now; the fixes are the
opposite. Given the editor has already absorbed `[CEUI-S15]`'s shared selector, `[CEUI-S21]`'s tree
descriptor and `[CEUI-S27]`'s severity model as net-new work, shipping a per-rule fix library on
top would be scope the walk has not costed.

**When fixes do arrive they are ordinary staged edits** — deterministic, previewable, and reverting
with the document per `[CEUI-S6]`. A fix that touches files or other documents is not a quick fix;
it is `[CEUI-S8]`'s confirmed cross-document write.

### `[CEUI-S29]` Advanced is one global mode — **RULED**, answering `CEUI-21`

`CEUI-21` resolves to **A**, with the disclosure shape pinned: **one Advanced toggle** in the editor
settings group (`[CEUI-S1]`) reveals ids, paths and schema versions **everywhere at once**. Author
language is the default. Per-panel expanders were considered and rejected — "is Advanced on?" must
have one answer, or the author hunts for the disclosure on every surface.

**Two things are never behind it.** Required attribution (`[CSA-13]`, `[CRD-6]`'s non-suppressible
channel) and issue/dirty state. An Advanced mode that can hide a licensing obligation is a
compliance defect wearing a preference's clothes.

**Raw JSON is not part of this mode.** `[CEUI-S5]` ruled the text view a **peer view of the
record**, reachable whether or not Advanced is on — it is the fallback when the structured form
fails, and gating it behind a preference would put the escape hatch behind the same door.

### `[CEUI-S30]` Map layers are derived from the map schema, not listed in the editor — **RULED**, answering `CEUI-23`

`CEUI-23` resolves to **A** — named layers with per-layer visibility and lock — and the layer set
comes from **the map schema's authored collections via `[CEUI-S21]`'s descriptor**. Terrain, map
objects, deployment/start tiles, unit placements, objectives and triggers, regions and annotations
are layers *because the map document has those collections*, not because the editor names them.
A new authored collection becomes a layer with no editor edit.

**This is the same ruling as `[CEUI-S21]`, applied one level down**, and it matters here because the
map data model is the least built part of the corpus: `MapData` today carries a terrain `grid` of
strings, `player_start_tiles`, `enemy_placements`, `factions`, `turn_order`, victory/defeat
conditions and `fog_enabled` — while `TER-1..10`'s **`map_objects` do not exist in code at all**
(`grep -rl map_object scripts/` is empty), and regions and annotations have never been modelled. A
hardcoded seven-layer list would be a forward commitment to a schema nobody has written; a derived
list is correct on the day the schema grows.

**All one document.** Layers are a view over the single map record — never separate files
(`CEUI-23` option C), which would create a synchronization problem `ICO`'s self-contained pack model
has no answer for.

### `[CEUI-S31]` The canvas toolbar is contextual, and mode is indicated three ways — **RULED**, answering `CEUI-24`

`CEUI-24` resolves to **A**: a toolbar on the canvas whose **tool set comes from the active layer**
(`[CEUI-S30]`), properties in the Inspector, shortcuts in tooltips.

**The mode indicator is the load-bearing half, and it is specified rather than left to a build
slice:** the active tool is shown by toolbar state, by the cursor, **and** by a persistent text
indicator. This is the second instance of an obligation `[CEUI-S3]` already imposed — a playable
session capturing the keyboard while the editor has focused fields needs a visible answer to
*which context owns input* — so the editor has one "what mode am I in" pattern covering both the
map tools and the embedded session, not two.

**Keyboard reachability is `[CEUI-S17]`'s, not this ruling's.** Every tool is reachable from the
keyboard because the accessibility baseline says so; the toolbar exists because option C's
keyboard-only exposure is undiscoverable for the fork-a-public-pack first-time author.

### `[CEUI-S32]` The ordered outline is canonical; every graph is a projection — **RULED**, answering `CEUI-25`

`CEUI-25` resolves to **A**, with `[DLUX-11]`/`[DRC-2]` generalized off dialogue: ordered readable
cards backed by registered predicates and actions, with links into the map, are **both the
authoring surface and the canonical form**. Any graph rendering of trigger logic is a
**demand-gated, read-mostly projection over the same data and stable IDs** — never a second source
format, never a second thing to migrate.

**`CEUI-8`'s Graph workspace is not demoted by this.** Campaign structure — nodes and the edges
between them — *is* graph-shaped data, so a graph is its canonical presentation. Trigger and
objective **logic** is ordered data, so an outline is its canonical presentation. The rule is that
the presentation follows the data's shape; it is not "no graphs anywhere".

**The predicate/action half was already forced.** `TCV-4`, `REQ` and `EXT` make the vocabulary an
open registry, so option C's fixed event dropdowns were never available — adding an objective
condition must not require editing a GDScript `match`.

## Wireframes drawn from these rulings — 2026-08-14

[`campaign_editor_shell_wireframes_2026-08-14.md`](../design/campaign_editor_shell_wireframes_2026-08-14.md)
/ [`../wireframes/albums/campaign_editor_shell_album.html`](../wireframes/albums/campaign_editor_shell_album.html)
— twelve lifecycle states, the seven workspaces, and the shell at all three display viewports.

**Drawn ahead of the gate by owner decision, not because the gate was met.** `UBS-8` and the
`UUI-15` album hold still require the whole walk to close. The set draws workspace *frames* only:
every region whose interior is Sections B–F or `NMTE` carries a dashed outline naming the open
question, so no unwalked question is answered by a drawing.

**Two things the drawing produced that the walk did not, and that `S11` should pick up:**

1. **The FHD/QHD/4K range collapses to three effective viewports.** `[CEUI-S2]`'s
   `window ÷ editor scale`, combined with never rendering editor type physically smaller than FHD at
   100%, gives `max effective = physical resolution − (chrome × DPR)`. 4K at 200% OS scaling is
   *the same window* as FHD at 100%, and 4K at 150% is the same as QHD at 100% — so `1920×880`,
   `2560×1240` and `3840×1960` are the whole range. Nothing in `CEUI-1..40` asks what the editor
   does above its floor, and the answer proposed is four responses keyed to content kind, not a
   breakpoint.
2. **Nine findings, `EW-1..9`**, in the album's Sheet 7 with options and recommendations. Two are
   load-bearing: `EW-1`, that nothing bounds the editor scale knob's *lower* end (clearing the floor
   on a 1366×768 laptop costs 36% of physical type size, and `[CEUI-S2]` named the knob as the remedy
   without bounding it); and `EW-8`, that `[CEUI-S3]`'s two-themes-at-once is a **test obligation**
   rather than a design choice, because a pack theme able to reach editor chrome tokens is a defect
   with a wide blast radius.

   Separately, and not an open finding: the width-response proposal fixes that the embedded
   session's game view must **not** grow with the editor window. Stretching it silently changes the
   size class the author believes they are previewing, which is the exact `[DLUX-15]` failure the
   per-size-class preview obligation exists to prevent. Measured in the album — the `1280×720`
   preview reaches 1:1 at the QHD viewport and must stop there.

## Queue and dependency result

This packet can be discussed now. Resolve `CEUI-1..40` as one campaign-editor
session or in the section order above. ~~Do **not** answer search-specific details
during that walk: first resolve the non-modal text-entry packet, then add a small
editor-search supplement if its shared decisions leave editor-only questions.~~

**Superseded 2026-08-14.** Search *is* answered in this walk. There is no separate
text-entry packet to resolve first and no supplement to add afterwards: `NMTE`'s twelve
surviving questions are editor questions now, and the sequencing plan schedules them as
`S11`, the second half of the `CEUI` walk. Run the `CEUI` precedence diff (`S9`) first —
forty questions authored before six registers resolved — and carry the `NMTE` residue into
it so both are checked against the same corpus at the same time.

