---
Role: dated
Type: register
Status: RESOLVED 2026-08-12 — UUI-1..19 ratified in the owner walk; UUI-20 ratified 2026-10-01
Last verified: 2026-10-01
Register: UUI-1..20
Tracker: UNIFIED-UI-PROGRAMME-2026-08-12
Control plane: [Project Control Plane](../plans/project_control_plane_2026-06-29.md)
---

# Unified UI Programme — Ratified Decisions

**What this is.** Nineteen decisions taken in a single owner walk on 2026-08-12, covering
the whole UI surface rather than one workstream at a time. They close open questions that
had been spread across five tracker rows and four design documents, and they are the
specification the wireframe album is drawn against.

**Authority.** Where this register and an older design doc disagree, this register is
later and wins. It explicitly supersedes named recommendations in `UITH-1..8`, whose
register was retired 2026-08-23 into `GDD_07_UI_UX.md` § *UI Theming* — that section is
now their single home and records this supersession — and named defaults in
[`responsive_ui_redesign_2026-08-06.md`](../design/responsive_ui_redesign_2026-08-06.md);
each supersession is called out on the decision that makes it.

**Wireframe album (proof set, 4 screens × 6 viewports, 26 frames):**
<https://claude.ai/code/artifact/34929585-0ec2-4e96-9040-b084ce5e7fe1>

---

## The six album viewports

Size class is derived from logical **width** alone. These six are the durable test points;
every conversion branch draws and captures against them.

| # | Logical | Class | Aspect | What it proves |
|---|---|---|---|---|
| 1 | 375 × 667 | Compact | 9:16 | the test floor (iPhone SE 2nd gen, `[UUI-20]`); the row-budget worst case |
| 1L | 667 × 375 | Medium | 16:9 | the test floor in landscape (`[UUI-20]`); the narrowest side columns |
| 2 | 393 × 852 | Compact | 19.5:9 | measured real phone (1179×2556 @ 3.0); notch and home indicator |
| 3 | 852 × 393 | Medium | 21:9 | landscape; 4:3 game view + two side control columns |
| 4 | 768 × 1024 | Medium | 3:4 | tablet portrait; the two-pane threshold |
| 5 | 1024 × 768 | Expanded | 4:3 | the Expanded boundary exactly |
| 6 | 1280 × 720 | Expanded | 16:9 | the legacy authoring size, now the largest class |

Control region present on 1–4 (touch), absent on 5–6 (desktop).

*Corrected 2026-10-01 by `[UUI-20]`:* viewport 1 was 360 × 640 and there was no landscape
floor point. The album's frames were drawn at 360 × 640 and are not redrawn; every new
capture uses 375 × 667 and 667 × 375.

---

## A. The control region

### [UUI-1] Landscape game-view rectangle — **preset list, 4:3 default**

`ControllerLayout._default_viewport()` returns portrait `{x:0.05, y:0.03, w:0.90, h:0.55}`
— a real reserved band — but landscape `{x:0, y:0, w:1.0, h:1.0}`, full bleed. Under the
ratified dead-space rule the control region is *whatever the game view leaves over*, so a
full-bleed landscape default reserves nothing, and both shipped landscape presets
("Landscape Side Grips", "Landscape Bottom Dock") can only ever be overlays. That
contradicts the "nothing covers the controls, by default" decision in the one orientation
where it was never drawn.

**Decision:** ship a preset list — 2:3, 1:1, 4:3, 16:9 — with **4:3 as the shipped
default**. 4:3 is the widest rectangle that still fits the split keyboard (3 columns per
side at 852×393); 3:2 and wider drop to 2 columns or fewer and force the shrink fallback.

*Amended 2026-10-01 by `[UUI-20]`:* the default is no longer 4:3 everywhere. It is the
**widest preset whose leftover side columns still hold the controls**: 4:3 at 852 × 393,
1:1 at the 667 × 375 test floor, where a 4:3 view (500 wide) leaves 83 px per side
against the ~150 px the D-pad needs. The preset list itself is unchanged.

