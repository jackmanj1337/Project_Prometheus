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

**Then items 2–4, finishing Phase 0.**

**Item 2 landed both remaining token columns in one edit.** The `R1` re-derivation ends the file
at **four** columns, so `[CEUI-S1]`'s editor column lands *with* `[UUI-11]`'s `dense` rather than
being retrofitted around it. The plan expected this to be a two-row coordination because
`EDITOR-BUILD-PREREQUISITES` also claimed the file — **it does not any more**; that claim was
released on 2026-08-17 and the row now claims nothing, so the plan's sentence is stale and this
was one edit.

The test asserts **the arithmetic the column exists for**, not merely its values: seven keys at
44 px fit the 360 floor in `dense` (348) and overflow it in touch (388), reproducing `[UUI-11]`'s
own figures. Values alone would let a well-meaning retune of `row_gap` or `gutter` quietly
reintroduce the overflow the ruling removed.

The editor column carries Sheet 8 with `min_target = 24` (`EW-9`), the six editor-only tokens, and
**the resize bounds for `tree_width` and `inspector_width`** — the bounds are part of the adopted
column, and leaving them in the album means the editor build goes looking for them again.
`SHARED_TOKENS` and `EDITOR_ONLY_TOKENS` are published from the autoload so *every column defines
every shared token* is checkable in code; a hand-maintained list in a test file is what rots when
a fifth column arrives.

**Item 3** published `[UUI-13]`'s eleven role names into the interaction vocabulary — the naming
authority that had explicitly deferred exactly this. It needed a new **Ratified** status term: the
doc's key offered Observed / Recommended / Pending and had no way to say *settled by a register*.
The versioned-API constraint is recorded with its reason (a rename breaks packs the build has
never seen and therefore cannot migrate), as is `EW-8`'s two-themes-at-once **test** obligation.
The deferred-terms paragraph no longer claims visual-theme tokens are wholly deferred.

**Item 4** painted `HSlider` and `ScrollBar`. Two things were verified rather than assumed. Godot
resolves theme entries **through the native class chain** — probed directly, so one `ScrollBar`
block genuinely covers both orientations rather than being a hopeful abstraction. And the grabber
state frames were chosen by **measured luminance** off the sheet: frame 3 (amber, 163) normal,
frame 1 (gold, 208, the brightest present) hover, frame 4 (109, the dimmest) disabled. Sliders get
real art; scrollbars get flat paint from the palette already in the file, because the only bar art
in the kit is horizontal and a horizontally-sliced texture stretches a `VScrollBar`'s caps along
the wrong axis.

Two corrections to the row while doing it: its claimed path `resources/themes/manasoul_ui.tres`
**does not exist** — the theme is at `assets/themes/manasoul_ui.tres` — and item 2's expected
claim collision is gone.

## Commits

Ownership is in `CLAIMS.tsv`. `3f75d1df` is item 0 (the autoload, `UnitDetailsScreen`, the suite),
claimed at `70d5ccc7`; `284ad6ac` is items 2–4 across six files.

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

**Phase 0 is complete.** Its successor, `UI-THEME-ASSEMBLER-2026-08-16` (programme Phase 2), is
gated on the v0.8.0 release window, not on this row.

**One debt is owed and is not dischargeable here: item 4 needs a Windows visual pass.** Headless
can prove a theme entry resolves — it cannot judge whether the slider margins are right, and this
theme's own header comment says the texture and content margins are the main thing to fine-tune.
Treat the paint as wired, not as approved.

`InputModeManager`'s context-scoping — the other half of `[CEUI-S3]` call 1 — is **not** in this
row and stays with `EDITOR-BUILD-PREREQUISITES-2026-08-14`: no comparable deadline, no Phase 0
consumer.

The branch is pushed and unmerged; it is a candidate for the v0.8.0 window rather than an
independent merge.
