# Session Note - 2026-08-18

## Branch context

- Branch: `agent/from-integration/responsive-layout-context-scope`
- Base branch: `agent/integration`
- Base SHA: `3f43a4c513789ea4d62956261a4c0a5cb93cc847`
- Coordination Work ID: `UI-PHASE0-UNBLOCKED-ITEMS-2026-08-16`

## What was done

Closing out `R1` in the tracker, then taking the first thing it unblocked.

**Three rows closed or sequenced, none of them new work.** `BAND4-PREP-V1-BOUNDARY-2026-08-18`
was still `in_progress` with its own prose reading *"NOT APPLIED BY R1"* — true when written,
false by the end of the same day. Verified before closing rather than taken from the diff's
closeout: both 2026-06-30 plans carry `Superseded in part 2026-08-18` banners with moves-out
tables (`0a1bdf17`), the shop plan's two retired non-goals are struck in place and
`ShopStockEntry` gained its durable quantity field, `PREP-V1-S05` carries the
`B4-SHOP-ECONOMY-2026-07-23` edge, and **the whole 435-row graph re-checked independently is
acyclic at 19 layers with `B4-SHOP-ECONOMY` at layer 2 and `PREP-V1-S05` at layer 14** — the
twelve-layer separation the ruling claimed.

**Both unphased non-terminal rows were sequenced**, `LOCALIZATION-L10N-BUILD-2026-08-17` into
`3-build` and `DESIGN-PREVIEW-EVIDENCE-HOME-2026-08-17` into `0-governance`. There are now
**zero** unphased non-terminal rows. Worth stating plainly because the phase is a *grouping*: it
does not answer `LOCALIZATION-L10N-BUILD`'s ordering question, and that was already answered
elsewhere — the owner ruled *before the conversions* on 2026-08-17 and the dependency edge is
live on `V080-RESPONSIVE-SCREEN-CONVERSIONS`. The row's own reference still poses it as open.

**The owner accepted the `R1` re-derivation of the unified UI programme**, closing
`UNIFIED-UI-PROGRAMME-2026-08-12` and unblocking Phase 0.

**Then Phase 0 item 0: `ResponsiveLayout` is context-scoped** (`[CEUI-S3]` call 1). The mechanism
is that **the script is the context** — the autoload instance is the root context and measures the
window exactly as before, and `create_context(sub_viewport)` returns another instance of the same
script bound to that viewport with its own `size_class`, `logical_size`, `menu_mode`,
`info_density` and signals. No new class, no new file, every existing caller untouched.

**Resolution is by viewport, not by an is-embedded flag.** `context_for(node)` walks
`node.get_viewport()` and falls back to the root context, so the same scene resolves to the game
context inside the editor's `SubViewport` and to the root context in the window. That is what
keeps the seven Phase 3 conversions from each acquiring a branch for it, and it is why the one
production consumer changed by a single call rather than a rewrite.

Three decisions worth recording because each could reasonably have gone the other way:

- **Sub-contexts never connect to `SettingsManager`.** `display_size_changed` describes the
  *window*, which is precisely the coupling this scoping exists to break — resizing the editor
  window must not republish a class into the embedded game view, whose size is whatever the editor
  gave its pane.
- **Menu Mode and density are seeded, not inherited.** A sub-context copies the root's values at
  creation and is independent afterwards. A live inheritance link is a propagation rule nobody has
  asked for, and one of those is wrong the first time someone needs it.
- **Freeing a bound viewport auto-releases its context** through `tree_exiting`. Tearing down an
  editor is not a moment anyone remembers to clean up in, so the registry cleans up after itself
  rather than trusting a caller to pair `create_context` with `release_context`.

## Commits

Ownership is in `CLAIMS.tsv`. The work is `3f75d1df` (three files: the autoload, `UnitDetailsScreen`
and the suite), claimed at `70d5ccc7`.

## Gates

- `test_responsive_layout`: **67 passed, 0 failed** — 14 new assertions covering divergent classes,
  per-viewport measurement, resolution in both directions, `context_for(null)`, idempotent
  creation, seeded-then-independent density, cross-context publish isolation, release,
  double-release and auto-release.
- `test_unit_details_screen`: 36 passed, 0 failed.
- `bash run_tests.sh`: **PASS, all suites green.**
- `check_gdscript_style.sh --fix`: PASS, 321 files.
- **Mutation-checked, not assumed.** Reverting `measured_viewport()` to `get_viewport()` fails
  exactly three assertions — *classes did not diverge*, *measured the wrong viewport*, *publish
  crossed contexts* — and leaves the other 64 passing. The new coverage discriminates.

Two things about the tests that are deliberate. They use a **real tree and a real `SubViewport`**
rather than `apply_logical_size()`, because the property under test is *which viewport a context
measures*, and driving the class by hand would assert the seam against itself and pass whatever the
code did. And the test node is **explicitly named** `ResponsiveLayoutUnderTest`: an unnamed
`add_child()` takes the script's name, one letter from the autoload's, and a node that shadows
`/root/ResponsiveLayout` hollows out every later assertion while still printing `OK`.

## Next

Phase 0 items 2–4, in the plan's order. Item 2 (the `dense` token column, `[UUI-11]`) is **one
coordination, not two edits**: the `R1` re-derivation ends the file at **four** columns, so
`[CEUI-S1]`'s editor column with `min_target = 24` should land *with* `dense` rather than be
retrofitted around it — and `EDITOR-BUILD-PREREQUISITES-2026-08-14` also claims that file. Items 3
(publish the role list, `[UUI-13]`) and 4 (SettingsScreen slider/scrollbar paint, `[UITH-6]` first
half) are order-independent and unclaimed.

`InputModeManager`'s context-scoping — the other half of `[CEUI-S3]` call 1 — is **not** in this
row and stays with `EDITOR-BUILD-PREREQUISITES-2026-08-14`: no comparable deadline, no Phase 0
consumer.

The branch is pushed and unmerged; it is a candidate for the v0.8.0 window rather than an
independent merge.