**Why a rectangle must be chosen deliberately.** An emulator gets its letterbox for free by
showing a fixed-aspect device on a phone. Prometheus runs `aspect=EXPAND` and will happily
fill the screen, so it must choose a rectangle on purpose in order to have any dead space
at all.

### [UUI-2] Landscape control arrangement — **two side columns**

D-pad plus SELECT/START in the left column, face buttons plus MENU in the right, shoulders
at the top of each. This is what the 4:3 rectangle's leftover geometry produces, and it
matches the DS-emulator landscape reference shot: stacked screens tall and narrow and
centred, leftover as two large side columns.

### [UUI-3] Portrait band — **player-adjustable, 55% default**

The portrait canvas band measures **26% of screen height**, not the 55% `portrait_top`
defines, because `game_view_preset` defaults to `auto` and the active controller
combination reserves roughly three quarters of the screen for controls. All three
references disagree with the measurement: DS 55%, Awakening 54%, the preset itself 0.55.

**Decision:** default 55%, exposed through the Game View editor already built in Slice 3.

*Corrected 2026-10-01:* the cause above is wrong. Read from the code (not re-rendered),
the 26% comes from `ControllerLayout.default_viewport("portrait")` being
`aspect_locked: true`, which `ControllerService._lock_aspect()` crops to a hard-coded 16:9:
0.90 W × 9/16 is 23% of height at 412 × 915 and 28% at 360 × 640. Delivering 55% therefore
means the aspect follows the chosen preset (`[UUI-20]`), not only a new default.
A 26% band cannot show the 12×14 tiles the map layouts are drawn against, which is why
this must land before the conversions reach the map HUD.

---

## B. Layout and chrome

### [UUI-4] Record screens — **drawn and built in UIREC-composed form**

Campaign Library, Load Game, New Game, Unit Details, Promotion and Reclass are specified as
list / detail / action components with a wide adapter and a narrow adapter, not as their
current bespoke trees. The album is therefore the `UIREC-V1-S03/S04` specification, and the
responsive conversion and the component library are built once against one drawing.

This is the concrete form of the `[UITH-2]` recommendation: theming rides UIREC for the
record screens. It removes the "work thrown away twice" risk that register identified.

### [UUI-5] Modal bounds — **confined to the game-view rect, at every size class**

A modal never leaves the game view. Compact is a sheet filling the 360×352 view; Medium and
Expanded are centred cards. Strict separation holds for dialogs the same way it holds for
menus — by construction, not by rule.

Supersedes "responsive modal bounds" as an open item on
`DISCUSS-RESPONSIVE-DISPLAY-LAYERS-2026-08-02`.

### [UUI-6] Safe areas — **background bleeds, interactive content insets**

Panel art, backgrounds and the game canvas fill to the physical edge; every control, label
and touch target insets to the safe rect. No visible letterbox, nothing unreachable.

The PWA shell already publishes real values —
`SettingsManager.refresh_web_safe_area()` reads `{safe, css}` through `JavaScriptBridge`
and `safe_area_insets_from_shell()` converts them — and **nothing consumes them today**.
This decision is the consumer.

*Corrected 2026-10-01:* the in-game half was already built when this was written —
`refresh_web_safe_area()` feeds `safe_area_insets` since 83a94acb (2026-08-04), read by
`HUD._safe_viewport_rect()`, `ModalScreen`, `TouchControls` and `MapResultsScreen`. What
still consumes nothing is the HTML on-screen controller: its buttons clamp to a 4 px edge
margin, not to the safe rect.

### [UUI-7] HUD panels — **free positions stored as viewport fractions, clamped**

Positions are stored as fractions of the viewport, not absolute pixels, and clamped on
every resize and class change. This preserves the pixel-exact placement players can achieve
today while removing the stranding.

**Three consequences that must land in the same change** (finding V070-08):

1. The attachment label ("Viewport: Bottom Left") is **derived from the stored fraction**,
   so label and position cannot diverge — today a panel reads "Bottom Left" while sitting
   mid-left.
2. `HUD._queue_layout_reflow` is connected to viewport `size_changed` (`HUD.gd:143`) and
   `_reflow_layout` (`:375-378`) re-applies only `_active_layout`, while `HudLayoutEditor`
   drives panels through `_hud.set_panel_layout` (`HudLayoutEditor.gd:264,274`). A resize
   therefore re-applies a layout that is not the one on screen. **The live layout must be
   the one reflowed.** *(Corrected 2026-10-01: already true when written — since 92d54bbe
   on 2026-08-02 `set_panel_layout` writes into `_active_layout`, which is what
   `_reflow_layout` re-applies.)*
3. The editor toolbar becomes an `HFlowContainer`. It is `PRESET_TOP_WIDE` with unwrapped
   children today, so "Done" clips off the right edge at high viewport — an editor that
   cannot be exited.

---

## C. Density and theming

### [UUI-8] Menu Scale — **multiplies the density tokens**

Menu Scale survives as a player slider (7 levels, 0.5–2.0) but **stops writing Themes
entirely**. It becomes a multiplier on the density token set, so row height, font, gutter,
header/footer and the derived content margins grow together.

**What this retires.** `MenuScale._scaled_theme()` and `_SCALED_CONSTANTS`. Today that
method duplicates the authored base Theme (correct — that is the V030-BUG-01 fix) and then
overwrites five container constants with `roundi(engine_default * factor)`, where the base
is the **engine default**, not the authored value. A pack author who sets
`BoxContainer/separation = 10` gets `4` at factor 1.0. The authored value is discarded
silently, with no warning and no validator.

**What this fixes on screen.** MenuScale scales `default_font_size` and container
separations but not StyleBox `content_margin_*`. On the seven scenes importing
`manasoul_ui.tres`, Menu Scale 2.0× produces 32px type inside an unchanged 14px panel
margin and 12/7 button padding. Under this decision the margins are derived from the same
multiplied tokens, so they grow with the type.

**What it makes general.** `MainMenu.gd:69` implements `apply_menu_scale(_factor)` and
ignores the factor, calling `_apply_responsive_tokens()` instead, because applying both
"would multiply the two density authorities". That was the correct local call and an
unsustainable global one. This decision makes it the rule.

**Accepted consequence.** Menu Scale does not change the size class — that is derived from
`backing ÷ content_scale_factor`, which Menu Scale never touches. So Compact at 2.0× shows
roughly 2 rows instead of 3.9. Nothing is cramped or clipped, and the map is unaffected.
The occlusion opt-in ([UUI-12]) is the relief valve.

### [UUI-9] `content_margin` — **derived from tokens; art keeps `texture_margin`**

A `StyleBoxTexture` carries both 9-slice art (paint) and `content_margin_*` (metric, because
it sets the padding children lay out against). The theme assembler **computes**
`content_margin_*` from density tokens at assembly time and writes it into the StyleBox.
`texture_margin_*` stays with the art — it describes how the bitmap slices, not how content
sits. A deliberately chunky ornate frame is expressed through the 9-slice border, not by
asking for more content padding.

Answers `[UITH-1]`, including its correction that content margins are metrics wearing
paint's clothing.

### [UUI-10] What a pack may author — **paint + font face only**

| Authorable | Not authorable |
|---|---|
| 9-slice art, colors, icons | `content_margin_*` — derived ([UUI-9]) |
| Font **face** | Font **size** — a token |
| | Row height, gutter, header/footer — tokens |
| | Scrollbar width, slider grabber size — safety |

`AssetResolver.gd` already ships a pack-scoped `raw_font` loader with path safety
(`_safe_relative_path` rejects absolute, `res://`, `user://` and `..`), and
`manasoul_ui.tres` already carries a font with an in-file comment inviting the swap — so
the font capability exists and withholding it would be a deliberate removal.

Grabber and scrollbar sizing stay engine-owned on a safety argument: grabber art sets the
touch target, and `ResponsiveLayout` publishes `min_target: 44.0` for touch mode. A pack
shipping a 20px grabber would produce an unhittable control on a phone — the same failure
class as the controller off-screen/overlap rule the harness already enforces. If this is
ever opened up, a validator asserting the **rendered** target against `min_target` is the
precondition, not a follow-up.

Answers `[UITH-4]`.

### [UUI-11] Keyboard metrics — **a third `dense` token column**

Seven columns at 44px with the authored touch tokens (gap 8, gutter 16) is 388px and
overflows 360. Rather than a local override or a named exception, add a third column:

| Token | touch | controller | **dense** |
|---|---|---|---|
| row_height | 48 | 28 | **44** |
| row_gap | 8 | 2 | **4** |
| body_font | 16 | 14 | **16** |
| detail_row | 44 | 18 | **44** |
| min_target | 44 | — | **44** |
| gutter | 16 | 8 | **8** |
| header / footer | 72 / 64 | 40 / 26 | **72 / 64** |

`dense` serves surfaces that are wall-to-wall equal-weight targets. Keys still meet 44pt;
only the whitespace between them shrinks. It composes with the [UUI-8] multiplier and needs
no exception list, so the next wall-to-wall grid inherits an answer instead of arguing for
one.

### [UUI-13] Roles — **adopt `theme_type_variation`, annotate every frame**

`theme_type_variation` is Godot's supported mechanism for painting the same Control class
differently by role, and it has **zero uses in the repo**, so adoption is greenfield.

Roles are named **semantically, never visually**: `frame`, `header`, `footer`, `list_row`,
`detail_pane`, `action`, `danger`, `tooltip`, `hud`, `dialog`, `slider`. "Danger" is the
name, not "the red one" — a pack repaints the palette.

The published list is a **versioned API**. Authors cannot invent roles because they cannot
edit `scenes/ui/`, and themes are distributed separately on their own cadence, so a rename
breaks packs the build has never seen and cannot migrate. The list rides `format_version` /
`builder_content_version` with a real compatibility story.

Answers `[UITH-3]`. Role names belong in
[`ui_ux_interaction_vocabulary_2026-07-24.md`](../design/ui_ux_interaction_vocabulary_2026-07-24.md),
which is the project's naming authority and explicitly deferred exactly this.

### [UUI-14] Theme scope — **application chrome vs in-campaign UI**

The campaign editor shares its theme with the Main Menu, pack management and Campaign
Library. These form one **application chrome** surface. Several themes ship built in — at
minimum a plain light and a plain dark, plus styled sets ("fantasy parchment", "pixelated
retro sci-fi"). Those assets are also published through the **Pack 0 repo** alongside the
public demo campaigns.

**Supersedes the `[UITH-5]` recommendation** (fixed editor theme plus a preview surface).
The editor is not themed separately — it is themed *with* the app chrome, and the player or
author picks that theme. The "a pack must not break the tool that edits it" risk is handled
by scope rather than by a fallback, because a pack simply cannot paint the editor.

**Authors may manually copy the shipped theme assets into their own packs and use them as
their own** for in-campaign UI. That makes the shipped assets a licensing surface: they
must carry terms permitting exactly that copy-into-your-pack use. Cross-check against LEG-4
and the CSA licensing clauses before publishing them.

### [UUI-16] The theme boundary — **the pack selection point**

> "Everything a player can access after selecting a pack should follow the pack's theme."

| Chrome — built-in themes only | Pack-themed — active pack paints |
|---|---|
| Main Menu | HUD, Unit Details, Prep |
| Campaign Library / pack management | Action / Item / Weapon menus |
| Campaign editor | Attack Preview, Level Up |
| New Game / Load Game selection | Promotion, Reclass, Map Results |
| Credits | Game Over, dialogue |
| | **Settings** |

**Settings is dual-themed** and is the one screen that crosses the boundary: chrome theme
when opened from the Main Menu, active pack's theme when opened from inside a campaign.
Identical structure, identical metrics, different paint — which is the strongest available
argument for [UUI-9] and [UUI-13], because today's baked `content_margin` values cannot
deliver that without two copies of the scene.

---

## D. Album method

### [UUI-12] Draw **both occlusion states** for affected screens

Default (separated) and opted-in (fullscreen overlay), for Settings, Campaign Library,
Roster and Prep Hub — the screens where the ~4-row Compact budget actually bites. The
opt-in is the design's own stated answer to the row budget, so an album that never shows it
hides the answer. Discovery of the setting rests on distributor documentation; there is no
in-app onboarding prompt, by owner decision.

### [UUI-15] Unbuilt screens — **hold only the screen whose questions remain open**

Dialogue (`DLUX`/`DRC`) and credits (`CRD`) are design-resolved and may be drawn now. Continue
to hold **shop/convoy, reference compendium and campaign editor** until each group's own walk
resolves. `NMTE-1..20` is the cross-cutting dependency for compendium and editor search, not a
screen sheet of its own. Release each group independently when its walk closes; the unbuilt-screen
album hold is fully lifted when all three groups are resolved. The re-issued agenda is
[`unbuilt_screen_research_agenda_2026-08-12.md`](unbuilt_screen_research_agenda_2026-08-12.md).

### [UUI-17] **Proof set first**, full album after

Four screens × six viewports — Main Menu, Campaign Library, Settings, map HUD — validate
the drawing conventions before the remaining nineteen built screens are drawn to them.

---

## E. Settings — safety and structure

Both raised by the owner on reviewing the proof set.

### [UUI-18] Confirm-or-revert is keyed on **reachability risk**, not on section

`DisplayConfirmDialog.gd` already implements the 15-second confirm-or-revert correctly:
the change is applied so the player can see it, then persisted only on **Keep**, and
restored on **Revert** or on the countdown reaching zero. What is wrong is its *reach*.

Today `confirm: true` is set on exactly two schema rows — `window_mode`
(`SettingsScreen.gd:153`) and `resolution` (`:162`). That misses the setting that can
strand a player most completely: **Control Style = Off on a touch-only device removes
every control there is**, and it lives in Controls, not Display. A display-scoped rule
could never catch it.

**Decision:** replace `confirm: true` with a `reachability_risk` property meaning *this
change can make the UI hard or impossible to get back from*. Any setting carrying it gets
the dialog, wherever it lives.

| Gets the dialog | Why |
|---|---|
| `window_mode` | already guarded — a wrong fullscreen mode can blank the screen |
| `resolution` | already guarded |
| `content_scale_factor` | **re-classes the screen the control is on** — the size class is derived from `backing ÷ factor` |
| `menu_scale_index` | under `UUI-8` it multiplies every token; 2.0× at Compact leaves ~2 rows |
| `menu_mode` | controller mode publishes `min_target: 0` — on a touch device that is a screen of untappable rows |
| `control_style` | **`off` on a touch-only device leaves no control at all** |
| `overlay_menus` | suppresses the control band |
| `game_view_preset` / size / offset | can shrink the canvas until the UI is unreachable — there is no design floor (`[UUI-20]`) |

No dialog: information density, audio, gameplay and accessibility toggles — all
recoverable in place.

*Amended 2026-10-01 by `[UUI-20]`:* this dialog is now the **only** guard against a
too-small view, so it is a precondition for removing the size limits, not a follow-up.

**The constraint that makes the dialog actually work.** It must be **exempt from the
setting it is confirming**. Viewport Scale 4.0 applied to the dialog renders the dialog
itself unreadable; Menu Mode = controller drops `min_target` to 0 under it. The safety net
would then fail in precisely the cases it exists for. **The dialog renders at a fixed safe
scale with 44pt targets regardless of the pending change**, and per `UUI-5` it is still
bounded by the game view, so it cannot cover the controls either.

**Also worth carrying:** `SettingsScreen._ready()` hides confirm-gated rows entirely where
`is_display_config_supported()` is false, so a web build never shows a dropdown it cannot
apply. That gating is keyed on the same property and must follow it — a `reachability_risk`
row is not automatically display-dependent, so the two concerns need separating rather than
sharing one flag as they do today.

### [UUI-19] Settings is **paged by section**, with tabs on wide screens

Six sections become six pages at every size class. Compact shows a section index, then that
section's page, with Back. Medium and Expanded show a **tab strip**.

This is the real answer to the row budget on the worst screen in the programme: 25+ rows
against 3.9 visible was six screens of scrolling; six sections at ~5 rows each is one short
scroll to pick a section and no scroll at all inside most of them. Composed with the
`UUI-12` occlusion opt-in, an entire eight-row section fits Compact at once.

**Consequence to record: Settings is therefore not a UIREC list/detail record screen.** It
is a tabbed pager — a deliberate third composition alongside the list/detail record screens
(`UUI-4`) and the free-position HUD (`UUI-7`). `EPIC-SHARED-RECORD-UI-V1` does not own it,
and the tab strip needs its own `[tab]` role.

**Measured while drawing:** six tabs do **not** fit 524 logical px — "Accessibility" alone
needs roughly 105px at the 16px body token — so the strip must scroll at Medium and only
fits outright at Expanded. Section count is data-adjacent and will grow, so a scrolling
strip is the general case rather than a fallback.

---

## F. Size limits

Ruled by the owner on 2026-10-01, reviewing `MOBILE-CONTROLLER-UUI-GAP-2026-09-28`.

### [UUI-20] **No player-facing minimum size**; the iPhone SE 2nd gen is the test floor

> "Let players make things as small as they want instead of arbitrary limits on screen
> size."

**Decision.**

1. **No design minimum on anything the player sizes.** The game view rectangle and Viewport
   Scale take any value. Three limits are retired: `ControllerLayout.MIN_VIEWPORT_PIXELS`
   (640 × 360 CSS px on the game view), the v0.8.6 Viewport Scale window limit
   (`SettingsManager.CONTENT_SCALE_FLOOR_LONG/SHORT`), and the controller branch's
   `GAME_VIEW_MIN_SIZE` (30% of the screen). `[UUI-18]`'s "640×360 floor" goes with them.
2. **What replaces them is `[UUI-18]`, and it lands first.** A player who shrinks past
   usability gets the 15-second confirm-or-revert. The limits are removed in the same change
   that ships `reachability_risk`, never before it.
3. **A technical minimum only.** The code keeps the smallest size that does not break its
   own arithmetic and still leaves the undo path reachable (on the order of one map tile, or
   the Game View editor's drag handles). It is documented as technical, not as a design floor.
4. **The test floor is the iPhone SE 2nd gen: 375 × 667 portrait and 667 × 375 landscape**
   (CSS px). Every screen is designed and verified there. Below it a screen may clip, but the
   confirm-or-revert dialog and the path to Settings must still work. Replaces 360 × 640.
5. **Default landscape game view: widest that fits** — see the `[UUI-1]` amendment.
6. **Viewport Scale measures the game view**, not the window. Once the shell sizes the
   canvas, the window and the game view differ, and the game view is what is drawn.
7. **Game View presets are `[UUI-1]`'s aspect list plus a size**, keeping the controller
   branch's free-drag editor for a custom rectangle. `auto` is dropped. The aspect lock
   follows the chosen preset; the hard-coded 16:9 is retired (see the `[UUI-3]` correction).
8. **Controller placement follows `[UUI-2]`** for both profiles: labelled actions move into
   the side columns, SELECT/START into the left column. The on-screen controller clamps to
   the safe rect (`[UUI-6]`).
9. **Scope: the web build.** Native desktop keeps the window as the game view.

**Unchanged by this:** `[UUI-11]`'s `dense` column is still needed at 375. With the touch
tokens, seven 44 px keys need 388 px and overflow; with `dense` they need 348 and fit.

---

## Findings raised by this walk

Two discrepancies found while drawing, neither previously recorded.

### The published Compact row budget is optimistic by half a row

`responsive_ui_redesign_2026-08-06.md` spends **header 56 + footer 56** in its budget
block, leaving 240px of content and 4.3 rows. But `ResponsiveLayout.DENSITY_TOKENS`
publishes **header 72 / footer 64**. Against the real tokens a 352px menu region leaves
**216px → 3.9 rows**, not 4.3.

The album is drawn against the token values. The doc and the code disagree and one of them
needs correcting — this register assumes the code is right, because the tokens are what
scenes actually read.

### There is no localization or i18n row anywhere in the tracker

Fonts are pack-swappable and every layout is required to survive roughly 1.3× text extent,
which is the constraint a translation would impose — but no row owns i18n, no design doc
mentions it, and no size-class decision was taken with it in mind. It does not gate any
wireframe. It is recorded here so the gap is visible rather than discovered later by a
translator.
